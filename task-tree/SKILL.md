---
name: task-tree
description: Task tree: the project's planned work as markdown task files in `docs/tasks/`, and its issue tracker for other skills. Use when working on, creating or changing tasks, or when a skill needs the issue tracker.
---

# Task tree

Planned work lives in the project as a tree of tasks, one markdown file per task: a simple task is a file, a task
with subtasks is a folder. The files are the whole tracker. The tree stays **lean**: it holds the open work and what
that work still needs; git history holds the rest.

The root is `docs/tasks/`, or the one the project's `CLAUDE.md` names (then set `TASKS_ROOT` for the script).

## Layout

```
docs/tasks/
	export_fix.md              a simple task
	bead_patterns/             a task with subtasks
		TASK.md                  the task itself: header, goal, scope, pivots
		DESIGN.md                optional, at any level: architecture and decisions, each with its reason
		pattern_ux.md            a subtask
		generator/               a subtask with subtasks of its own
			TASK.md
			sequences.md
```

- A file is a task when its first line starts with `Status:`. Other markdown files in the tree (`DESIGN.md`, notes)
	belong to the task whose folder holds them.
- A folder is a task when it has a `TASK.md`; every folder holding tasks has one, the root excepted.
- The folder is the list of its subtasks (`tasks.sh tree <id>`).
- A simple task that grows subtasks becomes a folder: `git mv x.md x/TASK.md`. Its ID stays the same.

## IDs

A task's ID is its path from the root without `.md` or `/TASK.md`: `bead_patterns/generator/sequences`,
`bead_patterns/generator`. The same ID whether the task is a file or a folder.

- Names are lowercase, words joined with `_`, and name the task's subject; order comes from `depends on`.
- Dependencies and links use full IDs.
- Moving or renaming a task changes its ID: update every task `tasks.sh refs <id>` lists.

## The header: two lines

```
Status: <todo | active | paused | blocked | done | dropped>; depends on: <id, id | none>[; <note>]
Labels: <label, label, ...>
```

- Line 1 is the task's whole current status, replaced as a whole when it changes. Its note is the why for
	`blocked` and `dropped`, the one-line outcome for `done`, and absent otherwise. Progress, results and open
	questions go in the body (**State**, **Outcome**, **Open questions**). Why: line 1 is what every listing shows,
	and anything more piles up there and goes stale.
- Line 2 is always present, empty or not (`Labels:`), so every task reads the same way.
- `active`: being worked on (for a wayfinder ticket: claimed). `paused`: stopped on purpose. `blocked`: waiting on
	something outside the tree; waiting on another task is `depends on`.
- A dependency is met when that task is `done`; a task with subtasks counts as one, done when it is. A task's
	dependencies hold back all its subtasks. Dependencies point outside the task's own ancestors, which finish only
	after it.
- A task with subtasks is `active` while any of them is, and `done` once all of them are `done` or `dropped`. Its
	status changes only when its own state does.
- Labels are added only when the user asks for them or a skill's workflow sets them (wayfinder, triage): a new task
	otherwise has an empty `Labels:` line. Why: unrequested labels are noise nobody filters on.
- Labels are free, comma separated, each task's own (subtasks do not inherit them). Reserved: the `wayfinder:` types
	([tracker.md](tracker.md)) and the triage roles (`needs-triage`, `needs-info`, `ready-for-agent`,
	`ready-for-human`, `wontfix`, or the project's names for them in `docs/agents/triage-labels.md`).

## The script

`scripts/tasks.sh` in this skill's folder, run from the project root:

- `tree [id]`: the tree, or a subtree, with each task's status line and labels.
- `frontier [id]`: the tasks that can start now: `todo`, dependencies met, no subtasks, under ancestors that are
	`todo` or `active` with their own dependencies met. In ID order.
- `label <label>`: the tasks carrying a label.
- `refs <id>`: the tasks depending on a task (or on its subtasks), then the files mentioning its ID.
- `check`: header format, statuses, dependencies, folders, parents and subtasks. Every change to the tree ends with
	`check` passing.

## New tasks

A new task starts as a copy of a template in this skill's `templates/`: `simple.md` for a task, `parent.md` for the
`TASK.md` of a task with subtasks, `map.md` and `ticket.md` for wayfinder ([tracker.md](tracker.md)). A `TASK.md`'s
**State** holds only what spans its subtasks.

New work found on the way becomes a new task in the folder it belongs to.

## Sessions

- **Start**: `tasks.sh tree`, then the `TASK.md` of each ancestor of the task, top down, then the task. The task is
	the one the user names, else the `active` one, else the first of `tasks.sh frontier`.
- **Pivot**: one line under **Pivots** in the `TASK.md` it concerns (date, what changed, why). A pivot that changes
	the design edits `DESIGN.md` too.
- **End**: the task's **State** replaced with where it stands, its status line current, `tasks.sh check` passing.
- **Done**: **Outcome** filled (what was built, which files, what was learned that affects other tasks), then the
	status line `done; <one-line outcome>`.

## Deleting tasks

A task is deleted once it is `done` or `dropped` and its definition serves nothing still open:

1. Move what still matters to where it lives on: a decision to the `DESIGN.md` above it, a fact a later task needs
	into that task, a lesson about the project to the project's docs or `CLAUDE.md`.
2. Take it out of the `depends on` of the tasks `tasks.sh refs <id>` lists (a met dependency is no dependency), and
	turn links to it into plain text.
3. Delete it, a task with subtasks whole, with its ID in the commit message so `git log -- <root>/<id>*` finds it.
	Done when `tasks.sh refs <id>` lists no dependents and `tasks.sh check` passes.

Dropping a task: `dropped; <why>`, and one line in the parent's **Pivots** so the reason outlives the file; then it
can be deleted at once. Wayfinder tickets follow [tracker.md](tracker.md).

## Subagents

A well-defined task (concrete **Done when**, its decisions settled in the task file or `DESIGN.md`) may run in a
subagent, the main session orchestrating: before proposing it, read [subagents.md](subagents.md).
