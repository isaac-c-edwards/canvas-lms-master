#!/usr/bin/env python3
"""Build repository indexes for the analyze-repo agent.

The script performs deterministic, out-of-LLM work: walking files, hashing,
extracting lightweight symbols, and writing machine-readable index files.
"""

from __future__ import annotations

import argparse
import datetime as dt
import fnmatch
import hashlib
import json
import os
import re
from collections import Counter, defaultdict
from pathlib import Path
from typing import Iterable


SCHEMA_VERSION = 1

DEFAULT_IGNORE_DIRS = {
    ".git",
    ".hg",
    ".svn",
    ".cache",
    ".repo-analysis",
    ".terraform",
    ".venv",
    "__pycache__",
    "build",
    "coverage",
    "dist",
    "log",
    "node_modules",
    "tmp",
    "vendor/bundle",
}

LANGUAGE_BY_EXTENSION = {
    ".c": "C",
    ".cc": "C++",
    ".cpp": "C++",
    ".cs": "C#",
    ".css": "CSS",
    ".go": "Go",
    ".h": "C/C++ Header",
    ".hpp": "C++ Header",
    ".html": "HTML",
    ".java": "Java",
    ".js": "JavaScript",
    ".jsx": "JavaScript React",
    ".kt": "Kotlin",
    ".md": "Markdown",
    ".php": "PHP",
    ".py": "Python",
    ".rb": "Ruby",
    ".rs": "Rust",
    ".scala": "Scala",
    ".scss": "SCSS",
    ".sh": "Shell",
    ".sql": "SQL",
    ".swift": "Swift",
    ".ts": "TypeScript",
    ".tsx": "TypeScript React",
    ".vue": "Vue",
    ".xml": "XML",
    ".yml": "YAML",
    ".yaml": "YAML",
}

KEY_FILE_NAMES = {
    ".env.example",
    ".gitignore",
    "AGENTS.md",
    "CLAUDE.md",
    "Dockerfile",
    "Gemfile",
    "Makefile",
    "README",
    "README.md",
    "README.rdoc",
    "docker-compose.yml",
    "go.mod",
    "package.json",
    "pom.xml",
    "pyproject.toml",
    "requirements.txt",
    "setup.py",
    "tsconfig.json",
}

