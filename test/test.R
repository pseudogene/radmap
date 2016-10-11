library(SNPassoc)
test <- read.delim2("test.snp",header=TRUE);
order <- read.delim2("test.gmap");
order$Marker <- paste('X',order$Marker,sep="");
testAssoc<-setupSNP(data=test,colSNPs=4:length(test), sort=TRUE, info=order,sep="/");
testAssocSex<-WGassociation(sex, data=testAssoc, model="codominant");
BonLiceAssocSex<-Bonferroni.sig(testAssocSex, model = "codominant", alpha = 0.05,include.all.SNPs=FALSE);
summary(testAssocSex);
write.csv(testAssocSex,file="test.testAssocSex");
