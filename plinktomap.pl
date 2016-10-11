#!/usr/bin/perl
# $Revision: 0.2 $
# $Date: 2016/10/11 $
# $Id: plinktomap.pl $
# $Author: Michael Bekaert $
#
# RAD-tags to Genetic Map (radmap)
# Copyright (C) 2016 Bekaert M <michael.bekaert@stir.ac.uk>
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

use strict;
use warnings;
use Getopt::Long;

#----------------------------------------------------------
our ($VERSION) = 0.2;

#----------------------------------------------------------
my ($female, $lepmap, $snpassoc, $loc, $plink, $ped, $parentage, $map, $genmap, $genetic, $markers) = (0, 0, 0, 0);
my @extra;
GetOptions(
           'plink:s'   => \$plink,
           'ped:s'     => \$ped,
           'meta:s'    => \$parentage,
           'map:s'     => \$map,
           'gmap:s'    => \$genmap,
           'genetic:s' => \$genetic,
           'extra:s'   => \@extra,
           'female!'   => \$female,
           'lepmap!'   => \$lepmap,
           'pos!'      => \$loc,
           'snpassoc!' => \$snpassoc,
           'markers:s' => \$markers
          );
my %parents_table;
my $count_meta = 0;

if (defined $parentage && -r $parentage && open(my $in, q{<}, $parentage))
{
    #
    #sample	father	mother	Sex	[..]
    #
    while (<$in>)
    {
        next if (m/^#/);
        chomp;
        my @data = split m/\t/;
        if (scalar @data >= 4 && defined $data[0] && defined $data[1] && defined $data[2] && defined $data[3])
        {
            $count_meta = scalar @data - 4 if ($count_meta < scalar @data - 4);
            @{$parents_table{$data[0]}} = @data;
        }
    }
    close $in;
}

#To LepMap
if (scalar keys %parents_table > 0 && $lepmap && defined $ped && -r $ped && open(my $in, q{<}, $ped))
{
    my %table = (A => 1, C => 2, G => 3, T => 4, N => 0, 0 => 0);

    # PEB
    # # Stacks v1.42;  PLINK v1.07; October 06, 2016
    # C7	F1_dam_C7	0	0	0	0	G	T	A	A	G	T	A	G	G	...
    # LINKAGE
    # #java Filtering  data=C07_LSalAtl2sD140.linkage.txt dataTolerance=0.001
    # C7	P0_sir_C7	0	0	1	0	1 1	0 0	1 2	1 2	1 2	1 2	...
    # C7	F1_dam_C7	P0_sir_C7	P0_dam_C7	2 	0	1 2	0 0	2 2	1 2	1 1	1 ...
    while (<$in>)
    {
        next if (m/^#/);
        chomp;
        my @data = split m/\t/;
        if (scalar @data > 8 && defined $data[0] && defined $data[1] && exists $parents_table{$data[1]})
        {
            print $data[0], "\t", $data[1], "\t", $parents_table{$data[1]}[1], "\t", $parents_table{$data[1]}[2], "\t", ($parents_table{$data[1]}[3] =~ /^F/ ? q{2} : ($parents_table{$data[1]}[3] =~ /^M/ ? q{1} : q{0})), "\t0";
            for my $i (6 .. (scalar @data) - 1) { print "\t", (defined $data[$i] && exists $table{$data[$i]} ? $table{$data[$i]} : q{0}); }
            print "\n";
        }
    }
    close $in;
}

#To SNPAssoc
if (scalar keys %parents_table > 0 && $snpassoc && defined $ped && -r $ped && defined $plink && -r $plink && open(my $in, q{<}, $plink))
{
    my @list_marker;

    # PEB
    # # Stacks v1.42;  PLINK v1.07; October 06, 2016
    # C7	F1_dam_C7	0	0	0	0	G	T	A	A	G	T	A	G	G	...
    # plink MAP
    # # Stacks v1.42;  PLINK v1.07; October 06, 2016
    # LSalAtl2s1	19757_13	0	4466                o
    # LSalAtl2s1	19756_74	0	4550          x
    # LSalAtl2s1	19491_4	0	106094            x     o
    # LSalAtl2s1	19492_81	0	106518        x     o
    # LSalAtl2s1	19498_31	0	118987              o
    # LSalAtl2s1	19749_27	0	381049
    # LEPMAP MAP
    # #java SeparateChromosomes  data=C07_LSalAtl2sD140_f.linkage.txt lodLimit=6.5 sizeLimit=2
    # 0
    # 6
    # 6
    # 6
    # 0
    # 0
    # SNPAssoc
    # id	Sex	Surviving	33	40	60	120	136	157	180
    # F2_C7_073	Female	2	A/A	-	A/B	A/B	A/B	A/B
    # F2_C7_074	Female	2	A/A	-	B/B	A/B	A/B	A/A
    while (<$in>)
    {
        next if (m/^#/);
        chomp;
        my @data = split m/\t/;
        if (scalar @data >= 2 && defined $data[0] && defined $data[1]) { push @list_marker, $data[1]; }
    }
    close $in;
    if (scalar @list_marker > 0 && defined $map && -r $map && open($in, q{<}, $map))
    {
        my $i = 0;
        while (<$in>)
        {
            next if (m/^#/);
            chomp;
            if ($_ eq '0') { undef $list_marker[$i]; }
            $i++;
        }
        close $in;
    }
    if (scalar @list_marker > 0 && open($in, q{<}, $ped))
    {
        print "id\tsex";
        for my $j (1 .. $count_meta) { print "\tphenotype_$j", }
        for my $j (0 .. (scalar @list_marker) - 1) { print "\t", $list_marker[$j] if (defined $list_marker[$j]); }
        print "\n";
        while (<$in>)
        {
            next if (m/^#/);
            chomp;
            my @data = split m/\t/;
            if (scalar @data > 8 && defined $data[0] && defined $data[1] && exists $parents_table{$data[1]} && $parents_table{$data[1]}[3] =~ /^(M|F)/)
            {
                print $data[1], "\t", ($parents_table{$data[1]}[3] =~ /^F/ ? 'Female' : 'Male');
                for my $j (1 .. $count_meta) { print "\t", (exists $parents_table{$data[1]}[3 + $j] ? $parents_table{$data[1]}[3 + $j] : q{}) }
                my $i = 6;
                for my $j (0 .. (scalar @list_marker) - 1) {
                    print "\t", (defined $data[6 + $j * 2] && $data[6 + $j * 2] ne '0' && defined $data[6 + $j * 2 + 1] && $data[6 + $j * 2 + 1] ne '0' ? $data[6 + $j * 2] . q{/} . $data[6 + $j * 2 + 1] : '-')
                      if (defined $list_marker[$j]);
                }
                print "\n";
            }
        }
        close $in;
    }
    if (scalar @list_marker > 0 && defined $genmap && -r $genmap && open($in, q{<}, $genmap))
    {
        my $lg;

        # genmap
        # #java OrderMarkers map=mapLOD5_js.txt data=C07_LSalAtl2sD140_f.linkage.txt sexAveraged=1 useKosambi=1
        # #*** LG = 1 likelihood = -5811.6314 with alpha penalty = -5811.6314
        # #marker_number	male_position	female_position	( error_estimate )[ duplicate* OR phases]	C7
        # 1886	0.000	0.000	( 0 )	11
        # 2789	0.270	0.270	( 0 )	11
        # 2749	2.568	2.568	( 0.2398 )	10
        # 4119	3.455	3.455	( 0 )	-1
        print {*STDERR} "Marker\tLG\tPosition\n";
        while (<$in>)
        {
            if (m/^#/)
            {
                if (m/LG = (\d+(\.\d+)?)/) { $lg = $1; }
            }
            else
            {
                chomp;
                my @data = split m/\t/;
                if (scalar @data > 3 && defined $data[0] && defined $data[1] && defined $data[2] && defined $list_marker[$data[0] - 1] && defined $lg) { print {*STDERR} $list_marker[$data[0] - 1], "\t", $lg, "\t", $data[($female ? 2 : 1)], "\n"; }
            }
        }
        close $in;
    }
}
if (scalar @extra > 0 && defined $genetic && -r $genetic && open(my $in, q{<}, $genetic))
{
    my %list_markers;

    # genetic
    # Marker	LG	Position
    # 67793_33	1	0.000
    # 65135_20	1	1.561
    # 47811_36	1	4.114
    # 47815_44	1	4.114
    # 11332_62	1	6.270
    # 47683_83	1	6.537
    while (<$in>)
    {
        next if (m/^(#|Marker)/);
        chomp;
        my @data = split m/\t/;
        if (scalar @data >= 2 && defined $data[0] && defined $data[1] && defined $data[2]) { @{$list_markers{$data[0]}} = @data; }
    }
    close $in;
    foreach my $infile (@extra)
    {
        if (defined $infile && -r $infile && open(my $in2, q{<}, $infile))
        {
            my %tmp_list;

            #Extra
            #           comments    codominant
            # X67793_33 -           0.02181
            # X65135_20 -           0.57684
            # X35663_43 -           0.40287
            # "","comments","codominant"
            # "X67793_33",NA,0.02511912
            while (<$in2>)
            {
                chomp;
                my @data = split m/,/;
                if (scalar @data >= 3 && defined $data[0] && $data[0] =~ m/X([\d\w\_\.]+)/ && defined $data[2] && $data[2] ne 'NA')
                {
                    #        if (m/^X([\d\w\_\.]+).*(\d+\.\d+)\s*$/) {
                    #        if (m/^X([\d\w\_\.]+).*(\d+\.\d+)\s*$/) {
                    $tmp_list{$1} = $data[2];
                }
            }
            close $in2;
            if (scalar keys %tmp_list > 0)
            {
                for my $item (keys %list_markers) { push @{$list_markers{$item}}, (exists $tmp_list{$item} ? $tmp_list{$item} : q{-}); }
            }
        }
    }
    if (defined $markers && -r $markers)
    {
        my %tmp_list;
        for my $item (keys %list_markers)
        {
            if   ($item =~ m/^(\d+)_\d+/) { $tmp_list{$1}    = $item; }
            else                          { $tmp_list{$item} = $item; }
        }
        if (open($in, q{<}, $markers))
        {
            # ## cstacks version 1.42; catalog generated on 2016-09-22 22:24:20
            # 0	2	1	LSalAtl2s1000	1022	-	consensus	0	263_8...	CATGTTTATGTATCATTTGTACTATTATAAAACTGAAATATATATTTTTATGTTTTTGTAAAAATGTTTAATTTATTATCTATAACCATTCCTATTCGCC	0	0	0	0
            # 0	2	2	LSalAtl2s1000	132767	+	consensus	0	263_13...	CATGGTAAATTCGTGGTTTACACTATCATTGTCAGACAAAATTGTTGTGAGTACTATCATCTTGAAGCAATGTCGATGCAAGCAATAAGATTGTAAGTAA	0	0	0	0
            while (<$in>)
            {
                next if (m/^#/);
                chomp;
                my @data = split m/\t/;
                if (scalar @data > 9 && defined $data[2] && defined $data[9] && exists $tmp_list{$data[2]}) {
                    push @{$list_markers{$tmp_list{$data[2]}}}, (int($loc) > 0 && defined $data[3] && defined $data[4] ? $data[3] . "\t" . $data[4] . "\t" . $data[9] : $data[9]);
                }
            }
            close $in;
        }
    }
    print {*STDOUT} "Marker\tLG\tPosition\t", join("\t", @extra), "\n";
    for my $item (keys %list_markers) { print {*STDOUT} join("\t", @{$list_markers{$item}}), "\n"; }
}
##Create the lepmap input file
# ./plinktomap.pl --ped batch_2.plink.ped --meta meta_parents.txt --lepmap
##Create the SNPAssoc input file (ALL markers)
# ./plinktomap.pl --plink batch_2.plink.map --ped batch_2.plink.ped --meta meta_parents.txt --snpassoc
##Create the SNPAssoc input file (mappable marker see LepMap)
# ./plinktomap.pl --plink batch_2.plink.map --ped batch_2.plink.ped --meta meta_parents.txt --snpassoc --map C7_C2.jsmap.txt
##Create the SNPAssoc input file (mappable marker see LepMap) and LepMap Genetic Map (based on the female map)
# ./plinktomap.pl --plink batch_2.plink.map --ped batch_2.plink.ped --meta meta_parents.txt --snpassoc --map C7_C2.jsmap.txt --gmap C7_C2.ordered.txt --female
##Create the final genetic map
#./plinktomap.pl --genetic test.gmap --extra test.LiceAssocSex --extra test.LiceAssocSur --marker stacks/batch_2.catalog.tags.tsv
#./genetic_mapper.pl -v --col 1 --var --compact --plot --pos --scale=5 --map=test.final -lod > gmap.svg
##https://www.biostars.org/p/114352/
##https://www.biostars.org/p/5862/
##https://software.broadinstitute.org/gatk/gatkdocs/org_broadinstitute_gatk_tools_walkers_variantutils_VariantsToBinaryPed.php
#library(SNPassoc)
#Lice <- read.delim("C7_C2.snpassoc");
##order <- read.delim2("map.2.all.tsv",header=TRUE);
##order$Marker <- paste('X',order$Marker,sep="");
##LiceAssoc<-setupSNP(data=Lice,colSNPs=5:length(Lice), sort=TRUE, info=order,sep="/");
#LiceAssoc<-setupSNP(data=Lice,colSNPs=5:length(Lice), sep="/");
#LiceAssocSex<-WGassociation(sex~1, data=LiceAssoc, model="co")
#
#Bonferroni.sig(LiceAssocSex, model = "co", alpha = 0.05, include.all.SNPs=FALSE)
#plot(LiceAssocSex, whole=FALSE, print.label.SNPs = FALSE)
