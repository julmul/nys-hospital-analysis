.PHONY: clean
.PHONY: init

init:
	mkdir -p derived_data
	mkdir -p figures
	mkdir -p logs

clean:
	rm -rf derived_data
	rm -rf figures
	rm -rf logs
	rm report.pdf

derived_data/hospital_discharges_tidied.csv: source_data/hospital_data.csv scripts/clean_hospital_data.R scripts/utils.R
	Rscript scripts/clean_hospital_data.R

derived_data/hospital-discharges.db: derived_data/hospital_discharges_tidied.csv scripts/create_sql_database.R
	Rscript scripts/create_sql_database.R

figures/hospitals_per_county.rds: derived_data/hospital-discharges.db source_data/Counties_Shoreline.shp scripts/map_hospitals_by_county.R scripts/utils.R
	Rscript scripts/map_hospitals_by_county.R

figures/nys_hospital_service_areas.rds: derived_data/hospital-discharges.db source_data/Counties_Shoreline.shp scripts/map_hospital_service_areas.R scripts/utils.R
	Rscript scripts/map_hospital_service_areas.R
	
figures/regional_mortality_risk_proportions.png logs/total_rom_nonmissing.txt logs/total_rom_count.txt: derived_data/hospital-discharges.db scripts/plot_mortality_risk_by_region.R scripts/utils.R
	Rscript scripts/plot_mortality_risk_by_region.R
	
figures/regional_mortality_odds.png: derived_data/hospital-discharges.db scripts/model_mortality_risk_by_region.R scripts/utils.R
	Rscript scripts/model_mortality_risk_by_region.R

figures/top_10_diagnosis_overall.png: derived_data/hospital-discharges.db scripts/plot_top_diagnoses.R scripts/utils.R
	Rscript scripts/plot_top_diagnoses.R
	
figures/top_10_diagnosis_deceased_pts.png logs/total_pt_count.txt logs/total_deceased_count.txt: derived_data/hospital-discharges.db scripts/plot_top_diagnoses_deceased.R scripts/utils.R
	Rscript scripts/plot_top_diagnoses_deceased.R

figures/relative_predictive_importance.rds: derived_data/hospital-discharges.db scripts/predict_mortality_risk.R scripts/utils.R
	Rscript scripts/predict_mortality_risk.R

figures/hospital_clusters_high_risk.png figures/nys_map_hospital_clusters.rds: derived_data/hospital-discharges.db scripts/cluster_hospital_risk.R scripts/utils.R
	Rscript scripts/cluster_hospital_risk.R

report.pdf: report.Rmd\
 init\
 figures/hospitals_per_county.rds\
 figures/nys_hospital_service_areas.rds\
 figures/regional_mortality_risk_proportions.png\
 figures/regional_mortality_odds.png\
 figures/top_10_diagnosis_overall.png\
 figures/top_10_diagnosis_deceased_pts.png\
 figures/relative_predictive_importance.rds\
 figures/hospital_clusters_high_risk.png\
 figures/nys_map_hospital_clusters.rds
	Rscript -e "rmarkdown::render('report.Rmd', output_format='pdf_document')"
	