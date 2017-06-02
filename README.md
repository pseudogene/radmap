> Warning: This is a pre-release version, we are actively developing this repository. Issues, bugs and features will happen, rise and change.

# RAD-tag to Genetic Map

We foster the openness, integrity, and reproducibility of scientific research.

Scripts and tools used to develop a pipeline to analyse RAD-tags and generate the Genetic Map with GWAS.


## How to use this repository?

This repository host both the scripts and tools developed by this study. Feel free to adapt the scripts and tools, but remember to cite their authors!

To look at our scripts and raw results, **browse** through this repository. If you want to reproduce our results you will need to **clone** this repository, build the docker, and the run all the scripts. If you want to use our data for our own research, **fork** this repository and **cite** the authors.


## Prepare a docker

All required files and tools run in a self-contained [docker](https://www.docker.com/) image.

#### bClone the repository

```
git clone https://github.com/pseudogene/radmap.git
cd radmap
```

#### Create a docker

```
docker build --rm=true -t radmap .
```

#### Start the docker

To import and export the results of your analysis, you need to link a folder to the docker. In this example your data will be store in `results` (current filesystem) which will be seem as been `/map` from within the docker by using `-v <USERFOLDER>:/map`.

```
mkdir results
docker run -i -t --rm -v $(pwd)/results:/map radmap /bin/bash
```

## Data importation
plink _classic_ file [PED](http://zzz.bwh.harvard.edu/plink/data.shtml#ped) and [MAP](http://zzz.bwh.harvard.edu/plink/data.shtml#map) are required as well as a **pedigree file**.

The **pedigree file** consists of on columns 1-4+. The columns are separated by tabs. The columns 1-4 are individual name, father, mother and sex; the next columns are for extra phenotypes: phenotype\_1 to phenotype\_n. The phenotypes are not required, but will be helpful for the GWAS analysis.

```
sample     father  mother  sex  phenotype_1
F1_C2_070  P0_sir  P0_dam  M    30
F1_C2_120  P0_sir  P0_dam  F    1
P0_dam     0       0       F    -
P0_sir     0       0       M    -
```

#### From STACKS

If you ran [stacks](http://catchenlab.life.illinois.edu/stacks/), you can generate the plink files using [populations](http://catchenlab.life.illinois.edu/stacks/comp/populations.php) command:

```
 populations -P dir -b batch_id [-M popmap] (filters) --write_single_snp -k --plink
or
 populations -V vcf -O dir [-M popmap] (filters) --write_single_snp -k --plink
```

```
e.g.:
 populations -P ./stakcs/ -M map.pop -b 1 -p 2 -r 0.75 --min_maf 0.01 --write_single_snp -k --plink
```

This should generate the ped and map file in `./stakcs/batch_1.plink.ped` and `./stakcs/batch_1.plink.map`.

#### From dDocent

If you used [dDocent](https://ddocent.wordpress.com/), you can convert your `Final.recode.vcf` with vcftools

```
vcftools --vcf Final.recode.vcf --plink --maf 0.01 --out plink
```

## LepMap2
See the official documentation at https://sourceforge.net/p/lepmap2/wiki/Home/

#### Create the lepmap input file  (recommended)

```
plinktomap.pl --ped plink.ped --meta meta_parents.txt --lepmap >input.linkage
```

#### Run LepMap2

```
#Filter dataset
java -cp /usr/local/bin/ Filtering data=input.linkage dataTolerance=0.001 MAFLimit=0.01 >input_f.linkage

#Test the best LOD limit (form 0.5 t 15)
for I in $(seq 0.5 0.5 15)
do
  java -cp /usr/local/bin/ SeparateChromosomes data=input_f.linkage sizeLimit=10 lodLimit=${I} >/dev/null 2>>lod.log
done

grep "Number of LGs" lod.log >lod.txt
cat lod.txt

#For the best LOD limit (e.g. 5.5)
java -cp /usr/local/bin/ SeparateChromosomes data=input_f.linkage sizeLimit=10 lodLimit=5.5 >input.map
java -cp /usr/local/bin/ JoinSingles input.map data=input_f.linkage lodLimit=0.5 >input.jsmap

#Calculate a genetic map (see LepMap2 documentation for more details)
java -cp /usr/local/bin/ OrderMarkers numThreads=2 useKosambi=1 maxDistance=50 map=input.jsmap data=input_f.linkage >lepmap.ordered
```

## R/SNPassoc
See the official documentation at https://CRAN.R-project.org/package=SNPassoc

### Data preparation

#### Create the SNPAssoc input file (ALL markers)

```
plinktomap.pl --plink plink.map --ped plink.ped --meta meta_parents.txt --snpassoc >input.all.snp
```

#### Create the SNPAssoc input file (mappable markers: filtered by LepMap2)

```
plinktomap.pl --plink plink.map --ped plink.ped --meta meta_parents.txt --map input.jsmap --snpassoc >input.mappable.snp
```

#### Create the SNPAssoc input file (based on LepMap2 Genetic Map, `female` map)  (recommended)

```
plinktomap.pl --plink plink.map --ped plink.ped --meta meta_parents.txt --map input.jsmap --gmap lepmap.ordered --female --snpassoc >input.snp 2>input.gmap
```

## Run R/SNPassoc

#### All or mappable markers

```
library(SNPassoc)
SNP <- read.delim("input.all.snp");
SNPAssoc<-setupSNP(data=SNP,colSNPs=4:length(SNP), sep="/");
SNPAssocSex<-WGassociation(sex~1, data=SNPAssoc, model="codominant")
BonSNPAssocSex<-Bonferroni.sig(SNPAssocSex, model = "codominant", alpha = 0.05,include.all.SNPs=FALSE);
summary(SNPAssocSex)
plot(SNPAssocSex, whole=FALSE, print.label.SNPs = FALSE)
```

#### based on LepMap2 Genetic Map  (recommended)

```
library(SNPassoc)
SNP <- read.delim2("input.snp",header=TRUE);
order <- read.delim2("input.gmap");
order$Marker <- paste('X',order$Marker,sep=""); #If Stacks output
#order$Marker<-gsub(":", ".", order$Marker);     #If dDocent output
SNPAssoc<-setupSNP(data=SNP,colSNPs=4:length(SNP), sort=TRUE, info=order,sep="/");
SNPAssocSex<-WGassociation(sex, data=SNPAssoc, model="codominant");
BonSNPAssocSex<-Bonferroni.sig(SNPAssocSex, model = "codominant", alpha = 0.05,include.all.SNPs=FALSE);
summary(SNPAssocSex)
png("AssocSex.png");
plot(SNPAssocSex, whole=FALSE, print.label.SNPs = FALSE, sort.chromosome=TRUE);
dev.off();
write.csv(SNPAssocSex,file="AssocSex.csv");
```

## Generate the summary Genetic map

#### Create the final genetic map

```
plinktomap.pl --genetic input.gmap --extra AssocSex.csv >genetic_map.tsv
```

#### Create the final genetic map with the marker sequences and locations (Stacks only)   (recommended **for publication**)

```
plinktomap.pl --genetic input.gmap --extra AssocSex.csv --marker batch_<n>.catalog.tags.tsv --loc >genetic_map.tsv
```

## Issues

If you have any problems with or questions about the scripts, please contact us through a [GitHub issue](https://github.com/pseudogene/radmap/issues).
Any issue related to the scientific results themselves must be done directly with the authors.


## Contributing

You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.


## License and distribution

The content of this project itself including the raw data and work are licensed under the [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/), and the source code presented is licensed under the [GPLv3 license](http://www.gnu.org/licenses/gpl-3.0.html).