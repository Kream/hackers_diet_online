package HDiet::Store;

use strict;
use warnings;
use HDiet::monthlog;
use HDiet::user ();
use HDiet::session ();
use HDiet::cookie ();
use HDiet::pubname ();

# File-backed month-log storage.
# read_month returns a loaded HDiet::monthlog object,
# or undef if the .hdb file does not exist.
# Behaviour must match the existing direct open/load.

sub read_month {
    my ($class, $user_file_name, $year_month) = @_;

    my $path = "/server/pub/hackdiet/Users/$user_file_name/$year_month.hdb";
    return undef unless -f $path;

    my $mlog = HDiet::monthlog->new();
    open(my $fh, "<:utf8", $path)
        or die "Cannot open monthly log file $path: $!";
    $mlog->load($fh);
    close($fh);

    return $mlog;
}

# list_months returns the user's month keys ("YYYY-MM"), sorted,
# for every .hdb file in their directory, or only those in $year if given.
# Copied from HDiet::user::enumerateMonths so behaviour is identical,
# including its quirks: $year is used as a regex, and the pattern is not
# anchored after ".hdb".
sub list_months {
    my ($class, $user_file_name, $year) = @_;

    my $dir = "/server/pub/hackdiet/Users/$user_file_name";
    my $selpat = $year ? $year : '\d+';

    opendir(my $dh, $dir)
        or die("Cannot open directory $dir");
    my @logs;
    foreach my $f (sort(grep(/^$selpat\-\d\d\.hdb/, readdir($dh)))) {
        $f =~ s/\.\w*$//;
        push(@logs, $f);
    }
    closedir($dh);

    return @logs;
}

# read_user returns a loaded HDiet::user object for UserAccount.hdu,
# or undef if the file does not exist or cannot be opened. Callers keep their own die
# or fallback, so error messages stay exactly as they were.
sub read_user {
    my ($class, $user_file_name) = @_;

    my $path = "/server/pub/hackdiet/Users/$user_file_name/UserAccount.hdu";
    return undef unless -f $path;
    open(my $fh, "<:utf8", $path) or return undef;
    my $ui = HDiet::user->new();
    $ui->load($fh);
    close($fh);

    return $ui;
}

# read_session returns a loaded HDiet::session object for Sessions/<id>.hds,
# or undef if the file does not exist or cannot be opened.
sub read_session {
    my ($class, $session_id) = @_;

    my $path = "/server/pub/hackdiet/Sessions/$session_id.hds";
    return undef unless -f $path;
    open(my $fh, "<:utf8", $path) or return undef;
    my $session = HDiet::session->new();
    $session->load($fh);
    close($fh);

    return $session;
}

# read_active_session returns the session id stored in the user's
# ActiveSession.hda, or undef if the file does not exist or cannot be opened.
sub read_active_session {
    my ($class, $user_file_name) = @_;

    my $path = "/server/pub/hackdiet/Users/$user_file_name/ActiveSession.hda";
    return undef unless -f $path;
    open(my $fh, "<:utf8", $path) or return undef;
    my $asn = HDiet::session::load_active_session($fh);
    close($fh);

    return $asn;
}

# list_sessions returns the ids of all sessions in the Sessions directory,
# in readdir order. Only files named <word chars>.hds are listed; the old
# loops matched /\w+\.hds/ anywhere in the name, which would also have
# picked up stray files such as backups.
sub list_sessions {
    my ($class) = @_;

    my $dir = "/server/pub/hackdiet/Sessions";
    opendir(my $dh, $dir)
        or die("Cannot open directory $dir");
    my @ids = map { /^(\w+)\.hds$/ ? $1 : () } readdir($dh);
    closedir($dh);

    return @ids;
}

# read_cookie returns a loaded HDiet::cookie object for RememberMe/<id>.hdr,
# or undef if the file does not exist or cannot be opened.
sub read_cookie {
    my ($class, $cookie_id) = @_;

    my $path = "/server/pub/hackdiet/RememberMe/$cookie_id.hdr";
    return undef unless -f $path;
    open(my $fh, "<:utf8", $path) or return undef;
    my $cookie = HDiet::cookie->new();
    $cookie->load($fh);
    close($fh);

    return $cookie;
}

