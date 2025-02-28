# NYS Hospital Discharges

This repository contains my final project for BIOS611 - Introduction to Data Science.
This analysis uses public, de-identified New York State hospital inpatient discharge data from 2022. This dataset is sourced from [New York State Health Data](https://health.data.ny.gov/Health/Hospital-Inpatient-Discharges-SPARCS-De-Identified/5dtw-tffi/about_data). Shape files used for mapping were retrieved from [New York State GIS Clearinghouse](https://gis.ny.gov/civil-boundaries).

The goal of this project is to analyze patterns in hospital admissions, identify regional differences in patient outcomes, and build predictive models to understand the factors influencing mortality risk in hospitals across New York State. The analysis demonstrates key data science techniques such as data cleaning, exploratory data analysis, and statistical analysis using R. Additionally, the project showcases the use of Docker for containerization, ensuring easy setup, reproducibility, and portability of the analysis.


## Getting Started

To clone this repository and set up the project, follow the steps below:

1. Clone the repository:

```bash
git clone https://github.com/julmul/nys-hospital-analysis.git
```

2. Navigate to the project directory:

```bash
cd nys-hospital-analysis
```

3. Download the dataset:

Due to the large size of the hospital data, the dataset is not stored in the repository and must be pulled from the NYS Health Data website. To automate this, run the following script in terminal:

```bash
./get_data.sh
```

This script downloads the dataset using `curl` and saves it to the `source_data` folder.

Note: This data retrieval step must be completed prior to running the analysis. It is not included in the Makefile to avoid repeated pulls.


## Building the Docker Container

This project is containerized using Docker for easy reproducibility. Ensure you have Docker installed on your machine; if not, follow the instructions on the [Docker website](https://www.docker.com/get-started/).

Note: The Docker container was built and tested on an M2 Mac, so there may be slight differences in behavior if you are using a different operating system.

Build the Docker container by running the following command in the terminal:

```bash
./start.sh
```

This will create the necessary environment to run the analysis and build the final report.


## Accessing the Analysis

Once the Docker container is built:

1. Open your browser and go to https://localhost:8787.

2. Log in with the credentials:

  * Username: `rstudio`
  
  * Password: `yourpassword`

This will open an RStudio session where you can access and run the project.

To build the final report in PDF format, run the following command in the terminal:

```bash
make report.pdf
```


### Project Structure

The project contains the following structure:

* `source_data/` - Folder containing the raw data.
* `scripts/` - R scripts for data cleaning, exploration, and analysis.
* `report.Rmd` - R Markdown file that will render the final report.
* `Dockerfile` - The Docker configuration file.
* `get_data.sh` - Shell script to download the dataset.
* `start.sh` - Shell script to initialize the Docker container.
* `Makefile` - Automates the process of generating the report.

