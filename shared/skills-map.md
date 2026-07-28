# Skills map — what to reach for, and when

Type `/` in Cortex Code to invoke a skill. These are **hints**, not requirements — explore freely. Each gate lists the one or two that actually fit that step.

## Useful on any track
| Skill | Reach for it when you want to... |
|---|---|
| `/cortex-code-guide` | Learn what Cortex Code can do, how `@` context and `/` skills work |
| `/sql-author` | Explore or query real tables — it finds the right tables/columns and avoids timeouts on big data |
| `/data-quality` | Profile data and quantify defects (nulls, dupes, out-of-range), then monitor them with DMFs |
| `/developing-with-streamlit-in-snowflake` | Build and deploy the Final-Gate Streamlit app on SPCS |
| `/snowflake-diagnostics` | **Troubleshooting only** — roles, grants, "not authorized" errors, warehouse/compute-pool status |

## Track A — AI Agents
| Skill | Reach for it when you want to... |
|---|---|
| `/semantic-view` | Build + validate the semantic view Cortex Analyst answers from |
| `/data-governance` | Classify PII and apply the masking policy so the agent can't leak identifiers |
| `/search-optimization` | Stand up the Cortex Search service over the field notes |
| `/cortex-agent` | Create the agent: its tools, orchestration and response instructions |
| `/agent-optimization` | Audit/tune tool descriptions and fix wrong tool selection |
| `/cortex-chart-customization` | Shape the charts the **agent** returns (agent / semantic-model chart config) |

## Track B — ML
| Skill | Reach for it when you want to... |
|---|---|
| `/machine-learning` | The whole ML path — feature engineering, training, Model Registry, scoring, evaluation |
| `/snowpark-python` | Write the feature/label transforms as Snowpark DataFrames at scale |
| `/snowflake-notebooks` | Author the Workspace notebook you build the model in |
| `/data-quality` | Quantify and clean the planted issues before training |
| `/snowflake-tasks` | *(stretch)* schedule periodic re-scoring |

## Track C — Data Engineering & Governance
| Skill | Reach for it when you want to... |
|---|---|
| `/data-quality` | Profile the defects, then attach + run DMFs to monitor them |
| `/data-governance` | Classify PII, apply masking (and optionally row-access) policies |
| `/snowpark-python` | Heavier reconciliation work — normalising keys, dedupe, survivorship at scale |
| `/dynamic-tables` | Build the incremental RAW → curated mart pipeline with a target lag |
| `/lineage` | Verify where the curated mart's data actually comes from |
| `/snowflake-tasks` | Schedule pipeline work or alert when a quality check breaches |

## The bonus (all tracks)
| Skill | Reach for it when you want to... |
|---|---|
| `/skill-development` | Package the workflow you just built into your own reusable skill |
| `/skill-architect` | Design it as a bigger multi-phase workflow if it has several distinct stages |