# list_cookies returns the ids of all remember-me cookies in RememberMe/,
# in readdir order. Like list_sessions, only files named exactly
# <word chars>.hdr are listed.
sub list_cookies {
    my ($class) = @_;

    my $dir = "/server/pub/hackdiet/RememberMe";
    opendir(my $dh, $dir)
        or die("Cannot open directory $dir");
    my @ids = map { /^(\w+)\.hdr$/ ? $1 : () } readdir($dh);
    closedir($dh);

    return @ids;
}

# read_pubname returns a loaded HDiet::pubname object for Pubname/<file>.hdp,
# where <file> is the public name already quoted with quoteUserName,
# or undef if the file does not exist or cannot be opened.
sub read_pubname {
    my ($class, $pub_file_name) = @_;

    my $path = "/server/pub/hackdiet/Pubname/$pub_file_name.hdp";
    return undef unless -f $path;
    open(my $fh, "<:utf8", $path) or return undef;
    my $pn = HDiet::pubname->new();
    $pn->load($fh);
    close($fh);

    return $pn;
}

# list_pubnames returns the quoted file names (without .hdp) of every
# public name in Pubname/, in readdir order. Same match as the old
# browse loop: any name ending in .hdp.
sub list_pubnames {
    my ($class) = @_;

    my $dir = "/server/pub/hackdiet/Pubname";
    opendir(my $dh, $dir)
        or die("Cannot open directory $dir");
    my @names = map { /^(.*)\.hdp$/ ? $1 : () } readdir($dh);
    closedir($dh);

    return @names;
}

# read_last_transaction returns the time (epoch seconds) stored in
# Users/<user>/LastTransaction.hdl, or 0 if the file cannot be opened,
# has the wrong version, or holds a non-numeric time. Like main::in,
# it dies if the file ends before a line it expects.
sub read_last_transaction {
    my ($class, $user_file_name) = @_;

    my $path = "/server/pub/hackdiet/Users/$user_file_name/LastTransaction.hdl";
    open(my $fh, "<:utf8", $path) or return 0;
    my $lt = 0;
    my $s = _line($fh);
    if ($s == 1) {          # Only proceed if version correct
        $s = _line($fh);
        if ($s =~ m/^\d+$/) {
            $lt = $s;
        }
    }
    close($fh);

    return $lt;
}

# list_users returns the directory names (quoted user names) in Users/,
# in readdir order. Same match as the old loops: anything not ending
# in . or .. (which drops the . and .. entries).
sub list_users {
    my ($class) = @_;

    my $dir = "/server/pub/hackdiet/Users";
    opendir(my $dh, $dir)
        or die("Cannot open directory $dir");
    my @names = grep { !/\.\.?\z/ } readdir($dh);
    closedir($dh);

    return @names;
}

# has_user is true if the account directory Users/<user> exists.
sub has_user {
    my ($class, $user_file_name) = @_;

    return -d "/server/pub/hackdiet/Users/$user_file_name";
}

# has_session is true if Sessions/<id>.hds exists.
sub has_session {
    my ($class, $session_id) = @_;

    return -f "/server/pub/hackdiet/Sessions/$session_id.hds";
}

# has_pubname is true if Pubname/<file>.hdp exists, where <file> is the
# public name already quoted with quoteUserName.
sub has_pubname {
    my ($class, $pub_file_name) = @_;

    return -f "/server/pub/hackdiet/Pubname/$pub_file_name.hdp";
}

# has_month is true if Users/<user>/<YYYY-MM>.hdb exists.
sub has_month {
    my ($class, $user_file_name, $year_month) = @_;

    return -f "/server/pub/hackdiet/Users/$user_file_name/$year_month.hdb";
}

# ---- Writes ----
# Each write method returns true on success, or false if the file cannot
# be opened, so the caller keeps its own die message.

# write_last_transaction stores <time> in Users/<user>/LastTransaction.hdl
# (version line 1, then the time).
sub write_last_transaction {
    my ($class, $user_file_name, $time) = @_;

    open(my $fh, ">:utf8", "/server/pub/hackdiet/Users/$user_file_name/LastTransaction.hdl")
        or return 0;
    print $fh "1\n$time\n";
    close($fh);

    return 1;
}

