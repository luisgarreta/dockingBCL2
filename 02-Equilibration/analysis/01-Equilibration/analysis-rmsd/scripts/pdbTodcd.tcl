foreach f [glob *pdb] {
mol addfile $f
}
animate write dcd filename.dcd

