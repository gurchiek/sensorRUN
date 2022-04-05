function [ session ] = rbmxEventDetection_sensorRUNv02_FootContactID_imu3_v01(session)
%Reed Gurchiek, 2019
%
%-----------------------------DESCRIPTION----------------------------------
%
%   Estimates foot contact indices and their corresponding side from left
%   and right shank and sacrum acceleration, during running. 
%   
%   Uses sensorRUNv02_footContact_algo1. Note: the algorithm
%   does not detect toe-off. 'Step end' is the same as foot contact for the
%   contralateral side. 'Stride end' is the subsequent foot contact for the 
%   ipsilateral side.
%   
%   For quality control, a graph of right shank, left shank, and sacrum 
%   resultant accelerations is plotted vs. time with 'o' indicating the index 
%   of each foot contact (step start) and 'x' for step end (= next step
%   foot contact)
%   
%----------------------------------INPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct with updated fields
%       New fields:
%           - run.footContact: struct; contains information related to foot 
%           contact identification 
%               - index: index corresponding to the estimated foot contact
%               - side: 'left' or 'right', step side
%               - valid_stride / valid_step: boolean 1 or 0; whether or not 
%                 a valid stride/step was identified (boolean 1 or 0)
%               - stepEndIndex: index of step end. Equivalent to index of 
%                 next step start
%               - strideEndIndex: index of stride end. Equivalent of index 
%                 of next stride start
%
%---------------------------REVISION HISTORY-------------------------------
%
% Jess Zendler, revised 2021, to:
%   - make consistent with variable naming and structure set in
%   initialization and activity identification scripts
%   - use sampling frequency calculated from APDM data rather than explicit
%   value set at initialization
%   - remove calls to session struct once session.run is already unpacked
%   - add quality control figure of identified step start/stops
%
%--------------------------------------------------------------------------
%% sensorRUNv02_FootContactID_imu3_v01

% unpack
run = session.run;
requiredSensorNames = session.apdm.requiredSensorNames;
lShankName = requiredSensorNames{1};
rShankName = requiredSensorNames{2};
sacrumName = requiredSensorNames{3};

% event detection algorithm
algo = str2func(session.eventDetection.detectionAlgorithm);

% for each run
for r = 1:length(run)
    
    % sampling frequency and time vector
    fs = round(run(r).samplingFrequency);
    t = run(r).time_s;
    
    % compute resultant acceleration
    rshank = vecnorm(run(r).data.imu.locations.(rShankName).a); %right shank acceleration
    lshank = vecnorm(run(r).data.imu.locations.(lShankName).a); %left shank acceleration
    sacrum = vecnorm(run(r).data.imu.locations.(sacrumName).a); %sacrum acceleration
    
    % get foot contact using shank and sacrum resultant accels
    [fc,side,rshankfilt,lshankfilt,sacrumfilt] = algo(rshank,lshank,sacrum,fs);
    
    % segment strides/steps for each foot contact
    footContact(1:length(fc)-1) = struct('index',[],'side',[],'validStep',0,'stepEndIndex',[],'validStride',0,'strideEndIndex',[]);
    c = 1;
    for i = 1:length(fc)-1
        
        % validate step
        valid_step = 1;
        if strcmp(side{i+1},'unidentified')
            valid_step = 0;
        elseif strcmp(side{i},side{i+1})
            valid_step = 0;
        end
        
        % validate stride
        valid_stride = 1;
        if i == length(fc)-1
            valid_stride = 0;
        elseif strcmp(side{i+2},'unidentified')
            valid_stride = 0;
        elseif ~strcmp(side{i+2},side{i})
            valid_stride = 0;
        end
        
        % get step metrics
        if valid_step
            footContact(c).stepEndIndex = fc(i+1);
        end
        
        % get stride metrics
        if valid_stride
            footContact(c).strideEndIndex = fc(i+2);
        end
        
        % store index and side then increment structure counter
        if valid_stride || valid_step
            footContact(c).index = fc(i);
            footContact(c).side = side{i};
            footContact(c).validStep = valid_step;
            footContact(c).validStride = valid_stride;
            c = c+1;
        else
            footContact(c) = [];
        end
        
    end
    
    % assemble x,y data. x = index, y = shank accel of side associated with
    % step to visualize step identification for quality control
    for k = 1:length(footContact)
        if footContact(k).index ~= -1
            % if valid step
            if footContact(k).validStep
                start_index(k) = footContact(k).index;
                end_index(k) = footContact(k).stepEndIndex;
                if footContact(k).side(1) == 'l'
                    start_shank(k) = lshankfilt(start_index(k));
                    end_shank(k) = lshankfilt(end_index(k));
                elseif footContact(k).side(1) == 'r'
                    start_shank(k) = rshankfilt(start_index(k));
                    end_shank(k) = rshankfilt(end_index(k));
                end
            end
        end
    end
    
    % Quality control: plot data fed into foot contact algo (raw sacrum, right shank, left shank
    % accelerations), filtered data used to find foot contact, and indices of 
    % start (o) and stop (x). Y-values are shank acceleration for step side at index.
   
    figure
    hold on
    plot(rshank,'r')
    plot(lshank,'g')
    plot(sacrum,'k')
    plot(rshankfilt,'r:')
    plot(lshankfilt,'g:')
    plot(sacrumfilt,'k:')
    plot(start_index,start_shank,'ko')
    plot(end_index,end_shank,'kx')

    legend('Right Shank','Left Shank','Sacrum','Right Shank Filtered',...
        'Left Shank Filtered','Sacrum Filtered','Step Start','Step End')
    ylabel('Vector Mag Acceleration (m/s^2)')
    title(['Run Bout ' num2str(r) ': Foot Contact Identification'])
    hold off
    
    % organize into structure
    session.run(r).footContact = footContact;
    
    clear footContact start_index start_shank end_index end_shank t rshank ...
        lshank sacrum
    
end

end