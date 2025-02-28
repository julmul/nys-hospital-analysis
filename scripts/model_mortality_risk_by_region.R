#####################################################
# Model risk of extreme mortality by hospital service area
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

# Pull hospital and clinical data from database
hospitals <- query_db('SELECT admission_id, hospital_service_area FROM hospital')
clinical <- query_db('SELECT admission_id, apr_risk_of_mortality, apr_drg_code FROM clinical')

# Prepare data for logistic regression
region_mortality_data <- clinical %>%
  left_join(hospitals, by = 'admission_id') %>%
  filter(!is.na(hospital_service_area), 
         !is.na(apr_risk_of_mortality), 
         !apr_drg_code %in% c(540, 640, 560)) %>%
  select(apr_risk_of_mortality, hospital_service_area) %>%
  mutate(apr_risk_of_mortality = factor(apr_risk_of_mortality, levels = c('Minor', 'Moderate', 'Major', 'Extreme')),
         hospital_service_area = factor(hospital_service_area, levels = unique(hospital_service_area)))

# Fit binary logistic regression for 'Extreme' risk category
model_extreme <- glm(apr_risk_of_mortality == 'Extreme' ~ hospital_service_area, 
                     data = region_mortality_data, 
                     family = 'binomial')

# Extract odds ratios, standard errors, and confidence intervals
model_summary <- summary(model_extreme)
coefs <- model_summary$coefficients
odds_ratios <- exp(coefs[, 'Estimate'])
std_errors <- coefs[, 'Std. Error']

# Calculate 95% confidence intervals
z_value <- qnorm(0.975)
lower_ci <- exp(coefs[, 'Estimate'] - z_value * std_errors)
upper_ci <- exp(coefs[, 'Estimate'] + z_value * std_errors)

# Combine results into a data frame
results_extreme <- data.frame(
  hospital_service_area = rownames(coefs),
  odds_ratio = odds_ratios,
  lower_ci = lower_ci,
  upper_ci = upper_ci) %>%
  filter(hospital_service_area != '(Intercept)') %>%
  mutate(hospital_service_area = recode(hospital_service_area,
                                   'hospital_service_areaSouthern Tier' = 'Southern Tier',
                                   'hospital_service_areaCapital/Adirond' = 'Capital/Adirondack',
                                   'hospital_service_areaFinger Lakes' = 'Finger Lakes',
                                   'hospital_service_areaHudson Valley' = 'Hudson Valley',
                                   'hospital_service_areaLong Island' = 'Long Island',
                                   'hospital_service_areaWestern NY' = 'Western NY',
                                   'hospital_service_areaCentral NY' = 'Central NY')) %>%
  arrange(desc(odds_ratio)) %>%
  mutate(hospital_service_area = factor(hospital_service_area, levels = hospital_service_area))
  
# Create forest plot
plt <- ggplot(results_extreme, aes(x = hospital_service_area, y = odds_ratio)) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci), width = 0.2) +
  geom_hline(yintercept = 1, linetype = 'dashed', color = 'red') +
  labs(x = 'Hospital Service Area',
       y = 'Odds Ratio') +
  theme_minimal(base_size = 20) +
  coord_flip()

# Save figure
ensure_directory('figures')
ggsave('figures/regional_mortality_odds.png', plt, height = 7, width = 7)
