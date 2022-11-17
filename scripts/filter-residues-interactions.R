#!/usr/bin/Rscript
USAGE="\
Filter residues with few interactions (1% of frames)"

args = commandArgs (trailingOnly=T)

infile    = args [1]
outfile   = sprintf ("%s-FILTERED.csv", strsplit (infile, "[.]")[[1]][1])
dt        = read.csv (infile)
minInter  = 30     # 200*0.1 

resnames = unique (dt$residue)

for (res in resnames) {
	dtt = dt[dt$value=="True" & dt$residue==res,]
	ninter = nrow (dtt)
	if (ninter < minInter) {
		message (res, ": ", ninter)
		dt = dt [dt$residue!=res,]
	}
}

write.csv (dt, outfile, quote=F, row.names = F)

