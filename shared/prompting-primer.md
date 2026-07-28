# How to prompt Cortex Code — exploration primer

This is a **buildathon**, not a script to follow. Each gate tells you *what* to achieve and hints at *skills* that can help — but **how** you get there is yours to discover. That is the whole point: learn how much Cortex Code can do when you describe intent and let it plan.

## Mindset
- **Describe the outcome, not the syntax.** "Mask the HCP email and full name so only my role sees them" beats hand-writing a masking policy.
- **Let it explore your data.** Use `@` to point it at a database, schema, or table (e.g. `@SNOWCAMP_DATAOPS.RAW`) so it reads real column names instead of guessing.
- **Work in steps.** Ask for a plan on anything multi-step, review it, then let it execute.
- **Iterate out loud.** "That query double-counts because of the tier join — fix it" is a valid prompt. It will.
- **Ask it to prove things.** "Show me the before/after" or "run it and show the counts" turns a claim into evidence.

## Using skills
Type `/` to see skills. A skill like `/data-governance` or `/semantic-view` primes Cortex Code with a specialized workflow. The gate hints suggest one or two — but you're free to use others, or none.

## First step (pre-req) — set your rules once with AGENTS.md
Before the gates, create an `AGENTS.md` at your workspace root (start from `shared/AGENTS.starter.md`). Cortex Code reads it every turn, so you don't repeat conventions like "always fully-qualify objects," "use warehouse X," or "explain SQL before running it." It's a Cortex Code concept, not part of a normal Snowsight session — so we call it out as a given first step. You can also just ask Cortex Code to create it for you.

## Gotchas worth knowing
- **Role:** everyone runs as **ACCOUNTADMIN** by default in this event — no role switching needed. If something comes back "not authorized," it's usually a missing **grant** (ask Cortex Code to add it), not the role.
- **Fully-qualify:** if session context (`USE SCHEMA`) doesn't stick in your client, prefer fully-qualified names like `DB.SCHEMA.TABLE`.
- **Big data:** you have multi-million-row tables. Ask for row counts and `LIMIT` samples before pulling everything; ask it to push work down to SQL.

## When you're stuck
- Ask it to **explain what it just did** and why.
- Ask for **two or three approaches** and pick one.
- Point it back at the **gate's pass condition** and ask "does my work satisfy this? test it."

Have fun — try to surprise yourself with what one well-phrased ask can build.
