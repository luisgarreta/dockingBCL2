#!/usr/bin/env Rscript

#!/users/legarreta/opt/miniconda3/envs/sims/bin/Rscript
#!/usr/bin/Rscript

# Plot lines plot  
USAGE = "plot-XY-generic.R <Data file in long format> <X column name> <Y column name> <X label> <Y label> <Main Title>" 

args      = commandArgs (trailingOnly=T)
if (length (args) < 3) {
	print (USAGE)
	quit ()
}
inputFile = args [1]
XCOL      = args [2]  
YCOL      = args [3]
ZCOL      = args [4]
values    = read.csv (inputFile, header=T)
# Preprocessing values: scale to ns, remove sw22
if (XCOL=="FRAME")
	values [,XCOL] = values [,XCOL]/10
#values = values [values$POSE=="sw06",]

XLABEL    = ifelse (is.na (args [5]), XCOL, args[5])
YLABEL    = ifelse (is.na (args [6]), YCOL, args[6])
TITLE     = ifelse (is.na (args [7]), paste("Plots for", YCOL), args[7])

library (ggplot2)

if (length (args) < 3) {
	message (USAGE)
	quit()
}

head (values)

plotXY <- function (values) {
	#TITLE = gsub ("Total", columnName, TITLE)
	outputFile  = sprintf ("%s.pdf", strsplit (inputFile, "[.]")[[1]][1])
	head (values)
	#response = colnames (values)[1]
	response = ZCOL
	FORMULA = as.formula(paste("~", response))
	#ggplot (data=values, aes_string(x=XCOL, y=YCOL, color="TYPE")) + 
	ggplot (data=values, aes_string(x=XCOL, y=YCOL)) + 
		geom_line (color="blue") +
		ggtitle (TITLE) + xlab(XLABEL) + ylab(YLABEL) +
		facet_wrap (FORMULA, ncol=2, scales="fixed") +
		theme(strip.text.x = element_text(size = 15))

	ggsave (outputFile, width=7, height=7)
}

plotXY (values)

