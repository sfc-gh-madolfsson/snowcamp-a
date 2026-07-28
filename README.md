# Track A — AI Agents · "Commercial Field Copilot"

> **Snow Camp 2026 - Cortex Code Buildathon.** Everything runs inside Snowsight - **nothing to download.** Open each SQL file below, click the **copy icon** (top-right), paste into a Snowsight **SQL worksheet**, and **Run All**.

**Setup - run in order:**
1. [`setup/00_provision.sql`](setup/00_provision.sql)
2. [`setup/01_data.sql`](setup/01_data.sql)

**Gate tracker:** [open it live](https://htmlpreview.github.io/?https://raw.githubusercontent.com/sfc-gh-madolfsson/snowcamp-buildathon-track-a-agents/main/tracker.html) - or [view the file](tracker.html) &nbsp;|&nbsp; **Primer:** [how to prompt Cortex Code](shared/prompting-primer.md) &nbsp;|&nbsp; **Skills:** [skills map](shared/skills-map.md)

---

**Time:** ~60 minutes · **Database:** `SNOWCAMP_AGENTS` · **Warehouse:** `SNOWCAMP_AGENTS_WH` · **Pool:** `SNOWCAMP_AGENTS_POOL`

> This is a build-your-own challenge. Each gate says **what** to achieve and hints at **skills** — you decide **how** to prompt Cortex Code. Read [shared/prompting-primer.md](shared/prompting-primer.md) first.

## The objective
Novo Nordisk field teams ask the same questions every week: *who* to engage and *why*. The numbers live in prescription and territory tables; the "why" lives in reps' free-text notes. Build a **Cortex Agent** that answers a blended question in plain English by combining **structured metrics** (Cortex Analyst over a semantic view) with **unstructured field intelligence** (Cortex Search over call notes), then **ship it as a Streamlit app on SPCS**.

**Definition of done:** an agent that, asked *"Who are my top-tier underperforming HCPs in the Nordics, and what have reps noted about them?"*, uses **both** tools and returns a structured, cited answer — and a Streamlit app on the container runtime that surfaces it.

## Your data (`SNOWCAMP_AGENTS.RAW`)
| Table | Rows | What it is |
|---|---|---|
| `HCP_MASTER` | ~50.5k | Prescriber profile + **PII** (name, email). Messy: null names, 500 dup IDs, country/tier spelling drift |
| `PRESCRIPTIONS` | ~3M | Rx fact. Messy: null/orphan HCP_ID, negative quantities, product case drift |
| `TERRITORY_PERFORMANCE` | 200 | Region (incl. Nordics), addressable patients, market penetration (~5% > 1) |
| `HCP_TARGETING` | 50k | Priority + tier (drifts from HCP_MASTER), digital engagement, focus flags |
| `FIELD_NOTES` | 40k | **Unstructured**: rep call notes, medical inquiries, market-access notes. Some null text/HCP |

## Setup (once)
Run [setup/00_provision.sql](setup/00_provision.sql) then [setup/01_data.sql](setup/01_data.sql) — open each file, copy, paste into a Snowsight SQL worksheet, and Run All.

---

## Gates

### G1 · Get to know your data  ·  *8 min*

**Your task:** You've been handed commercial data across several domains and asked to build an agent on top of it. Before you build anything, get to know it. Build a mental map of the tables — what's in each one, what a single row represents, how they join. You should be able to describe exactly what's in these tables. Are there PII issues? Messy or inconsistent values? Investigate with Cortex Code and decide whether this data is actually ready to build an agent on.

**Deliverable — what "done" looks like:**
- A summary of each RAW table: what one row represents, roughly how many rows, and the join key.
- A list of the columns holding personal data.
- A list of the data-quality problems you found, with rough counts.

**How to approach it** *(your prompts, your call)*:
1. Give Cortex Code the schema as context (`@SNOWCAMP_AGENTS.RAW`) and ask it to inventory the tables and explain the grain of each.
2. Pick the biggest tables and have it profile them — date ranges, distinct products and HCPs, nulls, anything suspicious.
3. Ask specifically which columns look like personal data, and which fields have inconsistent values.
4. Run one join across two tables to confirm you understand the keys.

> **Watch out:** Ask for counts, not examples — "how many rows have a null HCP_ID" tells you far more than "show me some bad rows".

**Check yourself:** Describe the grain of HCP_MASTER, PRESCRIPTIONS and FIELD_NOTES in one line each, then name the PII columns and the messiest fields.

**Gate:** You can explain what's in the data, and you've found the PII and the messy values.

**Skills that help:** `/sql-author` `/data-quality` `/cortex-code-guide`

### G2 · Teach it your business language  ·  *12 min*

**Your task:** Your agent will get asked number questions — how many prescriptions, which territories are underperforming. It can't answer those reliably against raw messy tables, so give it a model to reason over. Build a semantic view using the language a commercial team actually speaks, validate it, and make sure the messy tier and country values you found don't skew the numbers.

**Deliverable — what "done" looks like:**
- A semantic view in `ANALYTICS` that validates cleanly (suggested name `NN_COMMERCIAL_SEMANTIC_VIEW`).
- Dimensions covering HCP, product, territory, tier and month.
- Metrics for total prescriptions, active prescribers and market penetration.
- At least one verified query saved on the view.

**How to approach it** *(your prompts, your call)*:
1. Describe the dimensions and metrics you want in plain business language and let Cortex Code generate the view.
2. Ask it to validate the view, then fix whatever it reports.
3. Handle the messy tier and country values — standardize them inside the view rather than editing raw tables.
4. Ask a real business question in plain English and sanity-check the numbers that come back.

> **Watch out:** Negative quantities and null HCPs will quietly skew your metrics — decide whether to filter them in the view.

**Check yourself:** Ask it in plain English: which territories are below average on penetration this quarter, and who are their top-tier HCPs?

**Gate:** The semantic view validates and Cortex Analyst answers a real business question sensibly.

**Skills that help:** `/semantic-view`

### G3 · Lock down the PII first  ·  *8 min*

**Your task:** You spotted personal data in Gate 1 — names and emails of real prescribers. An agent that can read anything can also repeat anything, so protect it before you wire it up. Work out what's actually sensitive, mask it so only you can see raw values, then prove the mask does what you think it does.

**Deliverable — what "done" looks like:**
- The sensitive columns in HCP_MASTER classified or tagged.
- A masking policy applied to at least the HCP name and email.
- Evidence it works: the same query run as a privileged and an unprivileged role.

**How to approach it** *(your prompts, your call)*:
1. Ask Cortex Code to identify and classify the sensitive columns for you.
2. Describe the masking behaviour you want — who sees raw, who sees masked — and let it write and apply the policy.
3. Test it: read those columns from a role without access, then as yourself, and compare.

> **Watch out:** You're ACCOUNTADMIN, so you'll always see raw values. You must test as another role or you've proven nothing.

**Check yourself:** Read the PII columns as a role without access, then as yourself, and compare.

**Gate:** PII is classified and masked — masked for others, readable for you.

**Skills that help:** `/data-governance`

### G4 · Make the free text searchable  ·  *10 min*

**Your task:** Half of what your field team needs isn't in a table at all — it's buried in 40,000 rep call notes, medical inquiries and market-access notes. Make that text searchable so your agent can actually quote it, and test it with a question a real rep would ask.

**Deliverable — what "done" looks like:**
- A Cortex Search service over the note text (suggested name `ANALYTICS.NN_DOCS_SEARCH`).
- `DOC_TYPE`, `HCP_ID`, `REGION` and `NOTE_DATE` available as attributes.
- A test search whose top hits are genuinely on-topic.

**How to approach it** *(your prompts, your call)*:
1. Point Cortex Code at the notes table and ask it to build a search service over the text column, keeping the attributes you'd filter or cite by.
2. Exclude the rows with empty note text.
3. Search a commercial theme and inspect the top hits — are they really about it?
4. Try a second, different theme to see how well it generalizes.

> **Watch out:** Give the service a moment to finish indexing before you judge result quality.

**Check yourself:** Search something like "formulary access barriers" and check the top 5 are really about market access, with their doc type and HCP.

**Gate:** Your search service returns relevant notes with useful attributes.

**Skills that help:** `/search-optimization`

### G5 · Assemble the copilot  ·  *15 min*

**Your task:** Now put it together. Build one agent that can reach into both worlds: the semantic view when someone wants numbers, the notes when they want to know why. Teach it how to route and blend the two, shape how it answers, then go try to break it in Snowflake Intelligence.

**Deliverable — what "done" looks like:**
- One agent (suggested name `NN_COMMERCIAL_AGENT`) with two tools: Cortex Analyst on your semantic view and Cortex Search on your notes.
- A clear description on each tool so the agent knows when to use which.
- Orchestration instructions: numbers to Analyst, why/themes to Search, blend for mixed questions.
- Response instructions: a one-line answer, a metrics table, 2-3 cited note quotes, and a recommended next action.

**How to approach it** *(your prompts, your call)*:
1. Create the agent and attach both tools, writing a crisp description for each.
2. Set the orchestration instructions so routing is unambiguous, including what to do with a blended question.
3. Set the response instructions so every answer has the same shape and cites its sources.
4. Test in Snowflake Intelligence: a numbers-only question, a notes-only question, then a blended one.
5. Have `/agent-optimization` review the tool descriptions and routing, then tune.

> **Watch out:** If the Analyst tool errors on permissions, the agent's role needs REFERENCES (not just SELECT) on the semantic view — see the provision file, section 4.

**Check yourself:** Ask: who are my top-tier underperforming HCPs in the Nordics, and what have reps noted about them? Watch which tools it calls.

**Gate:** One question makes it use both tools and answer in your instructed format, with citations.

**Skills that help:** `/cortex-agent` `/agent-optimization` `/cortex-chart-customization`

### GF · Put it in someone's hands  ·  *7 min*

**Your task:** An agent nobody can reach isn't much use. Ship it as a Streamlit app running on the container runtime (SPCS). How far you take it is your call — a focused results view, or a full app with filters and drill-downs.

**Deliverable — what "done" looks like:**
- A Streamlit app deployed on the container runtime with a working URL.
- Your choice: a results view (chat to the agent plus a few KPIs) or a fuller app with territory and tier filters.

**How to approach it** *(your prompts, your call)*:
1. Describe the UI you want and let Cortex Code build the app.
2. Deploy it on the container runtime using your track's compute pool and warehouse.
3. Open the URL and actually use it — then change one thing and redeploy.

> **Watch out:** Deploy with RUNTIME_NAME='SYSTEM$ST_CONTAINER_RUNTIME_PY3_11', COMPUTE_POOL=SNOWCAMP_AGENTS_POOL, QUERY_WAREHOUSE=SNOWCAMP_AGENTS_WH. The first launch is slow while the pool starts — that's normal.

**Check yourself:** Open the app URL and ask your Nordics question in the app's own chat.

**Gate:** The app is live on the container runtime and answers in the UI.

**Skills that help:** `/developing-with-streamlit-in-snowflake`

---

## Stretch (fast finishers)
- Add a third agent tool (a SQL tool computing a custom "call-to-Rx" ratio) and re-run `/agent-optimization` to confirm routing still holds.
- Add a row-access policy so a rep only sees their own territory, and prove the agent respects it.

## Bonus — capture it as a reusable skill
Finished early? Take the whole workflow you just built — explore → semantic view → mask PII → Cortex Search → agent → Streamlit — and ask Cortex Code to turn it into a **custom skill**, so you (or your team) can run the same build on a new dataset with one command. Try: *"Create a skill that encodes the steps we just did, then invoke it on a fresh RAW schema and show me the plan."*
**Skills:** `/skill-development` `/skill-architect`
