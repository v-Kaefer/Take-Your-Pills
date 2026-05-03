#!/usr/bin/env python3
import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request


API_VERSION = "2022-11-28"
GRAPHQL_URL = "https://api.github.com/graphql"
REST_API_BASE = "https://api.github.com"
RETRYABLE_HTTP_STATUS = {502, 503, 504}


def get_token():
    return os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")


def http_request(method, url, token, payload=None, accept="application/vnd.github+json"):
    headers = {
        "Accept": accept,
        "Authorization": f"Bearer {token}",
        "X-GitHub-Api-Version": API_VERSION,
        "Content-Type": "application/json",
    }
    data = None
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
    for attempt in range(1, 6):
        req = urllib.request.Request(url, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req) as res:
                body = res.read().decode("utf-8")
                return json.loads(body) if body else {}, dict(res.headers)
        except urllib.error.HTTPError as e:
            details = e.read().decode("utf-8", errors="replace")
            if e.code in RETRYABLE_HTTP_STATUS and attempt < 5:
                wait_seconds = attempt * 2
                print(f"warning: HTTP {e.code} from GitHub; retrying in {wait_seconds}s")
                time.sleep(wait_seconds)
                continue
            raise RuntimeError(f"HTTP {e.code} {method} {url}: {details}") from e
        except urllib.error.URLError as e:
            if attempt < 5:
                wait_seconds = attempt * 2
                print(f"warning: GitHub request failed; retrying in {wait_seconds}s: {e.reason}")
                time.sleep(wait_seconds)
                continue
            raise


def graphql(token, query, variables=None):
    payload = {"query": query, "variables": variables or {}}
    data, _ = http_request("POST", GRAPHQL_URL, token, payload)
    if data.get("errors"):
        raise RuntimeError(f"GraphQL error: {json.dumps(data['errors'], ensure_ascii=False)}")
    return data["data"]


def find_project(owner, project_number, token):
    query_user = """
    query($login:String!, $number:Int!) {
      user(login:$login) {
        projectV2(number:$number) {
          id
          title
          url
        }
      }
    }
    """
    data = graphql(token, query_user, {"login": owner, "number": project_number})
    user = data.get("user")
    if user and user.get("projectV2"):
        return user["projectV2"], "user"

    query_org = """
    query($login:String!, $number:Int!) {
      organization(login:$login) {
        projectV2(number:$number) {
          id
          title
          url
        }
      }
    }
    """
    data = graphql(token, query_org, {"login": owner, "number": project_number})
    org = data.get("organization")
    if org and org.get("projectV2"):
        return org["projectV2"], "org"

    raise RuntimeError(f"Project v2 #{project_number} not found for owner '{owner}'")


def list_project_fields(project_id, token):
    query = """
    query($project:ID!, $cursor:String) {
      node(id:$project) {
        ... on ProjectV2 {
          fields(first:100, after:$cursor) {
            pageInfo { hasNextPage endCursor }
            nodes {
              __typename
              ... on ProjectV2Field {
                id
                name
                dataType
              }
              ... on ProjectV2SingleSelectField {
                id
                name
                dataType
                options { id name }
              }
              ... on ProjectV2IterationField {
                id
                name
                dataType
              }
            }
          }
        }
      }
    }
    """
    fields = []
    cursor = None
    while True:
        data = graphql(token, query, {"project": project_id, "cursor": cursor})
        page = data["node"]["fields"]
        fields.extend(page["nodes"])
        if not page["pageInfo"]["hasNextPage"]:
            break
        cursor = page["pageInfo"]["endCursor"]
    return fields


def create_text_field(project_id, name, token):
    mutation = """
    mutation($project:ID!, $name:String!) {
      createProjectV2Field(input:{projectId:$project, name:$name, dataType:TEXT}) {
        projectV2Field {
          ... on ProjectV2Field {
            id
            name
            dataType
          }
        }
      }
    }
    """
    data = graphql(token, mutation, {"project": project_id, "name": name})
    return data["createProjectV2Field"]["projectV2Field"]


