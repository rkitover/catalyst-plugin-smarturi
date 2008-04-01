use inc::Module::Install;

name     'Catalyst-Plugin-SmartURI';
all_from 'lib/Catalyst/Plugin/SmartURI.pm';
author   'Rafael Kitover <rkitover@cpan.org>';

requires 'Catalyst' => '5.7007';
requires 'Class::C3::Componentised';
requires 'File::Find::Rule';
requires 'List::Util';
requires 'List::MoreUtils';
requires 'Class::Accessor::Fast';
requires 'Class::Data::Inheritable';

build_requires 'Test::More';

tests 't/*.t t/*/*.t';

auto_install;

WriteAll;
