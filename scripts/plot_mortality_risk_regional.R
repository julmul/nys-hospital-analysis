library(tidyverse)
library(RSQLite)

conn <- dbConnect(RSQLite::SQLite(), dbname = 'derived_data/hospital-discharges.db')
hospitals <- dbGetQuery(conn, 'SELECT admission_id, hospital_service_area FROM hospital')
clinical <- dbGetQuery(conn, 'SELECT admission_id, apr_risk_of_mortality FROM clinical')
dbDisconnect(conn)

# Calculate proportions of mortality risk classifications by region
region_mortality_risk <- clinical %>%
  left_join(hospitals, by = 'admission_id') %>%
  filter(!is.na(hospital_service_area), !is.na(apr_risk_of_mortality)) %>%
  group_by(hospital_service_area, apr_risk_of_mortality) %>%
  summarize(count = n(), .groups = 'drop') %>%
  group_by(hospital_service_area) %>%
  mutate(proportion = count / sum(count)) %>%
  ungroup() %>%
  complete(hospital_service_area, apr_risk_of_mortality, fill = list(proportion = 0)) %>%
  mutate(name = factor(apr_risk_of_mortality, levels = c('Minor', 'Moderate', 'Major', 'Extreme')))

# Dodged bar plot of mortality risk by hospital service area
ggplot(region_mortality_risk, aes(x = hospital_service_area, y = proportion, fill = name)) +
  geom_bar(stat = 'identity', position = 'dodge') +
  labs(x = 'Hospital Service Area',
       y = 'Proportion of Patients',
       fill = 'Mortality Risk') +
  theme_minimal(base_size = 16) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_manual(values = c('#2ca02c', 'blue', '#ff7f0e', '#d62728'))

# Save figure
ggsave('figures/regional_mortality_risk_proportions.png', height = 5, width = 7)
