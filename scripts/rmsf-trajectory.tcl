#!/usr/bin/env xvmd.py
#
#!/users/legarreta/bin/xvmd
#!/home/lg/.bin/xvmd
#
# Aligning trajectories based on an atom selection and 
# calculate RMSF of alpha carbons

set PSF  [lindex $argv 0];
set DCD  [lindex $argv 1];

# Aligning trajectories based on an atom selection
# Used for aligning the transmembrane domain
proc align {rmolid smol} {
	set ref_molid $rmolid
	set sel_mol $smol
	set numframes [molinfo $ref_molid get numframes]
	set ref_frame [atomselect $ref_molid "$sel_mol" frame 0]
	$ref_frame writepdb "ref_frame.pdb"
	set n 1
	set sys [atomselect $ref_molid all]
	for {set i 0} {$i < $numframes} {incr i} {
		animate goto $i
		set align_frame [atomselect $ref_molid "$sel_mol"]
		set trans_matrix [measure fit $align_frame $ref_frame]
		$sys move $trans_matrix
		if {($n % $numframes) == 0 } {
			puts "alignment $n of $numframes"
		}
		incr n
	}
	puts "Alignments complete, ready for RMSD calculations"
}

# Calculate RMSF of alpha carbons
proc rmsf_selection {selection} {
  set sel_molecule $selection
  set file_name "rmsfs-calfa.csv"
  set outfile [open $file_name w];
  set sel [atomselect top $sel_molecule]
  set mol [$sel molindex]
  puts $outfile "RESID, RMSF"
  for {set i 0} {$i < [$sel num]} {incr i} {
	 set rmsf [measure rmsf $sel]
	 $sel set beta $rmsf	
	 puts $outfile "[expr {$i+1}], [lindex $rmsf $i]"
  }
  close $outfile
}

#open trajectory
mol new $PSF type {psf} first 0 last -1 step 1 waitfor 1
mol addfile $DCD type {dcd} first 0 last -1 step 1 waitfor -1 0
 
# Select head for aligning
#set alignment "protein and name CA and resid 209 to 231" 
set alignment "protein and name CA" 
set id 0
align $id $alignment
 
# Selects alpha carbons, can be changed
set backbone "protein and name CA" 
rmsf_selection $backbone

#quick selection to reveal the TM protein in VMD display
#mol modselect 0 0 protein
#mol modstyle 0 0 NewCartoon 0.300000 10.000000 4.100000 0
#mol modcolor 0 0 Beta
exit
