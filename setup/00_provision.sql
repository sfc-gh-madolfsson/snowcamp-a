/* =====================================================================
   Snow Camp 2026 — BUILDATHON · Track A (AI Agents)
   PROVISION  (repo file 00)  —  run this FIRST, then 01_data.sql
   ---------------------------------------------------------------------
   Problem: build a "Commercial Field Copilot" — a Cortex Agent over
   structured commercial metrics + unstructured field notes.

   Run as ACCOUNTADMIN (or your admin-like role). Creates: account
   settings for Cortex Code, a warehouse, and a compute pool for the
   final Streamlit-on-SPCS gate. 01_data.sql creates the database + data.

   All objects are FULLY QUALIFIED so this runs in any client, even if
   USE-context does not persist between statements.
   ===================================================================== */

USE ROLE ACCOUNTADMIN;   -- or your admin-like role

------------------------------------------------------------------------
-- 1. Account settings for Cortex Code / Cortex AI
------------------------------------------------------------------------
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_EU';   -- broaden per your residency policy

GRANT DATABASE ROLE SNOWFLAKE.COPILOT_USER      TO ROLE SYSADMIN;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER       TO ROLE SYSADMIN;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER TO ROLE SYSADMIN;
-- MANUAL (one-time, UI): Snowsight > AI/ML > Agents > Settings > enable Web search.

------------------------------------------------------------------------
-- 2. Warehouse (queries, Analyst, Search, the app)
------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS SNOWCAMP_AGENTS_WH
  WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = FALSE;

------------------------------------------------------------------------
-- 3. Compute pool — runs the final Streamlit-in-Snowflake app on SPCS
--    (container runtime, no Docker).
------------------------------------------------------------------------
CREATE COMPUTE POOL IF NOT EXISTS SNOWCAMP_AGENTS_POOL
  MIN_NODES = 1 MAX_NODES = 1 INSTANCE_FAMILY = CPU_X64_XS AUTO_SUSPEND_SECS = 300;

------------------------------------------------------------------------
-- 4. Semantic view REFERENCES grant (Cortex Analyst agent gotcha).
--    Run AFTER you create the semantic view in Gate 2. A Cortex Analyst
--    agent needs REFERENCES (not just SELECT) on the semantic view.
--    Uncomment and set <agent_role> if you build the agent under a non-admin role:
------------------------------------------------------------------------
-- GRANT SELECT     ON SEMANTIC VIEW SNOWCAMP_AGENTS.ANALYTICS.NN_COMMERCIAL_SEMANTIC_VIEW TO ROLE <agent_role>;
-- GRANT REFERENCES ON SEMANTIC VIEW SNOWCAMP_AGENTS.ANALYTICS.NN_COMMERCIAL_SEMANTIC_VIEW TO ROLE <agent_role>;

------------------------------------------------------------------------
-- 5. Verify
------------------------------------------------------------------------
SHOW COMPUTE POOLS LIKE 'SNOWCAMP_AGENTS_POOL';   -- expect STARTING then ACTIVE/IDLE
SHOW WAREHOUSES LIKE 'SNOWCAMP_AGENTS_WH';
-- Next: run 01_data.sql, then open a Workspace and start the mission brief.
