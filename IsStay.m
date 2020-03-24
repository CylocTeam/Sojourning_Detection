function [ isStay, stay_times, stay_durations ] = IsStay( accx, accy, accz, timestamp, params)
% function detects human sojourning using mobile phone's accelarometer
% recording.
%  Inputs:
%         accx          [Nx1 double]   - accelarometer vector along x axis
%         accy          [Nx1 double]   - accelarometer vector along y axis
%         accz          [Nx1 double]   - accelarometer vector along z axis
%         timestamp     [Nx1 datetime] - time vector corresponding to acc.
%         params        [1x1 struct]   - thresholds etc. regarding algorithm, as
%                                        follows:
%
%           win_size_sec      [double]  - sample's environment decision length in
%                                         seconds. Illustration below:
%
%                                                  <----- 3 sec ----->
%                                    [ ... s i g n a l ... s i g n a l ...] 
%                                                           ^
%                                                         isStay decision
%
%           max_time_gap_msec [dobule] - maximal time gap in miliseconds
%                                        between foloowing timestamps for
%                                        fs estimation
%                      
%           max_section_gap_minutes
%                             [double] - maximal time gap between folloing
%                                        samples, to be considered as same
%                                        section
%           
%           ecdf_diff_th      [double] - possible update to var_th parameter
%                                        by indicating a knee in the ECDF of
%                                        the moving variance of the signal
% 
%           var_th            [double] - moving variance threshold upon which
%                                        sojourning decision is beeing made
%           
%           abrupt_filt_time_const 
%                             [double] - abrupt movement detection filter's
%                                        timeconstant in seconds
%           
%           abrupt_pctg_th    [double] - abrupt movement detection threshold. 
%                                        Should be between [0 - 1], indicating 
%                                        minimal percentage of '1' isStay samples 
%                                        around filtered sample. For example:
%
%                            isStay = [ ... 0 1 1 0 1 1 1 0 0 1 0 0 0 1 0 1 0 1 ... ]
%                                                 sample of ^ interest 
%                                              | -- window of interest --- |   
%
%                                         then sample has '1' at 7/14=50% of its
%                                         environment. samples with more
%                                         than <abrupt_pctg_th> (not in
%                                         [%]) will become '1'
%
%           min_stay_duration [double] - minimal sojourning duration in minutes.
%                                        shorter detected sojourns are to
%                                        disqualified.
%                                          
%
%
% Outputs:
%       isStay          [Nx1 bol]      - bolean vector indicating sample sojourning
%       stay_times      [Mx2 datetime] - sojourning edges if exist, empty otherwise
%       stay_durations  [Mx1 datetime] - sojourning durations if exist, empty otherwise
%

%% unpack & definitions
MAX_HIST_BINS = 1e4;
data_len = length(timestamp);
var_th = params.var_th;
acc_mat = [ accx , accy , accz ];  % stacking
Ndims = 3;                         % {x y z}

%% calculate average sample rate
%  filter outliers
%  purposed logic to be presented in v2.

time_diffs_msec = diff(datenum(timestamp)) * 24 * 60 * 60 * 1e3;  % (datestr(timestamp),'dd-mmm-yyyy hh:MM:ss'));
fs = mean( 1e3 * 1 ./ time_diffs_msec( time_diffs_msec < params.max_time_gap_msec ));

% purposed - data driven
%%%   max_time_gap_msec_pctl [double] - pctile of maximal allowed time gap
%   fs = 1e3 * 1 ./ time_diffs_msec( time_diffs_msec < prctile(time_diffs_msec, max_time_gap_msec_pctl) );

%% calc params in sample
%  second2sample
sec2smp = @(sec) floor(sec*fs);  % util function

win_size_smp = sec2smp(params.win_size_sec);
abrupt_filt_len = sec2smp(params.abrupt_filt_time_const);

%% optionally update var_th
% vecnorm can be utilized starting from 2017b
acc_abs = sqrt(sum( acc_mat.^2 ,2));
acc_movevar = movvar(acc_abs, win_size_smp);
[hist_counts, hist_centers] = hist(acc_movevar,linspace(min(acc_movevar),max(acc_movevar),MAX_HIST_BINS));

mvr_epdf = hist_counts / sum(hist_counts);

% alternatively 
% mvr_ecdf = cumsum(hist_counts);
% mvr_ecdf  = mvr_ecdf  / mvr_ecdf(end);  % normalize to [0 1] range

ecdf_knee_idx = find( mvr_epdf < params.ecdf_diff_th ,1,'last');
knee_th = hist_centers(ecdf_knee_idx);

if ~isempty(knee_th)
   var_th = min( var_th , knee_th);
end

%% find all different sections
section_idxs = find( time_diffs_msec > params.max_section_gap_minutes*60*1e3 );

if isempty(section_idxs)
    section_idxs = [1 data_len];
end

%% go through each section and decide isStay
is_seperate_axis = [];  % should be realocated in other language
is_abs_stay = [];       % should be realocated in other language
for isect=1:size(section_idxs,1)
    curr_section_idxs = section_idxs(isect,1) : section_idxs(isect,2) ;
    curr_acc_mat = acc_mat(curr_section_idxs);
    curr_acc_abs = sqrt(sum(curr_acc_mat.^2,2)); 
    mvr_mat = movvar(curr_acc_mat, win_size_smp, 0, 1);
    mvr_abs = movvar(curr_acc_abs, win_size_smp);
    
    % check seperate axis
    is_seperate_axis(curr_section_idxs) = all(mvr_mat < var_th/Ndims,2);
    is_abs_stay(curr_section_idxs) = mvr_abs < var_th ;
end
isStay = is_seperate_axis & is_abs_stay ;


%% filter abrupt movements
filt_size = sec2smp(params.abrupt_filt_time_const);
filt_taps = ones(1,filt_size) / filt_size ;   % which is exacly mvmean, eh?

isStay = conv(double(isStay),filt_taps,'same');
% isStay = movmean(isStay,filt_size); % alternatively - will not work if
%                                     % weigthed mean desired

isStay(isStay > params.abrupt_pctg_th) = 1;

isStay = logical(isStay);

%% find start & end times
is_toggle = diff([ 0 , isStay ]);

start_times = timestamp(is_toggle == 1);
end_times   = timestamp(is_toggle == -1);

if ~isempty(start_times) && ( isempty(end_times) || ( start_times(end) > end_times(end)))  % means sojourn eccourd
                                                               % until end of data 
   end_times = [end_times ; timestamp(end)];
end

stay_times = [ start_times , end_times ];
stay_durations = diff(stay_times);

%% cancle short sojourns
is_short_stay = stay_durations < duration(0,params.min_stay_duration,0);
stay_times(is_short_stay,:) = [];
stay_durations(is_short_stay,:) = [];

end


