#####################################################
# Generate bar plot of top diagnoses among deceased
# Author: Julia Muller
# Date: 7 December 2024
# Last modified: February 2025
#####################################################

# Load libraries
suppressPackageStartupMessages({
  library(tidyverse)
  library(RSQLite)
})

# Source utility functions
source('scripts/utils.R')

# Pull patient, hospital, and clinical data from database
patient <- query_db('SELECT admission_id, age_group, gender, race, ethnicity FROM demographic')
hospital <- query_db('SELECT admission_id, hospital_service_area FROM hospital')
clinical <- query_db('SELECT admission_id, apr_risk_of_mortality, ccsr_diagnosis_description, type_of_admission, length_of_stay, patient_disposition FROM clinical')

# Merge datasets
data <- reduce(list(hospital, patient, clinical), full_join, by = 'admission_id')

# Select only deceased patients
deceased <- data %>% 
  filter(patient_disposition == 'Expired')

# Count the number of total and deceased records and write to separate log files
writeLines(as.character(nrow(data)), 'logs/total_pt_count.txt')
writeLines(as.character(nrow(deceased)), 'logs/total_deceased_count.txt')

# Risk of mortality distribution
deceased %>%
  group_by(apr_risk_of_mortality) %>%
  summarize(n())

# Top 10 diagnoses for deceased patients
top_10_cod <- deceased %>%
  count(ccsr_diagnosis_description) %>%
  mutate(prop = n/sum(n)) %>%
  arrange(desc(n)) %>%
  slice_head(n = 10)

# Simplify diagnosis naming for plotting
top_10_cod <- top_10_cod %>%
  mutate(ccsr_diagnosis_description = case_when(
    ccsr_diagnosis_description == 'Septicemia' ~ 'Sepsis',
    ccsr_diagnosis_description == 'Other aftercare encounter' ~ 'Aftercare',
    ccsr_diagnosis_description == 'Respiratory failure; insufficiency; arrest' ~ 'Respiratory Failure',
    ccsr_diagnosis_description == 'Cerebral infarction' ~ 'Stroke',
    ccsr_diagnosis_description == 'Acute hemorrhagic cerebrovascular disease' ~ 'Hemorrhagic Stroke',
    ccsr_diagnosis_description == 'Acute myocardial infarction' ~ 'Acute MI',
    ccsr_diagnosis_description == 'Secondary malignancies' ~ 'Secondary Cancer',
    ccsr_diagnosis_description == 'Traumatic brain injury (TBI); concussion, initial encounter' ~ 'TBI/Concussion',
    TRUE ~ ccsr_diagnosis_description))

# Plot top 10 diagnoses
plt <- ggplot(data = top_10_cod) +
  theme_minimal() +
  geom_bar(aes(x = reorder(ccsr_diagnosis_description, -prop), y = prop), stat = 'identity', fill = 'black') +
  theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5)) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 20)) +
  labs(x = 'APR-DRG Diagnosis Description', y = 'Proportion of Total Deaths')

# Save figure
ensure_directory('figures')
ggsave('figures/top_10_diagnosis_deceased_pts.png', plt, height = 5, width = 7, dpi = 600)
