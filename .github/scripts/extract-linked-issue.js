function extractLinkedIssueNumber(text) {
  if (!text) return null;

  const patterns = [
    /\b(?:close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved)\s+#(\d+)\b/gi,
    /\b(?:linked issue|issue|parent issue)\s*:\s*#(\d+)\b/gi
  ];

  for (const pattern of patterns) {
    let match;
    while ((match = pattern.exec(text)) !== null) {
      const number = Number(match[1]);
      if (Number.isInteger(number) && number > 0) {
        return number;
      }
    }
  }

  return null;
}

module.exports = {
  extractLinkedIssueNumber
};

