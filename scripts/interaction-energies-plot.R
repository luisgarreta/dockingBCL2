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
XLABEL     = "TIME (ns)"

values     = read.csv (inputFile)
response   = colnames (values)[1]
FORMULA    = as.formula(paste("~", response))
data       = read.csv (inputFile, stringsAsFactors=F)
#values = data [data$Pose=="sw06",]
values = data$FRAME/10. # For only one plot
data$FRAME = data$FRAME/10. # For only one plot
g = ggplot(data, 
       #aes(x = fct_inorder (RESIDUE), y=FRAME, fill = fct_inorder (INTERACTION))) + 
       aes(x = FRAME, y=RESIDUE, fill = INTERACTION)) + 
  	   geom_raster(position = "dodge") +
  	   facet_grid (cols=vars (fct_inorder (RESIDUE)),scales = "free", space = "free")+
  	   #theme(text=element_text (size=8), axis.title.x=element_blank(), axis.text.x=element_blank(), axis.ticks.x=element_blank()) +
       labs (fill = "INTERACTION") +
       #theme (panel.border = element_blank(), panel.grid = element_blank(), panel.spacing = element_blank()) +
       geom_hline(yintercept = 0.5 + 0:35, colour = "black", size = 0.001) +
       theme(legend.position="top") +
       ggtitle (TITLE) + xlab(XLABEL) + scale_fill_discrete(name = "") +
       facet_wrap (FORMULA, ncol=2, scales="free_y")

#ggsave (outputFile, height=3)
ggsave (outputFile, width=10, height=10)
