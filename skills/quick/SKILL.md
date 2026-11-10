---
name: quick
description: >
  Answer a quick factual question in 1-2 lines. For the stuff the user would
  normally google but can't be bothered to open a browser for - syntax, flags,
  CLI commands, "what's the difference between X and Y". No codebase context,
  no file reads, no research.
  Trigger: /quick.
---

# Quick mode

Answer the question. Nothing else.

## Hard rules

1. **One or two lines.** That is the target, not the limit you creep up to.
2. **Five lines is the hard ceiling.** If the honest answer needs more, do NOT write it - ask one clarifying question to narrow it down, then answer.
3. **No tools.** No reading files, no grep, no bash, no web search, no agents. This is recall, not research. Answer from what you know.
4. **No context.** Ignore the repo, the git state, the conversation history. The question stands alone.
5. **No preamble, no postamble.** No "Great question", no "Here's how", no "Let me know if". Just the answer.
6. **No explanation unless asked.** A command is the answer. Why it works is a follow-up question the user can ask.
7. **Ambiguous with two short answers?** Give both, one line each. Ambiguous with two long answers? Ask which one.

## Out of scope

If the question needs the codebase, files, or multi-step work: one line telling them to use `/ask` instead. Don't start doing it.

> That needs repo context - use `/ask` for this one.

## Format

- Commands in backticks or a fenced block, whichever is shorter.
- No headings. No bullet lists longer than 3 items. No tables.
- If uncertain, say so in the same line - don't add a disclaimer paragraph.

## Examples

**`/quick how do I perform a git reset`**

> Keep changes: `git reset --soft HEAD~1`
> Nuke changes: `git reset --hard HEAD~1`

**`/quick difference between COPY and ADD in docker`**

> `COPY` just copies files. `ADD` also unpacks local tarballs and fetches URLs - which is why you should use `COPY`.

**`/quick python dict comprehension syntax`**

> `{k: v for k, v in items if cond}`

**`/quick how do I set up auth`**

> Too broad - auth for what? (API, OAuth provider, ssh, database?)

**`/quick why is my test failing`**

> That needs repo context - use `/ask` for this one.
