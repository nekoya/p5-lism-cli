use strict;
use warnings;

use Test::More;
use FindBin::libs;

package Mock::App;
use Any::Moose;
extends 'Lism::CLI';

sub main {
    my ($self) = @_;
    $self->log("hogehoge\nfuga\n");
}

package main;
ok my $app = Mock::App->new, 'create application object';
$app->run;
is $app->failed, 0, 'script succeeded';
is $app->error_level, 'notice', 'assert error_level';

like $app->report, qr/\-{40}\nhogehoge\nfuga\n\-{40}/, 'assert report log';

done_testing;
