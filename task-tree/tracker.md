# Issue tracker: task tree

The issue tracker operations for the skills that use one (wayfinder, to-tickets, to-spec, triage, implement), on
the task tree of [SKILL.md](SKILL.md). A project points here from its `docs/agents/issue-tracker.md`.

When a skill gives `.scratch/` paths for local files, use the operations below instead, as for any other issue
tracker.

## Operations

- **Issue**: a task. Its title is its `# Title`; its number is its ID.
- **Create**: a task from a template (SKILL.md, New tasks), in the folder it belongs to.
- **Sub-issue**: a task in the parent's folder; a simple parent becomes a folder first (SKILL.md, Layout).
- **Read** (fetch the relevant ticket): the task's file, and the `TASK.md` of its ancestors when the context matters.
	The user normally passes the ID or the path.
- **List**: `tasks.sh tree`, `tasks.sh label <label>`, `tasks.sh frontier`.
- **Blocking**: `depends on`, wired once the tasks it names exist (create first, then wire), with real IDs.
- **Labels**: line 2.
- **Comment**: a `## Comments` section at the bottom of the file (created when first needed), one
	`- YYYY-MM-DD: text` entry per comment.
- **Claim / assign**: `Status: active` (one developer).
- **Close**: done work as in SKILL.md, Sessions. Rejected or abandoned: `dropped; <why>`, plus the `wontfix` label
	for triage. Then SKILL.md, Deleting tasks.

## Publish to the issue tracker

Create a task. A spec (to-spec) is a task folder with the spec as its `TASK.md` body; its tickets (to-tickets) are
its subtasks, created in dependency order and labelled `ready-for-agent` unless told otherwise.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a task folder; its **tickets** are its subtasks.

- **Map**: `<effort>/TASK.md` from `templates/map.md`, labelled `wayfinder:map`.
- **Ticket**: a subtask from `templates/ticket.md`, labelled with its type only (`wayfinder:research`,
	`wayfinder:prototype`, `wayfinder:grilling` or `wayfinder:task`). Its **Outcome** holds the answer.
- **Frontier**: `tasks.sh frontier <map id>`; the first listed wins.
- **Claim**: `Status: active`, saved before any other work.
- **Resolve**: the answer under **Outcome**, `Status: done; <gist>`, then the map's **Decisions so far** gets
	`- [<ticket title>](<path from the map>): <one-line gist>`.
- **Out of scope**: `Status: dropped; out of scope: <why>`, and one line in the map's **Out of scope** (gist, why).
- **Deleting**: a resolved ticket holds its decision, so it stays while the map is open, unless the decision has moved
	to a `DESIGN.md` (its Decisions-so-far line then links there). Once the destination is reached and handed off, the
	map is deleted whole.
