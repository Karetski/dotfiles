@RTK.md

## Git worktrees

Never use git worktrees unless I explicitly ask for them. This includes:

- Do not pass `isolation: "worktree"` to the Agent tool.
- Do not invoke the `superpowers:using-git-worktrees` skill on your own.
- Do not run `git worktree add` / related commands.

If a workflow or skill suggests a worktree, default to working in the current checkout instead. Only create a worktree when I explicitly say so (e.g. "use a worktree", "in a worktree", "isolate this in a worktree").
