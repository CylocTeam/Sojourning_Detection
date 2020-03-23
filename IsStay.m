function [ isStay ] = IsStay( accx, accy, accz, timestamp, params)
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
%           ecdf_diff_th      [double] - possible update to var_th parameter
%                                        by indicating a knee in the ECDF of
%                                        the moving variance of the signal
% 
%           var_th            [double] - moving variance threshold upon which
%                                        sojourning decision is beeing made
%           
%           abrupt_filt_time_const 
%                             [double] - outlier detectiong filter's timeconstant
%                                        in seconds
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

%% unpack 
MAX_HIST_BINS = 1e4;
var_th = params.var_th;

%% calculate average sample rate
%  filter outliers
%  purposed logic to be presented in v2.

time_diffs_msec = diff(datenum(timestamp)) * 24 * 60 * 60 * 1e3;  % (datestr(timestamp),'dd-mmm-yyyy hh:MM:ss'));
fs = mean( 1e3 * 1 ./ time_diffs_msec( time_diffs_msec < params.max_time_gap_msec ));



% purposed - data driven
%   max_time_gap_msec_pctl [double] - pctile of maximal allowed time gap
%   fs = 1e3 * 1 ./ time_diffs_msec( time_diffs_msec < prctile(time_diffs_msec, max_time_gap_msec_pctl) );

%% calc params in sample
%  second2sample
sec2smp = @(sec) floor(sec*fs);  % util function

win_size_smp = sec2smp(params.win_size_sec);
abrupt_filt_len = sec2smp(params.abrupt_filt_time_const);

%% optionally update var_th
% vecnorm can be utilized starting from 2017b
acc_abs = sqrt( accx.^2 + accy.^2 + accz.^2 );
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


end

