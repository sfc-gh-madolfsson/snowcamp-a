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

USE ROLE ACCOUNTADMIN;

-- Environment: warehouse, database, schemas. Plain SQL, runs top to bottom.
CREATE WAREHOUSE IF NOT EXISTS SNOWCAMP_AGENTS_WH
  WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE INITIALLY_SUSPENDED = FALSE;
USE WAREHOUSE SNOWCAMP_AGENTS_WH;

CREATE DATABASE IF NOT EXISTS SNOWCAMP_AGENTS;
USE DATABASE SNOWCAMP_AGENTS;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_AGENTS.RAW;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_AGENTS.ANALYTICS;
CREATE SCHEMA IF NOT EXISTS SNOWCAMP_AGENTS.APP;
USE SCHEMA SNOWCAMP_AGENTS.RAW;

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
WITH hcp AS (
  -- de-duplicate the 500 planted duplicate HCP_IDs so notes stay 1:1 with the seed
  SELECT HCP_ID, HCP_FULL_NAME, SPECIALTY
  FROM SNOWCAMP_AGENTS.RAW.HCP_MASTER
  QUALIFY ROW_NUMBER() OVER (PARTITION BY HCP_ID ORDER BY ONBOARDED_DATE) = 1
),
seed AS (
  SELECT
    'NOTE_' || LPAD(SEQ4()::string, 7, '0')                                AS NOTE_ID,
    GET(ARRAY_CONSTRUCT('Rep Call Note','Medical Inquiry','Market Access Note'), UNIFORM(0,2,RANDOM()))::string AS DOC_TYPE,
    CASE WHEN UNIFORM(1,100,RANDOM()) <= 3 THEN NULL
         ELSE 'HCP_' || LPAD(UNIFORM(0,49999,RANDOM())::string, 6, '0') END AS HCP_ID,
    GET(ARRAY_CONSTRUCT('Nordics','DACH','Benelux','Iberia','UK & Ireland'), UNIFORM(0,4,RANDOM()))::string AS REGION,
    DATEADD('day', -UNIFORM(0,540,RANDOM()), CURRENT_DATE())               AS NOTE_DATE,
    -- independent slot choices: 12 x 14 x 10 x 12 = 20,160 sentence structures
    UNIFORM(0,11,RANDOM()) AS I_OPEN,
    UNIFORM(0,13,RANDOM()) AS I_THEME,
    UNIFORM(0,9 ,RANDOM()) AS I_DETAIL,
    UNIFORM(0,11,RANDOM()) AS I_ASK,
    -- injected entities multiply that further
    GET(ARRAY_CONSTRUCT('Ozempic','Wegovy','Rybelsus','Saxenda','Norditropin','Tresiba'), UNIFORM(0,5,RANDOM()))::string AS PRODUCT,
    GET(ARRAY_CONSTRUCT('Mounjaro','Zepbound','Trulicity','a biosimilar'), UNIFORM(0,3,RANDOM()))::string AS COMPETITOR,
    GET(ARRAY_CONSTRUCT('Copenhagen','Aarhus','Stockholm','Gothenburg','Oslo',
                        'Bergen','Helsinki','Malmo','Odense','Uppsala'), UNIFORM(0,9,RANDOM()))::string AS CITY,
    GET(ARRAY_CONSTRUCT('Q1','Q2','Q3','Q4'), UNIFORM(0,3,RANDOM()))::string AS QTR,
    UNIFORM(3,40,RANDOM())  AS N_PATIENTS,
    UNIFORM(2,12,RANDOM())  AS N_WEEKS
  FROM TABLE(GENERATOR(ROWCOUNT => 40000))
)
SELECT
  s.NOTE_ID, s.DOC_TYPE, s.HCP_ID, s.REGION, s.NOTE_DATE,
  CASE WHEN UNIFORM(1,100,RANDOM()) <= 2 THEN NULL ELSE
    GET(ARRAY_CONSTRUCT(
      'Call with ' || nm || ' (' || sp || ', ' || s.CITY || ').',
      'Follow-up visit to the ' || s.CITY || ' clinic; primary contact ' || nm || '.',
      'Medical information request logged by ' || nm || '.',
      nm || ' joined the ' || s.CITY || ' advisory session.',
      'Brief corridor conversation with ' || nm || ' after ' || sp || ' rounds.',
      'Scheduled review with ' || nm || ' covering ' || s.QTR || ' performance.',
      'Virtual meeting with ' || nm || '; screen-shared the latest ' || sp || ' data.',
      'Unplanned drop-in at the ' || s.CITY || ' practice, spoke with ' || nm || '.',
      nm || ' asked that this note be routed to medical affairs.',
      'Territory visit in ' || s.CITY || '. Met ' || nm || '.',
      'Second call this quarter with ' || nm || '.',
      'Post-congress follow-up with ' || nm || ' (' || sp || ').'
    ), s.I_OPEN)::string
    || ' ' ||
    GET(ARRAY_CONSTRUCT(
      'Main topic was ' || s.PRODUCT || ' initiation in patients who have plateaued on diet and exercise alone.',
      'Raised device usability concerns with the ' || s.PRODUCT || ' pen, particularly for elderly patients.',
      'Wants head-to-head efficacy and adherence data versus ' || s.COMPETITOR || '.',
      'Competitive pressure from ' || s.COMPETITOR || ' is intense in this account, which is winning new starts.',
      'Asked for clearer titration guidance when switching patients from ' || s.COMPETITOR || ' to ' || s.PRODUCT || '.',
      'Reported gastrointestinal side effects during ' || s.PRODUCT || ' dose escalation and asked about mitigation.',
      'Formulary status for ' || s.PRODUCT || ' is still under review, which is blocking new prescriptions.',
      'Payer requires prior authorisation for ' || s.PRODUCT || '; the paperwork burden is slowing initiation.',
      'Flagged a ' || s.PRODUCT || ' stockout at the local pharmacy and is worried about therapy interruption.',
      'Positive on the cardiovascular outcomes data and open to using ' || s.PRODUCT || ' in higher-risk patients.',
      'Discussed long-term safety monitoring for ' || s.PRODUCT || ' in the paediatric growth-disorder setting.',
      'Adherence is the core issue: missed-dose patterns on ' || s.PRODUCT || ' appear linked to injection technique.',
      'Interested in real-world evidence for ' || s.PRODUCT || ' in primary care weight management.',
      'Reimbursement for the obesity indication remains the main barrier to ' || s.PRODUCT || ' uptake.'
    ), s.I_THEME)::string
    || ' ' ||
    GET(ARRAY_CONSTRUCT(
      'Approximately ' || s.N_PATIENTS::string || ' patients in the practice could be candidates.',
      'Roughly ' || s.N_PATIENTS::string || ' patients are on therapy, averaging ' || s.N_WEEKS::string || ' weeks duration.',
      'Reports ' || s.N_PATIENTS::string || ' discontinuations in the last ' || s.N_WEEKS::string || ' weeks.',
      'Uptake in ' || sp || ' is ahead of plan while the GP segment lags.',
      'Expects a decision after the next pharmacy and therapeutics committee in ' || s.QTR || '.',
      'Volume has been flat for ' || s.N_WEEKS::string || ' weeks despite increased call frequency.',
      'Nurse-led follow-up has improved persistence in about ' || s.N_PATIENTS::string || ' patients.',
      'Patient interest is high but ' || s.N_PATIENTS::string || ' starts are on hold pending reimbursement.',
      'Sees ' || s.N_PATIENTS::string || ' new referrals per month from the ' || s.CITY || ' network.',
      s.QTR || ' targets look achievable if supply stabilises.'
    ), s.I_DETAIL)::string
    || ' ' ||
    GET(ARRAY_CONSTRUCT(
      'Requested a pen demonstration and simplified onboarding materials.',
      'Action: send the head-to-head data pack and book a follow-up.',
      'Asked to be re-contacted after the formulary review.',
      'Wants a targeted educational webinar for the GP segment.',
      'Escalating to market access for payer support.',
      'Would consider participating in a speaker programme.',
      'Requested a medical affairs contact and declined to discuss further.',
      'No further action; declined additional detailing this cycle.',
      'Agreed to a nurse-training session on injection technique.',
      'Follow-up scheduled in ' || s.N_WEEKS::string || ' weeks.',
      'Asked for local health-economic data to support the business case.',
      'Referred the adherence question to the patient support programme team.'
    ), s.I_ASK)::string
  END                                                                      AS NOTE_TEXT
FROM seed s
LEFT JOIN hcp h ON s.HCP_ID = h.HCP_ID,
LATERAL (SELECT COALESCE(h.HCP_FULL_NAME, 'the HCP') AS nm,
                LOWER(COALESCE(h.SPECIALTY, 'general practice')) AS sp) v;

/* =====================================================================
   PROFILE — confirm tables + planted inconsistencies + total rows
   ===================================================================== */
SELECT 'HCP_MASTER' AS tbl, COUNT(*) AS row_count FROM SNOWCAMP_AGENTS.RAW.HCP_MASTER
UNION ALL SELECT 'PRESCRIPTIONS', COUNT(*) FROM SNOWCAMP_AGENTS.RAW.PRESCRIPTIONS
UNION ALL SELECT 'TERRITORY_PERFORMANCE', COUNT(*) FROM SNOWCAMP_AGENTS.RAW.TERRITORY_PERFORMANCE
UNION ALL SELECT 'HCP_TARGETING', COUNT(*) FROM SNOWCAMP_AGENTS.RAW.HCP_TARGETING
UNION ALL SELECT 'FIELD_NOTES', COUNT(*) FROM SNOWCAMP_AGENTS.RAW.FIELD_NOTES
ORDER BY row_count DESC;

