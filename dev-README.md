# The Word of Mouth Diet *Online* - development branch

The goal is to rebuild the website to become a modern webapp with responsive layout, modern Javascript, beautiful graphs and a modern database backend but which retains the core logic of John Walker's website, particularly the exponential moving average graphs.

Status, known bugs and next steps are in `dev-TODO.md`.

## Storage layer

Every read and write of user data goes through `src/HDiet/Store.pm`,
ready for a SQLite backend (reads moved as of 3c53c3a, writes in
d89e594 through 63d39ee). Do not add direct open, opendir, sysopen,
unlink, mkdir, -f or -d calls, tar or rm -rf on Users/, Sessions/,
RememberMe/, Pubname/ or Backups/; add a Store method instead.

### Methods
- Reads: read_month, list_months, read_user, read_session,
  read_active_session, list_sessions, read_cookie, list_cookies,
  read_pubname, list_pubnames, read_last_transaction, list_users,
  has_user, has_session, has_pubname, has_month.
- Writes: write_last_transaction, write_last_login, append_history,
  write_session, write_active_session, delete_session,
  delete_active_session, write_cookie, delete_cookie, create_user,
  write_user, write_month, create_pubname, delete_pubname,
  backup_user, delete_month, delete_user.

### Conventions
- read_X returns the loaded object, or undef if the file is missing or
  cannot be opened; the caller keeps its own die or fallback message.
- list_X dies "Cannot open directory $dir" and returns ids in readdir
  order. list_sessions and list_cookies match only ^\w+\.hds$ and
  ^\w+\.hdr$, the one deliberate tightening; every other method keeps
  the exact old match and behaviour.
- read_last_transaction returns 0 instead of undef, as
  last_transaction_time always did.
- write_X returns 1, or 0 if the file cannot be opened; the caller keeps
  its own die. delete_X returns unlink's result, create_user returns
  mkdir's result.
- create_pubname uses sysopen with O_EXCL, so claiming a name is
  atomic; it returns 0 if the name is taken.
- backup_user and delete_user run their tar and rm -rf through
  main::do_command, so --test and --verbose still apply.
- The write methods are the one place every write goes through, so the
  SQLite shadow hooks in there.
- Passwords stay in UserAccount.hdu.

### Left out of Store on purpose
- Out of scope (the operator does not care about these): spell-check
  and its temp file, badges (BadgeImage.png, and history.pm writing
  BadgeImageNew.png) and invitations (.hdi checks, create and unlink).
- Legacy cluster sync was removed entirely (aeb99e3 and 655b06a); do
  not bring it back.
- Not user data: the random-name word lists in Pubname/, hdo.log
  appends, the /tmp new-account file and the sendmail pipes.

## Working on this branch

Small steps, each one tested before commit. After each change, check
syntax inside the container, then run the golden corpus:

```bash
docker compose exec hackers-diet perl -c -I/server/bin/httpd/cgi-bin /server/bin/httpd/cgi-bin/HackDiet.pl
./run-golden.sh
./compare-golden.sh
```

The operator writes and pushes commits. Never commit secrets.env or
docker-compose.override.yml, and never force-push. Build stamps go
only in src/buildno.txt and the two copies in src/HackDiet.pl.

## Golden corpus

A deterministic golden-output corpus, generated under a frozen clock,
checks that storage and calculation changes do not change what the
site writes or shows.

### Frozen clock
- `FAKETIME="2026-01-15 12:00:00"`
- `LD_PRELOAD=/usr/lib/aarch64-linux-gnu/faketime/libfaketime.so.1`
- Both are passed by `run-golden.sh` via `docker compose run -e ...`.
  The image contains libfaketime for this (temporary; see dev-TODO.md).

### Reference artefacts
- `TEST_SCENARIO.md`: the account strings and operational notes
  (permissions after rsync, getting files out with `docker exec cat`).
- `golden-run-1/`: the frozen reference corpus (read-only), with
  `SHA256SUMS.txt`.

### Runner and comparator
Run both from the checkout root.

```bash
# rebuild the image, restore the snapshot and write a fresh corpus
# into test-run-temp/ (it refuses to overwrite an existing directory)
./run-golden.sh

# compare test-run-temp/ against golden-run-1/; HTML is normalized for
# session tokens and qx= cache-busters, everything else is exact
./compare-golden.sh
```

A clean comparison exits 0, prints "All oracles match (after
normalization).", and deletes `test-run-temp/`. Both scripts also
take directories as arguments; see the usage line at the top of each.

### What is covered
Account creation and login; writes in December, January, February and
April with March left empty; the log, trend and calendar views and
the charts; XML export, and XML import both into a missing month and
into a month that already has days; session replacement on a second
login; remember-me login and cookie replay; public names, the public
list and a public month view.

There are 28 oracles, and the compare must stay "all 28 match".

Not covered, so review diffs of these by hand: admin pages (acctmgr,
globalstats and HDiet::Aggregator), password reset, the session
manager, is_user_session_open, the cookie-cleanup loops, deleting all
logs and closing an account. Deleting all logs and closing an account
were last tested by hand on 2026-11-17 (backup written, months
removed, account directory removed).
