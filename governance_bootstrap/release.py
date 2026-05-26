from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re

from .comments import find_marked_comment, upsert_marked_comment
from .github import GitHubClient, GitHubRequestError
from .pr_validation import sections_from_body


CHANGE_SUMMARY_MARKER = "<!-- governance-change-summary -->"
RELEASE_PLAN_MARKER = "<!-- governance-release-plan -->"
RELEASE_NOTICE_MARKER = "<!-- governance-release-notice -->"

CHANNEL_ALIASES = {
    "a": "alpha",
    "alpha": "alpha",
    "b": "beta",
    "beta": "beta",
    "f": "final",
    "final": "final",
}

STATUS_ALIASES = {
    "a": "added",
    "added": "added",
    "m": "modified",
    "modified": "modified",
    "changed": "modified",
    "d": "removed",
    "deleted": "removed",
    "removed": "removed",
    "r": "renamed",
    "renamed": "renamed",
    "c": "copied",
    "copied": "copied",
}

SECTOR_RULES = [
    {
        "name": "Player systems",
        "category": "gameplay",
        "impact": "Player input, movement, or player scene wiring changed.",
        "prefixes": ("scenes/player/", "scripts/player/", "scripts/character/"),
        "suffixes": (),
    },
    {
        "name": "Core gameplay loop",
        "category": "gameplay",
        "impact": "The main game flow, state transitions, or scene bootstrapping changed.",
        "prefixes": ("scenes/game/game.gd", "scenes/game/game.tscn", "scripts/run_signals.gd"),
        "suffixes": (),
    },
    {
        "name": "Chunk generation",
        "category": "gameplay",
        "impact": "Chunk streaming, world assembly, or terrain-loading logic changed.",
        "prefixes": ("scenes/game/chunks/", "scenes/game/chunk_manager", "scripts/chunks/", "scripts/world/"),
        "suffixes": (),
    },
    {
        "name": "Obstacle systems",
        "category": "gameplay",
        "impact": "Obstacle spawning, collision, or obstacle content changed.",
        "prefixes": ("scenes/game/obstacles/", "scripts/obstacles/"),
        "suffixes": (),
    },
    {
        "name": "HUD / UI",
        "category": "gameplay",
        "impact": "HUD, menus, or in-game status presentation changed.",
        "prefixes": ("scenes/game/hud", "scenes/game/ui", "ui/"),
        "suffixes": (),
    },
    {
        "name": "Game scenes",
        "category": "gameplay",
        "impact": "General scene content or Godot resources in the game layer changed.",
        "prefixes": ("scenes/game/", "scenes/"),
        "suffixes": (),
    },
    {
        "name": "Godot content",
        "category": "gameplay",
        "impact": "Godot scene or resource files changed outside the main gameplay folders.",
        "prefixes": (),
        "suffixes": (".gd", ".tscn", ".tres"),
    },
    {
        "name": "Automation / CI",
        "category": "support",
        "impact": "Validation, release, or repository automation changed.",
        "prefixes": (".github/workflows/", ".github/", "scripts/validation/", "scripts/github/", "scripts/hooks/"),
        "suffixes": (),
    },
    {
        "name": "Configuration",
        "category": "support",
        "impact": "Repository or project configuration changed.",
        "prefixes": ("config/", "project.godot"),
        "suffixes": (),
    },
    {
        "name": "Documentation",
        "category": "support",
        "impact": "Documentation or runbook text changed.",
        "prefixes": ("docs/",),
        "suffixes": (),
    },
    {
        "name": "Tests",
        "category": "support",
        "impact": "Test coverage, fixtures, or test helpers changed.",
        "prefixes": ("tests/",),
        "suffixes": (),
    },
    {
        "name": "General scripts",
        "category": "support",
        "impact": "Repository helper scripts changed.",
        "prefixes": ("scripts/",),
        "suffixes": (),
    },
]

SECTOR_LOOKUP = {rule["name"]: rule for rule in SECTOR_RULES}

VERSION_PATTERN = re.compile(r"^(?P<channel>alpha|beta|final|a|b|f)[\s:/_-]?(?P<version>\d+(?:\.\d+){1,2})$", re.IGNORECASE)
PR_NUMBER_PATTERN = re.compile(r"(?:#|pull/)(\d+)")


