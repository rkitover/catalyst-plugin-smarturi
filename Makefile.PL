use inc::Module::Install;

name     'Catalyst-Plugin-SmartURI';
all_from 'lib/Catalyst/Plugin/SmartURI.pm';
author   'Rafael Kitover <rkitover@cpan.org>';

requires 'Catalyst' => '5.80002';
requires 'Class::C3::Componentised';
requires 'URI::SmartURI';
requires 'Task::Weaken';

build_requires 'Test::More';

auto_install;

WriteAll;
