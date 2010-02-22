use inc::Module::Install;
name 'Lism-CLI';
all_from 'lib/Lism/CLI.pm';

requires 'Any::Moose';
requires 'Lism::Config';
requires 'Encode';
requires 'Email::MIME';
requires 'Email::MIME::Creator';
requires 'Email::Send';
requires 'FindBin';
requires 'File::Find';
requires 'File::stat';
requires 'Getopt::Long';
requires 'POSIX';
requires 'Sys::Hostname';

author_tests('xt');

test_requires 'Test::More';

use_test_base;
auto_include;
WriteAll;
