# devlog-tools

Low-friction build logging for projects. Automatic screenshots, devlog entries, and tweet drafts — without leaving your editor.

## Install

From inside any git repo:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/dnewcome/devlog-tools/main/install.sh) --tag v1.0
```

After cloning an existing repo that uses devlog-tools:

```bash
bash scripts/install-hooks.sh
```

## Usage

**Automatic** — add `[snap]` to any commit message:
```bash
git commit -m "add scale mode selector [snap]"
```
Takes a screenshot, creates a devlog entry in `devlog/`.

**Deliberate** — from Claude Code:
```
/devsnap
/devsnap "thinking through whether to use cellular automata or a sweep plane"
```
Captures the live browser window, writes the narrative, drafts the tweet.

**Preview**:
```bash
bash scripts/devlog-preview.sh --open
```
Renders all entries to `devlog/preview.html` — opens as a `file://` URL, no server needed.

## How it works

See [PLAN.md](PLAN.md) for full design discussion and philosophy.