# write_last_login stores <time> in Users/<user>/LastLogin.hdl
# (version line 1, then the time).
sub write_last_login {
    my ($class, $user_file_name, $time) = @_;

    open(my $fh, ">:utf8", "/server/pub/hackdiet/Users/$user_file_name/LastLogin.hdl")
        or return 0;
    print $fh "1\n$time\n";
    close($fh);

    return 1;
}

# append_history appends one line (without its newline) to
# Users/<user>/History.hdh. The caller builds the line.
sub append_history {
    my ($class, $user_file_name, $line) = @_;

    open(my $fh, ">>:utf8", "/server/pub/hackdiet/Users/$user_file_name/History.hdh")
        or return 0;
    print $fh "$line\n";
    close($fh);

    return 1;
}

# write_session saves an HDiet::session object to Sessions/<id>.hds,
# using its own session_id.
sub write_session {
    my ($class, $session) = @_;

    open(my $fh, ">:utf8", "/server/pub/hackdiet/Sessions/$session->{session_id}.hds")
        or return 0;
    $session->save($fh);
    close($fh);

    return 1;
}

# write_active_session saves the back-link Users/<user>/ActiveSession.hda
# for an HDiet::session object.
sub write_active_session {
    my ($class, $user_file_name, $session) = @_;

    open(my $fh, ">:utf8", "/server/pub/hackdiet/Users/$user_file_name/ActiveSession.hda")
        or return 0;
    $session->save_active_session($fh);
    close($fh);

    return 1;
}

# delete_session removes Sessions/<id>.hds. Returns unlink's result;
# no caller checks it today.
sub delete_session {
    my ($class, $session_id) = @_;

    return unlink("/server/pub/hackdiet/Sessions/$session_id.hds");
}

# delete_active_session removes Users/<user>/ActiveSession.hda.
sub delete_active_session {
    my ($class, $user_file_name) = @_;

    return unlink("/server/pub/hackdiet/Users/$user_file_name/ActiveSession.hda");
}

# write_cookie saves an HDiet::cookie object to RememberMe/<id>.hdr,
# using its own cookie_id.
sub write_cookie {
    my ($class, $cookie) = @_;

    open(my $fh, ">:utf8", "/server/pub/hackdiet/RememberMe/$cookie->{cookie_id}.hdr")
        or return 0;
    $cookie->save($fh);
    close($fh);

    return 1;
}

# delete_cookie removes RememberMe/<id>.hdr. Returns unlink's result:
# 1 if a file was deleted, 0 if there was none.
sub delete_cookie {
    my ($class, $cookie_id) = @_;

    return unlink("/server/pub/hackdiet/RememberMe/$cookie_id.hdr");
}

# create_user makes the account directory Users/<user>. Returns mkdir's
# result: false if it already exists or cannot be made.
sub create_user {
    my ($class, $user_file_name) = @_;

    return mkdir("/server/pub/hackdiet/Users/$user_file_name");
}

# write_user saves an HDiet::user object (password included, as before)
# to Users/<user>/UserAccount.hdu.
sub write_user {
    my ($class, $user_file_name, $ui) = @_;

    open(my $fh, ">:utf8", "/server/pub/hackdiet/Users/$user_file_name/UserAccount.hdu")
        or return 0;
    $ui->save($fh);
    close($fh);

    return 1;
}

# write_month saves an HDiet::monthlog object to Users/<user>/<YYYY-MM>.hdb.
# The caller sets last_modification_time first, as before.
sub write_month {
    my ($class, $user_file_name, $year_month, $mlog) = @_;

    open(my $fh, ">:utf8", "/server/pub/hackdiet/Users/$user_file_name/$year_month.hdb")
        or return 0;
    $mlog->save($fh);
    close($fh);

    return 1;
}

# _line reads one line with trailing whitespace removed, dying at end of
# file with the same message as main::in.
sub _line {
    my ($fh) = @_;

    my $s = <$fh>;
    die("main::in: Unexpected end of file") unless defined($s);
    $s =~ s/\s+$//;
    return $s;
}

1;
