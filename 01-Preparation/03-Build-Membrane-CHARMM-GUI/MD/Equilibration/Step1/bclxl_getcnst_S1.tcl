set name bclxl_assembly

mol new ../../MembBuilding/${name}.psf
mol addfile ../../MembBuilding/${name}.pdb

set all [atomselect top all]

# Using info of PMPE lipid (same tail as POPC)
# lipid tail of phospholipid (POPC) 
set relax1 [atomselect top "((resname POPC) and not (name C1 C11 C12 C2 C21 C3 C31 HN1 HN2 HN3 H11A H11B H12A H12B HA HB HS HX HY O11 O12 O13 O14 O21 O22 O31 O32 N P))"]

$all set beta 1
$relax1 set beta 0

$all writepdb ${name}_S1.cnst
quit




