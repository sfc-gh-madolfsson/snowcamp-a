/* =====================================================================
   Snow Camp 2026 — BUILDATHON · Track A (AI Agents)
   SYNTHETIC DATA  (repo file 01)  —  run AFTER 00_provision.sql
   ---------------------------------------------------------------------
   Creates database SNOWCAMP_AGENTS (RAW / ANALYTICS / APP) and the data
   your "Commercial Field Copilot" reasons over:
     structured : HCP_MASTER, PRESCRIPTIONS (~3M), TERRITORY_PERFORMANCE,
                  HCP_TARGETING
     unstructured: FIELD_NOTES (rep call notes, medical inquiries,
                  market-access notes) — the text the agent explains with

   Deliberate messiness is planted (tagged "INCONSISTENCY:") so you must
   govern PII and standardize values while building. All objects are
   FULLY QUALIFIED. A LARGE generation warehouse is used, then dropped.
   Idempotent: CREATE OR REPLACE.
   ===================================================================== */

USE ROLE ACCOUNTADMIN;   -- or your admin-like role

-- Fast, disposable generation warehouse (dropped at the end)
CREATE OR REPLACE WAREHOUSE SNOWCAMP_GEN_WH
  WAREHOUSE_SIZE = 'LARGE' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = FALSE;
USE WAREHOUSE SNOWCAMP_GEN_WH;

-- Lab warehouse (created here too so 01 is safe to run standalone)
CREATE WAREHOUSE IF NOT EXISTS SNOWCAMP_AGENTS_WH
  WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = FALSE;

CREATE DATABASE IF NOT EXISTS SNOWCAMP_AGENTS;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_AGENTS.RAW;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_AGENTS.ANALYTICS;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_AGENTS.APP;

/* =====================================================================
   HCP_MASTER (50,000 + 500 duplicates) — prescriber profile + PII
   INCONSISTENCY: ~2% null names; 500 duplicate HCP_IDs; country + tier drift
   ===================================================================== */
CREATE OR REPLACE TABLE SNOWCAMP_AGENTS.RAW.HCP_MASTER AS
SELECT
  'HCP_' || LPAD(SEQ4()::string, 6, '0')                                 AS HCP_ID,
  CASE WHEN UNIFORM(1,100,RANDOM()) <= 2 THEN NULL
       ELSE GET(ARRAY_CONSTRUCT('Dr. Anna Sorensen','Dr. Lars Nielsen','Dr. Mette Jensen',
              'Dr. Erik Larsson','Dr. Sofia Berg','Dr. Johan Andersson','Dr. Karin Holm',
              'Dr. Peter Madsen','Dr. Elin Lund','Dr. Nils Pedersen','Dr. Freja Dahl','Dr. Anders Kjaer'),
              UNIFORM(0,11,RANDOM()))::string END                        AS HCP_FULL_NAME,
  LOWER('hcp' || SEQ4() || '@example-health.eu')                          AS EMAIL,
  GET(ARRAY_CONSTRUCT('Endocrinology','Cardiology','General Practice',
      'Diabetology','Internal Medicine','Nephrology'), UNIFORM(0,5,RANDOM()))::string AS SPECIALTY,
  -- INCONSISTENCY: same country written many ways
  GET(ARRAY_CONSTRUCT('Denmark','denmark','DK','Danmark','Sweden','sweden','SE',
      'Norway','norway','NO','Finland','FI'), UNIFORM(0,11,RANDOM()))::string AS COUNTRY,
  'TERR_' || LPAD(UNIFORM(1,200,RANDOM())::string, 3, '0')                AS TERRITORY_ID,
  -- INCONSISTENCY: tier label drift
  GET(ARRAY_CONSTRUCT('A','Tier 1','tier1','1','B','Tier 2','tier2','2','C','Tier 3'),
      UNIFORM(0,9,RANDOM()))::string                                     AS HCP_TIER,
  DATEADD('day', -UNIFORM(0,1800,RANDOM()), CURRENT_DATE())              AS ONBOARDED_DATE
FROM TABLE(GENERATOR(ROWCOUNT => 50000));

-- INCONSISTENCY: 500 duplicate HCP_ID rows (breaks uniqueness)
INSERT INTO SNOWCAMP_AGENTS.RAW.HCP_MASTER
SELECT * FROM SNOWCAMP_AGENTS.RAW.HCP_MASTER
WHERE HCP_ID IN (SELECT HCP_ID FROM SNOWCAMP_AGENTS.RAW.HCP_MASTER ORDER BY HCP_ID LIMIT 500);

