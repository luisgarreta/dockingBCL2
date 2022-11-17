#!/usr/bin/python3
import itertools

def splitToFiles (filename, direct, prefix, limit):
	'''
	Separates a .pdbqt file with multiple molecules into separate files with
	singles molecules segmented over sub directories.
	'''
	with open(filename) as infile:
		count = 0
		in_dir_count = 0
		dircount = 0
		for dircount in itertools.count():
			for line in infile:
				#if line.strip() == 'MODEL{:16}'.format(count+1):
				if line.strip().split()[0] == 'MODEL' and line.strip().split()[1] == '{}'.format(count+1):
					directory = os.path.join(direct, '{}'.format(dircount+1))
					#os.makedirs(directory, exist_ok=True)
					name = '{}_{:09}.pdbqt'.format(prefix, count+1)
					out = os.path.join(directory, name)
					with open(out, 'w') as outfile:
						for line in infile:
							if line.strip() == 'ENDMDL':
								break
							if line.split()[0] == 'REMARK' and line.split()[1] == 'Name':
								NewName = os.path.join(directory,\
											'{}.pdbqt'.format(line.split()[3]))
							outfile.write(line)

					# Modified by LG to set name instead dir
					NewName = "%s/%s%d.pdbqt" % (direct, prefix, count+1)
					os.rename(out, NewName)
					count += 1
					in_dir_count += 1
					if in_dir_count >= limit:
						in_dir_count = 0
						print('[+] Finished directory {}'.format(directory))
						break
			else: break
	print('----------\n[+] Done')

#-----------------------------------------------------------------------

splitToFiles ("autodock-parameters-GA.dlg", "out", "ad", 100)

