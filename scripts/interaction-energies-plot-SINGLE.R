#!/usr/bin/env Rscript

#!/users/legarreta/opt/miniconda3/envs/sims/bin/Rscript
USAGE=" Plot interactions energies for each ligand pose in a grid
INPUTS: <Energies file>"

library (ggplot2)
library (tidyverse)

args = commandArgs (trailingOnly = T)
inputFile  = args [1]  # Energies file as "interaction-energies-all.csv"
outputFile = paste0 (strsplit (inputFile, "[.]")[[1]][1], ".pdf")
TITLE      = "Other interaction energies"

values     = read.csv (inputFile)
response   = colnames (values)[1]
FORMULA    = as.formula(paste("~", response))
data       = read.csv (inputFile, stringsAsFactors=F)
data$FRAME = data$FRAME/10.
g = ggplot(data, 
       aes(x = FRAME, y=RESIDUE, fill = INTERACTION)) + 
  	   geom_tile(position = "dodge") +
       labs (fill = "Interactions") +
       geom_hline(yintercept = 0.5 + 0:35, colour = "black", size = 0.3) +
       theme(legend.position="top") +
       ggtitle (TITLE) + scale_fill_discrete(name = "") + 
       xlab ("FRAME (ns)") 

ggsave (outputFile, width=10, height=7)
