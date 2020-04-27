
root_data_dir = fullfile(pwd, '..', 'data\');
file_name = 'a02_p3.csv';
data = readtable([root_data_dir, file_name]);

root_config_dir = fullfile(pwd, '..\');
config = readtable([root_config_dir, 'config.csv']);

params.win_size_sec =           config.value(strcmp(config.name, 'win_size_sec'));
params.ecdf_diff_th =           config.value(strcmp(config.name, 'ecdf_diff_th'));
params.var_th =                 config.value(strcmp(config.name, 'var_th'));
params.abrupt_filt_time_const = config.value(strcmp(config.name, 'abrupt_filt_const_sec'));
params.abrupt_pctg_th =         config.value(strcmp(config.name, 'abrupt_pctg_th'));
params.min_stay_duration =      config.value(strcmp(config.name, 'min_stay_duration_m'));
params.max_time_gap_msec =      config.value(strcmp(config.name, 'max_time_gap_msec'));
params.max_section_gap_minutes =config.value(strcmp(config.name, 'max_section_gap_m'));
params.max_time_gap_pctl =      config.value(strcmp(config.name, 'max_time_gap_pctl'));

[isStay,stay_times,stay_durations] = IsStay(data.x, data.y, data.z , data.timestamp, params);

data.is_stay = isStay';