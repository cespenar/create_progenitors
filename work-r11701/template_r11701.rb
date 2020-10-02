#!/usr/bin/env ruby

require 'mesa_script'
require 'fileutils'

###############################################################################

def calculate_y(z, y_primordial, y_protosolar, z_protosolar)
	return y_primordial + (y_protosolar - y_primordial) * z / z_protosolar # Choi et al. (2016)
end

###############################################################################

Y_primordial = 0.249 # Planck Collaboration (2015)
Y_protosolar = 0.2703 # AGSS09
Z_protosolar = 0.0142 # AGSS09

###############################################################################

h1_fraction = 0.99998 # AGSS09
h2_fraction = 0.00002
he3_fraction = 0.000166
he4_fraction = 0.999834

###############################################################################

m = [[MASS]]
rot = [[ROT]]
z = [[Z]]
y = [[Y]]
f_h = [[F_H]]
mlt = [[MLT]]
sc = [[SC]]
eta_reimers = [[REIMERS]]

###############################################################################

x = 1.0 - y - z

f_he = 0.0
f_shell = 0.0

eta_blocker = 0.0

turbulence = 0.0

###############################################################################

use_zams = false

###############################################################################


out_dir = "../logs"
Dir.mkdir(out_dir) unless File.exist?(out_dir)
history_dir = "../history"
Dir.mkdir(history_dir) unless File.exist?(history_dir)
# mod_out_dir = "../mods"
# Dir.mkdir(mod_out_dir) unless File.exist?(mod_out_dir)

###############################################################################

history_string = "/history_m" + m.to_s + "_rot" + 
	rot.to_s + "_z" + z.to_s + "_y" + "#{y.round(5)}" + "_fh" + f_h.to_s + "_fhe" +
	f_he.to_s + "_fsh" + f_shell.to_s + "_mlt" + mlt.to_s + "_sc" + sc.to_s + 
	"_reimers" + eta_reimers.to_s + "_blocker" + eta_blocker.to_s + 
	"_turbulence" + turbulence.to_s + "_.data"

# next if File.file? history_dir + history_string

Inlist.add_star_job_defaults
Inlist.config_namelist(
	namelist: 'controls',
	source_files: 'namelists/star_controls.inc',
	defaults_file: 'namelists/controls.defaults')

