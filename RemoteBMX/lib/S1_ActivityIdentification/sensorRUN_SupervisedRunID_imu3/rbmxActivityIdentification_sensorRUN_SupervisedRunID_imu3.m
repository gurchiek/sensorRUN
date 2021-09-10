function [ session ] = rbmxActivityIdentification_sensorRUN_SupervisedRunID_imu3(session)
%Reed Gurchiek, 2019
%   read imu data during running activity. Subject folders should have only
%   one .h5 file corresponding the apdm imu data. there should also be only
%   one .xlsx sheet which contains annotated events data which describe the
%   start of each running bout. Currently, the end of the bout is not
%   specified. Instead, the amount of time after the start is specified in
%   the project initialization (activityIdentification.run_seconds)
%
%   see sensorRUN_importAPDM for import details
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct
%       new fields:
%           -session.run: 1xn struct, contains information for n running
%           bouts
%
%--------------------------------------------------------------------------
%% rbmxActivityIdentification_sensorRUN_SupervisedRunID_imu3

% get .h5 file to analyze
path = session.apdm.datapath;
filename = dir(fullfile(path,'*.h5'));
filename = filename.name;
session.apdm.filename = fullfile(path,filename);
session.apdm.h5name = filename;

%% INITIALIZE RUN STRUCT

% get annotated events data
events_data = dir(fullfile(path,'*.xlsx'));
[events_data,text_data] = xlsread(fullfile(path,events_data.name));
    
% N runs
n_runs = max(events_data(:,2));

% for each
for r = 1:n_runs

    row = find(events_data(:,2) == r);

    % get annotation number corresponding to run start
    session.run(r).start_apdm_annotation_no = events_data(row,1);

    % get running speed
    session.run(r).running_speed_mph = events_data(row,4);

    % get foot strike type
    session.run(r).foot_strike_type = text_data{row + 1,5};

end

%% IMPORT

session = sensorRUN_importAPDM(session);

end