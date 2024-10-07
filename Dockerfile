FROM rocker/verse

RUN apt-get update && apt-get install -y \
    git \
    man-db \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libmysqlclient-dev && \
    rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('tidyverse'))"
RUN R -e "install.packages(c('sf'))"