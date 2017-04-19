filename=MScThesis
lagda_dir=Figures/Agda

quick:
	pdflatex ${filename}

all:	figs
	pdflatex ${filename}
	bibtex ${filename}||true
	pdflatex ${filename}
	pdflatex ${filename}

figs:
	cd ${lagda_dir}; \
	agda --latex *.lagda

read:
	evince ${filename}.pdf &

clean:
	rm -rf ${lagda_dir}/latex/
	rm -f ${filename}.{pdf,log,aux,out,bbl,blg,idx,lof,lot,ptb,toc}
