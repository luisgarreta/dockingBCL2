package require Orient
namespace import Orient::orient

mol new bclxl.pdb

set sel [atomselect top "all"]
set I [draw principalaxes $sel]
set A [orient $sel [lindex $I 2] {0 0 1}]
$sel move $A
set I [draw principalaxes $sel]
set A [orient $sel [lindex $I 1] {0 1 0}]
$sel move $A
set I [draw principalaxes $sel]

set grooveRes "segname PROA and resid 105 to 155"
set grooveSel [atomselect top $grooveRes]

mol color ColorID 4
mol representation NewCartoon 0.300000 10.000000 4.100000 0
mol selection $grooveRes
mol addrep 0

set I [draw principalaxes $grooveSel]
#axes location Origin
set A [orient $grooveSel [lindex $I 2] {0 0 1}]
$grooveSel move $A
set A [orient $sel [lindex $I 1] {0 1 0}]
$sel move $A
set I [draw principalaxes $sel]


