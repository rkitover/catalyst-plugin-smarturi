use inc::Module::Install;

name     'Catalyst-Plugin-SmartURI';
all_from 'lib/Catalyst/Plugin/SmartURI.pm';
author   'Rafael Kitover <rkitover@cpan.org>';

requires 'Catalyst' => '5.7007';
requires 'Class::C3::Componentised';
requires 'Class::Accessor::Fast';
requires 'URI::SmartURI';
requires 'Task::Weaken';
requires 'parent';

build_requires 'Test::More';

auto_install;

WriteAll;
