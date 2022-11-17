#!/home/lg/.bin/xvmd
# Create PSF file from trajectory frame
package require psfgen

set PDB  [lindex $argv 0]
set NAME [lindex [split $PDB "."] 0]

mol new $PDB type {pdb} first 0 last -1 step 1 waitfor 1

topology top_all27_prot_lipid.inp
pdbalias residue HIS HSE
pdbalias atom ILE CD1 CD
segment U {pdb $PDB}
coordpdb $PDB U
guesscoord
writepdb ubq.pdb
writepsf $NAME.psf
quit
