import io
import json
import os
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest.mock import Mock, patch

from governance_bootstrap.auto_label import infer_issue_labels
from governance_bootstrap.cli import main
from governance_bootstrap.github import API_BASE, GitHubClient, GitHubRequestError
from governance_bootstrap.issue_milestones import milestone_from_body, parent_issue_number_from_body
from governance_bootstrap.issues import generate_issues
from governance_bootstrap.pr_validation import render_failure_comment, validate_branch_name, validate_pr_body, validate_pull_request
from governance_bootstrap.pr_hygiene import (
    apply_pr_hygiene,
    is_hotfix_pr,
    linked_task_number,
    project_status_for_event,
    status_option_id,
    sync_pr_metadata,
)
from governance_bootstrap.pr_hygiene import PullRequestContext as HygienePullRequestContext
from governance_bootstrap.project import label_value
from governance_bootstrap.release import (
    ReleaseAssetLink,
    ReleaseVersion,
    extract_release_context,
    parse_name_status_lines,
    prepare_main_release,
    publish_release,
    render_change_summary_comment,
    render_release_body,
    render_release_context_comment,
    summarize_change_items,
)


class GovernanceBootstrapTests(unittest.TestCase):
    def test_github_client_release_wrappers_call_expected_endpoints(self):
        client = GitHubClient("token")
        version = ReleaseVersion("final", "1.2.3")

        with patch.object(client, "request_json", return_value={}) as request_json:
            client.get_git_ref("owner/repo", "tags/final-1.2.3")
            request_json.assert_called_once_with("GET", f"{API_BASE}/repos/owner/repo/git/ref/tags/final-1.2.3")

        with patch.object(client, "request_json", return_value={}) as request_json:
            client.create_git_ref("owner/repo", "refs/tags/final-1.2.3", "abc123")
            request_json.assert_called_once_with(
                "POST",
                f"{API_BASE}/repos/owner/repo/git/refs",
                {"ref": "refs/tags/final-1.2.3", "sha": "abc123"},
            )

        with patch.object(client, "request_json", return_value={}) as request_json:
            client.get_release_by_tag("owner/repo", "final-1.2.3")
            request_json.assert_called_once_with("GET", f"{API_BASE}/repos/owner/repo/releases/tags/final-1.2.3")

        with patch.object(client, "request_json", return_value={}) as request_json:
            client.create_release("owner/repo", version, "abc123", "body")
            request_json.assert_called_once_with(
                "POST",
                f"{API_BASE}/repos/owner/repo/releases",
                {
                    "tag_name": "final-1.2.3",
                    "target_commitish": "abc123",
                    "name": "final-1.2.3",
                    "body": "body",
                    "prerelease": False,
                },
            )

        with patch.object(client, "request_json", return_value={}) as request_json:
            client.update_release("owner/repo", 77, version, "abc123", "body")
            request_json.assert_called_once_with(
                "PATCH",
                f"{API_BASE}/repos/owner/repo/releases/77",
                {
                    "tag_name": "final-1.2.3",
                    "target_commitish": "abc123",
                    "name": "final-1.2.3",
                    "body": "body",
                    "prerelease": False,
                },
            )

        with patch.object(client, "request_json", return_value={}) as request_json:
            client.delete_release_asset("owner/repo", 88)
            request_json.assert_called_once_with("DELETE", f"{API_BASE}/repos/owner/repo/releases/assets/88")

    def test_github_client_paginated_wrappers_call_expected_endpoints(self):
        client = GitHubClient("token")

        with patch.object(client, "paginated", return_value=[]) as paginated:
            client.list_pull_request_files("owner/repo", 42)
            paginated.assert_called_once_with(f"{API_BASE}/repos/owner/repo/pulls/42/files")

        with patch.object(client, "paginated", return_value=[]) as paginated:
            client.list_release_assets("owner/repo", 77)
            paginated.assert_called_once_with(f"{API_BASE}/repos/owner/repo/releases/77/assets")

    def test_github_client_upload_release_asset_sends_file_bytes(self):
        client = GitHubClient("token")

        with tempfile.NamedTemporaryFile() as asset:
            asset.write(b"release-bytes")
            asset.flush()

            with patch.object(client, "request_data_json", return_value={"name": "build file.zip"}) as request_data_json:
                result = client.upload_release_asset(
                    "owner/repo",
                    "https://uploads.github.com/repos/owner/repo/releases/77/assets{?name,label}",
                    asset.name,
                    "build file.zip",
                )

        self.assertEqual(result, {"name": "build file.zip"})
        method, url, data, headers = request_data_json.call_args.args
        self.assertEqual(method, "POST")
        self.assertEqual(url, "https://uploads.github.com/repos/owner/repo/releases/77/assets?name=build+file.zip")
        self.assertEqual(data, b"release-bytes")
        self.assertEqual(headers["Accept"], "application/vnd.github+json")
        self.assertEqual(headers["Authorization"], "Bearer token")
        self.assertEqual(headers["Content-Type"], "application/octet-stream")

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

    def test_pr_validation_accepts_develop_for_main_release_pr(self):
        findings = validate_pull_request("develop", "## Linked Issue\n- Closes #12", base_ref="main")

        self.assertFalse(any(finding.section == "Branch name" for finding in findings))

    def test_pr_validation_skips_body_requirements_for_hotfix_branch(self):
        findings = validate_pull_request("hotfix/release-workflow", "", base_ref="develop")

        self.assertEqual(findings, [])

    def test_pr_validation_still_rejects_develop_for_non_main_prs(self):
        findings = validate_branch_name("develop", base_ref="develop")

        self.assertEqual([finding.section for finding in findings], ["Branch name"])

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

    def test_pr_body_validation_accepts_template_bulleted_concrete_steps(self):
        body = """## Linked Issue
- Resolves #184

## Milestone
- MS0

## Summary
- Fix release automation wiring.

## How to test
- Test type: automated
- Steps: ran release workflow contract tests and governance unit tests.

## Evidence
- Local validation passed.

## Known risks
- None

## DoD checklist
- [x] Scope implemented as defined
"""

        findings = validate_pr_body(body)

        self.assertFalse(any(finding.section == "How to test" for finding in findings))

    def test_render_failure_comment_includes_fix_guidance(self):
        findings = validate_branch_name("bad-branch") + validate_pr_body("")

        comment = render_failure_comment(findings)

        self.assertIn("<!-- governance-pr-validation -->", comment)
        self.assertIn("## PR validation failed", comment)
        self.assertIn("Branch name", comment)
        self.assertIn("PR body", comment)
        self.assertIn("Closes #123", comment)
        self.assertIn("Steps: describe the commands", comment)

    def test_pr_hygiene_extracts_linked_task_number(self):
        self.assertEqual(linked_task_number("## Linked Issue\n- Closes #12"), 12)
        self.assertEqual(linked_task_number("Fixes: #44"), 44)
        self.assertEqual(linked_task_number("Resolves #101"), 101)
        self.assertIsNone(linked_task_number("Related to #9"))

    def test_pr_hygiene_status_mapping_respects_drafts_and_merge(self):
        base = {
            "number": 7,
            "body": "Closes #12",
            "base_ref": "develop",
            "head_ref": "feat/x",
            "author": "alice",
            "merged": False,
        }

        self.assertEqual(project_status_for_event(HygienePullRequestContext(action="opened", draft=True, **base)), "In progress")
        self.assertEqual(project_status_for_event(HygienePullRequestContext(action="converted_to_draft", draft=False, **base)), "In progress")
        self.assertEqual(project_status_for_event(HygienePullRequestContext(action="ready_for_review", draft=False, **base)), "In review")
        self.assertEqual(project_status_for_event(HygienePullRequestContext(action="opened", draft=False, **base)), "In review")
        self.assertEqual(project_status_for_event(HygienePullRequestContext(action="closed", draft=False, merged=True, **{k: v for k, v in base.items() if k != "merged"})), "Done")

    def test_pr_hygiene_finds_status_option_tolerantly(self):
        field = {
            "options": [
                {"id": "todo", "name": "Todo"},
                {"id": "in_review", "name": "In review"},
                {"id": "done", "name": "Done"},
            ]
        }

        self.assertEqual(status_option_id(field, "In Review"), "in_review")
        self.assertEqual(status_option_id(field, "in-review"), "in_review")

    def test_pr_hygiene_syncs_pr_metadata_from_task(self):
        client = Mock()
        ctx = HygienePullRequestContext(
            number=33,
            action="opened",
            body="Closes #12",
            base_ref="develop",
            head_ref="feat/phase-2/task",
            author="alice",
            draft=False,
            merged=False,
        )
        task = {
            "number": 12,
            "labels": [{"name": "type:task"}, {"name": "priority:critical"}, {"name": "status:backlog"}, {"name": "test:smoke"}],
            "milestone": {"number": 2},
            "assignees": [{"login": "bob"}],
        }
        pr_issue = {
            "number": 33,
            "labels": [{"name": "type:task"}],
            "milestone": {"number": 1},
            "assignees": [],
        }

        sync_pr_metadata(client, "owner/repo", ctx, task, pr_issue)

        client.add_issue_labels.assert_called_once_with("owner/repo", 33, ["priority:critical", "test:smoke"])
        client.update_issue_milestone.assert_called_once_with("owner/repo", 33, 2)
        client.add_issue_assignees.assert_called_once_with("owner/repo", 33, ["bob"])

    def test_pr_hygiene_self_assigns_task_and_pr_when_task_has_no_assignee(self):
        client = Mock()
        ctx = HygienePullRequestContext(
            number=33,
            action="opened",
            body="Closes #12",
            base_ref="develop",
            head_ref="feat/phase-2/task",
            author="alice",
            draft=False,
            merged=False,
        )
        task = {
            "number": 12,
            "labels": [],
            "milestone": None,
            "assignees": [],
        }
        pr_issue = {"number": 33, "labels": [], "milestone": None, "assignees": []}

        sync_pr_metadata(client, "owner/repo", ctx, task, pr_issue)

        client.add_issue_assignees.assert_any_call("owner/repo", 12, ["alice"])
        client.add_issue_assignees.assert_any_call("owner/repo", 33, ["alice"])

    def test_pr_hygiene_fails_without_linked_task(self):
        event = {
            "action": "opened",
            "pull_request": {
                "number": 33,
                "body": "No linked task",
                "base": {"ref": "develop"},
                "head": {"ref": "feat/phase-2/task"},
                "user": {"login": "alice"},
                "draft": False,
                "merged": False,
            },
        }
        client = Mock()

        with patch("governance_bootstrap.pr_hygiene.upsert_marked_comment") as upsert_comment:
            result = apply_pr_hygiene(client, "owner/repo", event, 4)

        self.assertEqual(result, 1)
        upsert_comment.assert_called_once()
        self.assertIn("No linked implementation task", upsert_comment.call_args.args[4])

    def test_pr_hygiene_applies_status_to_linked_task(self):
        event = {
            "action": "ready_for_review",
            "pull_request": {
                "number": 33,
                "body": "Closes #12",
                "base": {"ref": "develop"},
                "head": {"ref": "feat/phase-2/task"},
                "user": {"login": "alice"},
                "draft": False,
                "merged": False,
            },
        }
        task = {"number": 12, "labels": [], "milestone": None, "assignees": [], "body": ""}
        pr_issue = {"number": 33, "labels": [], "milestone": None, "assignees": []}
        client = Mock()
        client.get_issue.side_effect = [task, pr_issue]

        with (
            patch("governance_bootstrap.pr_hygiene.sync_pr_metadata") as sync_metadata,
            patch("governance_bootstrap.pr_hygiene.sync_task_project_status") as sync_status,
            patch("governance_bootstrap.pr_hygiene.sync_parent_relationship") as sync_relationship,
            patch("governance_bootstrap.pr_hygiene.upsert_marked_comment"),
        ):
            result = apply_pr_hygiene(client, "owner/repo", event, 4)

        self.assertEqual(result, 0)
        sync_metadata.assert_called_once()
        sync_status.assert_called_once_with(client, "owner/repo", 4, task, "In review", owner=None, dry_run=False)
        sync_relationship.assert_called_once()

    def test_pr_hygiene_ignores_develop_to_main_release_pr(self):
        event = {
            "action": "opened",
            "pull_request": {
                "number": 203,
                "body": "",
                "base": {"ref": "main"},
                "head": {"ref": "develop"},
                "user": {"login": "alice"},
                "draft": False,
                "merged": False,
            },
        }
        client = Mock()

        result = apply_pr_hygiene(client, "owner/repo", event, 4)

        self.assertEqual(result, 0)
        client.get_issue.assert_not_called()

    def test_pr_hygiene_ignores_hotfix_pr(self):
        event = {
            "action": "opened",
            "pull_request": {
                "number": 220,
                "body": "",
                "base": {"ref": "develop"},
                "head": {"ref": "hotfix/workflow-pipeline"},
                "user": {"login": "alice"},
                "draft": False,
                "merged": False,
            },
        }
        client = Mock()

        result = apply_pr_hygiene(client, "owner/repo", event, 4)

        self.assertEqual(result, 0)
        client.get_issue.assert_not_called()

    def test_pr_hygiene_identifies_hotfix_prs(self):
        self.assertTrue(
            is_hotfix_pr(
                HygienePullRequestContext(
                    number=220,
                    action="opened",
                    body="",
                    base_ref="develop",
                    head_ref="hotfix/workflow-pipeline",
                    author="alice",
                    draft=False,
                    merged=False,
                )
            )
        )
        self.assertFalse(
            is_hotfix_pr(
                HygienePullRequestContext(
                    number=220,
                    action="opened",
                    body="",
                    base_ref="develop",
                    head_ref="fix/workflow-pipeline",
                    author="alice",
                    draft=False,
                    merged=False,
                )
            )
        )

    def test_pr_hygiene_cli_skips_client_requirement_for_develop_to_main_release_pr(self):
        with tempfile.NamedTemporaryFile("w", encoding="utf-8") as event:
            event.write('{"action":"opened","pull_request":{"number":203,"body":"","base":{"ref":"main"},"head":{"ref":"develop"},"user":{"login":"alice"},"draft":false,"merged":false}}')
            event.flush()

            with (
                patch("governance_bootstrap.cli.require_client") as require_client,
                patch("governance_bootstrap.cli.apply_pr_hygiene_from_path", return_value=0) as apply_hygiene,
            ):
                result = main(
                    [
                        "pr",
                        "hygiene",
                        "--repo",
                        "owner/repo",
                        "--event-path",
                        event.name,
                        "--project-number",
                        "4",
                    ]
                )

        self.assertEqual(result, 0)
        require_client.assert_not_called()
        client = apply_hygiene.call_args.args[0]
        self.assertIsInstance(client, GitHubClient)
        self.assertEqual(client.token, "")
        apply_hygiene.assert_called_once_with(client, "owner/repo", event.name, 4, owner=None, dry_run=False)

    def test_pr_hygiene_cli_skips_client_requirement_for_hotfix_pr(self):
        with tempfile.NamedTemporaryFile("w", encoding="utf-8") as event:
            event.write('{"action":"opened","pull_request":{"number":220,"body":"","base":{"ref":"develop"},"head":{"ref":"hotfix/workflow-pipeline"},"user":{"login":"alice"},"draft":false,"merged":false}}')
            event.flush()

            with (
                patch("governance_bootstrap.cli.require_client") as require_client,
                patch("governance_bootstrap.cli.apply_pr_hygiene_from_path", return_value=0) as apply_hygiene,
            ):
                result = main(
                    [
                        "pr",
                        "hygiene",
                        "--repo",
                        "owner/repo",
                        "--event-path",
                        event.name,
                        "--project-number",
                        "4",
                    ]
                )

        self.assertEqual(result, 0)
        require_client.assert_not_called()
        client = apply_hygiene.call_args.args[0]
        self.assertIsInstance(client, GitHubClient)
        self.assertEqual(client.token, "")
        apply_hygiene.assert_called_once_with(client, "owner/repo", event.name, 4, owner=None, dry_run=False)

    def test_pr_hygiene_dry_run_cli_still_requires_real_client_for_reads(self):
        with tempfile.NamedTemporaryFile("w", encoding="utf-8") as event:
            event.write('{"action":"opened","pull_request":{"number":33,"body":"Closes #12","base":{"ref":"develop"},"head":{"ref":"feat/task"},"user":{"login":"alice"},"draft":false,"merged":false}}')
            event.flush()
            client = Mock()

            with (
                patch("governance_bootstrap.cli.require_client", return_value=client) as require_client,
                patch("governance_bootstrap.cli.apply_pr_hygiene_from_path", return_value=0) as apply_hygiene,
            ):
                result = main(
                    [
                        "pr",
                        "hygiene",
                        "--repo",
                        "owner/repo",
                        "--event-path",
                        event.name,
                        "--project-number",
                        "4",
                        "--dry-run",
                    ]
                )

        self.assertEqual(result, 0)
        require_client.assert_called_once_with()
        apply_hygiene.assert_called_once_with(client, "owner/repo", event.name, 4, owner=None, dry_run=True)

    def test_release_context_parser_accepts_short_versions(self):
        body = """## Release version
- b0.1

## Related develop PRs
- #12
- https://github.com/owner/repo/pull/15
"""

        context = extract_release_context(body)

        self.assertIsNotNone(context.version)
        self.assertEqual(context.version.canonical, "beta-0.1.0")
        self.assertEqual(context.related_prs, [12, 15])
        self.assertEqual(context.errors, [])

    def test_release_prepare_main_dry_run_accepts_valid_version(self):
        body = """## Release version
- f1.2.3

## Related develop PRs
- #12
- #15
"""

        client = Mock()
        output = io.StringIO()

        with redirect_stdout(output):
            result = prepare_main_release(client, "owner/repo", 42, body, dry_run=True)

        self.assertEqual(result, 0)
        self.assertIn("State: planned", output.getvalue())
        self.assertIn("final-1.2.3", output.getvalue())
        self.assertIn("#12", output.getvalue())
        self.assertIn("#15", output.getvalue())

    def test_release_prepare_main_dry_run_rejects_invalid_version(self):
        body = """## Release version
- maybe-later

## Related develop PRs
- #12
"""

        client = Mock()
        output = io.StringIO()

        with redirect_stdout(output):
            result = prepare_main_release(client, "owner/repo", 42, body, dry_run=True)

        self.assertEqual(result, 1)
        self.assertIn("Invalid release version", output.getvalue())
        self.assertIn("Accepted forms:", output.getvalue())

    def test_release_publish_creates_tag_and_release(self):
        body = """## Release version
- final-1.2.3

## Related develop PRs
- #12
"""

        client = Mock()
        client.get_git_ref.side_effect = GitHubRequestError("GET", "/repos/owner/repo/git/ref/tags/final-1.2.3", 404, "missing")
        client.get_release_by_tag.side_effect = GitHubRequestError("GET", "/repos/owner/repo/releases/tags/final-1.2.3", 404, "missing")
        client.create_release.return_value = {
            "id": 77,
            "html_url": "https://github.com/owner/repo/releases/tag/final-1.2.3",
            "upload_url": "https://uploads.github.com/repos/owner/repo/releases/77/assets{?name,label}",
        }
        client.update_release.return_value = {"html_url": "https://github.com/owner/repo/releases/tag/final-1.2.3"}
        client.list_issue_comments.return_value = []

        with patch("governance_bootstrap.release.upsert_marked_comment", return_value="created") as upsert_comment:
            result = publish_release(client, "owner/repo", 42, body, "abc123")

        self.assertEqual(result, 0)
        client.create_git_ref.assert_called_once_with("owner/repo", "refs/tags/final-1.2.3", "abc123")
        client.create_release.assert_called_once()
        self.assertEqual(client.create_release.call_args.args[1].canonical, "final-1.2.3")
        self.assertEqual(client.create_release.call_args.args[1].prerelease, False)
        client.update_release.assert_called_once()
        self.assertIn("Release `final-1.2.3`", client.update_release.call_args.args[4])
        upsert_comment.assert_any_call(client, "owner/repo", 42, "<!-- governance-release-plan -->", unittest.mock.ANY)
        upsert_comment.assert_any_call(client, "owner/repo", 12, "<!-- governance-release-notice -->", unittest.mock.ANY)

    def test_release_publish_uploads_assets_and_lists_downloads(self):
        body = """## Release version
- final-1.2.3

## Related develop PRs
- #12
"""

        client = Mock()
        client.get_git_ref.side_effect = GitHubRequestError("GET", "/repos/owner/repo/git/ref/tags/final-1.2.3", 404, "missing")
        client.get_release_by_tag.return_value = {
            "id": 77,
            "html_url": "https://github.com/owner/repo/releases/tag/final-1.2.3",
            "upload_url": "https://uploads.github.com/repos/owner/repo/releases/77/assets{?name,label}",
        }
        client.list_release_assets.return_value = [{"id": 88, "name": "take-your-pills-windows.exe"}]
        client.delete_release_asset.return_value = {}
        client.upload_release_asset.side_effect = [
            {"name": "take-your-pills-windows.exe", "browser_download_url": "https://github.com/owner/repo/releases/download/final-1.2.3/take-your-pills-windows.exe"},
            {"name": "take-your-pills-linux.x86_64", "browser_download_url": "https://github.com/owner/repo/releases/download/final-1.2.3/take-your-pills-linux.x86_64"},
            {"name": "take-your-pills-godot.zip", "browser_download_url": "https://github.com/owner/repo/releases/download/final-1.2.3/take-your-pills-godot.zip"},
        ]
        client.update_release.return_value = {"html_url": "https://github.com/owner/repo/releases/tag/final-1.2.3"}
        client.list_issue_comments.return_value = []

        with patch("governance_bootstrap.release.upsert_marked_comment", return_value="created"):
            result = publish_release(
                client,
                "owner/repo",
                42,
                body,
                "abc123",
                asset_paths=[
                    "dist/release/take-your-pills-windows.exe",
                    "dist/release/take-your-pills-linux.x86_64",
                    "dist/release/take-your-pills-godot.zip",
                ],
            )

        self.assertEqual(result, 0)
        client.delete_release_asset.assert_called_once_with("owner/repo", 88)
        self.assertEqual(client.upload_release_asset.call_count, 3)
        final_body = client.update_release.call_args.args[4]
        self.assertIn("## Downloads", final_body)
        self.assertIn("take-your-pills-windows.exe", final_body)
        self.assertIn("take-your-pills-linux.x86_64", final_body)
        self.assertIn("take-your-pills-godot.zip", final_body)
        self.assertIn("https://github.com/owner/repo/releases/download/final-1.2.3/take-your-pills-godot.zip", final_body)

    def test_release_publish_rejects_tag_sha_conflict(self):
        body = """## Release version
- final-1.2.3

## Related develop PRs
- #12
"""

        client = Mock()
        client.get_git_ref.return_value = {"object": {"sha": "oldsha"}}
        client.list_issue_comments.return_value = []

        with self.assertRaises(RuntimeError) as ctx:
            publish_release(client, "owner/repo", 42, body, "newsha")

        self.assertIn("Refusing to move existing release tag", str(ctx.exception))

    def test_release_prepare_main_removes_stale_develop_notice(self):
        body = """## Release version
- final-1.2.3

## Related develop PRs
- #12
"""

        client = Mock()
        client.list_issue_comments.return_value = [
            {
                "id": 1001,
                "body": "\n".join(
                    [
                        "<!-- governance-release-plan -->",
                        "## Release plan",
                        "- State: planned",
                        "- Release version: `final-1.2.3`",
                        "- Main PR: #42",
                        "- Related develop PRs:",
                        "  - #12",
                        "  - #15",
                    ]
                ),
            }
        ]

        with patch("governance_bootstrap.release.upsert_marked_comment", return_value="updated") as upsert_comment:
            result = prepare_main_release(client, "owner/repo", 42, body, dry_run=False)

        self.assertEqual(result, 0)
        upsert_comment.assert_any_call(client, "owner/repo", 15, "<!-- governance-release-notice -->", "")
        upsert_comment.assert_any_call(client, "owner/repo", 12, "<!-- governance-release-notice -->", unittest.mock.ANY)

    def test_release_publish_removes_stale_develop_notice(self):
        body = """## Release version
- final-1.2.3

## Related develop PRs
- #12
"""

        client = Mock()
        client.get_git_ref.side_effect = GitHubRequestError("GET", "/repos/owner/repo/git/ref/tags/final-1.2.3", 404, "missing")
        client.get_release_by_tag.side_effect = GitHubRequestError("GET", "/repos/owner/repo/releases/tags/final-1.2.3", 404, "missing")
        client.create_release.return_value = {
            "id": 77,
            "html_url": "https://github.com/owner/repo/releases/tag/final-1.2.3",
            "upload_url": "https://uploads.github.com/repos/owner/repo/releases/77/assets{?name,label}",
        }
        client.update_release.return_value = {"html_url": "https://github.com/owner/repo/releases/tag/final-1.2.3"}
        client.list_issue_comments.return_value = [
            {
                "id": 1001,
                "body": "\n".join(
                    [
                        "<!-- governance-release-plan -->",
                        "## Release plan",
                        "- State: planned",
                        "- Release version: `final-1.2.3`",
                        "- Main PR: #42",
                        "- Related develop PRs:",
                        "  - #12",
                        "  - #15",
                    ]
                ),
            }
        ]

        with patch("governance_bootstrap.release.upsert_marked_comment", return_value="updated") as upsert_comment:
            result = publish_release(client, "owner/repo", 42, body, "abc123")

        self.assertEqual(result, 0)
        upsert_comment.assert_any_call(client, "owner/repo", 15, "<!-- governance-release-notice -->", "")
        upsert_comment.assert_any_call(client, "owner/repo", 12, "<!-- governance-release-notice -->", unittest.mock.ANY)

    def test_render_release_body_lists_assets(self):
        context = extract_release_context(
            """## Release version
- final-1.2.3

## Related develop PRs
- #12
"""
        )

        body = render_release_body(
            context,
            42,
            "abc123",
            assets=[
                ReleaseAssetLink(name="take-your-pills-windows.exe", url="https://example.invalid/windows"),
                ReleaseAssetLink(name="take-your-pills-godot.zip", url="https://example.invalid/godot"),
            ],
        )

        self.assertIn("## Downloads", body)
        self.assertIn("[take-your-pills-windows.exe](https://example.invalid/windows)", body)
        self.assertIn("[take-your-pills-godot.zip](https://example.invalid/godot)", body)

    def test_change_summary_groups_paths_by_game_area(self):
        items = parse_name_status_lines(
            "\n".join(
                [
                    "M\tscenes/player/player.gd",
                    "A\tscenes/game/chunks/chunk_d.tscn",
                    "M\tdocs/workflow-map.md",
                ]
            )
        )

        summary = summarize_change_items(items)
        comment = render_change_summary_comment(summary)

        self.assertIn("Gameplay impact", comment)
        self.assertIn("Support changes", comment)
        self.assertIn("Player systems", comment)
        self.assertIn("Chunk generation", comment)
        self.assertIn("Documentation", comment)
        self.assertIn("Top-level folders: scenes (2), docs (1).", comment)
        self.assertNotIn("Likely game areas", comment)

    def test_parse_name_status_lines_accepts_plain_and_whitespace_paths(self):
        items = parse_name_status_lines(
            "\n".join(
                [
                    "scenes/player/player.gd",
                    "M docs/workflow-map.md",
                    "A\ttests/test_release_version.sh",
                    "R100\tdocs/old.md\tdocs/new.md",
                ]
            )
        )

        self.assertEqual(
            [(item.status, item.path) for item in items],
            [
                ("modified", "scenes/player/player.gd"),
                ("modified", "docs/workflow-map.md"),
                ("added", "tests/test_release_version.sh"),
                ("renamed", "docs/new.md"),
            ],
        )

    def test_release_context_comment_mentions_related_prs(self):
        context = extract_release_context(
            """## Release version
- final-1.0.0

## Related develop PRs
- #7
- #9
"""
        )

        comment = render_release_context_comment(context, 42, "planned")

        self.assertIn("final-1.0.0", comment)
        self.assertIn("State: planned", comment)
        self.assertIn("#7", comment)
        self.assertIn("#9", comment)

if __name__ == "__main__":
    unittest.main()
