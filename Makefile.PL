use inc::Module::Install 0.91;

name     'Catalyst-Plugin-SmartURI';
all_from 'lib/Catalyst/Plugin/SmartURI.pm';
author   'Rafael Kitover <rkitover@cpan.org>';

requires 'Catalyst' => '5.80002';
requires 'Class::C3::Componentised';
requires 'URI::SmartURI';
requires 'Task::Weaken';
requires 'Moose';
requires 'namespace::clean';
requires 'parent';

build_requires 'Test::More';

auto_provides;
auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-Plugin-SmartURI/1.000/trunk/';

WriteAll;
