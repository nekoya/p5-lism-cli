use strict;
use warnings;

use Test::More tests => 3;

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

#$app->send_report_mail;
like $app->report, qr/\-{40}\n\n\[ERROR!\] DIEEEEEEE![^\n]+\n\n\-{40}/, 'assert error report log';
#$app->print_report;
