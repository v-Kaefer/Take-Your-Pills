async function requestReviewers({
  github,
  owner,
  repo,
  pullNumber,
  reviewers,
  core
}) {
  if (!reviewers || reviewers.length === 0) {
    core.info("No reviewers to request.");
    return;
  }

  try {
    await github.rest.pulls.requestReviewers({
      owner,
      repo,
      pull_number: pullNumber,
      reviewers
    });
    core.info(`Requested reviewers: ${reviewers.join(", ")}`);
  } catch (error) {
    if (error.status === 422) {
      core.warning(`Could not request one or more reviewers: ${error.message}`);
      return;
    }
    throw error;
  }
}

module.exports = {
  requestReviewers
};

