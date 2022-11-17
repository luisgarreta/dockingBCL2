#!/usr/bin/Rscript
# Create table with averages for conformation.

suppressMessages (library (dplyr))
args = commandArgs (trailingOnly=T)

tableFilename = args[1]

data = read.csv (tableFilename)
avrData = data %>% group_by (Conformation, LigandName) %>% 
			   summarize (AutodockAvr=mean (AD_BindingEnergy),
			   VinaAvr=mean (VN_BindingEnergy), 
			   Average=mean(Average_Energy)) %>%
			   arrange (Average)

print (avrData)
outname = paste0 (strsplit (tableFilename, split="[.]")[[1]][1], "-AVR.csv")
write.csv (avrData, outname, row.names=F)
