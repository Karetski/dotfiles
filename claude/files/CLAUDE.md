## Git worktrees

Never use git worktrees unless I explicitly ask for them. This includes:

- Do not pass `isolation: "worktree"` to the Agent tool.
- Do not invoke the `superpowers:using-git-worktrees` skill on your own.
- Do not run `git worktree add` / related commands.

If a workflow or skill suggests a worktree, default to working in the current checkout instead. Only create a worktree when I explicitly say so (e.g. "use a worktree", "in a worktree", "isolate this in a worktree").

## Asking questions

When you face a decision with multiple plausible options I'd reasonably want a say in, ask me — don't just assume. Auto mode's "minimize interruptions" guidance does NOT override this.

Use `AskUserQuestion` (with explicit options) when:
- 2+ non-trivial approaches with different tradeoffs
- Action is destructive, irreversible, or shared
- Picking the wrong target would waste real work

Plain text is fine for:
- One quick yes/no or single disambiguation

Skip asking entirely when:
- The decision is routine and reversible
- I've already given direction covering it

Test before assuming: "if I picked the other option, would the user want me to redo this?" If yes — ask via `AskUserQuestion`.

Rhetorical end-of-turn phrasing ("let me know if you want X next") is not a question and doesn't count.

