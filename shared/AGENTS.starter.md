# AGENTS.md — Snow Camp 2026 Buildathon (starter)
# Copy this to the root of your Workspace and adapt for your track.
# Cortex Code reads AGENTS.md in every conversation, so set your rules once here.

## Context
- Event: Novo Nordisk commercial buildathon. You picked ONE track:
  - Track A (AI Agents)  -> database SNOWCAMP_AGENTS
  - Track B (ML)         -> database SNOWCAMP_ML
  - Track C (Data Eng & Governance) -> database SNOWCAMP_DATAOPS
- Set <TRACK_DB> below to your track's database. Schemas in every track: RAW, ANALYTICS, APP.
- <TRACK_WH>  = your track's warehouse  (e.g. SNOWCAMP_AGENTS_WH)
- <TRACK_POOL> = your track's compute pool (e.g. SNOWCAMP_AGENTS_POOL), used by the Streamlit-on-SPCS final gate.

## Conventions
- Always fully qualify objects: <TRACK_DB>.<schema>.<object>.
- Use warehouse <TRACK_WH> for queries.
- SQL: UPPERCASE keywords, snake_case identifiers.
- Explain SQL/DDL before running it; show me a plan for multi-step tasks.
- Prefer Altair for charts in Streamlit apps.
- Deploy Streamlit on the container runtime (SPCS): RUNTIME_NAME='SYSTEM$ST_CONTAINER_RUNTIME_PY3_11',
  COMPUTE_POOL=<TRACK_POOL>, QUERY_WAREHOUSE=<TRACK_WH>.

## Domain definitions
- HCP = Healthcare Professional (prescriber), keyed by HCP_ID.
- Rx  = prescription (fact).
- Territory = commercial geography; penetration = share of addressable prescriptions captured.
- Targeting tier = commercial priority band.

## DO-NOT (guardrails)
- Do not use ACCOUNTADMIN in application code.
- Do not publish a table without classifying PII first.
- Do not DROP or REPLACE objects without confirming with me.
- Do not hardcode credentials.
- Do not expose unmasked HCP/patient identifiers to roles other than my admin role.
