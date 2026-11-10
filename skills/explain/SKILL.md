---
name: explain
description: >
  Explain an error or a code snippet, briefly. Given error logs / a stack trace,
  investigate the codebase, find the root cause, explain it in 1-2 sentences and
  outline the fix - without changing anything. Given a code snippet, explain in
  as few words as possible what it does and where it fits in the app's flow.
  Read-only unless the user explicitly approves a specific fix.
  Trigger: /explain.
---

# Explain mode

The user wants a quick answer, not a lecture. They often just need a reminder or a high-level picture. If they want more, they'll ask.

First decide what you were given: **error logs** (stack trace, exception, failing test output, log lines) or a **code snippet**. If it's genuinely unclear, ask in one line.

## Error logs

1. Investigate: read the trace, open the referenced files, follow the call path until you find the actual root cause (not just the line that threw).
2. Do NOT edit anything. No file changes, no state-changing commands. Read-only investigation only.
3. Answer in this shape:

```
**Cause:** <1-2 sentences. Point at file:line.>

**Fix:** <1-3 short bullets or a sentence. What to change, not a full diff.>

Want me to implement this fix?
```

### Implementing the fix

- Only implement when the user explicitly says yes to **this specific fix** in their latest message.
- That approval covers only that one fix. It is never standing permission. Every new error, every follow-up fix, every "also change X" needs its own fresh offer and its own fresh yes, even if the user has said yes ten times already this session.
- Never infer approval from tone, "ok", "makes sense", "thanks", or the user just asking another question. When in doubt, ask.
- If the fix touches anything outside the narrow change you outlined (dependencies, migrations, config, other files), stop and ask again first.

## Code snippet

1. Look up the snippet in the codebase if it lives there (grep for it) so you can see callers and context.
2. Answer in as few words as possible:
   - **What it does:** 1-2 sentences.
   - **Where it fits** (only if it's part of a larger flow): one line on who calls it / what it feeds into, with file:line refs.
   - **Why it's needed:** one line, only if not obvious.
3. No line-by-line walkthroughs, no background on the language or library, no suggestions for improvement unless asked.

## Hard rules

- Short. Target under ~6 lines total. Cut anything the user didn't ask for.
- No preamble ("Let me look into this"), no postamble ("Hope this helps").
- Never change files or run state-changing commands without an explicit yes for that exact change.
