---
name: jira-plan
description: Plan the implementation of a feature from a Jira ticket. Use when the user runs /jira-plan with a Jira link or issue key, or asks to "plan this ticket", "plan the implementation of", "how should we build" a Jira issue.
allowed-tools: mcp__claude_ai_Atlassian__getJiraIssue, mcp__claude_ai_Atlassian__searchJiraIssuesUsingJql, mcp__claude_ai_Atlassian__atlassianUserInfo, mcp__claude_ai_Atlassian__getAccessibleAtlassianResources, ToolSearch, Skill, Agent, Read, Grep, Glob, Write
---

# Plan a feature from a Jira ticket

Runs from the root of the repo the feature will be built in. Reads the ticket, tears it apart
looking for gaps, interviews the user until nothing is ambiguous, then produces an
implementation plan, has a fresh `plan-reviewer` agent review it, and revises the plan based on
the review. The only files it writes are the plan and its review report: no code edits, no Jira
writes.

## Site constants (marktlink.atlassian.net)

| Thing | Value |
|---|---|
| `cloudId` | `666244fe-2f5f-4947-b803-51f2888ba3ba` |
| Browse URL | `https://marktlink.atlassian.net/browse/<KEY>` |

If `cloudId` fails, re-resolve it with `getAccessibleAtlassianResources`.

## THE RULE THAT OVERRIDES EVERYTHING

**Never assume anything.** Every fact in the plan comes from the ticket, the repo, or an
explicit answer from the user. If there is even a hint of ambiguity, ask. A plan with an open
question is fine; a plan built on a guess is not.

Also: never write to Jira and never edit code. This skill only plans. The plan file and the
review report are the only things it writes.

## Step 1: identify the ticket

Parse what came after `/jira-plan`:

- **A Jira link**: extract the key from `/browse/<KEY>` or from a `selectedIssue=<KEY>` query
  parameter.
- **An issue key** (`MLNEX-706`, anything matching `[A-Z][A-Z0-9]+-\d+`): use as is.
- **Only a number** (`706`): do not guess the project. Ask the user for the project key.
- **Nothing**: ask the user for the key or link.

Fetch it:

```
tool: getJiraIssue
cloudId: 666244fe-2f5f-4947-b803-51f2888ba3ba
issueIdOrKey: MLNEX-706
fields: ["summary","description","issuetype","status","parent","labels","components","comment","issuelinks","subtasks","attachment"]
```

If the ticket has a parent epic or linked issues that are clearly relevant, fetch those too
for context.

## Step 2: confirm the ticket, always

```
Found: MLNEX-706: Show linked companies in results of project search
       Story · In Progress · epic MLNEX-172 (Annual reports V2)
       https://marktlink.atlassian.net/browse/MLNEX-706

That the one you want planned?
```

Stop and wait for a yes. Required even when an exact key was given: it may be a typo.

## Step 3: understand the ticket

Summarize back in a few lines: what needs to be built, for whom, and why. Include anything
relevant from comments, the epic, and linked issues. If the description is empty or a
one-liner, say so plainly.

## Step 4: investigate the repo

Facts are your job, not the user's. Before asking the user anything, find out what the repo
can tell you. Spawn the `repo-investigator` agent with a well-structured question built from
the ticket: which modules, models, endpoints, tables, and patterns the feature touches, how
similar features are implemented, what tests exist for that area.

Never ask the user something the repo can answer.

## Step 5: the critical review

Take a super critical look at the ticket plus the investigation results. For every part of
the feature ask: do I know enough to implement this without guessing? Hunt for:

- vague wording ("should handle", "improve", "etc.", "and so on", "where relevant")
- missing acceptance criteria, or criteria that cannot be verified
- undefined behavior: edge cases, empty states, errors, permissions, invalid input
- unclear data: shapes, sources, volumes, migrations, backwards compatibility
- unclear scope: what is explicitly out, what neighboring behavior must stay unchanged
- UI/UX details: where, what it looks like, what text, which states
- non-functional needs: performance, logging, monitoring, feature flags, rollout
- conflicts between the ticket, the comments, and what the code actually does
- dependencies on other tickets, teams, or services

Write the result down as a list of open questions. Do not show it to the user as a wall; it
feeds the next step.

## Step 6: grill the user, one question at a time

Invoke the `grilling` skill to interview the user over the open questions, with one override:
**ask exactly one question per message**, not a whole round. Do not overwhelm the user.

