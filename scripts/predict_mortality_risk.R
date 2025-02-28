#####################################################
# Build a gradient boosting model for mortality risk prediction 
# Author: Julia Muller
# Date: 6 December 2024
# Last modified: February 2025
#####################################################

# Load libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(RSQLite)
  library(gbm)
  library(caret)
})

# Source utility functions
source('scripts/utils.R')

# Pull patient, hospital, and clinical data from database
patient <- query_db('SELECT admission_id, age_group, gender, race, ethnicity FROM demographic')
hospital <- query_db('SELECT admission_id, hospital_service_area FROM hospital')
clinical <- query_db('SELECT admission_id, apr_risk_of_mortality, type_of_admission, length_of_stay, patient_disposition FROM clinical')

# Merge the datasets and select only complete cases
data <- reduce(list(hospital, patient, clinical), full_join, by = 'admission_id') %>%
  filter(complete.cases(.))

# Convert categorical variables to factors and create binary outcome variable
data <- data %>%
  mutate(across(c(age_group, gender, race, ethnicity, hospital_service_area, type_of_admission, patient_disposition), as.factor))

# Create a binary outcome variable based on APR mortality risk (minor/moderate = 0, severe/critical = 1)
data <- data %>%
  mutate(apr_risk_of_mortality_binary = if_else(apr_risk_of_mortality %in% c('Minor', 'Moderate'), 0, 1)) %>%
  select(-apr_risk_of_mortality, -admission_id)

# Perform a train/test split
train_index <- sample(1:nrow(data), 0.5 * nrow(data))
train_data <- data[train_index, ]
test_data <- data[-train_index, ]

# Build the model
model <- gbm(
  apr_risk_of_mortality_binary ~ age_group + gender + race + length_of_stay + type_of_admission + hospital_service_area + patient_disposition,
  data = train_data,
  distribution = 'bernoulli',
  n.trees = 100)

# Generate predicted probabilities of mortality for the test data
prob <- predict(model, newdata = test_data, type = 'response')

# Convert probabilities to binary predictions (threshold at 0.5) and add to the test data
predictions <- ifelse(prob > 0.5, 1, 0)
test_data$predicted_risk_of_mortality <- predictions
test_data$predicted_probability_of_mortality <- prob

# Save summary results to RDS 
ensure_directory('figures')
write_rds(summary(model), 'figures/relative_predictive_importance.rds')
