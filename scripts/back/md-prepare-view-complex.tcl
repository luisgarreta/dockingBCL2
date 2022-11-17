# VMD for LINUXAMD64, version 1.9.4a51 (December 21, 2020)
# Log file '/home/lg/BIO/omicas/simulations/03-Docking/03-PreparingComplexes-for-MD/conformation02/outputs/prep.tcl', created by user lg

mol addrep 0
mol new {step3_input.psf} type {psf} first 0 last -1 step 1 waitfor 1
mol addfile {step4_equilibration.dcd} type {dcd} first 0 last -1 step 1 waitfor 1 0
mol addfile {step5_1.dcd} type {dcd} first 0 last -1 step 1 waitfor 1 0

#mol modcolor 0 0 ColorID 7
mol color ColorID 7
mol representation NewCartoon 0.300000 10.000000 4.100000 0
mol selection protein
mol modrep 0 0

mol addrep 0
mol color Name
mol representation Licorice 0.300000 12.000000 12.000000
mol selection segname HETA
mol modrep 1 0
# VMD for LINUXAMD64, version 1.9.4a51 (December 21, 2020)
# end of log file.
