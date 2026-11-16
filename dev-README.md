# The Word of Mouth Diet *Online* - development branch

The goal is to rebuild the website to become a modern webapp with responsive layout, modern Javascript, beautiful graphs and a modern database backend but which retains the core logic of John Walker's website, particularly the exponential moving average graphs. 

## Phase 1 Step 1 — Golden corpus

A deterministic golden-output corpus exists for the monthly log path.
It is generated under a frozen clock so that later storage or
calculation changes can be validated without manual curl sequences.

### Frozen clock
- `FAKETIME="2026-01-15 12:00:00"`
- `LD_PRELOAD=/usr/lib/aarch64-linux-gnu/faketime/libfaketime.so.1`
- Both variables are injected by `run-golden.sh` via
  `docker compose run -e ...`. The container image already contains
  libfaketime (temporary; see dev-TODO.md).

### Reference artefacts
- `TEST_SCENARIO.md` — the exact scenario, account strings, write
  sequence, and operational notes (permissions after rsync, session
  in query string, extract with `docker exec cat` / curl, etc.).
- `golden-run-1/` — the frozen reference corpus (read-only).
  Contains the two `.hdb` files, `export-jan.xml`, the four HTML
  views, `chart-jan.png`, and `SHA256SUMS.txt`.

### Runner and comparator
```bash
# regenerate a fresh corpus (always starts from the snapshot)
./run-golden.sh test-output

# compare against the reference (HTML is normalized for session
# tokens and qx= cache-busters; .hdb/.xml/.png are exact)
./compare-golden.sh test-output golden-run-1Both scripts must be run from the checkout root. A clean comparison

exits 0 and prints “All oracles match (after normalization).”What is coveredAccount creation, login, January writes (weight+flag+comment,

weight-only, comment-only, end-of-month), February cross-month

boundary, empty March listing, XML export, log/trend/calendar views,

and the January chart PNG. Accounts, sessions, and history remain

on the filesystem; only the monthly logs are exercised.
