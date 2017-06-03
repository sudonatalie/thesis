filename=MScThesis
presentation=Presentation
lagda_dir=Figures/Agda

all:	figs lhs
	pdflatex ${filename}
	bibtex ${filename}||true
	pdflatex ${filename}
	bibtex ${filename}||true
	pdflatex ${filename}

p: plhs
	pdflatex ${presentation}
	pdflatex ${presentation}
	bibtex ${presentation}||true
	pdflatex ${presentation}
	bibtex ${presentation}||true
	pdflatex ${presentation}

quick:  lhs
	pdflatex ${filename}

pquick:  plhs
	pdflatex ${presentation}

figs:
	cd ${lagda_dir}; \
	find . -name '*.lagda' -exec agda --latex {} \;

lhs:
	lhs2TeX ${filename}.lhs -o ${filename}.tex

plhs:
	lhs2TeX ${presentation}.lhs -o ${presentation}.tex

read:
	evince ${filename}.pdf &

clean:
	rm -rf ${lagda_dir}/latex/
	rm -f ${filename}.{pdf,log,aux,out,bbl,blg,idx,lof,lot,ptb,toc}
