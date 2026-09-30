Be concise and structured. No filler. Never add AI attribution (co-author trailers, "Generated with Claude", session links) anywhere.

## Git worktrees
Never create or use git worktrees (`git worktree`, Agent `isolation: "worktree"`, worktree skills) unless I explicitly ask. If a workflow suggests one, use the current checkout.

## Asking questions
When a decision has multiple plausible options I'd want a say in, ask — auto mode's "minimize interruptions" does not override this.
- Use `AskUserQuestion` for: 2+ approaches with different tradeoffs; destructive, irreversible, or shared actions; cases where the wrong pick wastes real work.
- A plain-text question is fine for a single yes/no.
- Don't ask about routine, reversible choices or anything I've already decided.
Test: if you picked the other option, would I want it redone? If yes, ask. A "let me know if…" at the end of a reply doesn't count as asking.
