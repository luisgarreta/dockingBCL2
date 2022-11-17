#!/usr/bin/env Rscript

#!/users/legarreta/opt/miniconda3/envs/sims/bin/Rscript
#!/usr/bin/Rscript

# Plot lines plot  
USAGE = "\n
Two lines generic plot (Two variables) \n
plot-XY-generic-MULTI.R <Data file in long format> <X column name> <Y column name> <X label> <Y label> <Main Title>\n" 

args      = commandArgs (trailingOnly=T)
if (length (args) < 3) {
	cat (USAGE)
	quit ()
}
inputFile = args [1]
XCOL      = args [2]  
YCOL      = args [3]
values    = read.csv (inputFile, header=T)

# Preprocessing values: scale to ns, remove sw22
values [,XCOL] = values [,XCOL]/10
#values = values [values$POSE=="sw06",]

XLABEL    = ifelse (is.na (args [4]), XCOL, args[4])
YLABEL    = ifelse (is.na (args [5]), YCOL, args[5])
TITLE     = ifelse (is.na (args [6]), paste("Plots for", YCOL), args[6])

library (ggplot2)

if (length (args) < 3) {
	message (USAGE)
	quit()
}

head (values)

ggplot (data=values, mapping=aes_string(x=XCOL, y=YCOL, color="TYPE")) + 
		geom_line () 
outputFile  = sprintf ("%s.pdf", strsplit (inputFile, "[.]")[[1]][1])
ggsave (outputFile, width=10, height=7)

plotXY <- function (values) {
	#TITLE = gsub ("Total", columnName, TITLE)
	outputFile  = sprintf ("%s.pdf", strsplit (inputFile, "[.]")[[1]][1])
	head (values)
	response = colnames (values)[1]
	FORMULA = as.formula(paste("~", response))
	ggplot (data=values, aes_string(x=XCOL, y=YCOL)) + 
		geom_line () +
		ggtitle (TITLE) + xlab(XLABEL) + ylab(YLABEL) +
		facet_wrap (FORMULA, ncol=1, scales="fixed") +
		theme(strip.text.x = element_text(size = 15)) 

	ggsave (outputFile, width=10, height=7)
}

#plotXY (values)

