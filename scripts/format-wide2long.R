#!/usr/bin/Rscript

library (reshape)

args = commandArgs (trailingOnly=T)

inputFile = args [1]
idName    = args [2]
varName   = args [3]
valueName = args [4]

data   = read.csv (inputFile)
n      = nrow (data)

head (data)


rdata = melt (data, id=c(idName), variable_name = varName, value.name = valueName)
names (rdata) = c(idName, varName, valueName)
outFile = sprintf ("%s-LONG.csv", strsplit (inputFile, "[.]")[[1]][1])
write.csv (rdata, outFile, row.names=F)


