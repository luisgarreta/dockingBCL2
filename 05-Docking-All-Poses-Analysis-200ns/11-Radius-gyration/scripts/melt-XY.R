#!/usr/bin/Rscript

library (reshape2)

args = commandArgs (trailingOnly=T)

file1 = args [1]
file2 = args [2]

data1 = read.csv (file1)
data2 = read.csv (file2)

tableWide = cbind (data1, data2[2])
names (tableWide) = c("FRAME", "PROTEIN", "COMPLEX")
write.csv (tableWide, "wide.csv", row.names=F)

tableLong = melt (tableWide, id.vars = c("FRAME"), variable.name ="TYPE")
write.csv (tableLong, "long.csv", row.names=F)

