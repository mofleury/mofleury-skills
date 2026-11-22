# Running tasks in subagents

The main session orchestrates; each subagent runs one task. Why: the subagent's exploration, runs and logs stay out
of the main session's context, which then stays fresh across many tasks.

- One task per subagent, one at a time when they touch the same files. Before delegating, write the user's
	decisions into the task file: the subagent only knows what the files and its brief say.
- The subagent deletes only files it created itself, by their exact paths as it noted them when they were written,
	never by a pattern (a timestamp, a glob): the developer may be running the app meanwhile, and its output can land
	in the same folders (godot-platformer, 2026-11-20: three of the developer's live traces were deleted along with a
	subagent's own).
- The subagent leaves its changes uncommitted and reports them to the orchestrator. It stops and reports early when
	the task needs a decision that is the user's (a plan or design change, code changes beyond what the task allows).
- After each task the orchestrator reviews the changes (closely those outside the task's usual scope), reruns the
	tests itself, adjusts what needs it, and reports to the user before committing or starting the next task.

## Lower-tier models (e.g. Sonnet)

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
