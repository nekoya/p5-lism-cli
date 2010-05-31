use strict;
use warnings;

use Test::More;
use FindBin;
use FindBin::libs;

package Mock::App;
use Any::Moose;
extends 'Lism::CLI';

sub main {
    my $self = shift;
    $self->logging('info', 'debug');
}

package main;

my $yamlname = "$FindBin::Bin/config.yaml";
ok my $app = Mock::App->new(config => $yamlname, debug => 1), 'create application object';
is $app->config, $yamlname, 'assert config yaml filename';
isa_ok $app->conf, 'Config::YAML';
is $app->conf->{ alert_email }->{ warn }, 'warn@example.com', 'assert config value of email:warn';

done_testing;