/* =====================================================================
   PRESCRIPTIONS (~3,000,000) — fact
   INCONSISTENCY: ~2% null HCP_ID; ~1% negative QUANTITY; ~3% orphan HCP; product case drift
   ===================================================================== */
CREATE OR REPLACE TABLE SNOWCAMP_AGENTS.RAW.PRESCRIPTIONS AS
SELECT
  'RX_' || LPAD(SEQ4()::string, 10, '0')                                 AS PRESCRIPTION_ID,
  CASE
    WHEN UNIFORM(1,100,RANDOM()) <= 2 THEN NULL
    WHEN UNIFORM(1,100,RANDOM()) <= 3 THEN 'HCP_' || LPAD(UNIFORM(900000,999999,RANDOM())::string,6,'0')
    ELSE 'HCP_' || LPAD(UNIFORM(0,49999,RANDOM())::string, 6, '0')
  END                                                                    AS HCP_ID,
  GET(ARRAY_CONSTRUCT('Ozempic','ozempic','Wegovy','wegovy','Rybelsus',
      'Victoza','Saxenda','Levemir','Tresiba','NovoRapid'), UNIFORM(0,9,RANDOM()))::string AS PRODUCT,
  DATEADD('day', -UNIFORM(0,730,RANDOM()), CURRENT_DATE())               AS PRESCRIPTION_DATE,
  CASE WHEN UNIFORM(1,100,RANDOM()) <= 1 THEN -1 * UNIFORM(1,5,RANDOM())
       ELSE UNIFORM(1,60,RANDOM()) END                                   AS QUANTITY,
  ROUND(UNIFORM(20,400,RANDOM()) + UNIFORM(0,99,RANDOM())/100.0, 2)       AS COPAY_AMOUNT
FROM TABLE(GENERATOR(ROWCOUNT => 3000000));

/* =====================================================================
   TERRITORY_PERFORMANCE (200)  — INCONSISTENCY: ~5% penetration > 1
   ===================================================================== */
CREATE OR REPLACE TABLE SNOWCAMP_AGENTS.RAW.TERRITORY_PERFORMANCE AS
SELECT
  'TERR_' || LPAD(SEQ4()::string, 3, '0')                                AS TERRITORY_ID,
  GET(ARRAY_CONSTRUCT('Nordics','DACH','Benelux','Iberia','UK & Ireland'), UNIFORM(0,4,RANDOM()))::string AS REGION,
  UNIFORM(50000, 400000, RANDOM())                                       AS ADDRESSABLE_PATIENTS,
  CASE WHEN UNIFORM(1,100,RANDOM()) <= 5 THEN ROUND(UNIFORM(101,140,RANDOM())/100.0, 3)
       ELSE ROUND(UNIFORM(5,85,RANDOM())/100.0, 3) END                   AS MARKET_PENETRATION,
  UNIFORM(3, 25, RANDOM())                                               AS ACTIVE_REPS,
  DATE_TRUNC('quarter', CURRENT_DATE())                                  AS REPORT_QUARTER
FROM TABLE(GENERATOR(ROWCOUNT => 200));

/* =====================================================================
   HCP_TARGETING (50,000) — INCONSISTENCY: priority case drift; tiers differ from HCP_MASTER
   ===================================================================== */
CREATE OR REPLACE TABLE SNOWCAMP_AGENTS.RAW.HCP_TARGETING AS
SELECT
  'HCP_' || LPAD(SEQ4()::string, 6, '0')                                 AS HCP_ID,
  GET(ARRAY_CONSTRUCT('High','Medium','Low','HIGH','med','LOW'), UNIFORM(0,5,RANDOM()))::string AS PRIORITY,
  GET(ARRAY_CONSTRUCT('Tier 1','Tier 2','Tier 3'), UNIFORM(0,2,RANDOM()))::string AS HCP_TIER,
  UNIFORM(0,100,RANDOM())                                                AS DIGITAL_ENGAGEMENT_SCORE,
  (UNIFORM(0,1,RANDOM()) = 1)                                            AS HIGH_PRIORITY_OBESITY,
  (UNIFORM(0,1,RANDOM()) = 1)                                            AS HIGH_PRIORITY_DIABETES
