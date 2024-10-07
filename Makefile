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
	
report.pdf: report.Rmd
	R -r "rmarkdown::render(\'report.Rmd'\, output_format=\'pdf_document'\)";