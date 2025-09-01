PDF=main.pdf
STATIC=../../static/papers/ted-law-karma.pdf

all: fig pdf publish

fig:
	python3 gen_figure.py

pdf:
	latexmk -pdf -silent main.tex

publish: $(PDF)
	@mkdir -p ../../static/papers
	cp $(PDF) $(STATIC)
	@echo "Published $(STATIC)"

clean:
	latexmk -C || true
	rm -f toy_example_plot.png $(PDF) *.aux *.log *.out *.toc *.bbl *.blg *.fls *.fdb_latexmk *.synctex.gz

.PHONY: all fig pdf publish clean