Inlist.make_inlist("inlist_temp") do
  #!-----------------------------STAR_JOB-------------------------------
  # &star_job
		
		if use_zams then
			create_pre_main_sequence_model false
			relax_Y true
			relax_initial_Y true
			new_Y y	
			relax_Z true
			relax_initial_Z true
			new_Z z
		else
			create_pre_main_sequence_model true
			# pre_ms_T_c 5.0e5
			set_uniform_initial_composition true
			# initial_h1 0.7154
			# initial_h2 1.43e-5
			# initial_he3 4.49e-5
			# initial_he4 0.2702551
			initial_h1 h1_fraction * x
			initial_h2 h2_fraction * x
			initial_he3 he3_fraction * y
			initial_he4 he4_fraction * y
			initial_zfracs 6
		end
		  
		history_columns_file 'history_custom.list'
		profile_columns_file 'profile_custom.list'
		
		change_net true
		new_net_name 'pp_cno_extras_o18_ne22_fe56_ni58.net'

		eos_file_prefix 'mesa'
		kappa_file_prefix 'a09' # OP_a09_nans_removed_by_hand
		kappa_lowt_prefix 'lowT_fa05_a09p'
		kappa_co_prefix 'a09_co' # Type 2 opacities. OPAL only.
	
		set_rates_preference true
		new_rates_preference 2 # jina
		
		change_lnpgas_flag false
		new_lnpgas_flag false
		
		set_tau_factor false
		set_to_this_tau_factor 1.0e-4

		if (rot > 0.0) then
			new_rotation_flag false
			change_rotation_flag false
			set_surface_rotation_v true
			set_near_zams_surface_rotation_v_steps 20
		else
			new_rotation_flag false
			change_rotation_flag false
			set_surface_rotation_v false
		end
		new_surface_rotation_v rot

		# first 100 models are run with 
		# simple_photosphere then switched to the following
		extras_lcpar 1
		extras_cpar[1] = 'photosphere_tables'
	
		pgstar_flag false
		disable_pgstar_for_relax true

  # / !end of star_job

  #!-----------------------CONTROLS--------------------------------
  # &controls

	 # definition of core boundaries
		# he_core_boundary_h1_fraction 1e-4
 
	 # mixing parameters   
		mixing_length_alpha mlt
				
		use_Ledoux_criterion true
		alpha_semiconvection sc
			
		# core overshooting
        overshoot_f_above_nonburn_core 0
        overshoot_f_above_burn_h_core f_h
        overshoot_f_above_burn_he_core f_he
        overshoot_f_above_burn_z_core 0
        overshoot_f0_above_nonburn_core 0
        overshoot_f0_above_burn_h_core 0.002 # f_h / 2.0
        overshoot_f0_above_burn_he_core 0.002 # f_he / 2.0
        overshoot_f0_above_burn_z_core 0
  
        # envelope overshooting
        overshoot_f_above_nonburn_shell 0
        overshoot_f_below_nonburn_shell f_shell
        overshoot_f_above_burn_h_shell 0
        overshoot_f_below_burn_h_shell 0
        overshoot_f_above_burn_he_shell 0
        overshoot_f_below_burn_he_shell 0
        overshoot_f_above_burn_z_shell 0
        overshoot_f_below_burn_z_shell 0
        overshoot_f0_above_nonburn_shell f_shell / 2.0
        overshoot_f0_below_nonburn_shell f_shell / 2.0
        overshoot_f0_above_burn_h_shell f_shell / 2.0
        overshoot_f0_below_burn_h_shell f_shell / 2.0
        overshoot_f0_above_burn_he_shell f_shell / 2.0
        overshoot_f0_below_burn_he_shell f_shell / 2.0
        overshoot_f0_below_burn_z_shell f_shell / 2.0
		overshoot_f0_above_burn_z_shell f_shell / 2.0
		

		# convective premixing

		do_conv_premix true
		conv_premix_avoid_increase false
		recalc_mix_info_after_evolve true


	# rotation controls

		if (rot > 0.0) then
		  am_d_mix_factor 0.0228 # Brott et al. (2011), (0.033e0 - CZ92)
		else
		  am_d_mix_factor 0.0
		end
		am_nu_factor 1
		am_gradmu_factor 0.05e0
	
		d_dsi_factor 1.0
		d_sh_factor 1.0
		d_ssi_factor 1.0
		d_es_factor 1.0
		d_gsf_factor 1.0
		d_st_factor 0
		  
		smooth_d_dsi 3
		smooth_d_sh 3
		smooth_d_ssi 3
		smooth_d_es 3
		smooth_d_gsf 3
		smooth_d_st 3
		smooth_nu_st 3

	 # controls for output
		max_num_profile_models 10000
 
	 # starting specifications
		initial_mass m
		
		if use_zams then
			# parameters of the ZAMS calculated for the proto-solar composition (AGSS09)
			initial_y Y_protosolar
			initial_z Z_protosolar
			
			# ZAMS
			zams_filename '/home/cespenar/zams/zams_z0.0142_y0.2703_basic_plus_fe56.data'
		else
			initial_y y
			initial_z z
		end
 
	 # output to files and terminal
		write_profiles_flag false
		photo_interval 1000
		profile_interval 50
		history_interval 1
		terminal_interval 5
		write_header_frequency 10

		write_pulse_data_with_profile false
		pulse_data_format 'GYRE'
		add_atmosphere_to_pulse_data true
		add_center_point_to_pulse_data true
		keep_surface_point_for_pulse_data false
		
		# save models
		x_logical_ctrl[1] = true
		x_integer_ctrl[1] = 10
		x_ctrl[1] = 3.75 # log_Teff_max
		x_ctrl[3] = 2.10 # log_L_min

	# mass gain or loss
		cool_wind_RGB_scheme 'Reimers'
		Reimers_scaling_factor eta_reimers
		cool_wind_AGB_scheme 'Blocker'
		Blocker_scaling_factor eta_blocker
		RGB_to_AGB_wind_switch 5.0e-4
		max_wind 1e-3

