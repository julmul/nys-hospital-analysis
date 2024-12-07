FROM rocker/verse

RUN apt-get update && apt-get install -y \
    git \
    man-db \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libmysqlclient-dev \
    sqlite3 && \
    rm -rf /var/lib/apt/lists/*

RUN apt update && apt install git 

RUN R -e "install.packages(c('tidyverse', 'sf', 'RSQLite', 'gbm', 'caret', 'nnet'))"