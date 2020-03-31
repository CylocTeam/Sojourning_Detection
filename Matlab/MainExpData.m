root_data_dir = fullfile(pwd, '..', 'data\');
acc_file_dir = 'a02\p3';
acc_data_dir = [root_data_dir acc_file_dir];

%% try dummy input

fs = 25; % [Hz]
t0 = datetime('now');

params.win_size_sec = 3;
params.ecdf_diff_th = 0.01;
params.var_th = 0.05;
params.abrupt_filt_time_const = 10;
params.abrupt_pctg_th = 0.2;
params.min_stay_duration = 4;
params.max_time_gap_msec = 1e3 * 5 / fs;
params.max_section_gap_minutes = 7;
params.max_time_gap_pctl = 60;

%% read experiment acc. data

all_segments = dir(fullfile(acc_data_dir,'*.txt'));
[~,sortby] = sort(vertcat({all_segments.name}'));

acc.x = [];
acc.y = [];
acc.z = [];

for j=1:length(sortby)
    curr_file = fullfile(acc_data_dir,all_segments(sortby(j)).name);
    data_tbl = readtable(curr_file);
    acc.x = [acc.x ; data_tbl.Var1]; % read data from torso only
    acc.y = [acc.y ; data_tbl.Var2];
    acc.z = [acc.z ; data_tbl.Var3];
end

%% create time vector
data_length = length(acc.x);
tick_vec = linspace(0 , data_length/fs , data_length)';
timestamp = t0 + duration(0,0,tick_vec);

acc.x = [acc.x ; acc.x]; % read data from torso only
acc.y = [acc.y ; acc.y];
acc.z = [acc.z ; acc.z];
timestamp = [timestamp ; timestamp + duration(1,0,0)];

%% export
data = table(acc.x, acc.y, acc.z , timestamp,'VariableNames',{'x','y','z','timestamp'});
file_name = [replace(acc_file_dir,'\','_'), '.csv'];
writetable(data,[root_data_dir, file_name])

%% run IsStay
[isStay,stay_times,stay_durations] = IsStay(data.x, data.y, data.z , data.timestamp, params);
