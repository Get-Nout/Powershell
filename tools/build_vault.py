#!/usr/bin/env python3
"""
Scans the category folders in this repo and regenerates the SCRIPTS
array embedded in script_vault.html.

Usage:
    python tools/build_vault.py

Run this after adding, moving, or documenting scripts, then commit the
updated script_vault.html alongside your script changes.
"""
import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
VAULT_HTML = REPO_ROOT / "script_vault.html"

# Top-level folders that hold scripts. Anything else at repo root
# (LICENSE, README, tools/, .git/) is ignored.
CATEGORY_DIRS = ["AD", "Commandlets", "Hyper-V", "Maintenance", "Reporting", "SQL"]

LANG_BY_EXT = {
    ".ps1": "powershell",
    ".psm1": "powershell",
    ".psd1": "powershell",
    ".bat": "batch",
    ".cmd": "batch",
    ".cs": "csharp",
}

HELP_BLOCK_RE = re.compile(r"<#(.*?)#>", re.DOTALL)
SECTION_RE = re.compile(r"\.(SYNOPSIS|DESCRIPTION|NOTES|EXAMPLE)\s*\r?\n(.*?)(?=\r?\n\s*\.\w+|\Z)", re.DOTALL | re.IGNORECASE)
NOTES_AUTHOR_RE = re.compile(r"^[ \t]*Author:[ \t]*([^(\r\n]+)", re.MULTILINE)
NOTES_EDITOR_RE = re.compile(r"^[ \t]*Editor:[ \t]*([^(\r\n]+)", re.MULTILINE)
NOTES_ORIGINAL_AUTHOR_RE = re.compile(r"^[ \t]*Original[ \t]+Author:[ \t]*([^(\r\n]+)", re.MULTILINE | re.IGNORECASE)

# Fallback for scripts that only have loose "Creator: X" style comments (with
# or without a leading '#' - some scripts put this inside a <# ... #> block),
# not a formal comment-based help block.
LOOSE_CREATOR_RE = re.compile(
    r"^[ \t]*#{0,3}[ \t]*(?:Original\s+)?(?:Creator|Creators|Author|Editor|Created\s+by)s?\s*:?\s*(.+?)\s*$",
    re.MULTILINE | re.IGNORECASE,
)


def clean(text):
    return re.sub(r"\s+", " ", text).strip(" \t\r\n#*'\"") if text else ""


def strip_bom(text):
    return text.lstrip("﻿")


def parse_help_block(content):
    """Return (synopsis, description, creator) from formal comment-based help, if present."""
    m = HELP_BLOCK_RE.search(content)
    if not m:
        return None, None, None
    block = m.group(1)
    sections = {}
    for sec_m in SECTION_RE.finditer(block):
        name, body = sec_m.group(1).upper(), sec_m.group(2)
        sections[name] = clean(body)

    synopsis = sections.get("SYNOPSIS")
    description = sections.get("DESCRIPTION")
    notes = block  # search whole block for Author/Editor, not just .NOTES body

    editor = NOTES_EDITOR_RE.search(notes)
    author = NOTES_AUTHOR_RE.search(notes)
    original = NOTES_ORIGINAL_AUTHOR_RE.search(notes)

    creator = None
    if editor:
        creator = clean(editor.group(1))
        if original:
            creator = f"{creator} (edit of {clean(original.group(1))})"
    elif author:
        creator = clean(author.group(1))

    return synopsis, description, creator


def parse_loose_creator(content):
    m = LOOSE_CREATOR_RE.search(content)
    if not m:
        return None
    val = clean(m.group(1))
    # Skip lines that clearly aren't a name (e.g. version numbers picked up by mistake)
    if not val or len(val) > 80:
        return None
    return val


def first_code_preview(content):
    in_block_comment = False
    for line in content.splitlines():
        s = line.strip().lstrip("﻿")
        if not s:
            continue
        if in_block_comment:
            if "#>" in s:
                in_block_comment = False
            continue
        if s.startswith("<#"):
            if "#>" not in s:
                in_block_comment = True
            continue
        if s.startswith("#") or s.startswith("*") or s.startswith("//"):
            continue
        return s[:140]
    return None


def build_entry(path, category):
    raw = path.read_bytes()
    try:
        content = raw.decode("utf-8-sig")
    except UnicodeDecodeError:
        content = raw.decode("latin-1")
    content = strip_bom(content)

    ext = path.suffix.lower()
    lang = LANG_BY_EXT.get(ext, "text")

    synopsis, description, creator = parse_help_block(content)
    if not creator:
        creator = parse_loose_creator(content)

    desc = description or synopsis
    entry = {
        "title": path.stem,
        "filename": path.name,
        "category": category,
        "lang": lang,
        "loc": len(content.splitlines()),
        "content": content,
    }
    if desc:
        entry["description"] = desc
    else:
        preview = first_code_preview(content)
        if preview:
            entry["preview_line"] = preview
    if creator:
        entry["creator"] = creator
    return entry


def main():
    scripts = []
    for cat in CATEGORY_DIRS:
        cat_dir = REPO_ROOT / cat
        if not cat_dir.is_dir():
            continue
        for path in sorted(cat_dir.rglob("*")):
            if path.is_dir():
                continue
            scripts.append(build_entry(path, cat))

    scripts.sort(key=lambda s: (s["category"], s["title"]))

    html = VAULT_HTML.read_text(encoding="utf-8")
    js_array = json.dumps(scripts, ensure_ascii=False, indent=2)
    # Guard against a script's content containing a literal "</script>",
    # which would otherwise close the surrounding <script> tag early.
    js_array = js_array.replace("</script", "<\\/script")
    replacement = "const SCRIPTS = " + js_array + ";"
    new_html, n = re.subn(
        r"const SCRIPTS = \[.*?\];",
        lambda _m: replacement,
        html,
        count=1,
        flags=re.DOTALL,
    )
    if n == 0:
        raise SystemExit("Could not find 'const SCRIPTS = [...]' in script_vault.html")

    VAULT_HTML.write_text(new_html, encoding="utf-8")
    print(f"Wrote {len(scripts)} scripts across {len(set(s['category'] for s in scripts))} categories into {VAULT_HTML.name}")


if __name__ == "__main__":
    main()
