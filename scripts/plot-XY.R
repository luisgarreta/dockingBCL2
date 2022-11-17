#!/users/legarreta/opt/miniconda3/envs/sims/bin/Rscript
#!/usr/bin/Rscript

# Plot lines plot  
USAGE = "plot-XY.R <Data file> <X column name> <Y column name> [Title] [X label] [Y label]" 

args      = commandArgs (trailingOnly=T)
if (length (args) < 3) {
	print (USAGE)
	quit ()
}
inputFile = args [1]
XCOL      = args [2]  
YCOL      = args [3]
values    = read.csv (inputFile, header=T)

TITLE     = ifelse (is.na (args [4]), paste("Plots for", YCOL), args[4])
XLABEL    = ifelse (is.na (args [5]), XCOL, args[5])
YLABEL    = ifelse (is.na (args [6]), YCOL, args[6])

library (ggplot2)

if (length (args) < 3) {
	message (USAGE)
	quit()
}

head (values)

plotXY <- function (values) {
	outputFile  = sprintf ("%s.pdf", strsplit (inputFile, "[.]")[[1]][1])
	head (values)
	response = colnames (values)[1]
	FORMULA = as.formula(paste("~", response))
	ggplot (data=values, aes_string(x=XCOL, y=YCOL)) + 
		geom_line (color="blue") +
		ggtitle (TITLE) + xlab(XLABEL) + ylab(YLABEL) 

	ggsave (outputFile, width=7, height=7)
}

plotXY (values)