def create_single_select_field(project_id, name, options, token):
    mutation = """
    mutation($project:ID!, $name:String!, $options:[ProjectV2SingleSelectFieldOptionInput!]!) {
      createProjectV2Field(input:{projectId:$project, name:$name, dataType:SINGLE_SELECT, singleSelectOptions:$options}) {
        projectV2Field {
          ... on ProjectV2SingleSelectField {
            id
            name
            dataType
            options { id name }
          }
        }
      }
    }
    """
    option_payload = [{"name": opt, "color": "GRAY", "description": ""} for opt in options]
    data = graphql(token, mutation, {"project": project_id, "name": name, "options": option_payload})
    return data["createProjectV2Field"]["projectV2Field"]


def ensure_fields(project_id, definition, token, dry_run=False):
    existing = list_project_fields(project_id, token)
    by_name = {f["name"]: f for f in existing if f and f.get("name")}

    for field in definition.get("fields", []):
        name = field["name"]
        if name in by_name:
            continue

        if dry_run:
            print(f"[DRY-RUN] Would create field: {name} ({field['type']})")
            continue

        if field["type"] == "text":
            created = create_text_field(project_id, name, token)
        elif field["type"] == "single_select":
            created = create_single_select_field(project_id, name, field.get("options", []), token)
        else:
            print(f"Skipping unsupported field type: {field['type']} ({name})")
            continue

        print(f"created field: {name}")
        by_name[name] = created

    if dry_run:
        return by_name
    return {f["name"]: f for f in list_project_fields(project_id, token) if f and f.get("name")}


def list_repo_issues(repo, token, state="open"):
    owner, name = repo.split("/", 1)
    page = 1
    issues = []
    while True:
        url = (
            f"{REST_API_BASE}/repos/{owner}/{name}/issues"
            f"?state={state}&sort=created&direction=asc&per_page=100&page={page}"
        )
        data, _ = http_request("GET", url, token)
        page_issues = [i for i in data if "pull_request" not in i]
        issues.extend(page_issues)
        if len(data) < 100:
            break
        page += 1
    return issues


def list_project_items(project_id, token):
    query = """
    query($project:ID!, $cursor:String) {
      node(id:$project) {
        ... on ProjectV2 {
          items(first:100, after:$cursor) {
            pageInfo { hasNextPage endCursor }
            nodes {
              id
              content {
                __typename
                ... on Issue { id number }
              }
            }
          }
        }
      }
    }
    """
    content_to_item = {}
    cursor = None
    while True:
        data = graphql(token, query, {"project": project_id, "cursor": cursor})
        page = data["node"]["items"]
        for item in page["nodes"]:
            content = item.get("content")
            if content and content.get("__typename") == "Issue":
                content_to_item[content["id"]] = item["id"]
        if not page["pageInfo"]["hasNextPage"]:
            break
        cursor = page["pageInfo"]["endCursor"]
    return content_to_item


def issue_node_id(repo, number, token):
    owner, name = repo.split("/", 1)
    query = """
    query($owner:String!, $repo:String!, $number:Int!) {
      repository(owner:$owner, name:$repo) {
        issue(number:$number) {
          id
        }
      }
    }
    """
    data = graphql(token, query, {"owner": owner, "repo": name, "number": number})
    issue = data["repository"]["issue"]
    if not issue:
        raise RuntimeError(f"Issue #{number} not found in {repo}")
    return issue["id"]


def add_issue_to_project(project_id, issue_id, token):
    mutation = """
    mutation($project:ID!, $content:ID!) {
      addProjectV2ItemById(input:{projectId:$project, contentId:$content}) {
        item { id }
      }
    }
    """
    data = graphql(token, mutation, {"project": project_id, "content": issue_id})
    return data["addProjectV2ItemById"]["item"]["id"]


