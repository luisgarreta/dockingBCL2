DIR1="trajectory1000ns-Head-Protein"
DIR2="trajectory1000ns-Head-Complex"
#DIR1="trj10ns-TestAAA"
#DIR2="trj10ns-TestBBB"

OUT="out-rmsfs-Head-1000ns"

rmsfs-ALLP.py $DIR1 
rmsfs-ALLP.py $DIR2 

mkdir $OUT
cp out-$DIR1/out-$DIR1.csv $OUT
cp out-$DIR2/out-$DIR2.csv $OUT

cmm="create-longtable-fromFiles.py $OUT"; echo $cmm; eval $cmm
cmm='plot-XY-MultiLine.R $OUT-LONG.csv "RESID" "RMSF" "SYSTEM" "RMSFs complex vs. protein" "RESID"'; echo $cmm; eval $cmm

