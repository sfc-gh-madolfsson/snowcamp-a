# Ship a Streamlit-in-Snowflake app on SPCS

Every track ends the same way: **turn your work into a Streamlit-in-Snowflake app running on Snowpark Container Services (SPCS)** — no Docker, no image build, all inside Snowsight. You choose the ambition level:

- **Option 1 — Results view (recommended if you're tight on time):** one focused page that visualizes what your track produced.
- **Option 2 — Full app:** a richer, multi-page app with filters, drill-downs, and actions.

Both options deploy the same way. The point is the **deployment on the container runtime** — though this time the app is also where you show your requirements were met.

---

## What "on SPCS" means here
Streamlit-in-Snowflake can run on either a virtual warehouse *or* a **container runtime**. The container runtime **is** Snowpark Container Services: Snowflake runs your app in a managed container on a **compute pool** — you never build or push a Docker image. That is the deployment we want.

## The three settings that put it on SPCS
When you create/deploy the Streamlit app, specify:

| Setting | Value | Why |
|---|---|---|
| `RUNTIME_NAME` | `SYSTEM$ST_CONTAINER_RUNTIME_PY3_11` | Selects the **container runtime** (SPCS) instead of a warehouse |
| `COMPUTE_POOL` | your track's pool (e.g. `SNOWCAMP_AGENTS_POOL`) | The SPCS compute that runs the container |
| `QUERY_WAREHOUSE` | your track's warehouse (e.g. `SNOWCAMP_AGENTS_WH`) | Runs the SQL your app issues |

Your provisioning script already created the pool and warehouse, so these exist.

## How to drive it with Cortex Code (exploratory — your wording may differ)
1. Ask it to **build the app** (describe the UI you want and the data/objects it should read).
2. Ask it to **deploy on the container runtime** with the three settings above, and to give you the **app URL**.
3. **Iterate**: ask for one change (a filter, a chart, a page) and redeploy.

Skill hints: `/developing-with-streamlit-in-snowflake` and `/cortex-chart-customization`.

## Validate
- The app is **live on the container runtime** (visible under Projects > Streamlit) and opens at its URL.
- It renders your track's result (or responds in the UI).
- If it's slow to open the first time, the **compute pool is resuming** — check `DESCRIBE COMPUTE POOL <your_pool>` and wait for `ACTIVE`/`IDLE`.

## Common gotchas
- **Privileges:** you're already ACCOUNTADMIN, so a deploy failure is usually a missing **grant** on the pool/warehouse/objects — ask Cortex Code to add it rather than switching roles.
- **Pool not ready:** first launch can take a minute while the pool starts. That's expected.
- **App can't read data:** confirm the app's role can `SELECT` the objects (and `REFERENCES` on any semantic view it queries via an agent).
