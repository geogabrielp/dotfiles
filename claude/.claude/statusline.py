#!/usr/bin/env python3
"""
Claude Code status line renderer.

Claude Code pipes a JSON payload on stdin; whatever this prints becomes the
status line. Each segment is a self-contained function rendering one piece of
that payload, so adding, removing, or reordering one is a single line in
SEGMENTS.
"""

import json
import os
import subprocess
import sys
from collections.abc import Callable

# ---------------------------------------------------------------------------
# Data ingestion
# ---------------------------------------------------------------------------


def load_data() -> dict:
    return json.load(sys.stdin)


# ---------------------------------------------------------------------------
# ANSI palette
# ---------------------------------------------------------------------------

R = "\033[0m"  # reset
BOLD = "\033[1m"

BLUE = "\033[38;5;39m"  # dodger blue  — current directory
PINK = "\033[38;5;213m"  # pink        — git branch
LILAC = "\033[38;5;141m"  # lilac      — model name
TEAL = "\033[38;5;86m"  # turquoise    — effort level
YELLOW = "\033[38;5;220m"  # gold      — cost, dirty marker
GRAY = "\033[38;5;240m"  # dim gray    — separators, muted detail

GREEN = "\033[38;5;82m"  # green       — context < 50%
ORANGE = "\033[38;5;208m"  # orange    — context >= 50%
RED = "\033[38;5;196m"  # red          — context >= 80%


# ---------------------------------------------------------------------------
# Context bar glyphs — eighth-blocks fill eight steps per cell.
# ---------------------------------------------------------------------------

_BLOCK = "█"
_EMPTY = "░"
_EIGHTHS = " ▏▎▍▌▋▊▉"


def color_for_pct(pct: int) -> str:
    if pct >= 80:
        return RED
    if pct >= 50:
        return ORANGE
    return GREEN


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def shorten_dir(cwd: str, depth: int = 2) -> str:
    home = os.path.expanduser("~")
    path = cwd.replace(home, "~", 1)
    parts = path.rstrip("/").split("/")
    if len(parts) > depth:
        # Prefix with ~/ under $HOME, and with …/ otherwise. A bare tail like
        # "b/c" reads as a relative path and hides that it was truncated.
        prefix = "~/" if path.startswith("~") else "…/"
        path = prefix + "/".join(parts[-depth:])
    return path


def git_run(*args, cwd: str) -> str:
    return subprocess.check_output(
        ["git", "-c", "core.hooksPath=/dev/null", *args],
        text=True,
        stderr=subprocess.DEVNULL,
        cwd=cwd,
    ).strip()


def git_state(cwd: str) -> tuple[str, bool]:
    """Branch name and dirty flag, from a single `git status` call."""
    try:
        out = git_run("status", "--porcelain=v2", "--branch", cwd=cwd)
    except Exception:
        return "", False
    branch, dirty = "", False
    for line in out.splitlines():
        if line.startswith("# branch.head "):
            head = line.removeprefix("# branch.head ").strip()
            # "(detached)" is git's placeholder, not a branch name.
            branch = "" if head == "(detached)" else head
        elif not line.startswith("#"):
            dirty = True
    return branch, dirty


# ---------------------------------------------------------------------------
# Segment builders
# Each function accepts the full data dict and returns a string (or "").
# Returning "" causes the segment to be omitted from the status line.
# ---------------------------------------------------------------------------


Segment = Callable[[dict], str]


def seg_location(data: dict) -> str:
    cwd = (data.get("workspace") or {}).get("current_dir") or os.getcwd()
    out = f"{BLUE}{shorten_dir(cwd)}{R}"
    branch, dirty = git_state(cwd)
    if branch:
        out += f"{GRAY}/{R}{PINK}{branch}{R}"
    if dirty:
        out += f" {YELLOW}*{R}"
    return out


def seg_model(data: dict) -> str:
    model = (data.get("model") or {}).get("display_name") or ""
    if not model:
        return ""
    out = f"{LILAC}{BOLD}{model}{R}"
    effort = (data.get("effort") or {}).get("level")
    if effort:
        out += f" {TEAL}({effort}){R}"
    return out


def seg_context(data: dict) -> str:
    ctx = data.get("context_window") or {}
    if not ctx:
        return ""  # no window reported — an empty bar is worse than no segment
    pct = max(0, min(100, int(ctx.get("used_percentage") or 0)))
    size = ctx.get("context_window_size", 0) or 0
    size_str = f"{size // 1000}k" if size >= 1000 else str(size)
    return f"{color_for_pct(pct)}{pct}%{R} {_context_bar(pct)} {GRAY}{size_str}{R}"


def _context_bar(pct: int, width: int = 10) -> str:
    """Eighth-block bar — eight sub-steps per cell, so 1% moves the fill."""
    full, rest = divmod(round(pct / 100 * width * 8), 8)
    partial = _EIGHTHS[rest] if rest and full < width else ""
    cells = full + (1 if partial else 0)
    return (
        f"{color_for_pct(pct)}{_BLOCK * full}{partial}{R}"
        f"{GRAY}{_EMPTY * (width - cells)}{R}"
    )


def seg_cost(data: dict) -> str:
    cost = data.get("cost", {}).get("total_cost_usd", 0) or 0
    if not cost:
        return ""  # subscription sessions always report 0 — skip "$0.0000"
    return f"{YELLOW}${cost:.4f}{R}"


# ---------------------------------------------------------------------------
# Segment registry — edit this list to add, remove, or reorder segments.
# ---------------------------------------------------------------------------

SEGMENTS: list[Segment] = [
    seg_location,
    seg_model,
    seg_context,
    # seg_cost,
]

# ---------------------------------------------------------------------------
# Assembly
# ---------------------------------------------------------------------------

SEP = f" {GRAY}│{R} "


def build_status(data: dict) -> str:
    parts = [fn(data) for fn in SEGMENTS]
    parts = [p for p in parts if p]
    return SEP.join(parts)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    # A malformed or empty payload must render as nothing — never as a
    # traceback in the middle of the status line.
    try:
        print(build_status(load_data()))
    except Exception:
        sys.exit(0)
