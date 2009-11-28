use inc::Module::Install;
name 'Lism-CLI';
all_from 'lib/Lism/CLI.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
