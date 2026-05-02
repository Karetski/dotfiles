@RTK.md

## Git worktrees

Never use git worktrees unless I explicitly ask for them. This includes:

- Do not pass `isolation: "worktree"` to the Agent tool.
- Do not invoke the `superpowers:using-git-worktrees` skill on your own.
- Do not run `git worktree add` / related commands.

If a workflow or skill suggests a worktree, default to working in the current checkout instead. Only create a worktree when I explicitly say so (e.g. "use a worktree", "in a worktree", "isolate this in a worktree").

## Asking questions

When you need to ask me something — clarification, confirmation, picking between options — always use the interactive `AskUserQuestion` tool. Do not phrase questions as plain text in your reply and wait for me to type an answer in the next turn.

This applies to every kind of question: clarifying ambiguous requirements, choosing between approaches, confirming a risky action, asking which file/branch/option to use, etc. If you have a yes/no or multiple-choice question, build it as an `AskUserQuestion` call with explicit options. If it's open-ended, still use `AskUserQuestion` with a free-form prompt rather than embedding the question in prose.

Exception: rhetorical or summary phrasing at the end of a reply ("let me know if you want X next") is fine — that's not a question I need to answer to unblock you.