def add_sub_issue(parent_id, child_id, token):
    mutation = """
    mutation($parent:ID!, $child:ID!) {
      addSubIssue(input:{issueId:$parent, subIssueId:$child}) {
        clientMutationId
      }
    }
    """
    graphql(token, mutation, {"parent": parent_id, "child": child_id})


def update_item_position(project_id, item_id, after_id, token):
    mutation = """
    mutation($project:ID!, $item:ID!, $after:ID) {
      updateProjectV2ItemPosition(input:{projectId:$project, itemId:$item, afterId:$after}) {
        clientMutationId
      }
    }
    """
    graphql(token, mutation, {"project": project_id, "item": item_id, "after": after_id})


def update_single_select(project_id, item_id, field_id, option_id, token):
    mutation = """
    mutation($project:ID!, $item:ID!, $field:ID!, $option:String!) {
      updateProjectV2ItemFieldValue(input:{projectId:$project, itemId:$item, fieldId:$field, value:{singleSelectOptionId:$option}}) {
        projectV2Item { id }
      }
    }
    """
    graphql(token, mutation, {"project": project_id, "item": item_id, "field": field_id, "option": option_id})


def update_text(project_id, item_id, field_id, text_value, token):
    mutation = """
    mutation($project:ID!, $item:ID!, $field:ID!, $text:String!) {
      updateProjectV2ItemFieldValue(input:{projectId:$project, itemId:$item, fieldId:$field, value:{text:$text}}) {
        projectV2Item { id }
      }
    }
    """
    graphql(token, mutation, {"project": project_id, "item": item_id, "field": field_id, "text": text_value})


def milestone_from_body(body):
    if not body:
        return None
    m = re.search(r"-\s*Milestone:\s*(MS\d+)", body)
    return m.group(1) if m else None


def parent_issue_number_from_body(body):
    if not body:
        return None
    m = re.search(r"Parent story:.*\(#(\d+)\)", body)
    return int(m.group(1)) if m else None


def label_value(labels, prefix):
    for label in labels:
        name = label["name"] if isinstance(label, dict) else str(label)
        if name.startswith(prefix):
            return name.split(":", 1)[1]
    return None


def option_id(field, option_name):
    for opt in field.get("options", []):
        if opt["name"] == option_name:
            return opt["id"]
    return None


def sync_issue_fields(project_id, item_id, issue, fields, token, dry_run=False):
    labels = issue.get("labels", [])
    body = issue.get("body", "") or ""

    mappings = {
        "Phase": f"F{label_value(labels, 'phase:')}" if label_value(labels, 'phase:') is not None else None,
        "Item Type": label_value(labels, "type:"),
        "Priority": label_value(labels, "priority:"),
        "Status": label_value(labels, "status:"),
        "Test Type": label_value(labels, "test:"),
        "Milestone": milestone_from_body(body),
    }

    for field_name, field_value in mappings.items():
        if not field_value:
            continue
        field = fields.get(field_name)
        if not field:
            continue
        if field.get("dataType") == "SINGLE_SELECT":
            oid = option_id(field, field_value)
            if not oid:
                print(f"warning: option '{field_value}' not found for field '{field_name}'")
                continue
            if dry_run:
                print(f"[DRY-RUN] Would set {field_name}={field_value} on issue #{issue['number']}")
            else:
                update_single_select(project_id, item_id, field["id"], oid, token)
        elif field.get("dataType") == "TEXT":
            if dry_run:
                print(f"[DRY-RUN] Would set {field_name}={field_value} on issue #{issue['number']}")
            else:
                update_text(project_id, item_id, field["id"], field_value, token)


def reorder_project_items(project_id, issues, current_items, token, dry_run=False):
    previous_item_id = None
    for issue in issues:
        item_id = current_items.get(issue["node_id"])
        if not item_id:
            continue
        if dry_run:
            print(f"[DRY-RUN] Would position issue #{issue['number']} after {previous_item_id or 'top'}")
        else:
            update_item_position(project_id, item_id, previous_item_id, token)
        previous_item_id = item_id


