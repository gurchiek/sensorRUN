function [ com_position ] = sensorRUNv02_comExcursion_algo1(sacrum_acceleration,time,fs)
%Reed Gurchiek, 2019
%   estimate com position using 3-axis accelerometer data
%
%   algorithm: estimate vertical using pca technique [1]. Lowpass at
%   estimated stride frequency [1]. Project onto estimated vertical. Demean
%   and integrate to estimate velocity. Detrend and integrate again to
%   estimate position. Then lowpass filter at 1 Hz. This last step (lowpass
%   filtering) may be improved with adaptive cutoffs. Should explore this
%   during validation. This approach is similar to that used in [2].
%
%   REFERENCES:
%       [1] Gurchiek et al., 2019, Sci Rep, 9(1)
%       [2] Gullstrand et al., 2009, Gait Posture, 30(1)
%
%----------------------------------INPUTS----------------------------------
%
%   sacrum_acceleration:
%       3xn accelerometer data in meters per second squared
%
%   time:
%       1xn time array
%
%   fs:
%       sampling frequency
%
%---------------------------------OUTPUTS----------------------------------
%
%   com position:
%       1xn com position in meters
%
%--------------------------------------------------------------------------
%% sensorRUN_comExcursion_algo1

% estimate vertical axis
c = size(sacrum_acceleration,2);
if c == 3; sacrum_acceleration = sacrum_acceleration'; end
z = pca(sacrum_acceleration');

% project
z = z(:,1)' * sacrum_acceleration;

% domf
L = length(z);
A = fft(z);
A = abs(A(2:round(L/2)));
f = fs*(1:round(L/2)-1)/L;
[~,domf] = max(A);
domf = f(domf);
z = bwfilt(z,domf*2,fs,'low',4);

% positive points vertically
z = sign(mean(z))*z;

% remove gravity estimate and integrate
com_velocity = cumtrapz(time,z - mean(z));

% detrend, integrate, high pass
com_position = bwfilt(cumtrapz(time,detrend(com_velocity)),1,fs,'high',4);

end