# 		mass_change_full_on_dt 1e3 # (seconds)
# 		mass_change_full_off_dt 1e2 # (seconds)
 
	 # temporal resolution	
		# varcontrol_target 1.0e-4
        
      	# better resolution of the Henyey hook
        delta_lg_xh_cntr_max -1.0
  		 
		# limit on magnitude of relative change at any grid point
        delta_lgteff_limit 0.01
        delta_lgteff_hard_limit 0.01
        # delta_lgl_limit 0.02 
        # delta_lgl_hard_limit 0.05
        # delta_HR_limit 0.002
        
        max_years_for_timestep 1.0e7

  	  # spatial resolution
		max_allowed_nz 50000
		mesh_delta_coeff 1.0
        
	 # structure equations

		use_dedt_form_of_energy_eqn false
	
	   
	 # solver controls

		use_gold_tolerances false
		warn_when_large_rel_run_E_err 1.0e99
		warn_when_stop_checking_residuals false

		use_eosDT2 true
		use_eosELM true

	 # when to stop

		x_ctrl[2] = 0.985 - z # center_he4_limit
 
	 # atmosphere boundary conditions
		if use_zams then
			which_atm_option 'photosphere_tables'
			# which_atm_option 'simple_photosphere'
			x_logical_ctrl[2] = false
		else
			which_atm_option 'simple_photosphere'
			x_logical_ctrl[2] = true # change atmosphere after 100 models
		end
	
	 # element diffusion
	 	# Diffusion limited to the MS and radiative regions.
	 	# Directly adopted from MIST (Choi et al. 2016).
		do_element_diffusion true
		# diffusion_dt_limit 3.15e13
		diffusion_min_t_at_surface 1e3
		diffusion_use_cgs_solver false
		# diffusion_use_paquette true
		# diffusion_use_iben_macdonald false
		diffusion_min_dq_at_surface 1e-3
  
		radiation_turbulence_coeff turbulence
	
		# opacity controls   
		# cubic_interpolation_in_X true
		# cubic_interpolation_in_Z true
		use_type2_opacities true
		# kap_type2_full_off_x 1e-3
		# kap_type2_full_on_x 1e-6
		zbase z

		
  # / ! end of controls namelist

  #!-------------------------PGSTAR-------------------------------------
  # &pgstar

  # / ! end of pgstar namelist
end

system './mk'
system './rn'

###############################################################################


# history_file = history_dir + history_string
# FileUtils.cp "LOGS/history.data", history_file

log_dir = "logs_m" + m.to_s + "_rot" + 
	rot.to_s + "_z" + z.to_s + "_y" + "#{y.round(5)}" + "_fh" + f_h.to_s + "_fhe" +
	f_he.to_s + "_fsh" + f_shell.to_s + "_mlt" + mlt.to_s + "_sc" + sc.to_s + 
	"_reimers" + eta_reimers.to_s + "_blocker" + eta_blocker.to_s + 
	"_turbulence" + turbulence.to_s

logs = out_dir + "/" + log_dir

Dir.mkdir(logs) unless File.exist?(logs)
FileUtils.mv Dir.glob('LOGS/*'), logs + "/"

# mod_file = mod_dir + "/" + "rgb" + history_string[8...-6] + ".mod"
# FileUtils.cp "LOGS/trgb.mod", mod_file

system './tidy'
