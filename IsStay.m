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

%% calculate average sample rate
%  filter outliers




%% unpack 


end

