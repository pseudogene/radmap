#
# Copyright 2018, Michaël Bekaert <michael.bekaert@stir.ac.uk>
#
# This file is part of RAD-tags to Genetic Map (radmap).
#
# radmap is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# radmap is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License v3
# along with radmap. If not, see <http://www.gnu.org/licenses/>.
#
FROM ubuntu:17.10
MAINTAINER Michael Bekaert <michael.bekaert@stir.ac.uk>

LABEL description="RAD-tags to Genetic Map Docker" version="2.0" Vendor="Institute of Aquaculture, University of Stirling"

USER root

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y dirmngr --no-install-recommends

RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu artful/" >> /etc/apt/sources.list && \
    gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 && \
    gpg -a --export E084DAB9 | apt-key add - && \
    apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget unzip ca-certificates-java default-jre-headless librsvg2-bin --no-install-recommends && \
    wget -q --no-check-certificate https://sourceforge.net/projects/lepmap2/files/binary.zip -O /root/lepmap2.zip && \
    wget -q --no-check-certificate https://sourceforge.net/projects/lepmap2/files/scripts.zip -O /root/scripts2.zip && \
    wget -q --no-check-certificate https://sourceforge.net/projects/lep-map3/files/binary.zip -O /root/lepmap3.zip && \
    cd /root && \
    unzip lepmap2.zip && \
    mv bin /usr/local/bin/lepmap2 && \
    rm -rf README lepmap2.zip && \
    unzip scripts2.zip && \
    mv scripts/linkage2post.awk /usr/local/bin/linkage2post.awk && \
    rm -rf scripts scripts2.zip && \
    unzip lepmap3.zip && \
    mv bin /usr/local/bin/lepmap3 && \
    rm -rf README README.txt lepmap3.zip

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y r-base r-cran-stringi r-cran-magrittr r-cran-colorspace r-cran-chron r-cran-stringr r-cran-dichromat r-cran-munsell r-cran-labeling r-cran-zoo r-cran-rcpp r-cran-acepack r-cran-gtable r-cran-digest r-cran-plyr r-cran-reshape2 r-cran-scales r-cran-matrixmodels r-cran-th.data r-cran-sandwich r-cran-hmisc r-cran-ggplot2 r-cran-sparsem r-cran-quantreg r-cran-polspline r-cran-multcomp r-cran-rms r-cran-haplo.stats r-cran-mvtnorm r-cran-rcolorbrewer r-cran-formula r-cran-latticeextra r-cran-gridextra --no-install-recommends && \
    Rscript -e "install.packages('SNPassoc', repos='http://cran.rstudio.com', dependencies = TRUE, Ncpus = 8);"

RUN mkdir /map

COPY plinktomap.pl /usr/local/bin/
COPY genetic-mapper/script/genetic_mapper.pl /usr/local/bin/
COPY test/* /map/

WORKDIR /map

