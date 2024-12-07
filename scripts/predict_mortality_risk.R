library(gbm)
library(caret)
library(tidyverse)
library(RSQLite)

# Load your dataset
conn <- dbConnect(RSQLite::SQLite(), dbname = 'derived_data/hospital-discharges.db')
patient <- dbGetQuery(conn, 'SELECT admission_id, age_group, gender, race, ethnicity FROM demographic')
hospital <- dbGetQuery(conn, 'SELECT admission_id, hospital_service_area FROM hospital')
clinical <- dbGetQuery(conn, 'SELECT admission_id, apr_risk_of_mortality, type_of_admission, length_of_stay, patient_disposition FROM clinical')
dbDisconnect(conn)

# Merge the data sets
data <- hospital %>%
  full_join(patient, by = 'admission_id') %>%
  full_join(clinical, by = 'admission_id') %>%
  filter(complete.cases(.))

# Convert categorical variables to factors and create binary outcome variable
data <- data %>%
  mutate(across(c(age_group, gender, race, ethnicity, hospital_service_area, type_of_admission, patient_disposition), as.factor)) %>%
  mutate(apr_risk_of_mortality_binary = if_else(apr_risk_of_mortality %in% c('Minor', 'Moderate'), 0, 1)) %>%
  dplyr::select(-apr_risk_of_mortality, -admission_id)

# Split data into training and testing sets
trainIndex <- sample(1:nrow(data), 0.5 * nrow(data))
trainData <- data[trainIndex, ]
testData <- data[-trainIndex, ]

# Build the gradient boosting model
model <- gbm(
  apr_risk_of_mortality_binary ~ age_group + gender + race + length_of_stay + type_of_admission + hospital_service_area + patient_disposition,
  data = trainData,
  distribution = "bernoulli",
  n.trees = 100)

# Generate predicted probabilities for the test data
prob <- predict(model, newdata = testData, type = "response")

# Add binary predictions to the test data for further analysis
predictions <- ifelse(prob > 0.5, 1, 0)
testData$predicted_risk_of_mortality <- predictions
testData$predicted_probability_of_mortality <- prob

# Save relative importance of variables to RDS 
summary <- summary(model)
write_rds(summary, 'figures/relative_predictive_importance.rds')
