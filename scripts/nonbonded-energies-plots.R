#!/usr/bin/env Rscript

#!/users/legarreta/opt/miniconda3/envs/sims/bin/Rscript
#!/usr/bin/Rscript

# Plot equilibration RMSDs for all six steps (1-6) 
USAGE="\
Plot a time series data (e.g. RMSD). \n\
File with first column with the name of each plot.\n\
\n\
USAGE: plot-XY-multi <Multi RMSD file>" 

MAINTITLE = "Non-bonded energies"
XLABEL    = "TIME (ns)"
YLABEL    = "Energy (kcal/mol)"
OUTFILE = "nonbonded-energies.pdf"

library (ggplot2)
main <- function () {
	args = commandArgs (trailingOnly=T)

	if (length (args) < 1) {
		print (USAGE)
		quit()
	}

	inputFile   = args [1]
	values      = read.table (inputFile, header=T)
	values      = values [,c("Pose","Frame","Elec","VdW", "Nonbond")]

	# Preprocessing values: scale to ns, remove sw22
	values$Frame = values$Frame/10 
	values = values [values$Pose=="sw06",]
	#plotXY (values, "Total")
	#plotXY (values, "Elec")
	#plotXY (values, "VdW")
	multiplotXY (values)
}

#----------------------------------------------------------
#----------------------------------------------------------
multiplotXY <- function (values) {
	library (reshape2)
	values = melt (values, id.vars = c("Pose", "Frame"), variable.name="Type") 
	head (values)
	response = colnames (values)[1]
	FORMULA  = as.formula(paste("~", response))
	XCOL     = "Frame"
	ggplot (data=values, aes_string(x=XCOL, y = "value", color = "Type")) + 
		geom_line () +
		ggtitle (MAINTITLE) + xlab(XLABEL) + ylab(YLABEL) +
		facet_wrap (FORMULA, ncol=2, scales="free") +
		theme(strip.text.x = element_text(size = 15))

	ggsave (OUTFILE, width=10, height=7)
}

#----------------------------------------------------------
#----------------------------------------------------------
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
		facet_wrap (FORMULA, ncol=2, scales="free") +
		theme(strip.text.x = element_text(size = 15))

	ggsave (outputFile, width=10, height=7)
}
#----------------------------------------------------------
#----------------------------------------------------------
main ()

