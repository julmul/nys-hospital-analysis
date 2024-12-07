docker build --platform linux/amd64 -t 611 .

docker run --rm -p 8787:8787 -e USER=rstudio -e PASSWORD=yourpassword --volume ${PWD}:/home/rstudio 611