@dataclass(frozen=True)
class ChangeItem:
    status: str
    path: str


@dataclass(frozen=True)
class ChangeSummary:
    items: list[ChangeItem]
    status_counts: dict[str, int]
    folder_counts: dict[str, int]
    sector_items: dict[str, list[str]]


@dataclass(frozen=True)
class ReleaseVersion:
    channel: str
    version: str

    @property
    def canonical(self) -> str:
        return f"{self.channel}-{self.version}"

    @property
    def prerelease(self) -> bool:
        return self.channel in {"alpha", "beta"}


@dataclass(frozen=True)
class ReleaseContext:
    version: ReleaseVersion | None
    related_prs: list[int]
    errors: list[str]
    raw_version: str | None


@dataclass(frozen=True)
class ReleaseAssetSpec:
    path: str
    name: str | None = None

    @property
    def upload_name(self) -> str:
        return self.name or Path(self.path).name


@dataclass(frozen=True)
class ReleaseAssetLink:
    name: str
    url: str


def _clean_line(value: str) -> str:
    return value.strip().lstrip("-*").strip()


def normalize_change_status(status: str | None) -> str:
    token = (status or "").strip().lower()
    if not token:
        return "modified"
    token = re.match(r"^[a-z]+", token).group(0) if re.match(r"^[a-z]+", token) else token
    return STATUS_ALIASES.get(token, token)


def parse_name_status_lines(text: str) -> list[ChangeItem]:
    items: list[ChangeItem] = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) == 1:
            whitespace_parts = line.split(maxsplit=1)
            status = normalize_change_status(whitespace_parts[0])
            if len(whitespace_parts) == 2 and status in set(STATUS_ALIASES.values()):
                items.append(ChangeItem(status=status, path=whitespace_parts[1].strip()))
            else:
                items.append(ChangeItem(status="modified", path=line))
            continue
        status = normalize_change_status(parts[0])
        if len(parts) >= 3 and status in {"renamed", "copied"}:
            path = parts[-1].strip()
        else:
            path = parts[1].strip()
        items.append(ChangeItem(status=status, path=path))
    return items


def _top_level_folder(path: str) -> str:
    parts = Path(path).parts
    if not parts:
        return "(root)"
    if len(parts) == 1:
        return "(root)"
    return parts[0]


def classify_sector(path: str) -> str:
    normalized = path.replace("\\", "/").lower()
    for rule in SECTOR_RULES:
        if any(normalized.startswith(prefix) for prefix in rule["prefixes"]):
            return rule["name"]
        if any(normalized.endswith(suffix) for suffix in rule["suffixes"]):
            return rule["name"]
    if normalized.endswith(".gd") or normalized.endswith(".tscn") or normalized.endswith(".tres"):
        return "Godot content"
    return "Other"


def classify_area(path: str) -> str:
    return classify_sector(path)


def summarize_change_items(items: list[ChangeItem]) -> ChangeSummary:
    normalized_items = [ChangeItem(status=normalize_change_status(item.status), path=item.path) for item in items if item.path]
    status_counts: dict[str, int] = {}
    folder_counts: dict[str, int] = {}
    sector_items: dict[str, list[str]] = {}

    for item in normalized_items:
        status_counts[item.status] = status_counts.get(item.status, 0) + 1
        folder = _top_level_folder(item.path)
        folder_counts[folder] = folder_counts.get(folder, 0) + 1
        sector = classify_sector(item.path)
        sector_items.setdefault(sector, []).append(item.path)

    for mapping in (sector_items,):
        for key in list(mapping):
            mapping[key] = sorted(mapping[key])

    return ChangeSummary(
        items=sorted(normalized_items, key=lambda item: item.path.lower()),
        status_counts=dict(sorted(status_counts.items())),
        folder_counts=dict(sorted(folder_counts.items(), key=lambda item: (-item[1], item[0].lower()))),
        sector_items=dict(sorted(sector_items.items(), key=lambda item: (-len(item[1]), item[0].lower()))),
    )


