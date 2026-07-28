# How to prompt Cortex Code — exploration primer

This is a **buildathon**, not a script to follow. Your track is a brief and a list of requirements: they tell you *what* the business needs, but **how** you get there is yours to discover. That is the whole point: learn how much Cortex Code can do when you describe intent and let it plan.

## Mindset
- **Describe the outcome, not the syntax.** "Mask the HCP email and full name so only my role sees them" beats hand-writing a masking policy.
- **Let it explore your data.** Use `@` to point it at a database, schema, or table (e.g. `@SNOWCAMP_DATAOPS.RAW`) so it reads real column names instead of guessing.
- **Work in steps.** Ask for a plan on anything multi-step, review it, then let it execute.
- **Iterate out loud.** "That query double-counts because of the tier join — fix it" is a valid prompt. It will.
- **Ask it to prove things.** "Show me the before/after" or "run it and show the counts" turns a claim into evidence.

## Using skills
Type `/` to see skills. A skill like `/data-governance` or `/semantic-view` primes Cortex Code with a specialized workflow. Each PRD has a Toolbox listing the ones that fit — but you're free to use others, or none. At the end there's a **bonus**: ask Cortex Code to package your whole workflow into your *own* skill (`/skill-development`) so you can rerun it with one command.

## Gotchas worth knowing
- **Role:** everyone runs as **ACCOUNTADMIN** by default in this event — no role switching needed. If something comes back "not authorized," it's usually a missing **grant** (ask Cortex Code to add it), not the role.
- **Fully-qualify:** if session context (`USE SCHEMA`) doesn't stick in your client, prefer fully-qualified names like `DB.SCHEMA.TABLE`.
- **Big data:** you have multi-million-row tables. Ask for row counts and `LIMIT` samples before pulling everything; ask it to push work down to SQL.

## When you're stuck
- Ask it to **explain what it just did** and why.
- Ask for **two or three approaches** and pick one.
- Point it back at the **requirement** and ask "does my work satisfy this? test it."

Have fun — try to surprise yourself with what one well-phrased ask can build.
