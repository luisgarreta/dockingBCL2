TYPE="Groove"
DIR1="trajectory1000ns-$TYPE-Protein"
DIR2="trajectory1000ns-$TYPE-Complex"
#DIR1="trj10ns-TestAAA"
#DIR2="trj10ns-TestBBB"
OUT="out-radiusg-1000ns"

RadioGyration-ALLP.py $DIR1 
#RadioGyration-ALLP.py $DIR2 

mkdir $OUT
cp out-$DIR1/out-$DIR1.csv $OUT
cp out-$DIR2/out-$DIR2.csv $OUT

cmm="create-longtable-fromFiles.py $OUT"; echo $cmm; eval $cmm
cmm='plot-XY-MultiLine.R $OUT-LONG.csv "FRAME" "RADIUSG" "SYSTEM" "Radius of gyration for complex vs. protein" "FRAME (ns)"'; echo $cmm; eval $cmm

