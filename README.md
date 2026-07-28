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

**Hints:**
- Point Cortex Code at @SNOWCAMP_AGENTS.RAW so it reads real column names instead of guessing.
- Ask for row counts, distinct values, and anything that looks wrong — not just a column list.
- Whatever mess you find is deliberate. Note it now; you deal with it in the next gates.

**Check yourself:** Describe the grain of HCP_MASTER, PRESCRIPTIONS and FIELD_NOTES in one line each, then name the PII columns and the messiest fields.

**Gate:** You can explain what's in the data, and you've found the PII and the messy values.

**Skills that help:** `/sql-author` `/data-quality` `/cortex-code-guide`

### G2 · Teach it your business language  ·  *12 min*
**Your task:** Your agent will get asked number questions — how many prescriptions, which territories are underperforming. It can't answer those reliably against raw messy tables, so give it a model to reason over. Build a semantic view using the language a commercial team actually speaks (HCP, product, territory, tier, month; total prescriptions, active prescribers, market penetration), validate it, and make sure the messy tier and country values you found don't skew the numbers.

**Hints:**
- Describe the business concepts you want — not SQL — and let Cortex Code build and validate the view.
- If numbers look strange, it's the messy tier/country values. Ask it to standardize them inside the view.
- Name it ANALYTICS.NN_COMMERCIAL_SEMANTIC_VIEW so later gates can find it.

**Check yourself:** Ask it in plain English: which territories are below average on penetration this quarter, and who are their top-tier HCPs?

**Gate:** The semantic view validates and Cortex Analyst answers a real business question sensibly.

**Skills that help:** `/semantic-view`

### G3 · Lock down the PII first  ·  *8 min*
**Your task:** You spotted personal data in Gate 1 — names and emails of real prescribers. An agent that can read anything can also repeat anything, so protect it before you wire it up. Work out what's actually sensitive, mask it so only you can see raw values, and then prove the mask does what you think it does.

**Hints:**
- Describe the outcome — 'mask HCP names and emails from anyone who isn't me' — and let it write and apply the policy.
- Proving it matters more than creating it. A policy you haven't tested is a policy you don't have.

**Check yourself:** Read the PII columns as a role without access, then as yourself, and compare.

**Gate:** PII is classified and masked — masked for others, readable for you.

**Skills that help:** `/data-governance`

### G4 · Make the free text searchable  ·  *10 min*
**Your task:** Half of what your field team needs isn't in a table at all — it's buried in 40,000 rep call notes, medical inquiries and market-access notes. Make that text searchable so your agent can actually quote it. Stand up a Cortex Search service over the notes, keep the attributes that matter for filtering and citation, and test it with a question a real rep would ask.

**Hints:**
- Point search at the note text and keep DOC_TYPE, HCP_ID, REGION and NOTE_DATE as attributes; skip the empty notes.
- Test with a theme rather than an exact keyword — then judge whether the top hits are genuinely about it.

**Check yourself:** Search something like 'formulary access barriers' and check the top 5 are really about market access, with their doc type and HCP.

**Gate:** Your search service returns relevant notes with useful attributes.

**Skills that help:** `/search-optimization`

### G5 · Assemble the copilot  ·  *15 min*
**Your task:** Now put it together. Build one agent that can reach into both worlds: the semantic view when someone wants numbers, the notes when they want to know why. Give each tool a description clear enough that the agent reliably picks the right one, teach it how to route and blend the two, and shape how it answers — lead with the answer, show the numbers, quote the notes, recommend a next action. Then go try to break it in Snowflake Intelligence.

**Hints:**
- Three layers: the tools it can call, the orchestration that decides which to use, and the response format. Build them in that order.
- Blended questions are the real test — numbers first to find who, then notes to explain why.
- If the Analyst tool errors on permissions, it needs REFERENCES on the semantic view (provision file, section 4).

**Check yourself:** Ask: who are my top-tier underperforming HCPs in the Nordics, and what have reps noted about them? Watch which tools it calls.

**Gate:** One question makes it use both tools and answer in your instructed format, with citations.

**Skills that help:** `/cortex-agent` `/agent-optimization` `/cortex-chart-customization`

### GF · Put it in someone's hands  ·  *7 min*
**Your task:** An agent nobody can reach isn't much use. Ship it as a Streamlit app running on the container runtime (SPCS). How far you take it is your call — a focused results view with a chat box and a few KPIs, or a full app with territory and tier filters and drill-downs. Get it deployed and open the URL.

**Hints:**
- Deploy on the container runtime: RUNTIME_NAME='SYSTEM$ST_CONTAINER_RUNTIME_PY3_11', COMPUTE_POOL=SNOWCAMP_AGENTS_POOL, QUERY_WAREHOUSE=SNOWCAMP_AGENTS_WH.
- Describe the UI you want, deploy it, then iterate — add one filter and redeploy.
- First launch can be slow while the compute pool wakes up. That's normal.

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
