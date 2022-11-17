#!/home/lg/.bin/xvmd
# Create PSF file from trajectory frame

set USAGE "xvmd md-create-psf-file.tcl <PDB file> <Topology file>"

set PDB       [lindex $argv 0]
set TOPOLOGY  [lindex $argv 1]

if {$PDB eq ""} then {
	puts $USAGE; exit
}

set NAME [lindex [split $PDB "."] 0]

mol new $PDB type {pdb} 

package require psfgen
topology top_all27_prot_lipid.inp
pdbalias residue HIS HSE
pdbalias atom ILE CD1 CD
segment MAIN {
	pdb $PDB
}
coordpdb $PDB MAIN
guesscoord

writepdb $NAME.pdb
writepsf $NAME.psf
quit