def _render_change_summary_lines(summary: ChangeSummary, title: str | None = None) -> list[str]:
    lines = [
        "## Change summary",
        "",
    ]
    if title:
        lines.append(f"- PR: {title}")
    lines.append(f"- {len(summary.items)} files changed across {len(summary.sector_items)} sectors.")
    if summary.status_counts:
        counts = ", ".join(f"{status}: {count}" for status, count in summary.status_counts.items())
        lines.append(f"- Status counts: {counts}.")
    if summary.folder_counts:
        folders = ", ".join(
            f"{label if label != '(root)' else 'repository root'} ({count})"
            for label, count in summary.folder_counts.items()
        )
        lines.append(f"- Top-level folders: {folders}.")
    lines.append("")

    gameplay = [name for name in summary.sector_items if SECTOR_LOOKUP.get(name, {}).get("category") == "gameplay"]
    support = [name for name in summary.sector_items if SECTOR_LOOKUP.get(name, {}).get("category") != "gameplay"]

    def add_sector_section(header: str, sector_names: list[str]) -> None:
        if not sector_names:
            return
        lines.append(header)
        for sector_name in sector_names:
            rule = SECTOR_LOOKUP.get(sector_name, {"category": "support", "impact": "Files changed."})
            paths = summary.sector_items[sector_name]
            file_label = "file" if len(paths) == 1 else "files"
            lines.append(f"- {sector_name} ({len(paths)} {file_label})")
            lines.append(f"  - {rule['impact']}")
            examples = ", ".join(f"`{path}`" for path in paths[:2])
            if len(paths) == 1:
                lines.append(f"  - Example: {examples}")
            else:
                extra = len(paths) - 2
                if extra > 0:
                    lines.append(f"  - Examples: {examples}, and {extra} more")
                else:
                    lines.append(f"  - Examples: {examples}")
        lines.append("")

    add_sector_section("### Gameplay impact", gameplay)
    add_sector_section("### Support changes", support)
    if not gameplay and not support:
        lines.append("### Change context")
        lines.append("- No files were detected.")
        lines.append("")
    return lines


def render_change_summary_report(summary: ChangeSummary, title: str | None = None) -> str:
    return "\n".join(_render_change_summary_lines(summary, title=title))


def render_change_summary_comment(summary: ChangeSummary, title: str | None = None) -> str:
    return "\n".join([CHANGE_SUMMARY_MARKER, *_render_change_summary_lines(summary, title=title)])


def render_release_context_comment(context: ReleaseContext, main_pr_number: int, state: str, release_url: str | None = None) -> str:
    lines = [RELEASE_PLAN_MARKER, "## Release plan", ""]
    if context.errors:
        lines.append("The release metadata is incomplete.")
        for error in context.errors:
            lines.append(f"- {error}")
        lines.append("")
        lines.append("Accepted forms:")
        lines.append("- `alpha-0.0.1` or `a0.0.1`")
        lines.append("- `beta-0.1.0` or `b0.1.0`")
        lines.append("- `final-1.0.0` or `f1.0.0`")
        return "\n".join(lines)

    assert context.version is not None
    lines.append(f"- State: {state}")
    lines.append(f"- Release version: `{context.version.canonical}`")
    lines.append(f"- Main PR: #{main_pr_number}")
    if context.related_prs:
        lines.append("- Related develop PRs:")
        for pr_number in context.related_prs:
            lines.append(f"  - #{pr_number}")
    if release_url:
        lines.append(f"- Release: {release_url}")
    return "\n".join(lines)


def render_develop_release_notice(context: ReleaseContext, main_pr_number: int, state: str, release_url: str | None = None) -> str:
    lines = [
        RELEASE_NOTICE_MARKER,
        "## Release linkage",
        f"- State: {state}",
    ]
    if context.version:
        lines.append(f"- Release version: `{context.version.canonical}`")
    lines.append(f"- Main PR: #{main_pr_number}")
    if release_url:
        lines.append(f"- Release: {release_url}")
    return "\n".join(lines)


