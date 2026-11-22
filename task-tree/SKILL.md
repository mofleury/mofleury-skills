---
name: task-tree
description: Plan and track work as a tree of markdown task files in the project (`docs/tasks/` by default), any depth, one file per task, with status, dependencies and labels in the first two lines. It is also the project's issue tracker for wayfinder, to-tickets, to-spec and triage. Use when starting a session on planned work, when creating, updating, moving or deleting tasks, and when a skill asks for the issue tracker.
---

# Task tree

Work too big for one session is planned in the project as a tree of tasks, one markdown file per task. A simple
task is one file; a task with subtasks is a folder. The files are the whole tracker: there is no index, list or
board anywhere else.

The root is `docs/tasks/` unless the project's `CLAUDE.md` names another one (then set `TASKS_ROOT` for the script).

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
	are documents of the task whose folder holds them.
- A folder is a task when it has a `TASK.md`. Every folder holding tasks has one (the root excepted).
- A simple task that grows subtasks becomes a folder: `git mv x.md x/TASK.md`. Its ID does not change.

## IDs

A task's ID is its path from the root, without `.md` or `/TASK.md`: `bead_patterns/generator/sequences`,
`bead_patterns/generator`. The same ID whether the task is a file or a folder.

- Names are lowercase, words joined with `_`, no spaces. Name a task for what it is about, not for its order.
- Dependencies and links use full IDs, never paths relative to the file.
- Moving or renaming a task changes its ID: update the tasks that name it (`tasks.sh refs <id>` lists them).

## The header: two lines

```
Status: <todo | active | paused | blocked | done | dropped>; depends on: <id, id | none>[; <note>]
Labels: <label, label, ...>
```

- Line 1 is the task's whole current status, **replaced** each time it changes, never appended to. The note is
	required for `blocked` and `dropped` (why) and `done` (a one-line outcome); otherwise there is none. No progress,
	results or open questions there: those go in the body (**State**, **Outcome**, **Open questions**). Why: line 1
	is what every listing shows; details there pile up and go stale.
- Line 2 is always present, empty or not (`Labels:`), so every task reads the same way.
- `active`: being worked on (for a wayfinder ticket: claimed). `paused`: stopped on purpose, mostly for tasks with
	subtasks. `blocked`: waiting on something outside the tree; a dependency on another task is not a block, it is
	`depends on`.
- A dependency is done when that task is `done`. Depending on a task with subtasks means depending on all of it.
	A task's dependencies hold back all its subtasks too. Never depend on your own ancestor: it cannot be done
	before you.
- A task with subtasks is `active` while any of them is, and `done` only when all of them are `done` or `dropped`.
	Its status changes only when its state does: subtasks moving along do not touch it.
- Labels are free, comma separated, and not inherited. Reserved ones: `wayfinder:map`, `wayfinder:research`,
	`wayfinder:prototype`, `wayfinder:grilling`, `wayfinder:task`, and the triage roles (`needs-triage`,
	`needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`, or the project's names for them in
	`docs/agents/triage-labels.md`).

## Listing and checking

`scripts/tasks.sh` in this skill's folder, run from the project root:

- `bash <skill>/scripts/tasks.sh` or `... tree [id]`: the tree (or a subtree) with each task's status line and labels.
- `... frontier [id]`: the tasks that can start now: `todo`, every dependency done, no subtask of their own, under
	ancestors that are `todo` or `active` with their own dependencies done. Listed in ID order.
- `... label <label>`: the tasks carrying a label.
- `... refs <id>`: the tasks that depend on the task (or on its subtasks), then the files that mention its ID.
- `... check`: header format, unknown statuses, missing dependencies or cycles, folders without `TASK.md`, tasks done
	before their subtasks. Run it after reorganizing the tree.

## Task bodies

A simple task:

```markdown
Status: todo; depends on: none
Labels:

# Title

**Goal:** one or two lines.

## Done when
- concrete, checkable conditions

## Approach
design notes specific to this task

## State
where it stands now (replaced each session)

## Open questions
-

## Outcome
(filled when done)
```

A task with subtasks (`TASK.md`):

