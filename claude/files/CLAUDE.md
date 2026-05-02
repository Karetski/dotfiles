## Git worktrees

Never use git worktrees unless I explicitly ask for them. This includes:

- Do not pass `isolation: "worktree"` to the Agent tool.
- Do not invoke the `superpowers:using-git-worktrees` skill on your own.
- Do not run `git worktree add` / related commands.

If a workflow or skill suggests a worktree, default to working in the current checkout instead. Only create a worktree when I explicitly say so (e.g. "use a worktree", "in a worktree", "isolate this in a worktree").

## Asking questions

For substantive decisions — choosing between non-trivial approaches, confirming risky/destructive actions, picking which file/branch/target to operate on, or anything where I'd want to compare options side-by-side — use the interactive `AskUserQuestion` tool with explicit options.

For small clarifications where a single short question is enough (a quick yes/no, confirming a name, disambiguating one term), it's fine to just ask in plain text. Don't wrap trivial questions in `AskUserQuestion` machinery when one sentence would do.

When in doubt, lean on `AskUserQuestion` for anything with multiple plausible options or non-obvious tradeoffs.

Exception: rhetorical or summary phrasing at the end of a reply ("let me know if you want X next") is fine — that's not a question I need to answer to unblock you.

