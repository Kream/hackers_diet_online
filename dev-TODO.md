- Temporary: libfaketime and curl added to the dev image for Phase 1 Step 1 corpus runs under a fixed clock. Remove both once the golden outputs are captured and the clock method is no longer needed.

- Temporary: validMailDomain in src/HackDiet.pl stubbed to always return 1 for Phase 1 Step 1 corpus runs under libfaketime (dig hangs). Mail is unused on dev. Restore the original after golden outputs are captured.





- Remember HDiet::Aggregator (src/HDiet/Aggregator.pm). It powers the admin-only Global Statistics page (q=globalstats) and is the only code that reads every user's months at once, so the SQLite backend must serve it too. Its .hdb reads now go through HDiet::Store->read_month; UserAccount.hdu reads and the readdir of Users/ are still direct. The golden harness does not cover globalstats (needs an admin login). Pre-existing bug: when a month file is missing, retrieve() does not advance $j, so later days get the wrong dates until the next January resync. jig.pl imports HDiet::Aggregator but never calls it.

REPORTED BY GROK BOT 2026-11-16

**CSV/XML import wipes existing months** ([L6729-6737](https://github.com/Kream/hackers_diet_online/blob/3d656b6fb848bfa4aee7b7fae4009d22c31b4834/src/HackDiet.pl#L6729-L6737) and the two copies after it). A blank month gets put in `%mondb` first, and the month loaded from disk never replaces it. The save loop then writes the blank one over the real file. In my test, a month with 30 weights was empty after importing 2 rows. Load the month first, then cache it.

**Medium:** the site-log weight change at [L4858-4865](https://github.com/Kream/hackers_diet_online/blob/3d656b6fb848bfa4aee7b7fae4009d22c31b4834/src/HackDiet.pl#L4858-L4865) still subtracts weights across months stored in different units (this is on master too). A lb month followed by a kg month shows a change of about −90 kg.

**Smaller things:**

- Every save re-reads the user's whole history.
- The very first weight ever gets marked "✪NLW".
- Users' comments go into a plain-text server log, so it's worth checking who can read it.
- `read_month` doesn't check its own arguments. Nothing can exploit that today, but checking would protect future callers.
- A few small cleanups: unused `new()` calls, `\` not being escaped in `quote_comment`, a double space in the log line, the hardcoded IST timestamp, `README.md` now being a symlink, and the temporary `libfaketime`/`curl` still in the Docker image.
