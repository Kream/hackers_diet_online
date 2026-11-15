package HDiet::Store;

use strict;
use warnings;
use HDiet::monthlog;

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

1;
