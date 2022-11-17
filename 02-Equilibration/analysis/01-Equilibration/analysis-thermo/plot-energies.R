#!/usr/bin/Rscript

# plot Variable1 vs Variable2 from energies input file
USAGE="USAGE: plot-energyes.R <energies file> <variable 1> <variable 2>"

library (ggplot2)

args = commandArgs (trailingOnly=T)

if (length (args) < 3) {
	print (USAGE)
	quit()
}

energiesFile = args [1]
prefix = strsplit (energiesFile, "[.]")[[1]][1]
varX = args [2]
varY = args [3]

energies = read.csv (energiesFile)
dataX = energies [,varX]
dataY = energies [,varY]
dataXY = data.frame (dataX, dataY)

#names (dataXY) = c(varX, sprintf ("%s (kcal/mol)",varY))
names (dataXY) = c(varX, varY)
outName =  sprintf ("%s_%s", prefix, varY)
write.csv (dataXY, paste0 (outName, ".csv"), row.names=F)
write.table (dataXY, paste0 (outName, ".xmg"), row.names=F, col.names=F, sep="\t")

pdf (sprintf (paste0 (outName, ".pdf")))
#par(las=1)
#par(mar=c(4,5,1,2))
#par(mar=c(8,10,1,1)) # adjust as needed
#plot (dataXY, type="l", col="blue",
#      main=sprintf ("%s vs %s", varY, varX ))
#dev.off()

getBreaks <- function (data, nBreaks=7) {
	vMin = min (data)
	vMax = max (data)

	vRange = vMax - vMin
	vStep  = as.integer (vRange / nBreaks)
	message (vMin, ", ", vMax, ",", vRange, ",", vStep)

	breaks = c()
	for (i in 0:nBreaks){
		b = vMin + (i)*vStep 
		print (b)
		if (i!=nBreaks)
			breaks = c(breaks, b)
		else
			breaks = c(breaks, vMax)
	}
	return (breaks)
}

xBreaks =  getBreaks (dataX)
yBreaks =  getBreaks (dataY)

TITLE=sprintf ("%s vs %s", varY, varX )

library (scales)
ggplot (dataXY, aes_string (x=varX, y=varY)) + 
	geom_line (color="blue") +
	labs (title=TITLE) +
	theme(plot.title = element_text(hjust = 0.5)) +
	scale_x_continuous(name=varX, labels = comma, breaks=xBreaks) +
	scale_y_continuous(name=varY, labels = comma, breaks=yBreaks)


