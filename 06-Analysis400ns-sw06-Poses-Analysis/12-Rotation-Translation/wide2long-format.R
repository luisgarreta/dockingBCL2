#!/usr/bin/Rscript

library (reshape)

args = commandArgs (trailingOnly=T)

inputFile = args [1]

data   = read.csv (inputFile)
n      = nrow (data)
#values = seq (1,n,10)
#data   = data [values,]

dataTranslation = data
#dataTranslation = data.frame (data[,1:4])
head (dataTranslation)
#dataRotation    = data.frame (FRAME=data[,1], data[,5:7])
#head (dataRotation)


rdataTrans = melt (dataTranslation, id=c("FRAME"))
names (rdataTrans) = c("FRAME", "MEASURE", "VALUE")
outFile = sprintf ("%s-LONG-translation.csv", strsplit (inputFile, "[.]")[[1]][1])
write.csv (rdataTrans, outFile, row.names=F)

#rdataRot = melt (dataRotation, id=c("FRAME"))
#names (rdataRot) = c("FRAME", "MEASURE", "VALUE")
#outFile = sprintf ("%s-LONG-rotation.csv", strsplit (inputFile, "[.]")[[1]][1])
#write.csv (rdataRot, outFile, row.names=F)

