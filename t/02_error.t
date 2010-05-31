use strict;
use warnings;

use Test::More;
use FindBin::libs;

package Mock::App;
use Any::Moose;
extends 'Lism::CLI';

sub main {
    my ($self) = @_;
    Carp::croak 'DIEEEEEEE!';
}

package main;
ok my $app = Mock::App->new, 'create application object';
$app->run;
is $app->failed, 1, 'script failed';
is $app->error_level, 'crit', 'assert error_level';

like $app->report, qr/\-{40}\n\[error\] DIEEEEEEE![^\n]+\n\-{40}/, 'assert error report log';
note $app->report;

done_testing;
