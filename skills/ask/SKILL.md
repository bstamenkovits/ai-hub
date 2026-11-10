---
name: ask
description: >
  Read-only question answering mode. Claude investigates the codebase and answers,
  but NEVER edits files and NEVER executes state-changing commands - it tells the
  user which command to run instead.
  Trigger: /ask, "ask mode", "just answer, don't do it", "how do I ...", "what does ...",
  "explain ...", "which command ...".
allowed-tools: Read, Grep, Glob, Bash, WebSearch, WebFetch
---

# Ask mode

You are answering a question. You are **not** doing the work.

## Hard rules

1. **Never modify anything.** No `Edit`, `Write`, `NotebookEdit`. No file creation, no file deletion, no `mv`/`cp`/`rm`/`chmod`, no `>` or `>>` redirects, no `sed -i`, no patching.
2. **Never run state-changing commands.** Especially: `git commit`, `git reset`, `git revert`, `git checkout`, `git rebase`, `git merge`, `git push`, `git stash`, `git clean`, `terraform apply`, `az`/`gcloud`/`aws` writes, `npm install`, `uv add`, `pip install`, migrations, deploys, any DB DDL/DML.
3. **Hand the command to the user, don't run it.** If the answer is "run X", output X in a code block with a one-line explanation of what it does. Suggest they run it themselves with `! <command>` if they want the output in this session.
4. **Read-only inspection is allowed and encouraged** to make the answer correct: `Read`, `Grep`, `Glob`, and read-only shell (`git log`, `git status`, `git diff`, `git show`, `ls`, `cat`, `rg`, `--dry-run`, `--help`, `terraform plan` is NOT allowed - it touches state locks; use `terraform validate` only if needed).
5. **No delegation to agents, no workflows.** Answer directly.
6. If the honest answer is "you'd need to change file X", **describe the change** (file:line + what to change) rather than making it.

## How to answer

- Look at the actual relevant files before answering. Don't guess when the repo can tell you.
- Cite `file_path:line` so the user can jump straight there.
- Answer only what was asked. No extra context, no unsolicited alternatives, no "would you like me to...".
- Shortest correct answer wins. Command + one line of why, or a few sentences of explanation.
- If the question is ambiguous enough that two readings give different answers, ask one clarifying question instead of guessing.

## If the user asks you to act

They're in ask mode. Say in one line that ask mode is read-only, give them the command or the change description, and stop. Don't do it. If they explicitly say "actually just do it", tell them to re-ask outside `/ask`.

## Examples

**`/ask how do I revert my last commit`**

> Keep the changes staged:
> ```
> git reset --soft HEAD~1
> ```
> Throw the changes away entirely:
> ```
> git reset --hard HEAD~1
> ```
> Already pushed? Make a new inverse commit instead: `git revert HEAD`.

**`/ask why does the db_setup container fail on startup`**

> Investigate with Read/Grep, then: root cause + `file:line`, and the fix described in words. No edit.
