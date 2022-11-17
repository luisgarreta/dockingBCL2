
INPUTDIR="frames"
OUTPUTDIR="out-BindingEnergies"
calculate_binding_energies-ALL.py $INPUTDIR
create_binding_energies_table.py $OUTPUTDIR
