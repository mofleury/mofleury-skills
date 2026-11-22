# Issue tracker: task tree

The issue tracker operations for skills that use one (wayfinder, to-tickets, to-spec, triage, implement). An issue
is a task in the tree described in [SKILL.md](SKILL.md); read that first. A project points here from its
`docs/agents/issue-tracker.md`.

This tracker is not the "local markdown" tracker: nothing goes in `.scratch/`. When a skill gives a path under
`.scratch/` for local files, use the operations below instead, as for any other issue tracker.

## Conventions

- **Issue**: a task. Its title is the `# Title` heading; its number is its ID (its path from the root).
- **Create an issue**: a new task file where it belongs, with the two header lines (`Status: todo; depends on: none`,
	then `Labels:`), its labels on line 2.
- **Sub-issue of a parent**: create it in the parent's folder. If the parent is a simple task, make it a folder
	first (`git mv x.md x/TASK.md`).
- **Read an issue**: read its file. The user normally passes the ID or the path.
- **List issues**: `tasks.sh tree [id]`, `tasks.sh label <label>`, `tasks.sh frontier [id]`.
- **Blocking**: the `depends on` part of line 1, full IDs. A task is unblocked when every task it depends on is
	`done`. Write dependencies once the tasks they name exist (create first, then wire), with real IDs.
- **Apply / remove labels**: edit line 2.
- **Comment**: append to a `## Comments` section at the bottom of the file (create it if missing), one entry per
	comment: `- YYYY-MM-DD: text` (sub-bullets for longer ones).
- **Assign / claim**: there is one developer; claiming is `Status: active`.
- **Close**: done work: fill **Outcome**, then `Status: done; <one-line outcome>`. Rejected or abandoned:
	`Status: dropped; <why>` (for triage, also the `wontfix` label). Then the deletion rules of SKILL.md apply.

## When a skill says "publish to the issue tracker"

Create a task. A spec (to-spec) is a task folder: `<slug>/TASK.md` with the spec as its body; the tickets made from
it (to-tickets) are its subtasks, created in dependency order, wired with `depends on`, labelled `ready-for-agent`
unless told otherwise.

## When a skill says "fetch the relevant ticket"

Read the task's file, and the `TASK.md` of its ancestors when the context matters.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a task folder; its **tickets** are its subtasks.

- **Map**: `<effort>/TASK.md`, labelled `wayfinder:map`, `Status: active`, with this body:

	```markdown
	Status: active; depends on: none
	Labels: wayfinder:map

	# Title

	## Destination

	## Notes

	## Decisions so far

	## Not yet specified

	## Out of scope
	```

- **Ticket**: a subtask of the map, labelled with its type only (`wayfinder:research`, `wayfinder:prototype`,
	`wayfinder:grilling`, `wayfinder:task`), with its question in the body and an **Outcome** for the answer:

	```markdown
	Status: todo; depends on: none
	Labels: wayfinder:grilling

	# Title

	## Question

	## Outcome
	```

- **Blocking**: `depends on`, as above.
- **Frontier**: `tasks.sh frontier <map id>`: open (`todo`), unblocked, unclaimed; the first listed wins.
- **Claim**: set `Status: active` and save, before any other work.
- **Resolve**: write the answer under **Outcome**, set `Status: done; <gist>`, then append a pointer to the map's
	**Decisions so far**: `- [<ticket title>](<path from the map>): <one-line gist>`.
- **Out of scope**: `Status: dropped; out of scope: <why>`, and one line in the map's **Out of scope** (gist and
	why).
- **Deleting tickets**: a decision lives in its ticket, so a resolved ticket stays as long as the map is open,
	unless its decision has moved to a `DESIGN.md` (then its Decisions-so-far line links there). When the destination
	is reached and handed off (a spec, a design, a change), the map is deleted whole.
