import numpy as np
import glob
import os
import shutil

def make_replacements(file_in, file_out, replacements, remove_original=False):
	with open(file_in) as infile, open(file_out, 'w') as outfile:
		for line in infile:
			for src, target in replacements.items():
				line = line.replace(src, target)
			outfile.write(line)
	if remove_original:
		os.remove(file_in)

def calculate_y(z, y_primordial, y_protosolar, z_protosolar):
	return y_primordial + (y_protosolar - y_primordial) * z / z_protosolar # Choi et al. (2016)

#########################################################################################

Y_primordial = 0.249 # Planck Collaboration (2015)
Y_protosolar = 0.2703 # AGSS09
Z_protosolar = 0.0142 # AGSS09

#########################################################################################

grid_name = 'sdb'
# z_range = [0.001, 0.005, 0.01, 0.015, 0.02, 0.025, 0.030, 0.035]
z_range = [0.015]

rot = [0.0]

mass_range = np.arange(1.00, 3.05, 0.05)

#########################################################################################

job_description = 'work_' + grid_name
template = 'work-r11701'

f_h = [0.0]

alpha_mlt = [1.80]

alpha_sc = [0.1]

reimers = [0.0]

for z in z_range:
	for mass in mass_range:
		for mlt in alpha_mlt:
			for v_rot in rot:
				for sc in alpha_sc:
					for f_core in f_h:
						for eta in reimers:
							y = calculate_y(z, Y_primordial, Y_protosolar, Z_protosolar)
							job_name = 'm' + '{:.3f}'.format(mass) + \
								'_z' + '{:.4f}'.format(z) + \
								'_y' + '{:.5f}'.format(y) + \
								'_rot' + '{:.1f}'.format(v_rot) + \
								'_mlt' + '{:.2f}'.format(mlt) + \
								'_sc' + '{:.3f}'.format(sc) + \
								'_fh' + '{:.3f}'.format(f_core) + \
								'_eta' + '{:.2f}'.format(eta)
							print(job_name)
							dest_dir = job_description + '_' + job_name
							shutil.copytree(template, dest_dir)
							shutil.move(dest_dir + '/template_run.sh', dest_dir + '/r_' + grid_name + '_' + \
								job_name + '.sh')
							replacements = { \
								'[[MASS]]':'{:.3f}'.format(mass), \
								'[[Z]]':'{:.5f}'.format(z), \
								'[[Y]]':'{:.5f}'.format(y), \
								'[[MLT]]':'{:.2f}'.format(mlt), \
								'[[SC]]':'{:.3f}'.format(sc), \
								'[[F_H]]':'{:.3f}'.format(f_core), \
								'[[ROT]]':'{:.1f}'.format(v_rot), \
								'[[REIMERS]]':'{:.2f}'.format(eta) \
								}
							make_replacements(dest_dir + '/template_r11701.rb', dest_dir + '/job.rb', \
								replacements)
