# devlog-tools — Plan & Discussion Log

This file captures the thinking behind devlog-tools: what it is, why it exists, and the ongoing design conversations that shaped it. It's as much a journal as a plan.

---

## What It Is

A small set of shell scripts and a Claude Code skill that add a low-friction build log to any project. The core loop:

- Work on something
- Commit with `[snap]` in the message → screenshot + devlog entry created automatically
- Or run `/devsnap` in Claude Code for a deliberate entry with a written narrative and tweet draft
- Preview everything locally as a single HTML file

No build system. No database. No server required. Everything is files in the project repo.

---

## Origin

Built during development of [Threequencer](https://github.com/dnewcome/threequencer) — a 3D voxel sequencer. The problem was familiar: interesting work happening, but capturing it in real time is friction, and friction means it doesn't happen.

The insight was that Claude Code already has full context — it knows what just got built, can read git history, and can write — so the skill should require almost zero effort to invoke. You type `/devsnap`, optionally add a note, and the entry writes itself.

---

## The Ecosystem

devlog-tools fits into a broader working-in-public setup:

| Repo | Role |
|---|---|
| `<project>` (e.g. threequencer) | Source of truth: code + devlog + screenshots |
| `wip-stream` | Processes Claude session transcripts from `~/.claude/projects/`, correlates artifacts by timestamp, project UUID |
| `dnuke.com` | Personal site — one publication target among several |
| `devlog-tools` (this repo) | Shared tooling, versioned independently |

Each project has a `.project.toml` with a stable UUID. That UUID is the linking key across the whole pipeline — devlog entries, session transcripts, published content. Convention established in the wip-stream project.

---

## Design Conversations

### Why not a monorepo or central hub?

The first instinct might be to make `wip-stream` a hub — everything flows through it, it routes content to publication targets. But that introduces centralization that conflicts with the intent.

Working in public implies internet-scale, not local-team scale. Internet workflows are inherently distributed. No shared database, no intranet, no "the server." Everything should work offline-first and sync by pushing to git or posting to a public URL.

Each project knows its own identity and its own targets. wip-stream is a *processor* (reads session transcripts, outputs correlation data) not a *hub* (receives everything, routes it).

### POSSE

[POSSE](https://indieweb.org/POSSE) — Publish on your Own Site, Syndicate Elsewhere. The devlog entry in the project repo is the canonical version. Copies go to Twitter, dnuke.com, wherever — but the source stays in the project. Deletion or edit at a syndication target doesn't affect the original.

dnuke.com is one publication target. Twitter is another. They're peers, not the source.

### Local source of truth

The project repo is the source of truth. The devlog lives next to the code. Screenshots live next to the devlog. The `.project.toml` UUID is the identity anchor. Nothing depends on a central server to be "real."

This is a deliberate choice. The alternative — a central artifact store that all projects push into — is more queryable but introduces a dependency and a single point of failure. Distributed is harder to query but harder to break.

### Tone

The `/devsnap` skill produces two kinds of entries:

- **Ship entries** — something was built. Narrative tone, genuine enthusiasm, no clickbait. Feels like a builder talking to other builders. Tweet draft announces the thing.
- **Design journal entries** — a question is being wrestled with. Captures tradeoffs, what's pulling in different directions. Tweet draft invites conversation rather than announcing a ship.

The line between "working in public" and "content marketing" is tone. The goal is the former.

### Versioning: tags, not submodules

devlog-tools needs to be usable across multiple repos without submodules (too much friction, too many footguns) and without a monorepo (conflicts with the distributed philosophy).

The chosen approach: vendoring at a tag. `install.sh` downloads a tarball from a specific GitHub tag and copies files into the project. The version is recorded in `.project.toml` under `[devlog]`. To upgrade, re-run install with a new tag.

Tradeoffs accepted:
- Local edits to scripts get clobbered on upgrade (intentional — if you need to diverge, fork the tool)
- You don't automatically know when you're behind (check the repo manually or add a `devlog-tools check` command later)
- No transitive dependency management (there are no dependencies, so this isn't a problem yet)

### Screenshot strategy

Two modes:
- **Chrome headless** (default, used on `[snap]` commits): no display needed, reliable in CI or when you're not at the machine. WebGL doesn't render without a GPU, so you get the UI chrome but not the 3D view.
- **Live window capture** (used by `/devsnap`): `import` (ImageMagick) grabs the actual browser window via `xdotool`. Captures real WebGL output. Requires a display and the browser to be open.

Mac support: `google-chrome` → `open -a "Google Chrome"` shim needed. Not implemented yet — added when the Macbook workflow becomes active.

---

## What's Not Settled

- **Publishing pipeline**: `devpublish.sh` is a stub. The real question is push vs. pull. Push (script copies file to dnuke.com, commits) is simpler but requires knowing about each target. Pull (dnuke.com reads from a feed or known path) is more decoupled and fits POSSE better. Leaning toward a per-project JSON or RSS feed that targets consume.

- **Multi-machine sync**: devlog markdown and assets sync fine via git. The git hook needs `install-hooks.sh` run once per clone. Screenshots taken on one machine don't automatically appear on another (they're in git, so they do after a push/pull, but the workflow is slightly awkward).

- **wip-stream integration**: wip-stream correlates Claude session transcripts to projects by UUID. The natural next step is for wip-stream to also read devlog entries from projects and include them in a unified artifact view. Not designed yet.

- **Notification / feed**: no way currently to know when a project has new devlog entries unless you check the repo. A simple `devlog/feed.json` generated by `devlog-preview.sh` would enable aggregation later.

---

## File Structure (installed into a project)

```
.project.toml                    project identity + devlog version
devlog/                          devlog entries
devlog/assets/                   screenshots
devlog/preview.html              generated preview (gitignored)
scripts/devsnap.sh               snapshot: screenshot + entry
scripts/devlog-preview.sh        render devlog to HTML
scripts/devpublish.sh            publish to a target (stub)
scripts/install-hooks.sh         install git hooks (run after clone)
.claude/commands/devsnap.md      /devsnap Claude Code skill
.git/hooks/post-commit           auto-snap on [snap] commits (not tracked)
```

---

## Versioning

This repo uses semantic tags. Breaking changes bump the major version. Install a specific tag to pin:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/dnewcome/devlog-tools/main/install.sh) --tag v1.0
```
