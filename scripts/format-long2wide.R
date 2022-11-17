#!/usr/bin/Rscript

library (reshape)

args = commandArgs (trailingOnly=T)

inputFile = args [1]
TIMEVAR   = args [2] # Var with names to be expanded to wide 
IDVAR    = args [3]  # Time or frames

data   = read.csv (inputFile)
n      = nrow (data)

head (data)

rdata = reshape(data, idvar = IDVAR, timevar = TIMEVAR, direction = "wide")

#rdata = melt (data, id=c(TIMEVAR), variable_name = IDVAR, value.name = valueName)
#names (rdata) = c(TIMEVAR, IDVAR, valueName)
outFile = sprintf ("%s-WIDE.csv", strsplit (inputFile, "[.]")[[1]][1])
write.csv (rdata, outFile, row.names=F)


