const fs = require("fs");

function normalize(text) {
  return (text || "").replace(/\r\n/g, "\n").trim();
}

function extractSection(block, label) {
  const pattern = new RegExp(
    `\\*\\*${label}:\\*\\*\\s*([\\s\\S]*?)(?=\\n\\*\\*[^\\n]+:\\*\\*|\\n### Sub-issues|$)`,
    "i"
  );
  const match = block.match(pattern);
  return match ? normalize(match[1]) : "";
}

function parseLabelsByIssueId(matrixText) {
  const labelsByIssueId = {};
  const lines = matrixText.split("\n");

  for (const line of lines) {
    if (!line.trim().startsWith("|")) continue;
    const cells = line.split("|").map((cell) => cell.trim());
    const issueId = cells[1];
    if (!/^\d+\.\d+$/.test(issueId)) continue;

    const labelsCell = cells[8] || "";
    const insideBackticks = labelsCell.match(/`([^`]+)`/);
    const labelsRaw = insideBackticks ? insideBackticks[1] : labelsCell;
    const labels = labelsRaw
      .split(",")
      .map((label) => label.trim())
      .filter(Boolean);

    labelsByIssueId[issueId] = labels;
  }

  return labelsByIssueId;
}

function parseBacklog(backlogText, labelsByIssueId) {
  const issueHeaderRegex = /^##\s+Issue\s+(\d+\.\d+)\s+[—-]\s+(.+)$/gm;
  const subIssueLineRegex = /^-\s+(\d+\.\d+\.\d+)\s+(.+)$/gm;
  const issues = [];
  const matches = [...backlogText.matchAll(issueHeaderRegex)];

  for (let index = 0; index < matches.length; index += 1) {
    const current = matches[index];
    const next = matches[index + 1];
    const issueId = current[1];
    const title = normalize(current[2]);
    const start = current.index + current[0].length;
    const end = next ? next.index : backlogText.length;
    const block = backlogText.slice(start, end);

    const objective = extractSection(block, "Objetivo");
    const description = extractSection(block, "Descrição exata");
    const expectedResult = extractSection(block, "Resultado esperado");
    const acceptance = extractSection(block, "Critérios de aceite");
    const dependencies = extractSection(block, "Dependências");
    const priority = extractSection(block, "Prioridade");
    const area = extractSection(block, "Área");
    const period = extractSection(block, "Período alvo");

    const subIssues = [];
    const subIssueSectionIndex = block.indexOf("### Sub-issues");
    if (subIssueSectionIndex >= 0) {
      const subIssueSection = block.slice(subIssueSectionIndex);
      for (const subMatch of subIssueSection.matchAll(subIssueLineRegex)) {
        subIssues.push({
          id: subMatch[1],
          title: normalize(subMatch[2])
        });
      }
    }

    issues.push({
      id: issueId,
      title,
      objective,
      description,
      expectedResult,
      acceptance,
      dependencies,
      priority,
      area,
      period,
      labels: labelsByIssueId[issueId] || [],
      subIssues
    });
  }

  return issues;
}

function buildIssueBody(issue) {
  const subIssuesChecklist =
    issue.subIssues.length === 0
      ? "- [ ] Nenhuma sub-issue planejada."
      : issue.subIssues.map((sub) => `- [ ] ${sub.id} — ${sub.title}`).join("\n");

  return normalize(`
### Issue ID
${issue.id}

### Objetivo
${issue.objective || "A definir"}

### Descrição exata
${issue.description || "A definir"}

### Resultado esperado
${issue.expectedResult || "A definir"}

### Critérios de aceite
${issue.acceptance || "A definir"}

### Dependências
${issue.dependencies || "nenhuma"}

### Prioridade
${issue.priority || "A definir"}

### Área
${issue.area || "A definir"}

### Período alvo
${issue.period || "A definir"}

### Sub-issues planejadas
${subIssuesChecklist}
`);
}

function buildSubIssueBody(subIssue, parentIssueId, parentIssueNumber) {
  return normalize(`
### Sub-issue ID
${subIssue.id}

### Parent issue
#${parentIssueNumber}

### Parent issue ID
${parentIssueId}

### Escopo
${subIssue.title}

### Critério de conclusão observável
- [ ] Escopo concluído
- [ ] Vinculada e alinhada com a issue pai
`);
}

async function listAllIssues(github, owner, repo) {
  return github.paginate(github.rest.issues.listForRepo, {
    owner,
    repo,
    state: "all",
    per_page: 100
  });
}

function findIssueByMarker(existingIssues, markerTitle, markerBody) {
  return existingIssues.find(
    (issue) => issue.title === markerTitle || (issue.body || "").includes(markerBody)
  );
}

async function run({ github, core, context, dryRun = true, includeSubIssues = true }) {
  const owner = context.repo.owner;
  const repo = context.repo.repo;

  const backlogText = fs.readFileSync("take_your_pills_issues_detalhados.md", "utf8");
  const matrixText = fs.readFileSync("docs/issues-creation-matrix.md", "utf8");
  const labelsByIssueId = parseLabelsByIssueId(matrixText);
  const parsedIssues = parseBacklog(backlogText, labelsByIssueId);

  if (parsedIssues.length === 0) {
    throw new Error("No issues parsed from take_your_pills_issues_detalhados.md");
  }

  core.info(`Parsed ${parsedIssues.length} parent issues from backlog.`);
  const existingIssues = await listAllIssues(github, owner, repo);
  const createdParents = new Map();

  for (const issue of parsedIssues) {
    const title = `Issue ${issue.id} — ${issue.title}`;
    const body = buildIssueBody(issue);
    const marker = `### Issue ID\n${issue.id}`;
    const existing = findIssueByMarker(existingIssues, title, marker);

    if (existing) {
      core.info(`Parent issue already exists for ${issue.id}: #${existing.number}`);
      createdParents.set(issue.id, existing.number);
      continue;
    }

    if (dryRun) {
      core.info(`[dry-run] Would create parent issue: ${title}`);
      continue;
    }

    const created = await github.rest.issues.create({
      owner,
      repo,
      title,
      body,
      labels: issue.labels
    });

    core.info(`Created parent issue ${issue.id}: #${created.data.number}`);
    createdParents.set(issue.id, created.data.number);
    existingIssues.push(created.data);
  }

  if (!includeSubIssues) {
    core.info("Skipping sub-issues by configuration.");
    return;
  }

  for (const issue of parsedIssues) {
    const parentNumber = createdParents.get(issue.id);
    if (!parentNumber) {
      core.info(
        `Skipping sub-issues for ${issue.id} because parent was not created/found in this execution.`
      );
      continue;
    }

    for (const subIssue of issue.subIssues) {
      const title = `Sub-issue ${subIssue.id} — ${subIssue.title}`;
      const marker = `### Sub-issue ID\n${subIssue.id}`;
      const existing = findIssueByMarker(existingIssues, title, marker);

      if (existing) {
        core.info(`Sub-issue already exists for ${subIssue.id}: #${existing.number}`);
        continue;
      }

      if (dryRun) {
        core.info(
          `[dry-run] Would create sub-issue: ${title} (parent #${parentNumber})`
        );
        continue;
      }

      const created = await github.rest.issues.create({
        owner,
        repo,
        title,
        body: buildSubIssueBody(subIssue, issue.id, parentNumber)
      });

      core.info(`Created sub-issue ${subIssue.id}: #${created.data.number}`);
      existingIssues.push(created.data);
    }
  }
}

module.exports = {
  run,
  parseBacklog,
  parseLabelsByIssueId
};

