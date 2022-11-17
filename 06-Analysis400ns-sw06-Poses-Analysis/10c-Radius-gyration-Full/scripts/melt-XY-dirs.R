#!/usr/bin/Rscript

library (reshape2)

meltFiles <- function (file1, file2, outName) {
	data1 = read.csv (file1)
	data2 = read.csv (file2)

	tableWide = cbind (data1, data2[2])
	names (tableWide) = c("FRAME", "PROTEIN", "COMPLEX")
	write.csv (tableWide, sprintf ("%s-wide.csv", outName), row.names=F)

	tableLong = melt (tableWide, id.vars = c("FRAME"), variable.name ="TYPE", value.name="RADIOG")
	write.csv (tableLong, sprintf ("%s-long.csv", outName), row.names=F)
}

args = commandArgs (trailingOnly=T)

dir1   = args [1]
dir2   = args [2]

outDir = "out-radiog"
system (sprintf ("mkdir %s", outDir))

subdirs = basename (list.dirs (dir1,  recursive=F))
print (subdirs)
for (sdir in subdirs) {
	path1 = sprintf ("%s/%s/radio-giration.csv", dir1, sdir)
	path2 = sprintf ("%s/%s/radio-giration.csv", dir2, sdir)

	system (sprintf ("mkdir  %s/%s", outDir, sdir)) 

	outName = sprintf ("%s/%s/radio-gyration", outDir, sdir)

	meltFiles (path1, path2, outName)
}