Per question:
- Keep it short and specific. Offer concrete options when they exist.
- Give your recommended answer, but only when it is grounded in the ticket or the repo. If
  you have no grounded recommendation, say so instead of inventing one.
- Wait for the answer before asking the next question.
- Each answer can open new questions or close others. Recompute the list after every answer.
  Ask the questions others depend on first.
- If an answer is itself vague ("whatever makes sense", "the usual way"), do not accept it.
  Show what the usual way is in the repo and ask the user to confirm it explicitly.
- If an answer needs a fact from the repo, look it up yourself (or via a subagent) before
  asking the follow-up.

Done when there are no open questions left. Then list every decision made, in short bullets,
and ask the user to confirm that this is a shared understanding. Do not proceed until they
confirm.

The user may stop the grilling early. In that case, every remaining open question goes into
the plan under **Open questions**, verbatim, never resolved by a guess.

## Step 7: write the plan

Save the plan to `plan-<KEY>.md` (e.g. `plan-MLNEX-706.md`) in the repo root, the directory
the skill was invoked from. If that file already exists, show the user and ask before
overwriting. Do not show the plan to the user yet; it goes to review first. Structure:

```
# Plan: <KEY>: <summary>

## Goal
<one or two lines>

## Decisions
<every decision from the grilling, one bullet each>

## Out of scope
<explicit exclusions>

## Implementation steps
1. <step> | files: `<path>` | verify: <how to check this step works>
2. ...

## Tests
<what to test, where the tests go, which existing test patterns to follow>

## Risks
<only real, grounded risks>

## Open questions
<anything unresolved; empty if the grilling finished>
```

Rules:
- Every file path, function, table, and endpoint in the plan exists in the repo or is
  explicitly marked as new.
- Steps are small and ordered so each one can be verified on its own.
- Follow the conventions the repo already uses. Do not introduce new patterns or
  dependencies unless the user agreed to it in the grilling.

## Step 8: review the plan

Spawn a fresh `plan-reviewer` agent. Fresh means a new agent, never a continued one, so it has
none of this conversation's assumptions. Give it only:

- the path to `plan-<KEY>.md`, and an instruction to read it
- the ticket key, summary, and description, so it can check requirements coverage
- the repo root to verify the plan against

Do not pass your reasoning, the grilling, or your opinion of the plan. The plan must stand on
its own.

Save the report it returns, verbatim, to `plan-<KEY>-review.md` next to the plan (overwrite a
previous one without asking; it belongs to this run).

## Step 9: revise the plan from the review

Go over the report issue by issue, in its **Hand-off Instructions** order. For each issue,
verify it against the repo before acting on it: the reviewer can be wrong too. Then:

- **HIGH**: fix it. If the fix needs a decision the ticket, repo, or grilling did not settle,
  ask the user (one question per message, same rules as Step 6). Never resolve it by guessing.
- **MID**: fix it, unless it is wrong or conflicts with a decision the user made. Then skip it
  and record why.
- **LOW**: apply if it is cheap and clearly better; otherwise skip.
- **Unverified Assumptions**: check each against the repo. Unresolvable ones go under
  **Open questions** in the plan.

A fix must never override a decision the user confirmed in Step 6. If the reviewer disagrees
with one, show the user both sides and let them decide.

Write the revised plan back to `plan-<KEY>.md`. Then post in chat:

```
Plan: plan-<KEY>.md
Review: plan-<KEY>-review.md (<verdict>, <n> HIGH, <n> MID, <n> LOW)

Applied: H1, M1, M3, L2
Skipped: M2 (<reason>), L1 (<reason>)
Asked you: H2

<short plan summary>
```

If the verdict was REVISE or REJECT, ask the user whether to run another review round on the
revised plan. Each round repeats Steps 8 and 9 with a new fresh agent.

Iterate on the plan as long as the user wants. Every revision is written back to the same
`plan-<KEY>.md`.

## Arguments

- `/jira-plan MLNEX-706`: plan that key
- `/jira-plan https://marktlink.atlassian.net/browse/MLNEX-706`: plan the linked ticket
- `/jira-plan`: ask for the key or link
- Anything else in the invocation is extra steering applied on top of the normal flow

## Writing Guidelines
* Keep your answers short, concise, to the point, and clear
* Do not use unnecessary fluff text, only what is truly needed
* Do not be vague, be specific and explicit, but NOT wordy
* American English. No em-dashes.
