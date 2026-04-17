function normalizeUsername(value) {
  if (!value) return null;
  const username = String(value).trim().replace(/^@/, "");
  return username || null;
}

function extractField(body, fieldName) {
  if (!body) return null;
  const escaped = fieldName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const regex = new RegExp(`###\\s*${escaped}\\s*\\n+([^\\n]+)`, "i");
  const match = body.match(regex);
  return match ? match[1].trim() : null;
}

function extractParentIssue(body) {
  const rawParent = extractField(body, "Parent issue");
  if (!rawParent) return null;
  const match = rawParent.match(/#?(\d+)/);
  return match ? Number(match[1]) : null;
}

function extractAdditionalReviewers(body) {
  const raw = extractField(body, "Reviewers adicionais (opcional)");
  if (!raw) return [];
  return raw
    .split(",")
    .map((item) => normalizeUsername(item))
    .filter(Boolean);
}

function extractFunctionalLead(body) {
  const rawLead =
    extractField(body, "Líder funcional") ||
    extractField(body, "Lider funcional");
  return normalizeUsername(rawLead);
}

function parseIssueMetadata(issue) {
  const body = issue?.body || "";
  const labels = (issue?.labels || []).map((label) =>
    typeof label === "string" ? label : label.name
  );

  const areaLabel = labels.find((name) => name && name.startsWith("area:"));
  const area = areaLabel ? areaLabel.replace("area:", "") : null;

  return {
    area,
    parentIssue: extractParentIssue(body),
    functionalLead: extractFunctionalLead(body),
    additionalReviewers: extractAdditionalReviewers(body)
  };
}

module.exports = {
  normalizeUsername,
  parseIssueMetadata
};
