package HDiet::Store;

use strict;
use warnings;
use HDiet::monthlog;
use HDiet::user ();

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

1;
