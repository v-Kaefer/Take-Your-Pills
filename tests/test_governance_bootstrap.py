import io
import json
import os
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

from governance_bootstrap.auto_label import infer_issue_labels
from governance_bootstrap.cli import main
from governance_bootstrap.issue_milestones import milestone_from_body, parent_issue_number_from_body
from governance_bootstrap.issues import generate_issues
from governance_bootstrap.pr_validation import render_failure_comment, validate_branch_name, validate_pr_body, validate_pull_request
from governance_bootstrap.project import label_value


class GovernanceBootstrapTests(unittest.TestCase):
    def test_auto_label_infers_type_status_priority_and_test(self):
        issue = {
            "title": "US-01 | Example",
            "body": "Severity\nHigh\n\nTest type: smoke",
            "labels": [],
        }

        self.assertEqual(
            infer_issue_labels(issue),
            {"type:user-story", "status:backlog", "priority:high", "test:smoke"},
        )

    def test_issue_metadata_parsers_accept_generic_milestones(self):
        body = "Parent story: US-01 (#42)\n\n- Milestone: Release-1.0"

        self.assertEqual(milestone_from_body(body), "Release-1.0")
        self.assertEqual(parent_issue_number_from_body(body), 42)

    def test_label_value_reads_github_label_payloads(self):
        labels = [{"name": "type:task"}, {"name": "priority:critical"}]

        self.assertEqual(label_value(labels, "priority:"), "critical")

    def test_bootstrap_dry_run_does_not_require_token(self):
        with tempfile.TemporaryDirectory() as tmp:
            labels = os.path.join(tmp, "labels.json")
            milestones = os.path.join(tmp, "milestones.json")
            project = os.path.join(tmp, "project.json")
            backlog = os.path.join(tmp, "backlog.json")
            config = os.path.join(tmp, "governance.bootstrap.json")

            with open(labels, "w", encoding="utf-8") as f:
                f.write('[{"name":"status:backlog","color":"C5DEF5","description":"Backlog"}]')
            with open(milestones, "w", encoding="utf-8") as f:
                f.write('[{"title":"M1","description":"Milestone"}]')
            with open(project, "w", encoding="utf-8") as f:
                f.write('{"name":"Board","fields":[]}')
            with open(backlog, "w", encoding="utf-8") as f:
                f.write('{"phases":[]}')
            with open(config, "w", encoding="utf-8") as f:
                f.write(
                    "{"
                    f'"labelsFile":"{labels}",'
                    f'"milestonesFile":"{milestones}",'
                    f'"projectDefinitionFile":"{project}",'
                    f'"backlogManifestFile":"{backlog}",'
                    '"defaults":{"dryRun":true,"runLabels":true,"runMilestones":true,'
                    '"runProjectCreation":true,"runIssueGeneration":true}'
                    "}"
                )

            with patch.dict(os.environ, {"GITHUB_TOKEN": "", "GH_TOKEN": ""}, clear=False):
                output = io.StringIO()
                with redirect_stdout(output):
                    result = main(["bootstrap", "--repo", "owner/repo", "--config", config, "--dry-run"])

        self.assertEqual(result, 0)
        self.assertIn("[DRY-RUN] Would sync 1 labels", output.getvalue())
        self.assertIn("Governance bootstrap finished.", output.getvalue())

    def test_generate_issues_renders_structured_story_and_task_bodies(self):
        manifest = {
            "defaultIssueLabels": ["status:backlog"],
            "phases": [
                {
                    "phase": "phase:1",
                    "milestone": "MS1",
                    "stories": [
                        {
                            "storyId": "US-01",
                            "title": "US-01 | Example",
                            "labels": ["type:user-story", "priority:critical"],
                            "body": "Como jogador, quero um loop base.",
                            "acceptanceCriteria": [
                                "auto-run begins immediately",
                                "pause stops movement",
                            ],
                            "testStrategy": ["open Game and verify motion"],
                            "dod": ["player scene and Game hookup exist"],
                            "tasks": [
                                {
                                    "title": "T-01.1 | Create Player scene",
                                    "technicalScope": ["create scene", "add collider"],
                                    "completionCriteria": ["scene instantiates cleanly"],
                                    "testStrategy": ["open the scene in editor"],
                                    "expectedEvidence": ["scene tree screenshot"],
                                    "dod": ["player scene created"],
                                }
                            ],
                        }
                    ],
                }
            ],
        }

        with tempfile.TemporaryDirectory() as tmp:
            manifest_path = os.path.join(tmp, "backlog.json")
            with open(manifest_path, "w", encoding="utf-8") as f:
                json.dump(manifest, f)

            with patch("governance_bootstrap.issues.create_issue", side_effect=[101, 102]) as create_issue:
                generate_issues("owner/repo", manifest_path)

        self.assertEqual(create_issue.call_count, 2)

        story_body = create_issue.call_args_list[0].args[2]
        task_body = create_issue.call_args_list[1].args[2]

        self.assertIn("## Acceptance criteria", story_body)
        self.assertIn("- auto-run begins immediately", story_body)
        self.assertIn("## Test strategy", story_body)
        self.assertIn("- open Game and verify motion", story_body)
        self.assertIn("## Definition of Done", story_body)
        self.assertIn("- player scene and Game hookup exist", story_body)

        self.assertIn("## Technical scope", task_body)
        self.assertIn("- create scene", task_body)
        self.assertIn("## Completion criteria", task_body)
        self.assertIn("- scene instantiates cleanly", task_body)
        self.assertIn("## Expected evidence", task_body)
        self.assertIn("- scene tree screenshot", task_body)

    def test_pr_validation_collects_branch_and_body_findings(self):
        findings = validate_pull_request("feature/new-branch", "")

        self.assertEqual([finding.section for finding in findings], ["Branch name", "PR body"])
        self.assertIn("feat/repo-governance-bootstrap", findings[0].fix)
        self.assertIn("blank", findings[1].problem)

    def test_pr_body_validation_rejects_placeholder_steps(self):
        body = """## Linked Issue
- Closes #12

## Milestone
- MS1

## Summary
- Replace me

## How to test
- Test type: manual
- Steps: describe the commands, manual flow, or verification evidence

## Evidence
- [ ] Screenshot/GIF attached (when applicable)

## Known risks
- None

## DoD checklist
- [ ] Scope implemented as defined
"""

        findings = validate_pr_body(body)

        self.assertTrue(any(finding.section == "Summary" for finding in findings))
        self.assertTrue(any(finding.section == "How to test" and "test steps" in finding.problem for finding in findings))

    def test_render_failure_comment_includes_fix_guidance(self):
        findings = validate_branch_name("bad-branch") + validate_pr_body("")

        comment = render_failure_comment(findings)

        self.assertIn("<!-- governance-pr-validation -->", comment)
        self.assertIn("## PR validation failed", comment)
        self.assertIn("Branch name", comment)
        self.assertIn("PR body", comment)
        self.assertIn("Closes #123", comment)
        self.assertIn("Steps: describe the commands", comment)


if __name__ == "__main__":
    unittest.main()
