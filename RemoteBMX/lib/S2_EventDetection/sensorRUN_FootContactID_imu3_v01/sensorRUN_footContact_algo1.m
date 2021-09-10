function [ fc, side] = sensorRUN_footContact_algo1(rshank,lshank,sacrum,fs)
%Reed Gurchiek, 2019
%   algorithm to identify foot contacts from right/left shank and sacrum
%   accelerometer data. It is assumed that the accelerometer data are time
%   synchronized and the data contains only running data (no walking,
%   jumping, standing, etc.)
%
%   algorithm: follows closely that in ref [1] where right/left resultant
%   shank accelerometer data are low pass filtered and peaks in this signal
%   correspond to foot contact events.
%
%       -first, the dominant frequency of the resultant sacral acceleration
%        trace is determined as a first estimate of the step frequency. The
%        signals are then low passed at this frequency. This adaptive
%        filtering approach was used in [2] and is different than the
%        constant 5 hz cutoff frequency used in [1]. 
%       -peaks in the filtered sacral acceleration time series nicely
%        isolate steps.
%       -the largest peak in the right and left filtered shank acceleration
%        series between each of these sacral acceleration peaks are
%        identified and the index of the largest is taken as the foot
%        contact estimate.
%
%       REFERENCES:
%           [1] Mansour et al., 2015, Gait Posture, 42(4)
%           [2] Gurchiek et al., 2019, Sci Rep, 9(1)
%
%----------------------------------INPUTS----------------------------------
%
%   rshank, lshank, sacrum:
%       1xn double array, resultant accelerometer data from the right
%       shank, left shank, and sacrum. These must be the same length and
%       time synchronized
%
%   fs:
%       sampling frequency of the accelerometer data in hz
%
%---------------------------------OUTPUTS----------------------------------
%
%   fc:
%       1xn integer array, contains the indices of foot contacts in the
%       accelerometer arrays. The length of fc corresponds to the number of
%       foot contacts identified using the low passed sacral acceleration
%       trace, however, because the algorithm looks between each two
%       consecutive sacral acceleration peaks to identify foot contacts,
%       there will always be one less actual foot contact index than there
%       were foot contacts. For this reason, the last element of the fc
%       array will always be -1. Further, there might be the case that the
%       detection algorithm does not detect any shank peaks between 
%       identified sacral peaks. In this event, a -1 is returned for this
%       foot contact. This information should be used for any subsequent
%       stride/step segmentation along with the 'side' cell array output.
%
%   side:
%      1xn cell array, contains 'right' or 'left' to indicate whether the
%      right or left foot contacted the ground for the corresponding foot
%      contact index in fc. For -1 fc indices (see fc description), the
%      corresponding side element will be 'unidentified'.
%
%--------------------------------------------------------------------------
%% sensorRUN_footContact_algo1

% get dominant frequency of sacral accelerations
L = length(sacrum);
A = fft(sacrum);
A = abs(A(2:round(L/2)));
f = fs*(1:round(L/2)-1)/L;
[~,domf] = max(A);
domf = f(domf);

% lowpass
rshank = bwfilt(rshank,domf,fs,'low',4);
lshank = bwfilt(lshank,domf,fs,'low',4);
sacrum = bwfilt(sacrum,domf,fs,'low',4);

% get peaks
[~,ipk] = findpeaks(sacrum);

% for each peak
fc = -ones(1,length(ipk));
side = repmat({'unidentified'},[1 length(ipk)]);
for p = 1:length(ipk)-1

    % get peak r and l
    [right_peaks,iright_peaks] = findpeaks(rshank(ipk(p):ipk(p+1)));
    [left_peaks,ileft_peaks] = findpeaks(lshank(ipk(p):ipk(p+1)));
    
    % keep max for each
    [rmax,ir_max] = max(right_peaks);
    ir_max = iright_peaks(ir_max);
    [lmax,il_max] = max(left_peaks);
    il_max = ileft_peaks(il_max);

    % if no peaks then dont trust algo, go to next
    skip = 0;
    if isempty(ir_max) && isempty(il_max)
        skip = 1;
    % if only one side missing then use other
    elseif isempty(il_max)
        fc(p) = ir_max;
        side{p} = 'right';
        
    elseif isempty(ir_max)
        fc(p) = il_max;
        side{p} = 'left';
        
    % otherwise use largest peak
    else
        fc(p) = ir_max;
        side{p} = 'right';
        if lmax > rmax
            fc(p) = il_max; 
            side{p} = 'left';
        end
        
    end
    
    % update
    if skip
        warning('No peak was observed for either the right nor the left shank acceleration trace. Corresponding index will be 0 (This is the first time this has happened. Please contact algorithm designer.)')
    else
        fc(p) = fc(p) + ipk(p) - 1;
    end

end

end