def extract_release_context(body: str | None) -> ReleaseContext:
    sections = sections_from_body(body or "")
    errors: list[str] = []

    version_text = ""
    for header in ("release version", "version", "release"):
        lines = sections.get(header)
        if lines:
            version_text = "\n".join(lines).strip()
            break

    version: ReleaseVersion | None = None
    if version_text:
        candidate = _clean_line(version_text.splitlines()[0])
        match = VERSION_PATTERN.fullmatch(candidate)
        if not match:
            errors.append(
                f"Invalid release version `{candidate}`. Use `alpha-0.0.1`, `beta-0.1.0`, or `final-1.0.0`."
            )
        else:
            channel = CHANNEL_ALIASES[match.group("channel").lower()]
            version_value = match.group("version")
            version_parts = version_value.split(".")
            if len(version_parts) == 2:
                version_value = f"{version_value}.0"
            version = ReleaseVersion(channel=channel, version=version_value)
    else:
        errors.append("Missing `## Release version` section.")

    related_text = ""
    for header in ("related develop prs", "develop prs", "related prs", "linked develop prs"):
        lines = sections.get(header)
        if lines:
            related_text = "\n".join(lines)
            break

    related_prs = []
    if related_text:
        seen: set[int] = set()
        for match in PR_NUMBER_PATTERN.finditer(related_text):
            number = int(match.group(1))
            if number not in seen:
                seen.add(number)
                related_prs.append(number)
    if not related_prs:
        errors.append("Missing related develop PR numbers in `## Related develop PRs`.")

    return ReleaseContext(version=version, related_prs=related_prs, errors=errors, raw_version=version_text or None)


def _extract_related_prs_from_release_comment(comment_body: str | None, main_pr_number: int) -> list[int]:
    if not comment_body:
        return []
    seen: set[int] = set()
    related: list[int] = []
    for match in PR_NUMBER_PATTERN.finditer(comment_body):
        pr_number = int(match.group(1))
        if pr_number == main_pr_number or pr_number in seen:
            continue
        seen.add(pr_number)
        related.append(pr_number)
    return related


def _previous_related_prs(client: GitHubClient, repo: str, pr_number: int) -> list[int]:
    existing = find_marked_comment(client, repo, pr_number, RELEASE_PLAN_MARKER)
    if not existing:
        return []
    return _extract_related_prs_from_release_comment(existing.get("body"), pr_number)


def _remove_stale_develop_notices(
    client: GitHubClient,
    repo: str,
    main_pr_number: int,
    previous_related_prs: list[int],
    current_related_prs: list[int],
) -> None:
    removed = sorted(set(previous_related_prs) - set(current_related_prs))
    if not removed:
        return
    for develop_pr in removed:
        if develop_pr == main_pr_number:
            continue
        upsert_marked_comment(client, repo, develop_pr, RELEASE_NOTICE_MARKER, "")


def ensure_tag(client: GitHubClient, repo: str, tag: str, sha: str) -> str:
    ref_path = f"tags/{tag}"
    try:
        current = client.get_git_ref(repo, ref_path)
    except GitHubRequestError as exc:
        if exc.status != 404:
            raise
        client.create_git_ref(repo, f"refs/tags/{tag}", sha)
        return "created"

    current_sha = current["object"]["sha"]
    if current_sha != sha:
        raise RuntimeError(
            f"Tag `{tag}` already points to `{current_sha}`; expected `{sha}`. Refusing to move existing release tag."
        )
    return "unchanged"


def render_release_body(
    context: ReleaseContext,
    main_pr_number: int,
    sha: str,
    assets: list[ReleaseAssetLink] | None = None,
) -> str:
    assert context.version is not None
    lines = [
        f"Release `{context.version.canonical}`",
        "",
        f"- Main PR: #{main_pr_number}",
        f"- Commit: `{sha}`",
    ]
    if context.related_prs:
        lines.append("- Related develop PRs:")
        for number in context.related_prs:
            lines.append(f"  - #{number}")
    if assets:
        lines.extend(["", "## Downloads"])
        for asset in assets:
            lines.append(f"- [{asset.name}]({asset.url})")
    return "\n".join(lines)


def _normalize_release_assets(asset_paths: list[str] | None) -> list[ReleaseAssetSpec]:
    if not asset_paths:
        return []
    return [ReleaseAssetSpec(path=path) for path in asset_paths]


def _release_assets_by_name(assets: list[dict]) -> dict[str, dict]:
    return {asset["name"]: asset for asset in assets if asset.get("name")}