SYMBOL_PATTERNS = [
    re.compile(r"^\s*(?:export\s+)?(?:async\s+)?function\s+([A-Za-z_$][\w$]*)\s*\("),
    re.compile(r"^\s*(?:export\s+)?class\s+([A-Za-z_$][\w$]*)\b"),
    re.compile(r"^\s*(?:export\s+)?(?:const|let|var)\s+([A-Za-z_$][\w$]*)\s*="),
    re.compile(r"^\s*(?:class|module)\s+([A-Z][\w:]*)(?:\s|$)"),
    re.compile(r"^\s*def\s+([A-Za-z_]\w*[!?=]?)\b"),
    re.compile(r"^\s*class\s+([A-Za-z_]\w*)\b"),
    re.compile(r"^\s*def\s+([A-Za-z_]\w*)\s*\("),
    re.compile(r"^\s*func\s+(?:\([^)]+\)\s*)?([A-Za-z_]\w*)\s*\("),
    re.compile(r"^\s*(?:public|private|protected|internal)?\s*(?:class|interface|enum)\s+([A-Za-z_]\w*)\b"),
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build repository analysis indexes.")
    parser.add_argument("repo", nargs="?", default=".", help="Repository root to index.")
    parser.add_argument(
        "--out",
        default=".repo-analysis",
        help="Output directory, relative to the repository root unless absolute.",
    )
    parser.add_argument(
        "--context-budget",
        type=int,
        default=128_000,
        help="Usable model context window in tokens for budget estimates.",
    )
    parser.add_argument(
        "--max-symbol-file-bytes",
        type=int,
        default=250_000,
        help="Skip symbol extraction for files larger than this size.",
    )
    parser.add_argument(
        "--ignore",
        action="append",
        default=[],
        help="Additional directory or glob pattern to ignore. May be repeated.",
    )
    return parser.parse_args()


def should_ignore(path: Path, root: Path, ignore_patterns: set[str]) -> bool:
    rel = path.relative_to(root).as_posix()
    parts = set(path.relative_to(root).parts)
    if parts & ignore_patterns:
        return True
    return any(fnmatch.fnmatch(rel, pattern) for pattern in ignore_patterns)


def iter_repo_files(root: Path, ignore_patterns: set[str]) -> Iterable[Path]:
    for current_root, dirnames, filenames in os.walk(root):
        current_path = Path(current_root)
        dirnames[:] = [
            dirname
            for dirname in dirnames
            if not should_ignore(current_path / dirname, root, ignore_patterns)
        ]
        for filename in filenames:
            path = current_path / filename
            if should_ignore(path, root, ignore_patterns):
                continue
            yield path


def sha256_short(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()[:16]


def is_probably_text(path: Path, sample_size: int = 4096) -> bool:
    try:
        sample = path.read_bytes()[:sample_size]
    except OSError:
        return False
    return b"\x00" not in sample


def language_for(path: Path) -> str:
    return LANGUAGE_BY_EXTENSION.get(path.suffix.lower(), "Other")


def extract_symbols(path: Path, root: Path, max_bytes: int) -> list[dict[str, object]]:
    if path.stat().st_size > max_bytes or not is_probably_text(path):
        return []

    symbols: list[dict[str, object]] = []
    try:
        with path.open("r", encoding="utf-8", errors="replace") as file:
            for line_number, line in enumerate(file, start=1):
                for pattern in SYMBOL_PATTERNS:
                    match = pattern.match(line)
                    if match:
                        symbols.append(
                            {
                                "path": path.relative_to(root).as_posix(),
                                "line": line_number,
                                "name": match.group(1),
                                "text": line.strip()[:200],
                            }
                        )
                        break
    except OSError:
        return []
    return symbols


def estimate_tokens(text: str) -> int:
    # A conservative English/code estimate without depending on tokenizer libs.
    return max(1, (len(text) + 3) // 4)


def write_json(path: Path, payload: object) -> None:
    path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()
    root = Path(args.repo).resolve()
    out_dir = Path(args.out)
    if not out_dir.is_absolute():
        out_dir = root / out_dir
    out_dir.mkdir(parents=True, exist_ok=True)

    ignore_patterns = set(DEFAULT_IGNORE_DIRS) | set(args.ignore)
    files: list[dict[str, object]] = []
    key_files: list[dict[str, object]] = []
    checksums: dict[str, str] = {}
    directories: dict[str, dict[str, object]] = defaultdict(
        lambda: {"files": 0, "bytes": 0, "languages": Counter()}
    )
    languages: Counter[str] = Counter()
    symbols: list[dict[str, object]] = []

    for path in sorted(iter_repo_files(root, ignore_patterns), key=lambda item: item.as_posix()):
        rel = path.relative_to(root).as_posix()
        try:
            stat = path.stat()
            digest = sha256_short(path)
        except OSError:
            continue

        language = language_for(path)
        record = {
            "path": rel,
            "bytes": stat.st_size,
            "language": language,
            "sha256": digest,
        }
        files.append(record)
        checksums[rel] = digest
        languages[language] += 1

        directory = path.parent.relative_to(root).as_posix()
        if directory == ".":
            directory = ""
        directories[directory]["files"] += 1
        directories[directory]["bytes"] += stat.st_size
        directories[directory]["languages"][language] += 1

        if path.name in KEY_FILE_NAMES or path.name.lower().startswith("readme"):
            key_files.append(record)

        if language != "Other":
            symbols.extend(extract_symbols(path, root, args.max_symbol_file_bytes))

    normalized_directories = {
        directory: {
            "files": data["files"],
            "bytes": data["bytes"],
            "languages": dict(sorted(data["languages"].items())),
        }
        for directory, data in sorted(directories.items())
    }

    generated_at = dt.datetime.now(dt.UTC).isoformat()
    manifest = {
        "schema_version": SCHEMA_VERSION,
        "generated_at": generated_at,
        "root": str(root),
        "ignore_patterns": sorted(ignore_patterns),
        "totals": {
            "files": len(files),
            "bytes": sum(int(file["bytes"]) for file in files),
            "languages": dict(sorted(languages.items())),
            "symbols": len(symbols),
        },
        "directories": normalized_directories,
        "files": files,
    }

    target_max_context_tokens = int(args.context_budget * 0.40)
    manifest_summary_tokens = estimate_tokens(
        json.dumps(
            {
                "totals": manifest["totals"],
                "top_level_directories": {
                    name: data
                    for name, data in normalized_directories.items()
                    if "/" not in name and name
                },
            },
            sort_keys=True,
        )
    )
    key_file_tokens = estimate_tokens(json.dumps(key_files, sort_keys=True))
    symbols_jsonl_text = "\n".join(json.dumps(symbol, sort_keys=True) for symbol in symbols)
    full_symbol_tokens = estimate_tokens(symbols_jsonl_text) if symbols else 0
    typical_pass_tokens = {
        "manifest_summary": manifest_summary_tokens,
        "key_file_listing": key_file_tokens,
        "selected_symbol_lookup": min(full_symbol_tokens, int(args.context_budget * 0.05)),
        "source_excerpt_allowance": int(args.context_budget * 0.15),
        "working_notes_and_report": int(args.context_budget * 0.05),
    }
    typical_total = sum(typical_pass_tokens.values())

    budget_payload = {
        "schema_version": SCHEMA_VERSION,
        "generated_at": generated_at,
        "usable_context_tokens": args.context_budget,
        "target_max_context_tokens": target_max_context_tokens,
        "estimation_method": "ceil(character_count / 4) for generated index text and selected excerpts",
        "typical_pass": {
            "estimated_tokens": typical_pass_tokens,
            "estimated_total_tokens": typical_total,
            "estimated_context_percent": round((typical_total / args.context_budget) * 100, 2),
            "under_40_percent_target": typical_total <= target_max_context_tokens,
        },
        "full_index_token_estimates": {
            "manifest_summary": manifest_summary_tokens,
            "key_files": key_file_tokens,
            "symbols_jsonl_full_file": full_symbol_tokens,
            "symbols_jsonl_note": "Do not load the full symbols file. Filter it by path, language, or symbol name first.",
        },
    }

    write_json(out_dir / "manifest.json", manifest)
    write_json(out_dir / "key-files.json", {"schema_version": SCHEMA_VERSION, "files": key_files})
    write_json(out_dir / "checksums.json", {"schema_version": SCHEMA_VERSION, "files": checksums})
    write_json(out_dir / "context-budget.json", budget_payload)
    (out_dir / "symbols.jsonl").write_text(
        symbols_jsonl_text + ("\n" if symbols else ""),
        encoding="utf-8",
    )

    summaries_path = out_dir / "folder-summaries.md"
    if not summaries_path.exists():
        summaries_path.write_text(
            "# Folder Summaries\n\n"
            "This file is maintained by the analyze-repo agent after reading targeted files.\n"
            "Each summary should include purpose, important entry points, and refresh hash notes.\n",
            encoding="utf-8",
        )

    print(json.dumps({"out": str(out_dir), "files": len(files), "symbols": len(symbols)}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
