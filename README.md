# NYS Hospital Discharges

This is my final project for BIOS611 - Introduction to Data Science. This analysis uses public, de-identified New York State hospital inpatient discharge data from 2022. Data are from https://health.data.ny.gov/Health/Hospital-Inpatient-Discharges-SPARCS-De-Identified/5dtw-tffi/about_data

This Docker container was built on an M2 Mac.

## Getting Started

To clone this repository, run the following command in your terminal:

```bash
git clone https://github.com/julmul/BIOS611.git
```

Once this is complete, navigate to the directory on your computer using `cd BIOS611`.

This project uses Git LFS due to the large size of the hospital data set. Ensure you have Git LFS installed. Once you have navigated to the project directory, type `git lfs pull` into your terminal to retrieve the source data.

## Building the Docker Container

To access this repository, you must have Docker installed. Once Docker is installed, run `./start.sh` from your terminal to build the container.

## Accessing the Report

Once the container is built, open your browser and navigate to `localhost:8787`, then log in using the username `rstudio` and the password `yourpassword`. This will open RStudio.

To build the final report, type `make report.pdf` in the terminal within RStudio.
