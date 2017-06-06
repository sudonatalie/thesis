filename=MScThesis
lagda_dir=Figures/Agda

all:	figs lhs
	pdflatex ${filename}
	bibtex ${filename}||true
	pdflatex ${filename}
	bibtex ${filename}||true
	pdflatex ${filename}

quick:  lhs
	pdflatex ${filename}

figs:
	cd ${lagda_dir}; \
	find . -name '*.lagda' -exec agda --latex {} \;

lhs:
	lhs2TeX ${filename}.lhs -o ${filename}.tex

read:
	evince ${filename}.pdf &

clean:
	rm -rf ${lagda_dir}/latex/
	rm -f ${filename}.{tex,pdf,log,aux,out,bbl,blg,idx,lof,lot,ptb,toc}
	find . -name "*.agdai" -delete
