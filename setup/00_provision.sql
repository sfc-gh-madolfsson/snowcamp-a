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

USE ROLE ACCOUNTADMIN;

-- Environment for Track. Plain SQL, runs top to bottom.
-- 01_data.sql also creates the database and warehouse, so if you only run
-- 01_data.sql you still get a working data lab. This file adds the Cortex
-- grants and the compute pool used by the final Streamlit-on-SPCS step.

CREATE WAREHOUSE IF NOT EXISTS SNOWCAMP_AGENTS_WH
  WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = FALSE;

CREATE DATABASE IF NOT EXISTS SNOWCAMP_AGENTS;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_AGENTS.RAW;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_AGENTS.ANALYTICS;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_AGENTS.APP;

-- Cortex access for the agent / Analyst / Search work.
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ACCOUNTADMIN;

-- Compute pool for the final Streamlit-in-Snowflake app on SPCS (container
-- runtime, no Docker). Not needed until the app step.
CREATE COMPUTE POOL IF NOT EXISTS SNOWCAMP_AGENTS_POOL
  MIN_NODES = 1 MAX_NODES = 1 INSTANCE_FAMILY = CPU_X64_XS AUTO_SUSPEND_SECS = 300;

-- Verify.
SHOW WAREHOUSES LIKE 'SNOWCAMP_AGENTS_WH';
SHOW DATABASES  LIKE 'SNOWCAMP_AGENTS';
-- Next: run 01_data.sql, then open a Workspace and start on the requirements.
