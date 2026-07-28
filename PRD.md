# Commercial Field Copilot
**Track A · AI Agents**

> **Snow Camp 2026 — Cortex Code Buildathon.** Everything runs inside Snowsight — **nothing to download.** Open each SQL file below, click the **copy icon** (top-right), paste into a Snowsight **SQL worksheet**, and **Run All**.

---

## Setup (run these first)

1. Open a **Snowsight SQL worksheet**, paste [`setup/00_provision.sql`](setup/00_provision.sql), **Run All**.
2. New worksheet, paste [`setup/01_data.sql`](setup/01_data.sql), **Run All** (~1–3 min).
3. Open a **Workspace** and start building with Cortex Code.

New to prompting Cortex Code? [Prompting primer](shared/prompting-primer.md) ·
Deploying the app: [Streamlit on SPCS](shared/streamlit-spcs-deploy.md)

---

## The brief

You are working with the commercial field team. Before a call, a rep wants to know how a prescriber is
actually doing — volumes, tier, how the territory is performing — and also what colleagues have already
learned about them on previous visits. Today that means one person in a dashboard and another person
scrolling through free-text notes, and reps have time for neither. You have been asked to build them a
single place where they can ask a question in plain language and get an answer that draws on both the
numbers and the notes. Reps will act on these answers in front of customers, so the data needs to be
correct and governed, and the answers need to be traceable back to where they came from. It all needs to
land in a Streamlit in Snowflake application a rep would actually open.

## What you're given

Database `SNOWCAMP_AGENTS`, schema `RAW`:

| Table | Rows | What it is |
|---|---|---|
| `HCP_MASTER` | ~50k | Prescriber profiles — specialty, country, tier, territory. Contains PII. |
| `PRESCRIPTIONS` | ~3M | What was prescribed, by whom, when, how much. |
| `HCP_TARGETING` | 50k | Priority, tier and digital engagement score per prescriber. |
| `TERRITORY_PERFORMANCE` | 200 | Addressable patients, market penetration and rep count per territory. |
| `FIELD_NOTES` | 40k | Free-text rep call notes, medical inquiries and market access notes. |

Work out what's actually in there before you build on it.

## Here are the requirements for the copilot and application

1. Make the structured commercial data answerable in plain language by building a **semantic view** over
   it, so a rep can ask about prescribing volumes, tiers and territory performance and get an answer
   without anyone writing SQL for them.
2. Make the field notes searchable with **Cortex Search**, so the qualitative context a rep needs is
   findable rather than buried in 40,000 rows of text.
3. Build a **Cortex Agent** that uses both — the semantic view for the numbers, the search service for
   the notes — so it can answer a question needing both at once. For example: which high-tier
   prescribers in the Nordics are trending down, and what have reps noted about them.
4. Show the rep where an answer came from — which tool the agent used, the query it ran, the notes it
   quoted — so they can judge whether to trust it before repeating it to a customer.
5. Protect the PII in the prescriber data with **masking policies**, and make the data quality good and
   measurable — the same prescriber is described differently in different places, so decide what the
   truth is.
6. Build a **Streamlit in Snowflake** application that shows all of the above requirements are met, and
   that a rep would actually want to use before a call, in a highly visual and appealing way.

## Nice to have

- Give the agent a third tool and see whether it picks the right one.
- Let the agent search the web for public context alongside internal data.
- Tune how the agent responds — length, tone, when it should refuse to answer.
- Control how the agent charts its answers.
- Turn what you built into a reusable skill so the next person runs it in one command.

## Toolbox

Skills that are relevant here. No particular order — use them if they help.

`/semantic-view` · `/search-optimization` · `/cortex-agent` · `/data-governance` · `/data-quality` ·
`/developing-with-streamlit-in-snowflake` · `/cortex-chart-customization` · `/sql-author` ·
`/skill-development`

## Watch out

The same prescriber, country and tier are written several different ways across these tables, and some
prescriptions point at prescribers who don't exist. An agent will answer confidently on top of all of it.

---

**Objects:** DB `SNOWCAMP_AGENTS` · Warehouse `SNOWCAMP_AGENTS_WH` · Compute pool `SNOWCAMP_AGENTS_POOL`
