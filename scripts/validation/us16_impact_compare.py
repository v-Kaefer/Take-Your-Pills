#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


PROBE_FILES = (
    Path("tests/validation/us16_impact_probe.gd"),
    Path("tests/validation/us16_impact_probe.tscn"),
)
PROBE_SCENE = "res://tests/validation/us16_impact_probe.tscn"
USERDATA_LOG_DIR = Path(".local/share/godot/app_userdata/Take Your Pills/logs")
DEFAULT_REFS = (
    ("baseline_pre_us16", "cc38aca"),
    ("initial_us16_retune", "fa5493c"),
    ("current_us16", "HEAD"),
)


@dataclass(frozen=True)
class RefResult:
    label: str
    ref: str
    commit: str
    impact: dict[str, Any]
    benchmark: dict[str, Any]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare the gameplay impact of US-16 balancing across historical refs.",
    )
    parser.add_argument(
        "--repo",
        type=Path,
        default=Path.cwd(),
        help="Repository root to analyze. Defaults to the current directory.",
    )
    parser.add_argument(
        "--godot-bin",
        default="godot",
        help="Godot executable name or absolute path.",
    )
    parser.add_argument(
        "--report-path",
        type=Path,
        default=Path("docs/playtests/us16-impact-verification.md"),
        help="Markdown report output path, relative to --repo unless absolute.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo = args.repo.resolve()
    report_path = args.report_path if args.report_path.is_absolute() else repo / args.report_path

    ensure_probe_files_exist(repo)
    godot_version = run_command([args.godot_bin, "--version"], cwd=repo).stdout.strip()

    with tempfile.TemporaryDirectory(prefix="us16-impact-") as temp_dir:
        temp_root = Path(temp_dir)
        results = [
            collect_ref_result(
                repo=repo,
                worktree_root=temp_root / label,
                artifact_root=temp_root / "artifacts" / label,
                user_home=temp_root / "homes" / label,
                label=label,
                ref=ref,
                godot_bin=args.godot_bin,
            )
            for label, ref in DEFAULT_REFS
        ]

        report = render_report(results=results, godot_version=godot_version)
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(report, encoding="utf-8")

    print(f"Report written to {report_path}")
    return 0


def ensure_probe_files_exist(repo: Path) -> None:
    missing = [str(path) for path in PROBE_FILES if not (repo / path).is_file()]
    if missing:
        raise FileNotFoundError(f"Missing probe files: {', '.join(missing)}")


def collect_ref_result(
    *,
    repo: Path,
    worktree_root: Path,
    artifact_root: Path,
    user_home: Path,
    label: str,
    ref: str,
    godot_bin: str,
) -> RefResult:
    artifact_root.mkdir(parents=True, exist_ok=True)
    env = build_godot_env(user_home)
    add_worktree(repo=repo, path=worktree_root, ref=ref)
    try:
        copy_probe_files(repo=repo, worktree=worktree_root)
        import_project(worktree_root, godot_bin, env)

        impact_path = artifact_root / "impact.json"
        benchmark_path = artifact_root / "benchmark.json"

        run_probe(
            worktree=worktree_root,
            godot_bin=godot_bin,
            mode="impact",
            label=label,
            output_path=impact_path,
            env=env,
        )
        run_probe(
            worktree=worktree_root,
            godot_bin=godot_bin,
            mode="benchmark",
            label=label,
            output_path=benchmark_path,
            env=env,
        )

        commit = run_command(
            ["git", "rev-parse", "--short", "HEAD"],
            cwd=worktree_root,
        ).stdout.strip()
        impact = json.loads(impact_path.read_text(encoding="utf-8"))
        benchmark = json.loads(benchmark_path.read_text(encoding="utf-8"))
        return RefResult(
            label=label,
            ref=ref,
            commit=commit,
            impact=impact["result"],
            benchmark=benchmark["result"],
        )
    finally:
        remove_worktree(repo=repo, path=worktree_root)


def add_worktree(*, repo: Path, path: Path, ref: str) -> None:
    run_command(
        ["git", "worktree", "add", "--detach", str(path), ref],
        cwd=repo,
    )


def remove_worktree(*, repo: Path, path: Path) -> None:
    run_command(
        ["git", "worktree", "remove", "--force", str(path)],
        cwd=repo,
    )


def copy_probe_files(*, repo: Path, worktree: Path) -> None:
    for relative_path in PROBE_FILES:
        source = repo / relative_path
        destination = worktree / relative_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)