def link_subissues(repo, issues, token, dry_run=False):
    node_ids_by_number = {issue["number"]: issue.get("node_id") for issue in issues}
    linked = 0
    skipped = 0

    for issue in issues:
        parent_number = parent_issue_number_from_body(issue.get("body", "") or "")
        if parent_number is None:
            continue

        parent_id = node_ids_by_number.get(parent_number)
        if not parent_id:
            parent_id = issue_node_id(repo, parent_number, token)
            node_ids_by_number[parent_number] = parent_id

        if dry_run:
            print(f"[DRY-RUN] Would link issue #{issue['number']} as sub-issue of #{parent_number}")
            continue

        try:
            add_sub_issue(parent_id, issue["node_id"], token)
            print(f"Linked issue #{issue['number']} as sub-issue of #{parent_number}")
            linked += 1
        except RuntimeError as e:
            error_text = str(e).lower()
            if (
                "already" in error_text
                or "exists" in error_text
                or "duplicate sub-issues" in error_text
                or "may only have one parent" in error_text
            ):
                print(f"Sub-issue link already exists: #{issue['number']} -> #{parent_number}")
                skipped += 1
                continue
            raise

    print(f"Sub-issue linking finished: linked={linked}, already_present={skipped}")


def main():
    parser = argparse.ArgumentParser(description="Configure a GitHub Project v2 and add repo issues to it")
    parser.add_argument("project_definition", help="Path to project-definition.json")
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY"), help="owner/repo")
    parser.add_argument("--owner", help="Project owner login (defaults to repo owner)")
    parser.add_argument("--project-number", type=int, required=True, help="Project v2 number, e.g. 4")
    parser.add_argument("--issue-state", default="open", choices=["open", "closed", "all"])
    parser.add_argument("--link-subissues", action="store_true", help="Link tasks to parent stories using Parent story references")
    parser.add_argument("--only-link-subissues", action="store_true", help="Only link tasks to parent stories; skip Project item sync")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    token = get_token()
    if not token:
        raise SystemExit("Missing GITHUB_TOKEN or GH_TOKEN")
    if not args.repo:
        raise SystemExit("Missing --repo and GITHUB_REPOSITORY")

    owner = args.owner or args.repo.split("/", 1)[0]
    with open(args.project_definition, "r", encoding="utf-8") as f:
        definition = json.load(f)

    issues = list_repo_issues(args.repo, token, state=args.issue_state)
    for issue in issues:
        issue["node_id"] = issue_node_id(args.repo, issue["number"], token)

    if args.only_link_subissues:
        link_subissues(args.repo, issues, token, dry_run=args.dry_run)
        return 0

    project, owner_type = find_project(owner, args.project_number, token)
    print(f"Project found: {project['title']} ({project['url']}) owner_type={owner_type}")

    fields = ensure_fields(project["id"], definition, token, dry_run=args.dry_run)

    current_items = list_project_items(project["id"], token)

    for issue in issues:
        issue_id = issue["node_id"]
        item_id = current_items.get(issue_id)

        if not item_id:
            if args.dry_run:
                print(f"[DRY-RUN] Would add issue #{issue['number']} to project")
                item_id = f"dry-run-item-{issue['number']}"
            else:
                item_id = add_issue_to_project(project["id"], issue_id, token)
                current_items[issue_id] = item_id
                print(f"Added issue #{issue['number']} to project")
        else:
            print(f"Issue #{issue['number']} already in project")

        sync_issue_fields(project["id"], item_id, issue, fields, token, dry_run=args.dry_run)

    reorder_project_items(project["id"], issues, current_items, token, dry_run=args.dry_run)

    if args.link_subissues:
        link_subissues(args.repo, issues, token, dry_run=args.dry_run)

    if definition.get("views"):
        print("Note: project views are listed in project-definition.json but are not automated by this script.")
        for view in definition["views"]:
            print(f"- create manually if needed: {view}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