```markdown
Status: active; depends on: none
Labels:

# Title

Conventions for this tree: the task-tree skill.

**Goal:** what reaching the end looks like.

## Scope
- In:
- Not now:

## Pivots
- YYYY-MM-DD: what changed, why.

## State
only what spans the subtasks (each subtask has its own); often empty

## Outcome
(filled when done)
```

There is no list of subtasks in `TASK.md`: the folder is the list (`tasks.sh tree <id>`).

A wayfinder map and its tickets: see [tracker.md](tracker.md).

## Sessions

- Start a session with `tasks.sh tree`, then read the `TASK.md` of each ancestor of the task you will work on, top
	down, then the task. Work on the active task, else the first task of `tasks.sh frontier`, unless the user names one.
- At the end of a session, replace (do not append to) the task's **State** and update its status line.
- When a task is done, fill its **Outcome**: what was built, which files, what was learned that affects other tasks.
	Then set its status line to `done; <one-line outcome>`.
- A pivot is one line under **Pivots** in the `TASK.md` it concerns (date, what changed, why). If it changes the
	design, edit `DESIGN.md` too.
- New work found on the way is a new task in the folder it belongs to, not a paragraph in the current one.

## Deleting tasks

The tree holds the work still open and what that work needs, nothing else. Git history keeps the rest.

- Delete a task once it is `done` or `dropped` and nothing still needs its definition. Before deleting:
	- `tasks.sh refs <id>`: remove it from the `depends on` of the tasks that name it (a finished dependency is no
		dependency), and turn links to it into plain text.
	- Move what still matters to where it lives on: a decision to the `DESIGN.md` above it, a fact that a later task
		needs into that task, a lesson about working on the project to the project's docs or `CLAUDE.md`.
	- Delete it in a commit of its own, or name its ID in the commit message, so `git log -- docs/tasks/<id>*` finds it.
- Dropping: set `dropped; <why>` and add a line to the parent's **Pivots** (or a wayfinder map's **Out of scope**),
	so the reason outlives the file. Then it can be deleted at once.
- A task with subtasks is deleted whole, once it is done.

## Running tasks in subagents

When a task is well defined (concrete **Done when**, its decisions settled in the task file or `DESIGN.md`), the
session may propose running it in a subagent, the main session orchestrating. Why: the subagent's exploration,
runs and logs stay out of the main session's context, which then stays fresh across many tasks.
- One task per subagent, one at a time when they touch the same files. Before delegating, write the user's
	decisions into the task file: the subagent only knows what the files and its brief say.
- The subagent deletes only files it created itself, by their exact paths as it noted them when they were written,
	never by a pattern (a timestamp, a glob): the developer may be running the app meanwhile, and its output can land
	in the same folders (godot-platformer, 2026-11-20: three of the developer's live traces were deleted along with a
	subagent's own).
- The subagent does not commit: it reports its changes to the orchestrator. It stops and reports early when the task
	needs a decision that is the user's (a plan or design change, code changes beyond what the task allows).
- After each task the orchestrator reviews the changes (closely those outside the task's usual scope), reruns the
	tests itself, adjusts what needs it, and reports to the user before committing or starting the next task.

### Lower-tier models (e.g. Sonnet)
The orchestrator may run a subagent on a lower-tier model to save cost. What worked and what did not
(godot-platformer, 2026-11-21: three pieces on Sonnet, reviewed by the orchestrator):
- Give it closed pieces: a decided fix, a recheck with fixed outcomes ("if it fails, fix and add a test; if not,
	a pin"), a measurement with a stated use. Keep open design work, open-ended diagnosis and judging measurements
	against design rules for the orchestrator, or for a stronger model.
- Make "report before doing anything other than the decided approach" a hard stop, not a judgment call. "Stop if
	the scope grows" was not enough: when the decided rule proved wrong, the subagent built a larger model in its
	place (about 280 lines) and reported only once done; the developer then dropped it. Why: a lower-tier model
	treats a stop condition it has to judge as permission to go on.
- Write into the brief what the files do not say yet: this session's practical lessons (paths a tool cannot read,
	commands, timeouts), the files it must not touch, and the evidence it must bring back (numbers before and after,
	a failure shown with the fix reverted). A lead from the orchestrator goes in marked unchecked.
- Review its claims, not just its diff. Rerun the tests; revert the fix and watch the regression check fail; check
	physical or geometric claims against the source; check its cleanup (the files it created gone, no one else's
	touched).