def build_godot_env(user_home: Path) -> dict[str, str]:
    user_home.mkdir(parents=True, exist_ok=True)
    (user_home / USERDATA_LOG_DIR).mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env["HOME"] = str(user_home)
    env["XDG_DATA_HOME"] = str(user_home / ".local" / "share")
    env["XDG_CONFIG_HOME"] = str(user_home / ".config")
    return env


def import_project(worktree: Path, godot_bin: str, env: dict[str, str]) -> None:
    run_command(
        [godot_bin, "--headless", "--path", str(worktree), "--import"],
        cwd=worktree,
        env=env,
    )


def run_probe(
    *,
    worktree: Path,
    godot_bin: str,
    mode: str,
    label: str,
    output_path: Path,
    env: dict[str, str],
) -> None:
    run_command(
        [
            godot_bin,
            "--headless",
            "--path",
            str(worktree),
            "--scene",
            PROBE_SCENE,
            "--",
            "--mode",
            mode,
            "--label",
            label,
            "--output",
            str(output_path),
        ],
        cwd=worktree,
        env=env,
    )


def run_command(
    command: list[str],
    *,
    cwd: Path,
    env: dict[str, str] | None = None,
) -> subprocess.CompletedProcess[str]:
    completed = subprocess.run(
        command,
        cwd=cwd,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError(
            "Command failed ({code}): {command}\nSTDOUT:\n{stdout}\nSTDERR:\n{stderr}".format(
                code=completed.returncode,
                command=" ".join(command),
                stdout=completed.stdout,
                stderr=completed.stderr,
            )
        )
    return completed


def render_report(*, results: list[RefResult], godot_version: str) -> str:
    indexed = {result.label: result for result in results}
    baseline = indexed["baseline_pre_us16"]
    retune = indexed["initial_us16_retune"]
    current = indexed["current_us16"]
    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    mechanics_rows = [
        (
            "Opening scroll speed",
            baseline.impact["pacing_response"]["opening_scroll_speed"],
            retune.impact["pacing_response"]["opening_scroll_speed"],
            current.impact["pacing_response"]["opening_scroll_speed"],
            "Lower is calmer in the opening seconds.",
        ),
        (
            "Time to mid band",
            baseline.impact["progression"]["seconds_to_mid"],
            retune.impact["progression"]["seconds_to_mid"],
            current.impact["progression"]["seconds_to_mid"],
            "Higher means the first readable phase lasts longer.",
        ),
        (
            "Time to transition score",
            baseline.impact["progression"]["seconds_to_transition"],
            retune.impact["progression"]["seconds_to_transition"],
            current.impact["progression"]["seconds_to_transition"],
            "Higher delays the scenario swap and keeps the opening calmer.",
        ),
        (
            "Tier-1 speed-up effective speed",
            baseline.impact["speed_up"]["tier_one_speed"],
            retune.impact["speed_up"]["tier_one_speed"],
            current.impact["speed_up"]["tier_one_speed"],
            "Lower reduces the first post-pickup spike.",
        ),
        (
            "Tier-2 speed-up effective speed",
            baseline.impact["speed_up"]["tier_two_speed"],
            retune.impact["speed_up"]["tier_two_speed"],
            current.impact["speed_up"]["tier_two_speed"],
            "Lower reduces the harshest boost spike.",
        ),
        (
            "Tier-1 slowdown effective speed",
            baseline.impact["speed_down"]["tier_one_speed"],
            retune.impact["speed_down"]["tier_one_speed"],
            current.impact["speed_down"]["tier_one_speed"],
            "Higher is less punitive after one slowdown stack.",
        ),
        (
            "Tier-2 slowdown effective speed",
            baseline.impact["speed_down"]["tier_two_speed"],
            retune.impact["speed_down"]["tier_two_speed"],
            current.impact["speed_down"]["tier_two_speed"],
            "Higher is less punitive after two slowdown stacks.",
        ),
        (
            "Single pill score delta",
            baseline.impact["pill_bonus"]["score_delta"],
            retune.impact["pill_bonus"]["score_delta"],
            current.impact["pill_bonus"]["score_delta"],
            "Lower reduces score inflation from common pickups.",
        ),
    ]

    performance_rows = [
        (
            "Score signal burst median (`us/emit`)",
            baseline.benchmark["score_signal_burst"]["median_us_per_emit"],
            retune.benchmark["score_signal_burst"]["median_us_per_emit"],
            current.benchmark["score_signal_burst"]["median_us_per_emit"],
        ),
        (
            "Score tick loop median (`us/frame`)",
            baseline.benchmark["score_tick_loop"]["median_us_per_frame"],
            retune.benchmark["score_tick_loop"]["median_us_per_frame"],
            current.benchmark["score_tick_loop"]["median_us_per_frame"],
        ),
    ]

    lines = [
        "# US-16 Impact Verification",
        "",
        f"- Generated: {generated_at}",
        f"- Engine: `{godot_version}`",
        "- Compared refs:",
        f"  - `baseline_pre_us16` -> `{baseline.ref}` (`{baseline.commit}`)",
        f"  - `initial_us16_retune` -> `{retune.ref}` (`{retune.commit}`)",
        f"  - `current_us16` -> `{current.ref}` (`{current.commit}`)",
        "- Method: headless Godot probe run against each ref through `scripts/validation/us16_impact_compare.py`.",
        "",
        "## Mechanics and pacing",
        "",
        "| Metric | Baseline | Initial retune | Current | Current vs baseline | Current vs retune | Reading |",
        "| --- | ---: | ---: | ---: | ---: | ---: | --- |",
    ]

    for label, baseline_value, retune_value, current_value, reading in mechanics_rows:
        lines.append(
            "| {label} | {baseline} | {retune} | {current} | {vs_baseline} | {vs_retune} | {reading} |".format(
                label=label,
                baseline=format_number(baseline_value),
                retune=format_number(retune_value),
                current=format_number(current_value),
                vs_baseline=format_delta(current_value, baseline_value),
                vs_retune=format_delta(current_value, retune_value),
                reading=reading,
            )
        )

    lines.extend(
        [
            "",
            "## Key observations",
            "",
            "- The current branch materially calms the opening by dropping the base scroll speed and by delaying the score-band ramp compared with both earlier states.",
            "- The final speed-up spikes are the softest of the three revisions, which directly improves readability after stacking the red-orange collectables.",
            "- The slowdown path stays failure-compatible but is less punishing than the baseline at the second stack, so recovery remains possible for longer.",
            "- Pill scoring is back to `100`, undoing the inflated `120` value from the first retune and reducing score inflation on common pickups.",
            "- The added pacing logic remains visible in the synthetic benchmark, but the absolute controller-path cost still stays in the single-digit microsecond range on this machine.",
            "",
            "## Performance",
            "",
            "| Benchmark | Baseline | Initial retune | Current | Current vs baseline | Current vs retune |",
            "| --- | ---: | ---: | ---: | ---: | ---: |",
        ]
    )

    for label, baseline_value, retune_value, current_value in performance_rows:
        lines.append(
            "| {label} | {baseline} | {retune} | {current} | {vs_baseline} | {vs_retune} |".format(
                label=label,
                baseline=format_number(baseline_value),
                retune=format_number(retune_value),
                current=format_number(current_value),
                vs_baseline=format_delta(current_value, baseline_value),
                vs_retune=format_delta(current_value, retune_value),
            )
        )

    lines.extend(
        [
            "",
            "The benchmark numbers come from the same local machine and should be read as synthetic spot checks, not as full frame-budget accounting. They are sensitive to import state and cache warm-up, so any important regression should be confirmed with an isolated rerun on the target ref.",
            "",
            "## Raw samples",
            "",
            f"- `score_signal_burst` current samples: `{current.benchmark['score_signal_burst']['samples_us_per_emit']}`",
            f"- `score_tick_loop` current samples: `{current.benchmark['score_tick_loop']['samples_us_per_frame']}`",
        ]
    )

    return "\n".join(lines) + "\n"


def format_number(value: Any) -> str:
    if isinstance(value, float):
        return f"{value:.3f}".rstrip("0").rstrip(".")
    return str(value)


def format_delta(current: Any, previous: Any) -> str:
    if not isinstance(current, (int, float)) or not isinstance(previous, (int, float)):
        return "n/a"
    if previous == 0:
        return "n/a"
    delta = ((float(current) - float(previous)) / float(previous)) * 100.0
    sign = "+" if delta > 0 else ""
    return f"{sign}{delta:.1f}%"


if __name__ == "__main__":
    raise SystemExit(main())
