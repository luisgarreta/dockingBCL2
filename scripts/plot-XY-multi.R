#!/usr/bin/Rscript

# Plot equilibration RMSDs for all six steps (1-6) 
USAGE="\
Plot a time series data (e.g. RMSD). \n\
File with first column with the name of each plot.\n\
\n\
USAGE: plot-XY-multi <Multi RMSD file>" 

MAINTITLE="RMSDs for Docking poses"

library (ggplot2)

args = commandArgs (trailingOnly=T)

if (length (args) < 1) {
	print (USAGE)
	quit()
}

inputFile   = args [1]
outputFile  = sprintf ("%s.pdf", strsplit (inputFile, "[.]")[[1]][1])
values      = read.csv (inputFile)
values$TIME = values$TIME*5000

response = colnames (values)[1]
FORMULA = as.formula(paste("~", response))
ggplot (data=values, aes(x=TIME, y=RMSD)) + 
	geom_line (color="blue") +
	ggtitle (MAINTITLE)+xlab("TIME (fs)")+ylab("RMSD (A)") +

	facet_wrap (FORMULA, ncol=2, scales="free")
ggsave (outputFile, width=10, height=10)

