const { normalizeUsername } = require("./parse-issue-metadata");

function unique(values) {
  return [...new Set(values.filter(Boolean))];
}

function resolveTechnicalReviewers(changedFiles, routingConfig = {}) {
  const rules = routingConfig.path_reviewers || [];
  const reviewers = [];
  let detectedArea = null;

  for (const file of changedFiles) {
    for (const rule of rules) {
      const prefix = rule.path_prefix || "";
      if (prefix === "" || file.startsWith(prefix)) {
        reviewers.push(...(rule.reviewers || []));
        if (!detectedArea && rule.area) detectedArea = rule.area;
      }
    }
  }

  return {
    technicalReviewers: unique(reviewers.map(normalizeUsername)),
    detectedArea
  };
}

function resolveFunctionalReviewers({
  metadata,
  parentMetadata,
  routingConfig = {}
}) {
  const fallback = normalizeUsername(routingConfig.fallback_reviewer);
  const reviewers = [];

  if (metadata?.functionalLead) {
    reviewers.push(metadata.functionalLead);
  } else if (parentMetadata?.functionalLead) {
    reviewers.push(parentMetadata.functionalLead);
  } else if (fallback) {
    reviewers.push(fallback);
  }

  reviewers.push(...(metadata?.additionalReviewers || []));

  return unique(reviewers.map(normalizeUsername));
}

function filterOutAuthor(reviewers, authorLogin) {
  const normalizedAuthor = normalizeUsername(authorLogin);
  return reviewers.filter((reviewer) => reviewer !== normalizedAuthor);
}

module.exports = {
  resolveTechnicalReviewers,
  resolveFunctionalReviewers,
  filterOutAuthor
};

