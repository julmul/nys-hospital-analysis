library(tidyverse)
library(RSQLite)

source('scripts/utils.R')

conn <- dbConnect(RSQLite::SQLite(), dbname = 'derived_data/hospital-discharges.db')
patient <- dbGetQuery(conn, 'SELECT admission_id, age_group, gender, race, ethnicity FROM demographic')
hospital <- dbGetQuery(conn, 'SELECT admission_id, hospital_service_area FROM hospital')
clinical <- dbGetQuery(conn, 'SELECT admission_id, apr_risk_of_mortality, ccsr_diagnosis_description, type_of_admission, length_of_stay, patient_disposition FROM clinical')
dbDisconnect(conn)

# Merge data
data <- hospital %>%
  full_join(patient, by = 'admission_id') %>%
  full_join(clinical, by = 'admission_id')

# Filter only deceased patients
expired <- data %>% 
  filter(patient_disposition == 'Expired')

# Count the number of records
data_count <- nrow(data)
expired_count <- nrow(expired)

# Write counts to separate .txt files
writeLines(as.character(data_count), 'logs/total_pt_count.txt')
writeLines(as.character(expired_count), 'logs/total_deceased_count.txt')

# Risk of mortality distribution
expired %>%
  group_by(apr_risk_of_mortality) %>%
  summarize(n())

# Top 10 diagnoses for expired patients
top_10_cod <- expired %>%
  group_by(ccsr_diagnosis_description) %>%
  tally() %>%
  arrange(desc(n)) %>%
  mutate(prop = n / sum(n)) %>%
  slice(1:10) %>%
  mutate(ccsr_diagnosis_description = if_else(ccsr_diagnosis_description == 'Traumatic brain injury (TBI); concussion, initial encounter', 
                                              'TBI/concussion', 
                                              ccsr_diagnosis_description))

# Plot top 10 diagnoses
ggplot(data = top_10_cod) +
  theme_minimal() +
  geom_bar(aes(x = reorder(ccsr_diagnosis_description, -prop), y = prop), stat = 'identity', fill = 'black') +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 20)) +
  labs(x = 'APR-DRG Diagnosis Description', y = 'Proportion of Total Deaths')

# Save figure
ensure_directory('figures')
ggsave('figures/top_10_diagnosis_deceased_pts.png', height = 5, width = 7, dpi = 600)
