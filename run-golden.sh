#!/bin/bash
# Golden corpus runner for Phase 1 Step 1
# Usage: ./run-golden.sh <output-dir>
set -euo pipefail

OUTDIR="${1:?Usage: $0 <output-dir>}"
SESSION=""
BASE="http://127.0.0.1:8082/cgi-bin/HackDiet"

echo "=== Golden run into $OUTDIR ==="
# steps will be added here

echo "Building image from current checkout..."
docker compose build hackers-diet
echo "Image built."

echo "Restoring snapshot..."
sudo rsync -a --delete /var/tmp/hdo-phase1-snapshot/ ./hackdiet-data/
sudo chown -R www-data:www-data ./hackdiet-data
sudo chmod -R u+rwX,g+rwX ./hackdiet-data
echo "Snapshot restored and ownership fixed."

echo "Stopping any existing container..."
docker rm -f dev-hackers-diet 2>/dev/null || true

echo "Starting container under frozen clock..."
docker compose run -d \
  -e LD_PRELOAD=/usr/lib/aarch64-linux-gnu/faketime/libfaketime.so.1 \
  -e FAKETIME="2026-01-15 12:00:00" \
  --name dev-hackers-diet \
  --service-ports \
  hackers-diet

echo "Waiting for container to accept connections..."
for i in {1..30}; do
  if curl -sf -o /dev/null http://127.0.0.1:8082/cgi-bin/HackDiet; then
    echo "Container is up."
    break
  fi
  sleep 1
done

echo "Creating account golden1..."
curl -s -X POST \
  -d 'q=new_account' \
  -d 'HDiet_username=golden1' \
  -d 'HDiet_password=Golden1Test!' \
  -d 'HDiet_rpassword=Golden1Test!' \
  -d 'HDiet_email=golden@goldentest.com' \
  -d 'HDiet_wunit=0' \
  -d 'HDiet_dunit=0' \
  -d 'login=Create Account' \
  "$BASE" > /dev/null
echo "Account created."

echo "Logging in and capturing session..."
SESSION=$(curl -s -X POST \
  -d 'q=validate_user' \
  -d 'HDiet_username=golden1' \
  -d 'HDiet_password=Golden1Test!' \
  -d 'login=Sign In' \
  "$BASE" \
  | grep -oE 's=[A-Za-z0-9]{10,}' \
  | head -1 \
  | cut -d= -f2)
echo "Session: $SESSION"

echo "Writing December 2025 day 10..."
curl -s -X POST -d 'q=update_log' -d "s=$SESSION" -d 'm=2025-12' \
  -d 'w10=83.0' -d 'c10=golden december' "$BASE" > /dev/null
echo "December write done."

echo "Writing January days..."
curl -s -X POST -d 'q=update_log' -d "s=$SESSION" -d 'm=2026-01' \
  -d 'w15=82.5' -d 'f15=1' -d 'c15=golden flag comment' "$BASE" > /dev/null
curl -s -X POST -d 'q=update_log' -d "s=$SESSION" -d 'm=2026-01' \
  -d 'f15=1' -d 'w16=82.3' "$BASE" > /dev/null
curl -s -X POST -d 'q=update_log' -d "s=$SESSION" -d 'm=2026-01' \
  -d 'f15=1' -d 'c17=golden comment only' "$BASE" > /dev/null
curl -s -X POST -d 'q=update_log' -d "s=$SESSION" -d 'm=2026-01' \
  -d 'f15=1' -d 'w31=82.0' -d 'c31=end of january' "$BASE" > /dev/null
echo "January writes done."

echo "Writing February day 1..."
curl -s -X POST -d 'q=update_log' -d "s=$SESSION" -d 'm=2026-02' \
  -d 'w1=81.8' -d 'c1=start of february' "$BASE" > /dev/null
echo "February write done."

echo "Writing April days 2 and 5 (March left empty)..."
curl -s -X POST -d 'q=update_log' -d "s=$SESSION" -d 'm=2026-04' \
  -d 'w2=81.6' -d 'w5=81.2' -d 'c5=golden april' "$BASE" > /dev/null
echo "April write done."

echo "Fetching empty March view..."
mkdir -p "$OUTDIR"
curl -s -o "$OUTDIR/view-mar.html" \
  "$BASE?s=$SESSION&q=log&m=2026-03"
echo "March view saved."

echo "Extracting remaining oracles..."
curl -s -o "$OUTDIR/export-jan.xml" \
  "$BASE?s=$SESSION&q=xmlout&m=2026-01"
curl -s -o "$OUTDIR/view-jan.html" \
  "$BASE?s=$SESSION&q=log&m=2026-01"
curl -s -o "$OUTDIR/view-trend.html" \
  "$BASE?s=$SESSION&q=trendan"
curl -s -o "$OUTDIR/view-cal.html" \
  "$BASE?s=$SESSION&q=calendar"
curl -s -o "$OUTDIR/chart-jan.png" \
  "$BASE?s=$SESSION&q=chart&m=2026-01"
curl -s -o "$OUTDIR/view-feb.html" \
  "$BASE?s=$SESSION&q=log&m=2026-02"
curl -s -o "$OUTDIR/view-apr.html" \
  "$BASE?s=$SESSION&q=log&m=2026-04"
curl -s -o "$OUTDIR/chart-hist.png" \
  "$BASE?s=$SESSION&q=histchart&start=2025-12-01&end=2026-04-30&width=640&height=480"

cp hackdiet-data/Users/golden1/2025-12.hdb "$OUTDIR/"
cp hackdiet-data/Users/golden1/2026-01.hdb "$OUTDIR/"
cp hackdiet-data/Users/golden1/2026-02.hdb "$OUTDIR/"
cp hackdiet-data/Users/golden1/2026-04.hdb "$OUTDIR/"

cd "$OUTDIR"
sha256sum 2025-12.hdb 2026-01.hdb 2026-02.hdb 2026-04.hdb export-jan.xml \
  view-jan.html view-trend.html view-cal.html view-mar.html chart-jan.png \
  view-feb.html view-apr.html chart-hist.png \
  > SHA256SUMS.txt
echo "Oracles and SHA256SUMS.txt written to $OUTDIR"
