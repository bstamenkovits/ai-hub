---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. At the start of each round, fix the whole frontier as that round's questions. Then ask them **one at a time**: one question per message, with your recommended answer, and wait for the user's answer before asking the next question of the round. If an answer makes a remaining question in the round moot, drop it.

Number each question `Q<round>.<n>`: round 1 is Q1.1, Q1.2, ...; round 2 is Q2.1, Q2.2, ...

Format a question like so:

```
❓ **Q1.2** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

💡 <your recommended answer>
```

Word each question so "yes" accepts your recommended answer.

Once every question in a round is answered, the answers reshape the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and start the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent with a fresh context window to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
