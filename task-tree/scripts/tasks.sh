#!/usr/bin/env bash
# List and check a task tree (conventions: ../SKILL.md). Run from the project root.
#   tasks.sh [tree [id]]     the tree, each task with its status line and labels
#   tasks.sh frontier [id]   tasks that can start now
#   tasks.sh label <label>   tasks carrying a label
#   tasks.sh refs <id>       tasks depending on <id> (or its subtasks), then files mentioning it
#   tasks.sh check           format and consistency errors (exit code 1 if any)
# The root is $TASKS_ROOT, else docs/tasks.
set -euo pipefail

root="${TASKS_ROOT:-docs/tasks}"
root="${root%/}"
cmd="${1:-tree}"
arg="${2:-}"
arg="${arg%/}"

case "$cmd" in
	tree|frontier|check) ;;
	label|refs) [ -n "$arg" ] || { echo "usage: tasks.sh $cmd <arg>" >&2; exit 2; } ;;
	*) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 2 ;;
esac
[ -d "$root" ] || { echo "no task root: $root (run from the project root, or set TASKS_ROOT)" >&2; exit 2; }

tab=$'\t'

# Stage 1: one record per task file: sort key, id, kind, status, deps, labels, note, file, error.
records() {
	find "$root" -type f -name '*.md' | awk -v root="$root" '
		function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
		{
			f = $0; rel = substr(f, length(root) + 2)
			l1 = ""; l2 = ""; n = 0
			while (n < 2 && (getline line < f) > 0) {
				sub(/\r$/, "", line); n++
				if (n == 1) l1 = line; else l2 = line
			}
			close(f)
			base = rel; sub(/.*\//, "", base)
			err = ""
			if (l1 !~ /^Status:/) {
				if (base != "TASK.md") next
				err = "TASK.md without a Status line"
			}
			if (base == "TASK.md") {
				if (rel == "TASK.md") { print "\001\t(root)\tdir\t\t\t\t\t" f "\tthe root is not a task: no TASK.md there"; next }
				id = rel; sub(/\/TASK\.md$/, "", id); kind = "dir"
			} else {
				id = rel; sub(/\.md$/, "", id); kind = "leaf"
			}
			s = l1; sub(/^Status:[ \t]*/, "", s); gsub(/\t/, " ", s)
			m = split(s, parts, ";")
			status = trim(parts[1]); deps = ""; note = ""
			for (i = 2; i <= m; i++) {
				p = trim(parts[i])
				if (p ~ /^depends on:/) {
					sub(/^depends on:[ \t]*/, "", p); gsub(/[ \t]/, "", p)
					if (p != "none") deps = p
				} else note = (note == "" ? p : note "; " p)
			}
			labels = ""
			if (l2 ~ /^Labels:/) { labels = l2; sub(/^Labels:[ \t]*/, "", labels); gsub(/[ \t]/, "", labels) }
			else if (err == "") err = "line 2 is not a Labels: line"
			key = id; gsub(/\//, "\001", key)
			print key "\t" id "\t" kind "\t" status "\t" deps "\t" labels "\t" note "\t" f "\t" err
		}' | LC_ALL=C sort -t "$tab" -k1,1
}

records | awk -F '\t' -v cmd="$cmd" -v arg="$arg" '
	function parent(x) { if (index(x, "/") == 0) return ""; sub(/\/[^\/]*$/, "", x); return x }
	function under(x, top) { return top == "" || x == top || index(x, top "/") == 1 }
	function depsdone(i,   ds, k, m) {
		m = split(deps[i], ds, ",")
		for (k = 1; k <= m; k++) if (!(ds[k] in ix) || status[ix[ds[k]]] != "done") return 0
		return 1
	}
	function ancestorsopen(i,   p, j) {
		for (p = parent(id[i]); p != ""; p = parent(p)) {
			if (!(p in ix)) continue
			j = ix[p]
			if ((status[j] != "todo" && status[j] != "active") || !depsdone(j)) return 0
		}
		return 1
	}
	function line(i) {
		return "[" status[i] "]" (deps[i] != "" ? " after: " deps[i] : "") (note[i] != "" ? "; " note[i] : "") \
			(labels[i] != "" ? "  {" labels[i] "}" : "")
	}
	function fail(msg) { print "error: " msg; errors++ }
	function visit(i,   ds, k, m, j) {
		color[i] = 1
		m = split(deps[i], ds, ",")
		for (k = 1; k <= m; k++) {
			if (!(ds[k] in ix) || ds[k] == id[i]) continue
			j = ix[ds[k]]
			if (color[j] == 1) fail("dependency cycle through " id[i] " -> " ds[k])
			else if (color[j] == 0) visit(j)
		}
		color[i] = 2
	}
	{
		n++; id[n] = $2; kind[n] = $3; status[n] = $4; deps[n] = $5; labels[n] = $6; note[n] = $7; file[n] = $8; err[n] = $9
		if ($2 in ix) dup[n] = 1; else ix[$2] = n
		p = parent($2); if (p != "") haschild[p] = 1
	}
	END {
		if (cmd == "tree") {
			if (arg != "" && !(arg in ix)) { print "no task " arg > "/dev/stderr"; exit 2 }
			base = (arg == "" ? 0 : gsub(/\//, "/", arg) + 0)
			for (i = 1; i <= n; i++) {
				if (!under(id[i], arg) || id[i] == "(root)") continue
				x = id[i]; depth = gsub(/\//, "/", x) - base
				name = id[i]; sub(/.*\//, "", name)
				indent = ""; for (k = 0; k < depth; k++) indent = indent "  "
				print indent name (kind[i] == "dir" ? "/" : "") "  " line(i)
			}
		} else if (cmd == "frontier") {
			for (i = 1; i <= n; i++)
				if (under(id[i], arg) && status[i] == "todo" && !haschild[id[i]] && depsdone(i) && ancestorsopen(i))
					print id[i] (labels[i] != "" ? "  {" labels[i] "}" : "")
		} else if (cmd == "label") {
			for (i = 1; i <= n; i++)
				if (index("," labels[i] ",", "," arg ",")) print id[i] "  [" status[i] "]"
		} else if (cmd == "refs") {
			for (i = 1; i <= n; i++) {
				m = split(deps[i], ds, ",")
				for (k = 1; k <= m; k++) if (under(ds[k], arg)) { print id[i] " depends on " ds[k]; }
			}
		} else if (cmd == "check") {
			ok = ",todo,active,paused,blocked,done,dropped,"
			for (i = 1; i <= n; i++) {
				where = id[i] " (" file[i] ")"
				if (err[i] != "") { fail(where ": " err[i]); continue }
				if (dup[i]) fail(id[i] ": both " id[i] ".md and " id[i] "/TASK.md")
				if (!index(ok, "," status[i] ",")) fail(where ": unknown status \"" status[i] "\"")
				if ((status[i] == "blocked" || status[i] == "dropped" || status[i] == "done") && note[i] == "")
					fail(where ": " status[i] " needs a note (why, or the one-line outcome)")
				if (id[i] !~ /^[a-z0-9_\/-]+$/) fail(where ": name not lowercase with _ (no spaces)")
				p = parent(id[i])
				if (p != "" && !(p in ix) && !reported[p]++) fail("folder " p " holds tasks but has no TASK.md")
				m = split(deps[i], ds, ",")
				for (k = 1; k <= m; k++) {
					if (!(ds[k] in ix)) fail(id[i] ": depends on " ds[k] ", which does not exist")
					else if (ds[k] == id[i]) fail(id[i] ": depends on itself")
					else if (index(id[i], ds[k] "/") == 1) fail(id[i] ": depends on its ancestor " ds[k])
				}
				if (p in ix && status[i] != "done" && status[i] != "dropped" && status[ix[p]] == "done")
					fail(p " is done but its subtask " id[i] " is " status[i])
			}
			for (i = 1; i <= n; i++) if (!color[i]) visit(i)
			if (errors) exit 1
			print "ok: " (n + 0) " tasks"
		}
	}'

if [ "$cmd" = refs ]; then
	echo "mentions:"
	grep -rlF -- "$arg" "$root" || true
fi
