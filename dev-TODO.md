- Temporary: libfaketime and curl added to the dev image for Phase 1 Step 1 corpus runs under a fixed clock. Remove both once the golden outputs are captured and the clock method is no longer needed.

- Temporary: validMailDomain in src/HackDiet.pl stubbed to always return 1 for Phase 1 Step 1 corpus runs under libfaketime (dig hangs). Mail is unused on dev. Restore the original after golden outputs are captured.

- Remember HDiet::Aggregator (src/HDiet/Aggregator.pm). It powers the admin-only Global Statistics page (q=globalstats) and is the only code that reads every user's months at once, so the SQLite backend must serve it too. All its reads now go through HDiet::Store (read_month, read_user, list_users). The golden harness does not cover globalstats (needs an admin login). Pre-existing bug: when a month file is missing, retrieve() does not advance $j, so later days get the wrong dates until the next January resync. (jig.pl, which imported it but never called it, was removed from dev.)

- src/Makefile and src/Makefile.mkf are dead upstream build files: they build everything from hdiet.w, which is not in this repo, and still list the removed jig.pl, Cluster.pm and ClusterSync.pl. Decide whether to delete them.

- Trend carry-forward is stored with different digits depending on which path wrote the month last. The log save for a new month (HackDiet.pl around L4797-4810) stores the raw previous trend, e.g. 82.69685; propagate_trend (around L12940) stores sprintf("%.4f") with trailing zeros stripped, e.g. 82.6968. Same value, different text. The XML import round trip in the golden harness shows it: propagate_trend from "0000-00" rewrites April. Fixed in c02eced: the log save now formats it the same way. Months written before that still hold the raw text, so the file-vs-db shadow diff should compare carry-forward as a number, not text. Quirk kept on purpose: the trailing-zero strip only works when no other 0 comes before the trailing zeros, so 82.103 is stored as 82.1030, while 82.1000 becomes 82.1.

- Store layout, conventions and what is left out of Store on purpose are in dev-README.md.

- backup_user tars the Users/<user> files. Once SQLite holds data, it must also dump that user's db rows into the backup, or a restore would lose them.

- Next steps of the migration plan, in order: add a SQLite shadow behind HDO_STORE_BACKEND; run a nightly file-vs-db diff that catches both missing-from-db and missing-from-files; NO DUAL-WRITE until that diff stays empty; then switch reads over. Passwords stay in UserAccount.hdu. Every days row carries its logged unit and calendar date. Compare trend carry-forward as a number (see the carry-forward note above).

REPORTED BY GROK BOT 2026-11-16

**FIXED in b0ccfad: CSV/XML import wiped existing months** ([L6729-6737](https://github.com/Kream/hackers_diet_online/blob/3d656b6fb848bfa4aee7b7fae4009d22c31b4834/src/HackDiet.pl#L6729-L6737) and the two copies after it). A blank month gets put in `%mondb` first, and the month loaded from disk never replaces it. The save loop then writes the blank one over the real file. In my test, a month with 30 weights was empty after importing 2 rows. Load the month first, then cache it. Golden now checks this (import-existing-check.txt, added in c037399).

**Medium:** the site-log weight change at [L4858-4865](https://github.com/Kream/hackers_diet_online/blob/3d656b6fb848bfa4aee7b7fae4009d22c31b4834/src/HackDiet.pl#L4858-L4865) still subtracts weights across months stored in different units (this is on master too). A lb month followed by a kg month shows a change of about −90 kg.

**Smaller things:**

- Every save re-reads the user's whole history.
- The very first weight ever gets marked "✪NLW". Intentional, not a bug.
- Users' comments go into a plain-text server log, so it's worth checking who can read it. Intentional: hdo.log is forwarded to Telegram by ~/hdo_notify.
- `read_month` doesn't check its own arguments. Nothing can exploit that today, but checking would protect future callers.
- A few small cleanups: unused `new()` calls, `\` not being escaped in `quote_comment`, a double space in the log line, the hardcoded IST timestamp (intentional, keep it), `README.md` now being a symlink, and the temporary `libfaketime`/`curl` still in the Docker image.
- The image had no bzip2, so every tar cfj backup before deleting logs or closing an account was a 0-byte file. Fixed on dev in f4629fb. test and www are built from the same Dockerfile and probably still make empty backups.
