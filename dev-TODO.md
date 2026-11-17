- Temporary: libfaketime and curl added to the dev image for Phase 1 Step 1 corpus runs under a fixed clock. Remove both once the golden outputs are captured and the clock method is no longer needed.

- Temporary: validMailDomain in src/HackDiet.pl stubbed to always return 1 for Phase 1 Step 1 corpus runs under libfaketime (dig hangs). Mail is unused on dev. Restore the original after golden outputs are captured.





- Remember HDiet::Aggregator (src/HDiet/Aggregator.pm). It powers the admin-only Global Statistics page (q=globalstats) and is the only code that reads every user's months at once, so the SQLite backend must serve it too. All its reads now go through HDiet::Store (read_month, read_user, list_users). The golden harness does not cover globalstats (needs an admin login). Pre-existing bug: when a month file is missing, retrieve() does not advance $j, so later days get the wrong dates until the next January resync. (jig.pl, which imported it but never called it, was removed from dev.)

- src/Makefile and src/Makefile.mkf are dead upstream build files: they build everything from hdiet.w, which is not in this repo, and still list the removed jig.pl. Decide whether to delete them.

- Trend carry-forward is stored with different digits depending on which path wrote the month last. The log save for a new month (HackDiet.pl around L4797-4810) stores the raw previous trend, e.g. 82.69685; propagate_trend (around L12940) stores sprintf("%.4f") with trailing zeros stripped, e.g. 82.6968. Same value, different text. The XML import round trip in the golden harness shows it: propagate_trend from "0000-00" rewrites April. Fixed in c02eced: the log save now formats it the same way. Months written before that still hold the raw text, so the file-vs-db shadow diff should compare carry-forward as a number, not text. Quirk kept on purpose: the trailing-zero strip only works when no other 0 comes before the trailing zeros, so 82.103 is stored as 82.1030, while 82.1000 becomes 82.1.

- READ SIDE OF THE STORAGE MIGRATION IS DONE (as of 3c53c3a). Every read of user data goes through src/HDiet/Store.pm. Do not add new direct open/opendir/-f/-d calls on Users/, Sessions/, RememberMe/ or Pubname/; add a Store method instead.

  Store methods: read_month, list_months, read_user, read_session, read_active_session, list_sessions, read_cookie, list_cookies, read_pubname, list_pubnames, read_last_transaction, list_users, has_user, has_session, has_pubname.

  Conventions: read_X returns the loaded object, or undef if the file is missing or cannot be opened, and the caller keeps its own die or fallback message unchanged. list_X dies "Cannot open directory $dir" and returns ids in readdir order. read_last_transaction returns 0 instead of undef, as last_transaction_time always did. Each method keeps the exact old match and behaviour; the only deliberate tightening is list_sessions and list_cookies, which match only ^\w+\.hds$ and ^\w+\.hdr$.

  Deliberately out of scope (the operator does not care about these): spell-check, cluster-sync, badges (.hdb existence checks, BadgeImage.png), invitations (.hdi). Not user data: the random-name word lists in Pubname/, hdo.log, sendmail, /tmp files.

- Still direct reads, to handle with the write step:
  - Every write (> and >> opens), the sysopen create in pubname.pm, unlinks, clusterCopy/clusterDelete, and rm -rf on account delete.
  - Three -f checks that guard an unlink + clusterDelete: HackDiet.pl around L10542 (RememberMe) and L11895 (Sessions), and cookie.pm around L207. Removing a guard would queue cluster deletes for files that do not exist.
  - The tar backups before destructive actions: four identical blocks running `tar cfj ... -C ../Users $user_file_name` via do_command (HackDiet.pl around L2116 wipe logs, L2518 delete account, L9379 admin purge, L9744 admin delete). With a SQLite backend a file tarball would miss db data; plan is a Store->backup_user grouped with the delete paths.

- Next steps of the migration plan, in order: add a SQLite shadow behind HDO_STORE_BACKEND; run a nightly file-vs-db diff that catches both missing-from-db and missing-from-files; NO DUAL-WRITE until that diff stays empty; then switch reads over. Passwords stay in UserAccount.hdu. Every days row carries its logged unit and calendar date. Compare trend carry-forward as a number (see the carry-forward note above).

- How to work on this repo: small steps, each one tested before commit. Test with ./run-golden.sh then ./compare-golden.sh (27 oracles; must stay "all 27 match"). Also run perl -c inside the container: docker compose exec hackers-diet perl -c -I/server/bin/httpd/cgi-bin /server/bin/httpd/cgi-bin/HackDiet.pl. Golden does NOT cover admin pages (acctmgr, globalstats/Aggregator), password reset, the session manager, is_user_session_open, or the cookie-cleanup loops, so review diffs of those by hand. The operator writes and pushes commits; never commit secrets.env or docker-compose.override.yml; never force-push; build stamps go only in src/buildno.txt and the two copies in src/HackDiet.pl.

REPORTED BY GROK BOT 2026-11-16

**CSV/XML import wipes existing months** ([L6729-6737](https://github.com/Kream/hackers_diet_online/blob/3d656b6fb848bfa4aee7b7fae4009d22c31b4834/src/HackDiet.pl#L6729-L6737) and the two copies after it). A blank month gets put in `%mondb` first, and the month loaded from disk never replaces it. The save loop then writes the blank one over the real file. In my test, a month with 30 weights was empty after importing 2 rows. Load the month first, then cache it.

**Medium:** the site-log weight change at [L4858-4865](https://github.com/Kream/hackers_diet_online/blob/3d656b6fb848bfa4aee7b7fae4009d22c31b4834/src/HackDiet.pl#L4858-L4865) still subtracts weights across months stored in different units (this is on master too). A lb month followed by a kg month shows a change of about −90 kg.

**Smaller things:**

- Every save re-reads the user's whole history.
- The very first weight ever gets marked "✪NLW".
- Users' comments go into a plain-text server log, so it's worth checking who can read it.
- `read_month` doesn't check its own arguments. Nothing can exploit that today, but checking would protect future callers.
- A few small cleanups: unused `new()` calls, `\` not being escaped in `quote_comment`, a double space in the log line, the hardcoded IST timestamp, `README.md` now being a symlink, and the temporary `libfaketime`/`curl` still in the Docker image.
