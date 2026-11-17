#!/bin/bash
# Golden corpus runner for Phase 1 Step 1
# Usage: ./run-golden.sh [output-dir]   (default: test-run-temp)
set -euo pipefail

OUTDIR="${1:-test-run-temp}"

# Never write into an existing directory: it may be golden-run-1, or a
# failed run you still want to look at, and stale files would mix in.
if [[ -e "$OUTDIR" ]]; then
  echo "$OUTDIR already exists. Look at it or remove it first (rm -r $OUTDIR)," >&2
  echo "or give another directory: $0 <output-dir>" >&2
  exit 1
fi
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
sudo rm -f ./hackdiet-data/Pubname/*.hdp
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

echo "Logging in again to test session replacement..."
SESSION2=$(curl -s -X POST \
  -d 'q=validate_user' \
  -d 'HDiet_username=golden1' \
  -d 'HDiet_password=Golden1Test!' \
  -d 'login=Sign In' \
  "$BASE" \
  | grep -oE 's=[A-Za-z0-9]{10,}' \
  | head -1 \
  | cut -d= -f2)
echo "Second session: $SESSION2"
curl -s -o "$OUTDIR/session-old.html" \
  "$BASE?s=$SESSION&q=log&m=2026-01"
{
  if [[ "$(sed -n 2p hackdiet-data/Users/golden1/ActiveSession.hda)" == "$SESSION2" ]]; then
    echo "active_session_is_second_login=yes"
  else
    echo "active_session_is_second_login=no"
  fi
  if [[ -f "hackdiet-data/Sessions/$SESSION.hds" ]]; then
    echo "old_session_file=present"
  else
    echo "old_session_file=absent"
  fi
  if [[ -f "hackdiet-data/Sessions/$SESSION2.hds" ]]; then
    echo "new_session_file=present"
  else
    echo "new_session_file=absent"
  fi
} > "$OUTDIR/session-check.txt"
echo "Session replacement checked."

echo "Testing remember-me..."
# Log in with "Remember me" ticked. The cookie is set by JavaScript in the page
# (document.cookie = 'HDiet=...'), not a Set-Cookie header, so read it from the HTML.
curl -s -o "$OUTDIR/remember-login.html" -X POST \
  -d 'q=validate_user' \
  -d 'HDiet_username=golden1' \
  -d 'HDiet_password=Golden1Test!' \
  -d 'HDiet_remember=y' \
  -d 'login=Sign In' \
  "$BASE"
COOKIE1=$(grep -oE 'HDiet=[0-9FGJKQW]{48}' "$OUTDIR/remember-login.html" | head -1 | cut -d= -f2 || true)
# The file name is the cookie with its 8-character signature (positions 23-30) removed
CID1="${COOKIE1:0:23}${COOKIE1:31}"
FIRST_FILE=absent
[[ -n "$COOKIE1" && -f "hackdiet-data/RememberMe/$CID1.hdr" ]] && FIRST_FILE=present

# Come back with only the cookie: no session, no q, like a returning browser
curl -s -o "$OUTDIR/remember-cookie-login.html" \
  -H "Cookie: HDiet=$COOKIE1" "$BASE"
SESSION4=$(grep -oE 's=[A-Za-z0-9]{10,}' "$OUTDIR/remember-cookie-login.html" | head -1 | cut -d= -f2 || true)
COOKIE2=$(grep -oE 'HDiet=[0-9FGJKQW]{48}' "$OUTDIR/remember-cookie-login.html" | head -1 | cut -d= -f2 || true)
CID2="${COOKIE2:0:23}${COOKIE2:31}"

# Replay the first cookie: it should have been used up
curl -s -o "$OUTDIR/remember-replay.html" \
  -H "Cookie: HDiet=$COOKIE1" "$BASE"

{
  [[ -n "$COOKIE1" ]] && echo "first_cookie_issued=yes" || echo "first_cookie_issued=no"
  echo "first_cookie_file_after_login=$FIRST_FILE"
  if [[ -n "$SESSION4" && -f "hackdiet-data/Sessions/$SESSION4.hds" ]]; then
    echo "logged_in_by_cookie=yes"
  else
    echo "logged_in_by_cookie=no"
  fi
  if [[ -n "$COOKIE1" && -f "hackdiet-data/RememberMe/$CID1.hdr" ]]; then
    echo "first_cookie_file_after_use=present"
  else
    echo "first_cookie_file_after_use=absent"
  fi
  if [[ -n "$COOKIE2" && "$COOKIE2" != "$COOKIE1" ]]; then
    echo "new_cookie_issued=yes"
  else
    echo "new_cookie_issued=no"
  fi
  if [[ -n "$COOKIE2" && -f "hackdiet-data/RememberMe/$CID2.hdr" ]]; then
    echo "new_cookie_file=present"
  else
    echo "new_cookie_file=absent"
  fi
  if grep -q '<title>[^<]*Please Sign In' "$OUTDIR/remember-replay.html"; then
    echo "replayed_cookie_gets_sign_in=yes"
  else
    echo "replayed_cookie_gets_sign_in=no"
  fi
} > "$OUTDIR/remember-check.txt"
echo "Remember-me checked."

echo "Testing public names..."
# edit_account replaces every setting with what the form sends, so send the same
# values golden1 was created with. Fields left out (names, height, energy unit,
# decimal character, password) come back the same as at creation.
curl -s -o "$OUTDIR/pub-settings.html" -X POST \
  -d 'q=edit_account' \
  -d "s=$SESSION4" \
  -d 'HDiet_email=golden@goldentest.com' \
  -d 'HDiet_wunit=0' \
  -d 'HDiet_dunit=0' \
  -d 'HDiet_public=on' \
  "$BASE"

# Line 2 of the .hdp file is the pseudonym, line 3 the real user name
PUBFILE=$(ls hackdiet-data/Pubname/*.hdp 2>/dev/null | head -1 || true)
PUBNAME=""
PUBTRUE=""
if [[ -n "$PUBFILE" ]]; then
  PUBNAME=$(sed -n 2p "$PUBFILE")
  PUBTRUE=$(sed -n 3p "$PUBFILE")
fi

# The public list (default view is active accounts)
curl -s -o "$OUTDIR/pub-browse.html" "$BASE?q=browsepub&s=$SESSION4"

# Pick golden1's pseudonym from the list, the way the Access button does
curl -s -o "$OUTDIR/pub-account.html" -X POST \
  -d 'q=do_public_browseacct' \
  -d "s=$SESSION4" \
  --data-urlencode "pubacct=$PUBNAME" \
  "$BASE"

# A month log as the public sees it
curl -s -o "$OUTDIR/pub-view-jan.html" "$BASE?q=log&m=2026-01&s=$SESSION4"

{
  echo "pubname_files=$(ls hackdiet-data/Pubname/*.hdp 2>/dev/null | wc -l)"
  echo "pubname_true_name=$PUBTRUE"
  if [[ -n "$PUBNAME" ]] && grep -qF "$PUBNAME" "$OUTDIR/pub-browse.html"; then
    echo "listed_in_browse=yes"
  else
    echo "listed_in_browse=no"
  fi
  if grep -q 'Browsing public account' "$OUTDIR/pub-view-jan.html"; then
    echo "browsing_banner_on_log=yes"
  else
    echo "browsing_banner_on_log=no"
  fi
} > "$OUTDIR/pub-check.txt"

# The pseudonym is random: swap it for PUBNAME, both as written and with + for spaces
if [[ -n "$PUBNAME" ]]; then
  PN="$PUBNAME" PNPLUS="${PUBNAME// /+}" perl -pi -e 's/\Q$ENV{PN}\E/PUBNAME/g; s/\Q$ENV{PNPLUS}\E/PUBNAME/g' \
    "$OUTDIR/pub-settings.html" "$OUTDIR/pub-browse.html" \
    "$OUTDIR/pub-account.html" "$OUTDIR/pub-view-jan.html"
fi
echo "Public names checked."

echo "Testing XML import round trip..."
# Leave public browsing, since import is not allowed while browsing
curl -s -o /dev/null -X POST \
  -d 'q=quitbrowse' \
  -d "s=$SESSION4" \
  "$BASE"

# Remember January as the site wrote it, then lose it, like a month restored from backup
ORIG_JAN=$(sha256sum < hackdiet-data/Users/golden1/2026-01.hdb)
sudo rm hackdiet-data/Users/golden1/2026-01.hdb

# Paste the earlier export into the import form's text box. -F sends multipart like
# the browser form, and "file=<path" sends the file's contents as the field value.
curl -s -o "$OUTDIR/import-jan.html" \
  -F 'q=csv_import_data' \
  -F "s=$SESSION4" \
  -F "file=<$OUTDIR/export-jan.xml" \
  "$BASE"

{
  if [[ -f hackdiet-data/Users/golden1/2026-01.hdb ]]; then
    echo "jan_file_after_import=present"
    if [[ "$(sha256sum < hackdiet-data/Users/golden1/2026-01.hdb)" == "$ORIG_JAN" ]]; then
      echo "reimport_matches_original=yes"
    else
      echo "reimport_matches_original=no"
    fi
  else
    echo "jan_file_after_import=absent"
    echo "reimport_matches_original=no"
  fi
} > "$OUTDIR/import-check.txt"
echo "XML import checked."

cp hackdiet-data/Users/golden1/2025-12.hdb "$OUTDIR/"
cp hackdiet-data/Users/golden1/2026-01.hdb "$OUTDIR/"
cp hackdiet-data/Users/golden1/2026-02.hdb "$OUTDIR/"
cp hackdiet-data/Users/golden1/2026-04.hdb "$OUTDIR/"
cp hackdiet-data/Users/golden1/LastTransaction.hdl "$OUTDIR/"

cd "$OUTDIR"
sha256sum 2025-12.hdb 2026-01.hdb 2026-02.hdb 2026-04.hdb export-jan.xml \
  view-jan.html view-trend.html view-cal.html view-mar.html chart-jan.png \
  view-feb.html view-apr.html chart-hist.png \
  LastTransaction.hdl session-check.txt session-old.html \
  remember-check.txt remember-login.html remember-cookie-login.html remember-replay.html \
  pub-check.txt pub-settings.html pub-browse.html pub-account.html pub-view-jan.html \
  import-check.txt import-jan.html \
  > SHA256SUMS.txt
echo "Oracles and SHA256SUMS.txt written to $OUTDIR"
