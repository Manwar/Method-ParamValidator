#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Method::ParamValidator',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Method/ParamValidator.pm',
    ABSTRACT_FROM      => 'lib/Method/ParamValidator.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'JSON'             => 0,
        'Moo'              => '2.000000',
        'Moo::Role'        => '2.000000',
        'namespace::clean' => '0.24',
        'Type::Tiny'       => 0,
        'Throwable'        => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Method-ParamValidator-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Method-ParamValidator.git',
                web  => 'https://github.com/manwar/Method-ParamValidator',
            },
        }})
     : ()
    ),
);
