#!/home/lg/.bin/xvmd
#
# Calculate non-bonded energies from namd trajectories

if { $argc < 4 } then {
	puts "-----------------------------------------------------------------------"
	puts "Calculate non-bonded energies from namd trajectories"
	puts "USAGE: nonbonded-energies-trajectory.tcl <PSF file> <DCD file> <CHARMM PARAMS dir>"
	puts "-----------------------------------------------------------------------"
	exit
}

package require namdenergy

set PSFFILE [lindex $argv 0];
set DCDFILE [lindex $argv 1];
set TOPPAR  [lindex $argv 2];
set OUTFILE [lindex $argv 3];

mol new $PSFFILE first 0 last -1
mol addfile $DCDFILE first 0 last -1 step 1 waitfor -1 0

namdenergy -nonb -skip 0 -ts 0 -cutoff 12 \
   -sel [atomselect top "segname PROA or segname HETA"] \
   -die 1.0 -stride 1 -ofile $OUTFILE\
   -par $TOPPAR/toppar_all36_carb_glycolipid.str -par $TOPPAR/toppar_all36_nano_lig_patch.str -par $TOPPAR/toppar_all36_prot_heme.str -par $TOPPAR/toppar_all36_lipid_miscellaneous.str -par $TOPPAR/toppar_all36_na_nad_ppi.str -par $TOPPAR/toppar_all36_lipid_ether.str -par $TOPPAR/toppar_all36_lipid_archaeal.str -par $TOPPAR/par_interface.prm -par $TOPPAR/toppar_water_ions.str -par $TOPPAR/toppar_all36_prot_fluoro_alkanes.str -par $TOPPAR/toppar_all36_lipid_cardiolipin.str -par $TOPPAR/unl.prm -par $TOPPAR/toppar_all36_polymer_solvent.str -par $TOPPAR/toppar_all36_synthetic_polymer.str -par $TOPPAR/toppar_all36_lipid_inositol.str -par $TOPPAR/par_all36_carb.prm -par $TOPPAR/par_all36m_prot.prm -par $TOPPAR/toppar_all36_lipid_tag.str -par $TOPPAR/toppar_all36_prot_na_combined.str -par $TOPPAR/toppar_all36_prot_model.str -par $TOPPAR/toppar_all36_na_rna_modified.str -par $TOPPAR/toppar_all36_lipid_detergent.str -par $TOPPAR/toppar_all36_nano_lig.str -par $TOPPAR/toppar_all36_lipid_cholesterol.str -par $TOPPAR/toppar_all36_lipid_sphingo.str -par $TOPPAR/toppar_all36_lipid_dag.str -par $TOPPAR/toppar_all36_moreions.str -par $TOPPAR/toppar_all36_label_fluorophore.str -par $TOPPAR/par_all36_cgenff.prm -par $TOPPAR/toppar_ions_won.str -par $TOPPAR/toppar_all36_lipid_lps.str -par $TOPPAR/toppar_all36_lipid_prot.str -par $TOPPAR/toppar_all36_prot_retinol.str -par $TOPPAR/toppar_all36_lipid_bacterial.str -par $TOPPAR/toppar_all36_label_spin.str -par $TOPPAR/toppar_all36_lipid_lnp.str -par $TOPPAR/toppar_all36_prot_modify_res.str -par $TOPPAR/toppar_all36_prot_arg0.str -par $TOPPAR/toppar_dum_noble_gases.str -par $TOPPAR/toppar_all36_carb_glycopeptide.str -par $TOPPAR/toppar_all36_carb_imlab.str -par $TOPPAR/toppar_all36_lipid_mycobacterial.str -par $TOPPAR/toppar_all36_prot_c36m_d_aminoacids.str -par $TOPPAR/par_all36_na.prm -par $TOPPAR/toppar_all36_synthetic_polymer_patch.str -par $TOPPAR/toppar_all36_lipid_hmmm.str -par $TOPPAR/toppar_all36_lipid_yeast.str -par $TOPPAR/par_all36_lipid.prm -par $TOPPAR/toppar_all36_lipid_model.str 

exit
