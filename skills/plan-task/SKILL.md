---
name: plan-task
description: Plan the implementation of a task from the user's own description. Use when the user runs /plan-task followed by a task description, or asks to "plan this task", "plan how to build", "make a plan for" something that is not a Jira ticket.
argument-hint: <description of the task>
allowed-tools: Skill, Agent, Read, Grep, Glob, Write
---

# Plan a task from a description

Runs from the root of the repo the task will be built in. Takes the task description the user
gives, tears it apart looking for gaps, interviews the user until nothing is ambiguous, then
produces an implementation plan, has a fresh `plan-reviewer` agent review it, and revises the
plan based on the review before showing it. The only files it writes are the plan and its
review report: no code edits.

## THE RULE THAT OVERRIDES EVERYTHING

**Never assume anything.** Every fact in the plan comes from the task description, the repo,
or an explicit answer from the user. If there is even a hint of ambiguity, ask. A plan with an
open question is fine; a plan built on a guess is not.

Also: never edit code. This skill only plans. The plan file and the review report are the
only things it writes.

## Step 1: read the task

Everything after `/plan-task` is the task description.

- **Nothing**: ask the user to describe the task.
- **A reference to something external** (a ticket, a doc, a PR, a URL): fetch it only if a
  tool for it is available, otherwise ask the user to paste the relevant content. For a Jira
  ticket, point the user to `/jira-plan` instead.

## Step 2: confirm the task, always

Summarize back in a few lines: what needs to be built, for whom, and why. If the description
does not say who or why, say so plainly instead of filling it in. Propose a short kebab-case
slug for the plan file name, derived from the task:

```
Task: Add CSV export to the project search results
      For: <who, or "not stated">
      Why: <why, or "not stated">
Plan file: plan-csv-export-project-search.md

That right?
```

Stop and wait for a yes. The user may correct the summary or the slug.

## Step 3: investigate the repo

Facts are your job, not the user's. Before asking the user anything, find out what the repo
can tell you. Spawn the `repo-investigator` agent with a well-structured question built from
the task: which modules, models, endpoints, tables, and patterns the task touches, how
similar features are implemented, what tests exist for that area.

Never ask the user something the repo can answer.

## Step 4: the critical review

Take a super critical look at the task description plus the investigation results. For every
part of the task ask: do I know enough to implement this without guessing? Hunt for:

- vague wording ("should handle", "improve", "etc.", "and so on", "where relevant")
- missing acceptance criteria: how will we know it is done?
- undefined behavior: edge cases, empty states, errors, permissions, invalid input
- unclear data: shapes, sources, volumes, migrations, backwards compatibility
- unclear scope: what is explicitly out, what neighboring behavior must stay unchanged
- UI/UX details: where, what it looks like, what text, which states
- non-functional needs: performance, logging, monitoring, feature flags, rollout
- conflicts between the description and what the code actually does
- dependencies on other work, teams, or services

Write the result down as a list of open questions. Do not show it to the user as a wall; it
feeds the next step.

## Step 5: grill the user, one question at a time

Invoke the `grilling` skill to interview the user over the open questions, with one override:
**ask exactly one question per message**, not a whole round. Do not overwhelm the user.

Per question:
- Keep it short and specific. Offer concrete options when they exist.
- Give your recommended answer, but only when it is grounded in the description or the repo.
  If you have no grounded recommendation, say so instead of inventing one.
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

## Step 6: write the plan

Save the plan to `plan-<slug>.md` in the repo root, the directory the skill was invoked from,
using the slug confirmed in Step 2. If that file already exists, show the user and ask before
overwriting. Do not show the plan to the user yet; it goes to review first. Structure:

```
# Plan: <task title>

## Goal
<one or two lines>

## Acceptance criteria
<how we know it is done; each one verifiable>

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

## Step 7: review the plan

Spawn a fresh `plan-reviewer` agent. Fresh means a new agent, never a continued one, so it has
none of this conversation's assumptions. Give it only:

- the path to `plan-<slug>.md`, and an instruction to read it
- the task description as the user gave it, plus the confirmed summary from Step 2, so it can
  check requirements coverage
- the repo root to verify the plan against

Do not pass your reasoning, the grilling, or your opinion of the plan. The plan must stand on
its own.

Save the report it returns, verbatim, to `plan-<slug>-review.md` next to the plan (overwrite a
previous one without asking; it belongs to this run).

## Step 8: revise the plan from the review

Go over the report issue by issue, in its **Hand-off Instructions** order. For each issue,
verify it against the repo before acting on it: the reviewer can be wrong too. Then:

- **HIGH**: fix it. If the fix needs a decision the description, repo, or grilling did not
  settle, ask the user (one question per message, same rules as Step 5). Never resolve it by
  guessing.
- **MID**: fix it, unless it is wrong or conflicts with a decision the user made. Then skip it
  and record why.
- **LOW**: apply if it is cheap and clearly better; otherwise skip.
- **Unverified Assumptions**: check each against the repo. Unresolvable ones go under
  **Open questions** in the plan.

A fix must never override a decision the user confirmed in Step 5. If the reviewer disagrees
with one, show the user both sides and let them decide.

Write the revised plan back to `plan-<slug>.md`. Then present it in chat:

```
Plan: plan-<slug>.md
Review: plan-<slug>-review.md (<verdict>, <n> HIGH, <n> MID, <n> LOW)

Applied: H1, M1, M3, L2
Skipped: M2 (<reason>), L1 (<reason>)
Asked you: H2

<short plan summary>
```

If the verdict was REVISE or REJECT, ask the user whether to run another review round on the
revised plan. Each round repeats Steps 7 and 8 with a new fresh agent.

Iterate on the plan as long as the user wants. Every revision is written back to the same
`plan-<slug>.md`.

## Arguments

- `/plan-task <description>`: plan that task
- `/plan-task`: ask for the task description

## Writing Guidelines
* Keep your answers short, concise, to the point, and clear
* Do not use unnecessary fluff text, only what is truly needed
* Do not be vague, be specific and explicit, but NOT wordy
* American English. No em-dashes.
