#!/usr/bin/Rscript
library (reshape2)
library (ggplot2)

USAGE="plot-thermodinamics-energies.R <Energies file>"

args = commandArgs (trailingOnly=T)
if (length (args) < 1){
	print (USAGE)
	quit()
}

energiesFile = args [1]
prefix       = strsplit (energiesFile, "[.]")[[1]][1]
energies     = read.csv (energiesFile)
vars         = colnames (energies)
print (vars)

#energies20k = energies [energies$TS>20000,]

energiesLong = melt (energies, id.vars=vars[1])
write.csv (energiesLong, paste0(prefix, "-LONG.csv"), row.names=F)

ggplot (data=energiesLong, aes(x=TS, y=value)) + 
	geom_line (color="blue") +
	ggtitle ("Thermodynamic variables")+xlab("TIME STEPS")+ylab("Energy") +
	facet_wrap (~variable, scales="free_y")
ggsave (paste0(prefix, "-PLOT.pdf"), width=20, height=10)

