#!/bin/bash

java -cp /usr/local/bin/lepmap2 Filtering data=test.linkage dataTolerance=0.001 MAFLimit=0.01 >test_f.linkage
java -cp /usr/local/bin/lepmap2 SeparateChromosomes data=test_f.linkage sizeLimit=10 lodLimit=5.5 >test.map.txt

Rscript --vanilla test.R

plinktomap.pl --genetic test.gmap --extra test.testAssocSex
