use strict;
use warnings;

use Test::More;
use FindBin;
use FindBin::libs;

use Config::YAML;

package Mock::App;
use Any::Moose;
extends 'Lism::CLI';

sub main {
    my $self = shift;
    $self->logging('info', 'debug');
}

package main;

my $yamlname = "$FindBin::Bin/config.yaml";
my $config = Config::YAML->new(config => $yamlname);
ok my $app = Mock::App->new(config => $config, debug => 1), 'create application object';
isa_ok $app->config, 'Config::YAML';
is $app->config->{ alert_email }->{ warn }, 'warn@example.com', 'assert config value of email:warn';

done_testing;
