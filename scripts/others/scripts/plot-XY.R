#!/usr/bin/Rscript

# plot Variable1 vs Variable2 from energies input file
USAGE="USAGE: plot-energyes.R <data table file> <variable 1> <variable 2>"

library (ggplot2)

args = commandArgs (trailingOnly=T)

if (length (args) < 3) {
	print (USAGE)
	quit()
}

dataFile = args [1]
prefix = strsplit (dataFile, "[.]csv")[[1]][1]
varX = args [2]
varY = args [3]

energies = read.csv (dataFile)
dataX = energies [,varX]
dataY = energies [,varY]
dataXY = data.frame (dataX, dataY)
#names (dataXY) = c(varX, sprintf ("%s (kcal/mol)",varY))
names (dataXY) = c(varX, varY)


#----------------------------------------------------------
getBreaks <- function (data, nBreaks=7) {
	vMin = min (data)
	vMax = max (data)

	vRange = vMax - vMin
	vStep  = (vRange / nBreaks)
	message (vMin, ", ", vMax, ",", vRange, ",", vStep)

	breaks = c()
	for (i in 0:nBreaks){
		b = vMin + (i)*vStep 
		if (i!=nBreaks)
			breaks = c(breaks, b)
		else
			breaks = c(breaks, vMax)
	}
	return (breaks)
}
#----------------------------------------------------------

xBreaks =  as.integer (getBreaks (dataX))
print (xBreaks)
yBreaks =  getBreaks (dataY)
print (yBreaks)

TITLE=sprintf ("%s vs %s", varY, varX )

library (scales)
ggplot (dataXY, aes_string (x=varX, y=varY)) + 
	geom_line (color="blue") +
	labs (title=TITLE) +
	theme(plot.title = element_text(hjust = 0.5)) +
	scale_x_continuous(name=varX, labels = comma, breaks=xBreaks) +
	scale_y_continuous(name=varY, labels = comma, breaks=yBreaks)


outPdf = sprintf ("%s_%s.pdf", prefix, varY)
ggsave (outPdf, width=10, height=10)
