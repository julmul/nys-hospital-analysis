#####################################################
# Load tidied hospital data into SQLite database
# Author: Julia Muller
# Date: 2 December 2024
# Last modified: February 2025
#####################################################

# Load libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(RSQLite)
})

# Import tidied hospital data
data <- read_csv('derived_data/hospital_discharges_tidied.csv', show_col_types = F)

# Connect to SQLite database
conn <- dbConnect(RSQLite::SQLite(), dbname = 'derived_data/hospital-discharges.db')

# Drop existing tables to avoid conflicts with new data
dbExecute(con, 'DROP TABLE IF EXISTS hospital')
dbExecute(con, 'DROP TABLE IF EXISTS demographic')
dbExecute(con, 'DROP TABLE IF EXISTS clinical')
dbExecute(con, 'DROP TABLE IF EXISTS payment')

# Write table of hospital information
dbWriteTable(conn, 'hospital', 
             data[, c('admission_id', 'hospital_service_area', 'hospital_county', 
                      'operating_certificate_number', 'permanent_facility_id', 
                      'facility_name')], 
             row.names = FALSE)

# Write table of patient-level demographic information
dbWriteTable(conn, 'demographic', 
             data[, c('admission_id', 'age_group', 'gender', 'race', 'ethnicity', 
                      'birth_weight', 'zip_code')], 
             row.names = FALSE)

# Write table of clinical procedures, diagnoses, and outcomes
dbWriteTable(conn, 'clinical', 
             data[, c('admission_id', 'type_of_admission', 'patient_disposition', 
                      'length_of_stay', 'discharge_year', 'emergency_department_indicator', 
                      'ccsr_diagnosis_code', 'ccsr_diagnosis_description', 'ccsr_procedure_code', 
                      'ccsr_procedure_description', 'apr_drg_code', 'apr_drg_description', 
                      'apr_mdc_code', 'apr_mdc_description', 'apr_severity_of_illness_code', 
                      'apr_severity_of_illness_description', 'apr_risk_of_mortality', 
                      'apr_medical_surgical_description')], 
             row.names = FALSE)

# Write table of payment information
dbWriteTable(conn, 'payment', 
             data[, c('admission_id', 'payment_typology_1', 'payment_typology_2', 
                      'payment_typology_3', 'total_charges', 'total_costs')], 
             row.names = FALSE)

# Disconnect from the database
dbDisconnect(conn)
