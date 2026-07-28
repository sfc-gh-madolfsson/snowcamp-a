# Track A — AI Agents · "Commercial Field Copilot"

> **Snow Camp 2026 - Cortex Code Buildathon.** Everything runs inside Snowsight - **nothing to download.** Open each SQL file below, click the **copy icon** (top-right), paste into a Snowsight **SQL worksheet**, and **Run All**.

**Setup - run in order:**
1. [`setup/00_provision.sql`](setup/00_provision.sql)
2. [`setup/01_data.sql`](setup/01_data.sql)

**Gate tracker:** [open it live](https://htmlpreview.github.io/?https://raw.githubusercontent.com/sfc-gh-madolfsson/snowcamp-buildathon-track-a-agents/main/tracker.html) - or [view the file](tracker.html) &nbsp;|&nbsp; **Primer:** [how to prompt Cortex Code](shared/prompting-primer.md) &nbsp;|&nbsp; **AGENTS.md starter:** [shared/AGENTS.starter.md](shared/AGENTS.starter.md)

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

## Pre-req — create your `AGENTS.md` (do this first, before the gates)
**What it is & why:** `AGENTS.md` is a plain-markdown file at your Workspace root that Cortex Code reads at the start of *every* conversation. It's how you set your conventions **once** — which database/warehouse to use, to fully-qualify object names, to explain SQL before running it, to protect PII — instead of repeating them in each prompt. This isn't part of a normal ad-hoc session; for the buildathon we treat it as a given first step so Cortex Code works the way you want from the start.

**How (pick one):**
- Ask Cortex Code to create it — e.g. *"Create an AGENTS.md at my workspace root: use database `SNOWCAMP_AGENTS` and warehouse `SNOWCAMP_AGENTS_WH`, always fully-qualify objects as DB.SCHEMA.OBJECT, explain SQL before running it, and never expose unmasked HCP PII."*
- Or copy [shared/AGENTS.starter.md](shared/AGENTS.starter.md) into a new file named `AGENTS.md` at your workspace root and fill in the placeholders.

---

## Gates

### G1 · Orient & set your rules
**Achieve:** you start in **ACCOUNTADMIN** by default — no role switch needed (with your `AGENTS.md` from the pre-req already in place). Build a mental map of the structured tables and the text notes.
**Validate:** you can describe the grain of `HCP_MASTER`, `PRESCRIPTIONS`, and `FIELD_NOTES`, and you spotted the PII and the messy values.
**Skills:** `/cortex-code-guide` `/sql-author`

### G2 · Model the numbers (semantic view)
**Achieve:** a governed semantic view in `ANALYTICS` (call it `NN_COMMERCIAL_SEMANTIC_VIEW`) with business dimensions (HCP, product, territory, tier, month) and metrics (total prescriptions, active prescribers, market penetration). Make it stand up to the messy tier/country values.
**Validate:** the view validates, and Cortex Analyst answers *"which territories are below-average on penetration this quarter, and who are their top-tier HCPs?"* with sensible numbers.
**Skills:** `/semantic-view`

### G3 · Protect it (govern PII)
**Achieve:** classify and mask the HCP PII (name, email) so only your admin role sees raw values — the agent must not leak identifiers.
**Validate:** selecting the PII columns as a role without access returns masked values; as you, real values.
**Skills:** `/data-governance`

### G4 · Unlock the text (Cortex Search)
**Achieve:** a Cortex Search service over `FIELD_NOTES.NOTE_TEXT`, keeping `DOC_TYPE`, `HCP_ID`, `REGION`, `NOTE_DATE` as attributes; skip null text.
**Validate:** searching a real theme (e.g. *"formulary access barriers"*) returns relevant notes with their doc type and HCP.
**Skills:** `/search-optimization`

### G5 · Assemble & teach the agent
**Achieve:** one agent (`NN_COMMERCIAL_AGENT`) with **two tools** — Cortex Analyst on the semantic view (numbers) and Cortex Search on the notes (narrative), each with a crisp description. Then set its **orchestration** (route numbers -> Analyst, qualitative -> Search, blend for mixed questions) and **response** instructions (one-line answer, metrics table, 2-3 cited quotes, a next action). Test in Snowflake Intelligence.
**Validate:** the blended Nordics question uses **both** tools and returns the instructed structure with citations. (If Analyst errors on permissions, grant `REFERENCES` on the semantic view — see provision file, section 4.)
**Skills:** `/cortex-agent` `/agent-optimization` `/cortex-chart-customization`

### GF · Ship it — Streamlit on SPCS
**Achieve:** a Streamlit-in-Snowflake app on the **container runtime** — your choice of a **results view** (a chat box to the agent + a KPI panel from the semantic view) or a **full app** (add territory/tier filters, drill-downs). Deploy per [shared/streamlit-spcs-deploy.md](shared/streamlit-spcs-deploy.md).
**Validate:** the app is live on the container runtime (Projects > Streamlit) and the in-app chat returns the agent's answer.
**Skills:** `/developing-with-streamlit-in-snowflake` `/cortex-chart-customization`

---

## Stretch (fast finishers)
- Add a third agent tool (a SQL tool computing a custom "call-to-Rx" ratio) and re-run `/agent-optimization` to confirm routing still holds.
- Add a row-access policy so a rep only sees their own territory, and prove the agent respects it.
