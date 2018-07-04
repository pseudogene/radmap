#!/usr/bin/perl
# $Revision: 0.10 $
# $Date: 2018/07/04 $
# $Id: linkage2post.pl $
# $Author: Michael Bekaert $
#
# Linkage file to LepMap post file (radmap)
# Copyright (C) 2016-2018 Bekaert M <michael.bekaert@stir.ac.uk>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# POD documentation - main docs before the code

=head1 NAME

Linkage file to LepMap post file (radmap)

=head1 SYNOPSIS

  # Command line help

  Usage: ./linkage2post.pl [-e 0.001] -in <linkage_file>

    -in  linkage_file   MANDATORY
    -e   error rate     OPTIONAL 0.001 by default

=cut

use strict;
use warnings;
use Getopt::Long;

sub allele1
{
    my $code = shift;
    return 1 if ($code <= 4);
    return 2 if ($code <= 7);
    return 3 if ($code <= 9);
    return 4;
}

sub allele2
{
    my $code = shift;
    return $code     if ($code <= 4);
    return $code - 3 if ($code <= 7);
    return $code - 5 if ($code <= 9);
    return 4;
}

sub distance
{
    my ($code1, $code2) = @_;
    return 0 if ($code1 == $code2);
    my $a1 = allele1($code1);
    my $a2 = allele2($code1);
    my $b1 = allele1($code2);
    my $b2 = allele2($code2);
    return 1 if ($a1 == $b1 || $a1 == $b2 || $a2 == $b1 || $a2 == $b2);
    return 2;
}

my ($error, $infile) = (0.001);
GetOptions('e|error:f' => \$error, 'i|in=s' => \$infile,);
if ($error >= 0 && defined $infile && -r $infile && (open my $seq_fh, q{<}, $infile))
{
    my %map;
    my $code = 1;
    for (my $i = 1 ; $i <= 4 ; ++$i)
    {
        for (my $j = $i ; $j <= 4 ; ++$j)
        {
            my $s = q{};
            for (1..10) { $s = $s . q{ } . $error**distance($code, $_); }
            $map{$i . q{ } . $j} = substr($s, (2) - 1);
            $map{$j . q{ } . $i} = $map{$i . q{ } . $j};
            ++$code;
        }
    }
    $map{'0 0'} = '1 1 1 1 1 1 1 1 1 1';
    my $count = 0;
    while (<$seq_fh>)
    {
        next if /^\#/;
        chomp;
        $count++;
        my @line = split /\t/;
        print 'CHR', "\tCHR" x (scalar @line - 1), "\n", 'POS', "\tPOS" x (scalar @line - 1), "\n" if ($count == 1);
        my @tab;
        for (6 .. scalar @line -1) { push @tab, $map{$line[$_]}; }
        print $line[0], "\t", $line[1], "\t", $line[2], "\t", $line[3], "\t", $line[4], "\t", $line[5], "\t", join("\t", @tab), "\n";
    }
	close $seq_fh;
}