FROM TABLE(GENERATOR(ROWCOUNT => 50000));

/* =====================================================================
   FIELD_NOTES (40,000) — UNSTRUCTURED text (Cortex Search source)
   Doc types: Rep Call Note / Medical Inquiry / Market Access Note
   INCONSISTENCY: ~2% empty text; ~3% blank HCP ref
   ===================================================================== */
CREATE OR REPLACE TABLE SNOWCAMP_AGENTS.RAW.FIELD_NOTES AS
SELECT
  'NOTE_' || LPAD(SEQ4()::string, 7, '0')                                AS NOTE_ID,
  GET(ARRAY_CONSTRUCT('Rep Call Note','Medical Inquiry','Market Access Note'), UNIFORM(0,2,RANDOM()))::string AS DOC_TYPE,
  CASE WHEN UNIFORM(1,100,RANDOM()) <= 3 THEN NULL
       ELSE 'HCP_' || LPAD(UNIFORM(0,49999,RANDOM())::string, 6, '0') END AS HCP_ID,
  GET(ARRAY_CONSTRUCT('Nordics','DACH','Benelux','Iberia','UK & Ireland'), UNIFORM(0,4,RANDOM()))::string AS REGION,
  DATEADD('day', -UNIFORM(0,540,RANDOM()), CURRENT_DATE())               AS NOTE_DATE,
  CASE WHEN UNIFORM(1,100,RANDOM()) <= 2 THEN NULL ELSE
    GET(ARRAY_CONSTRUCT(
      'HCP raised concerns about injection device usability for elderly obesity patients; requested a pen demo and simpler onboarding materials.',
      'Discussed titration schedule for GLP-1 therapy; HCP wants clearer dosing guidance for patients switching from a competitor product.',
      'Market access: local formulary review pending; reimbursement for the obesity indication is the main barrier to new starts this quarter.',
      'Medical inquiry regarding gastrointestinal side effects and mitigation strategies during dose escalation.',
      'HCP reports strong patient interest in the weight-management program but cites supply concerns affecting continuity of care.',
      'Competitive pressure noted: a rival GLP-1 is being promoted heavily; HCP asked for head-to-head efficacy and adherence data.',
      'Patient adherence discussion: missed-dose patterns linked to device handling; support intervention recommended.',
      'Access note: payer requires prior authorization; HCP frustrated with the paperwork burden slowing initiation.',
      'Positive feedback on cardiovascular outcomes data; HCP open to expanding use in high-risk diabetes patients.',
      'Inquiry about pediatric growth-disorder dosing and long-term safety monitoring.',
      'Nordics territory: strong uptake in endocrinology but GP segment lags; requested targeted educational webinars.',
      'HCP declined new detailing due to formulary exclusion; asked to be re-contacted after the next pharmacy and therapeutics committee.',
      'Reported a stockout at the local pharmacy; concerned about patients pausing therapy and losing progress.',
      'Enthusiastic about real-world evidence; would consider a speaker program on obesity management in primary care.'
    ), UNIFORM(0,13,RANDOM()))::string END                               AS NOTE_TEXT
FROM TABLE(GENERATOR(ROWCOUNT => 40000));

/* =====================================================================
   PROFILE — confirm tables + planted inconsistencies + total rows
   ===================================================================== */
SELECT 'HCP_MASTER' AS tbl, COUNT(*) AS row_count FROM SNOWCAMP_AGENTS.RAW.HCP_MASTER
UNION ALL SELECT 'PRESCRIPTIONS', COUNT(*) FROM SNOWCAMP_AGENTS.RAW.PRESCRIPTIONS
UNION ALL SELECT 'TERRITORY_PERFORMANCE', COUNT(*) FROM SNOWCAMP_AGENTS.RAW.TERRITORY_PERFORMANCE
UNION ALL SELECT 'HCP_TARGETING', COUNT(*) FROM SNOWCAMP_AGENTS.RAW.HCP_TARGETING
UNION ALL SELECT 'FIELD_NOTES', COUNT(*) FROM SNOWCAMP_AGENTS.RAW.FIELD_NOTES
ORDER BY row_count DESC;

-- Tidy up: drop the disposable generation warehouse, leave the MEDIUM lab warehouse.
USE WAREHOUSE SNOWCAMP_AGENTS_WH;
DROP WAREHOUSE IF EXISTS SNOWCAMP_GEN_WH;
