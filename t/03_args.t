use strict;
use warnings;

use Test::More tests => 2;

use FindBin::libs;

package Mock::App;
use Any::Moose;
extends 'Lism::CLI';

sub main {
    my ($self, @args) = @_;
    join '-', @args;
}

package main;
ok my $app = Mock::App->new, 'create application object';
is $app->run('hoge', 'fuga'), 'hoge-fuga', 'result from args';
