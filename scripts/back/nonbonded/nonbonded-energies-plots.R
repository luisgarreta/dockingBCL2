#!/usr/bin/Rscript

# Plot equilibration RMSDs for all six steps (1-6) 
USAGE="\
Plot a time series data (e.g. RMSD). \n\
File with first column with the name of each plot.\n\
\n\
USAGE: plot-XY-multi <Multi RMSD file>" 

MAINTITLE = "Total non-bonded energies (Elec+VdW)"
XLABEL    = "TIME (x5000fs)"
YLABEL    = "Energy (kcal/mol)"

library (ggplot2)

args = commandArgs (trailingOnly=T)

if (length (args) < 1) {
	print (USAGE)
	quit()
}

inputFile   = args [1]
values      = read.table (inputFile, header=T)

plotXY <- function (values, columnName) {
	MAINTITLE = gsub ("Total", columnName, MAINTITLE)
	outputFile  = sprintf ("%s-%s.pdf", strsplit (inputFile, "[.]")[[1]][1], columnName)
	head (values)
	response = colnames (values)[1]
	FORMULA = as.formula(paste("~", response))
	XCOL = "Frame"
	YCOL = columnName
	ggplot (data=values, aes_string(x=XCOL, y=YCOL)) + 
		geom_line (color="blue") +
		ggtitle (MAINTITLE) + xlab(XLABEL) + ylab(YLABEL) +
		facet_wrap (FORMULA, ncol=2, scales="free")

	ggsave (outputFile, width=10, height=10)
}

plotXY (values, "Total")
plotXY (values, "Elec")
plotXY (values, "VdW")

