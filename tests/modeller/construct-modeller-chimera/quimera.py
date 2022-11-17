#!/opt/miniconda3/envs/biobb_env/bin/python3

from modeller import *
from modeller.automodel import *    # Load the AutoModel class
import os

log.verbose()
env = Environ()

# directories for input atom files
env.io.atom_files_directory = ['.', '../atom_files']

a = AutoModel(env, alnfile = 'align_1lxl.ali',
              knowns = ('1lxl_template'), sequence = '1lxl_sequence')
              #knowns = ('6f46_template', '1lxl_template'), sequence = '1lxl_sequence')

class MyModel(AllHModel):
    def select_atoms(self):
        return Selection(self.residue_range('202:A', '210:A'))

a = MyModel(env, alnfile = 'align_quimera.ali',
            knowns = ('1lxl_template','6f46_template'), sequence = '1lxl_sequence')
            #knowns = ('1lxl_template'), sequence = '1lxl_sequence')
a.starting_model= 1
a.ending_model  = 1

a.make()

os.system ("mv 1lxl_* outputs")
