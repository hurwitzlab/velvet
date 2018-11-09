#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use autodie;
use Cwd 'cwd';
use Data::Dump 'dump';
use File::Basename 'fileparse';
use File::Spec::Functions 'catfile';
use File::Path 'make_path';
use File::Find::Rule;
use Getopt::Long;
use Pod::Usage;

my $DEBUG = 0;

main();

# --------------------------------------------------
sub main {
    my %args = get_args();

    if ($args{'help'} || $args{'man_page'}) {
        pod2usage({
            -exitval => 0,
            -verbose => $args{'man_page'} ? 2 : 1
        });
    }; 

    debug("args = ", dump(\%args));
    my $in_dir = $args{'dir'}      or pod2usage('No input --dir');
    my $out_dir = $args{'out_dir'} or pod2usage('No --out_dir');

    my @files;
    if (-f $in_dir) {
        debug("Directory arg '$in_dir' is actually a file");
        push @files, $in_dir;
    }
    else {
        debug("Looking for files in '$in_dir'");
        @files = File::Find::Rule->file()->in($in_dir);
    }

    printf "Found %s files\n", scalar(@files);

    if (@files < 1) {
        pod2usage('No input data');
    }

    my @inputs;
    for my $file (@files) {
        my ($basename, $path, $ext) = fileparse($file, qr/\.[^.]*/);
        $ext =~ s/^\.//; # remove leading dot
        $ext = lc $ext;  

        my $type;
        if ($ext =~ /^fa(?:sta)?(\.gz)?$/) {
            $type = join('', 'fasta', $1 || '');
        }
        elsif ($ext =~ /^f(?:ast)?q(\.gz)?$/) {
            $type = join('', 'fastq', $1 || '');
        }
        elsif ($ext =~ /^([bs]am)$/) {
            $type = $1;
        }
        elsif ($ext =~ /^(eland|gerald)$/) {
            $type = $1;
        }

        unless ($type) {
            pod2usage("Can't figure type of '$file'");
        }

        my $category = 'short';
        if ($basename =~ /(shortPaired2?|short2?|long|longPaired)/) {
            $category = $1;
        }

        push @inputs, { file => $file, format => $type, category => $category };
    }   

    unless (@inputs) {
        pod2usage("Found no usable inputs");
    } 

    debug("inputs =", dump(\@inputs));

    execute(sprintf('velveth %s %s %s',
        $args{'out_dir'}, 
        $args{'hash_size'}, 
        join(' ', 
            map { 
                sprintf '-%s -%s %s', $_->{'format'}, $_->{'category'}, $_->{'file'}
            } @inputs
        )
    ));

    my @args;
    for my $arg (
        qw[cov_cutoff ins_length read_trkg min_contig_lgth amos_file 
           exp_cov long_cov_cutoff]
    ) {
        if (my $val = $args{$arg}) {
            push @args, sprintf "-%s %s", $arg, $val;
        }
    }

    execute(sprintf('velvetg %s %s', $args{'out_dir'}, join(' ', @args)));

    printf("Finished, see results in '%s'\n", $args{'out_dir'});
}

# --------------------------------------------------
sub debug {
    say @_ if $DEBUG;
}

# --------------------------------------------------
sub execute {
    my @cmd = @_ or return;
    debug("\n\n>>>>>>\n\n", join(' ', @cmd), "\n\n<<<<<<\n\n");

    unless (system(@cmd) == 0) {
        die sprintf(
            "FATAL ERROR! Could not execute command:\n%s\n",
            join(' ', @cmd)
        );
    }
}

# --------------------------------------------------
sub get_args {
    my %args = (
        'dir'               => '',
        'debug'             => 0,
        'hash_size'         => 31,
        'cov_cutoff'        => 0,
        'exp_cov'           => 0,
        'ins_length'        => 0,
        'read_trkg'         => 'no',
        'min_contig_length' => 0,
        'amos_file'         => 'no',
        'long_cov_cutoff'   => 0,
        'out_dir'           => cwd(),
    );

    GetOptions(
        \%args,
        'dir|d=s',
        'hash_size|s:i',
        'cov_cutoff|c:i',
        'exp_cov|e:i',
        'out_dir|o:s',
        'ins_length|i:i',
        'read_trkg|r:s',
        'min_contig_lgth|m:s',
        'amos_file|a:s',
        'long_cov_cutoff|l:s',
        'debug',
        'help',
        'man',
    ) or pod2usage(2);

    $DEBUG = $args{'debug'};

    if (-d $args{'out_dir'}) {
        my @previous = 
          grep { -e $_ }
          map  { catfile($args{'out_dir'}, $_) }
          qw[contigs.fa Graph2 LastGraph Log PreGraph Roadmaps Sequences stats.txt];

        debug("Removing previous files = ", dump(\@previous));

        map { unlink($_) } @previous;
    }
    else {
        make_path($args{'out_dir'});
    }

    return %args;
}

__END__

# --------------------------------------------------

=pod

=head1 NAME

run-velvet.pl - runs velvet

=head1 SYNOPSIS

  run-velvet.pl -d /path/to/data

Required Arguments:

  -d|--dir   Input directory

Options (defaults in parentheses):

  -s|--hash_size    Velvet hash size (31)
  -c|--cov_cutoff   Coverage cutoff (auto)
  -e|--exp_cov      Expected coverage (auto)
  -o|--out_dir      Output directory (cwd)

  --help            Show brief help and exit
  --man             Show full documentation

=head1 DESCRIPTION

Runs velvet.

=head1 SEE ALSO

Velvet.

=head1 AUTHOR

Ken Youens-Clark E<lt>kyclark@email.arizona.eduE<gt>.

=head1 COPYRIGHT

Copyright (c) 2016 Ken Youens-Clark

This module is free software; you can redistribute it and/or
modify it under the terms of the GPL (either version 1, or at
your option, any later version) or the Artistic License 2.0.
Refer to LICENSE for the full license text and to DISCLAIMER for
additional warranty disclaimers.

=cut