def _upload_release_assets(
    client: GitHubClient,
    repo: str,
    upload_url: str,
    release_id: int,
    assets: list[ReleaseAssetSpec],
) -> list[ReleaseAssetLink]:
    if not assets:
        return []

    existing_assets = _release_assets_by_name(client.list_release_assets(repo, release_id))
    uploaded_assets: list[ReleaseAssetLink] = []

    for asset in assets:
        existing = existing_assets.get(asset.upload_name)
        if existing:
            client.delete_release_asset(repo, existing["id"])
        result = client.upload_release_asset(repo, upload_url, asset.path, asset.upload_name)
        uploaded_assets.append(
            ReleaseAssetLink(
                name=result.get("name", asset.upload_name),
                url=result.get("browser_download_url", ""),
            )
        )
    return uploaded_assets
def summarize_pull_request(client: GitHubClient, repo: str, pr_number: int, dry_run: bool = False, title: str | None = None) -> int:
    files = client.list_pull_request_files(repo, pr_number)
    items = [ChangeItem(status=item.get("status"), path=item.get("filename", "")) for item in files]
    summary = summarize_change_items(items)
    body = render_change_summary_comment(summary, title=title)
    if dry_run:
        print(body)
        return 0
    upsert_marked_comment(client, repo, pr_number, CHANGE_SUMMARY_MARKER, body)
    return 0


def prepare_main_release(client: GitHubClient, repo: str, pr_number: int, body: str | None, dry_run: bool = False) -> int:
    context = extract_release_context(body)
    rendered = render_release_context_comment(context, pr_number, "planned")
    if dry_run:
        print(rendered)
        return 0 if not context.errors else 1

    previous_related_prs = _previous_related_prs(client, repo, pr_number)
    upsert_marked_comment(client, repo, pr_number, RELEASE_PLAN_MARKER, rendered)

    if context.errors:
        return 1

    _remove_stale_develop_notices(client, repo, pr_number, previous_related_prs, context.related_prs)

    notice = render_develop_release_notice(context, pr_number, "planned")
    for develop_pr in context.related_prs:
        upsert_marked_comment(client, repo, develop_pr, RELEASE_NOTICE_MARKER, notice)
    return 0


def publish_release(
    client: GitHubClient,
    repo: str,
    pr_number: int,
    body: str | None,
    merge_sha: str,
    asset_paths: list[str] | None = None,
    dry_run: bool = False,
) -> int:
    context = extract_release_context(body)
    if context.errors:
        rendered = render_release_context_comment(context, pr_number, "released")
        if dry_run:
            print(rendered)
        else:
            upsert_marked_comment(client, repo, pr_number, RELEASE_PLAN_MARKER, rendered)
        return 1

    assert context.version is not None
    release_assets = _normalize_release_assets(asset_paths)
    release_body = render_release_body(context, pr_number, merge_sha)
    if dry_run:
        if release_assets:
            print(release_body)
            for asset in release_assets:
                print(f"- would upload `{asset.path}` as `{asset.upload_name}`")
            return 0
        print(release_body)
        return 0

    previous_related_prs = _previous_related_prs(client, repo, pr_number)
    ensure_tag(client, repo, context.version.canonical, merge_sha)

    try:
        release = client.get_release_by_tag(repo, context.version.canonical)
    except GitHubRequestError as exc:
        if exc.status != 404:
            raise
        release = client.create_release(repo, context.version, merge_sha, release_body)

    release_id = release["id"]
    upload_url = release.get("upload_url", "").split("{", 1)[0]
    uploaded_assets = _upload_release_assets(client, repo, upload_url, release_id, release_assets)
    final_body = render_release_body(context, pr_number, merge_sha, assets=uploaded_assets)
    result = client.update_release(repo, release_id, context.version, merge_sha, final_body)

    release_url = result.get("html_url")
    upsert_marked_comment(client, repo, pr_number, RELEASE_PLAN_MARKER, render_release_context_comment(context, pr_number, "released", release_url))
    _remove_stale_develop_notices(client, repo, pr_number, previous_related_prs, context.related_prs)
    notice = render_develop_release_notice(context, pr_number, "released", release_url)
    for develop_pr in context.related_prs:
        upsert_marked_comment(client, repo, develop_pr, RELEASE_NOTICE_MARKER, notice)
    return 0
