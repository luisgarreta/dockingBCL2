#!/usr/bin/env Rscript

#!/users/legarreta/opt/miniconda3/envs/sims/bin/Rscript
#!/usr/bin/Rscript

# Plot lines plot  
USAGE = "\n
Two lines generic plot (Two variables) \n
plot-XY-generic-nVarsOneFigure.R  <Long format file> <X column> <Y column> <Var column> <Title> [X label] [Y label]\n" 

args = commandArgs (trailingOnly=T)
if (length (args) < 3) {
	cat (USAGE)
	quit ()
}
inputFile = args [1]
XCOL      = args [2]  
YCOL      = args [3]
ZCOL      = args [4]
TITLE     = ifelse (is.na (args [5]), "Plot for %s" + YCOL, args[5])
values    = read.csv (inputFile, header=T)
if (XCOL=="FRAME")
	values[,XCOL] = values[,XCOL]/10

# Preprocessing values: scale to ns, 
#values [,XCOL] = values [,XCOL]/10

n = 5
XLABEL    = ifelse (is.na (args [n+1]), XCOL, args[n+1])
YLABEL    = ifelse (is.na (args [n+2]), YCOL, args[n+2])

library (ggplot2)

if (length (args) < 3) {
	message (USAGE)
	quit()
}

head (values)

# Check if single or multiline
if (length (unique (values[,ZCOL])) > 1) { 
	ggplot (data=values, mapping=aes_string(x=XCOL, y=YCOL, color=ZCOL)) + 
			geom_line (alpha=0.8) +
			ggtitle (TITLE) + xlab(XLABEL) + ylab(YLABEL) +
			theme (text = element_text(size = 12)) #+ ylim (-280, 80) 
			#theme(strip.text.x = element_text(size = 45)) 
}else {
	ggplot (data=values, mapping=aes_string(x=XCOL, y=YCOL)) + 
			geom_line (alpha=0.8, color="blue") +
			ggtitle (TITLE) + xlab(XLABEL) + ylab(YLABEL) +
			theme (text = element_text(size = 12)) #+ ylim (-250, 50) 
			#theme(strip.text.x = element_text(size = 45)) 
}


outputFile  = sprintf ("%s.pdf", strsplit (inputFile, "[.]")[[1]][1])
ggsave (outputFile, width=7, height=5)

plotXY <- function (values) {
	outputFile  = sprintf ("%s.pdf", strsplit (inputFile, "[.]")[[1]][1])
	head (values)
	response = colnames (values)[1]
	FORMULA = as.formula(paste("~", response))
	ggplot (data=values, aes_string(x=XCOL, y=YCOL)) + 
		geom_line (alpha=0.4) +
		ggtitle ("TITLE") + xlab(XLABEL) + ylab(YLABEL) +
		facet_wrap (FORMULA, ncol=1, scales="fixed") +

	ggsave (outputFile, width=10, height=7)
}

#plotXY (values)

