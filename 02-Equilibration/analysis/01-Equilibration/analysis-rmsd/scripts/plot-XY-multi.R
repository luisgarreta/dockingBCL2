#!/usr/bin/Rscript

# Plot equilibration RMSDs for all six steps (1-6) 
USAGE="USAGE: plot-energyes.R <Multi RMSD file>" 

library (ggplot2)

args = commandArgs (trailingOnly=T)

if (length (args) < 1) {
	print (USAGE)
	quit()
}

dataFile = args [1]
values = read.csv (dataFile)
values$TIME = values$TIME*5000
conditions = values$STEP=="step6.4"

# timestep=2fs
values [conditions,"TIME"] = values [conditions, "TIME"]*2
conditions = values$STEP=="step6.5"
values [conditions,"TIME"] = values [conditions, "TIME"]*2
conditions = values$STEP=="step6.6"
values [conditions,"TIME"] = values [conditions, "TIME"]*2

ggplot (data=values, aes(x=TIME, y=RMSD)) + 
	geom_line (color="blue") +
	ggtitle ("Equilibration")+xlab("TIME (fs)")+ylab("RMSD (A)") +
	facet_wrap (~STEP, ncol=2, scales="free")
ggsave ("rmsds_multi.pdf", width=20, height=10)

