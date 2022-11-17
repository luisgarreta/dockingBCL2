#!/users/legarreta/opt/miniconda3/envs/sims/bin/Rscript
#!/usr/bin/Rscript

# Plot equilibration RMSDs for all six steps (1-6) 
USAGE="\
Plot a time series data (e.g. RMSD). \n\
File with first column with the name of each plot.\n\
\n\
USAGE: plot-XY-multi <Multi RMSD file>" 

MAINTITLE = "RMSDs for ligand poses"
XLABEL    = "Frame No."
YLABEL    = "RMSD (Angstroms)"
XCOL      = "FRAME"

library (ggplot2)

args = commandArgs (trailingOnly=T)

if (length (args) < 1) {
	print (USAGE)
	quit()
}

inputFile   = args [1]
MAINTITLE   = args [2]
TYPE        = args [3]

outputFile  = sprintf ("%s-%s.pdf", strsplit (inputFile, "[.]")[[1]][1], TYPE)
values      = read.csv (inputFile, header=T)
print ("....")
head (values)

plotXY <- function (values, columnName, MAINTITLE, outputFile) {
	head (values)
	response = colnames (values)[1]
	FORMULA = as.formula(paste("~", response))
	YCOL = columnName
	ggplot (data=values, aes_string(x=XCOL, y=YCOL)) + 
		geom_line (color="blue") +
		ggtitle (MAINTITLE) + xlab(XLABEL) + ylab(YLABEL) +
		facet_wrap (FORMULA, ncol=2, scales="free")

	ggsave (outputFile, width=10, height=10)
}

plotXY (values, "RMSD", MAINTITLE, outputFile)

