function [ session ] = rbmxEventDetection_sensorRUN_FootContactID_imu3_v01(session)
%Reed Gurchiek, 2019
%   uses sensorRUN_footContact_algo1 to estimate foot contact indices and
%   their corresponding side. Then segments strides/steps for each
%   identified foot contact
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       same input struct with updated fields. New fields include:
%           run.footContact: n element struct containing the index
%           corresponding to the estimated foot contact, stride end/step
%           end indices, and whether or not a valid stride/step was
%           identified (boolean 1 or 0)
%
%--------------------------------------------------------------------------
%% sensorRUN_FootContactID_imu3_v01

% sampling frequency and number of seconds to analyze
fs = session.apdm.fs;
%seconds = 60;

% event detection algorithm
algo = str2func(session.eventDetection.detectionAlgorithm);

% for each run
run = session.run;
for r = 1:length(run)
    
    % get foot contact using shank accel
    rshank = vecnorm(session.run(r).data.imu.locations.Rshank.a(:,session.run(r).data.imu.locations.pelvis.start_sample:session.run(r).data.imu.locations.pelvis.end_sample));
    lshank = vecnorm(session.run(r).data.imu.locations.Lshank.a(:,session.run(r).data.imu.locations.pelvis.start_sample:session.run(r).data.imu.locations.pelvis.end_sample));
    sacrum = vecnorm(session.run(r).data.imu.locations.pelvis.a(:,session.run(r).data.imu.locations.pelvis.start_sample:session.run(r).data.imu.locations.pelvis.end_sample));
    [fc,side] = algo(rshank,lshank,sacrum,fs);
    
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
    
    % organize into structure
    session.run(r).footContact = footContact;
    clear footContact

end

end