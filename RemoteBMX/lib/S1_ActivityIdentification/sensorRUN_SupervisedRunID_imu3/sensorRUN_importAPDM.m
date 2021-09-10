function [ session ] = sensorRUN_importAPDM(session)
%Reed Gurchiek, 2019
%   description
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       struct, should have an apdm field which contains the filename (.h5
%       file). The apdm field should also contain the fs parameter which 
%       specifies the apdm sampling rate (should be same for all sensors).
%       Should also contain an activityIdentification field which
%       contains the run_seconds parameter which controls how long (in
%       seconds) after the start of the run bout to analyze. Should also
%       have a run field which contains the start_apdm_annotation_no
%       parameter which specifies which annotation provides the data index
%       at which that particular run begins.
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       same session struct as input but now with sensor data housed in:
%           run.data.imu.locations.(locationName)
%
%--------------------------------------------------------------------------
%% sensorRUN_importAPDM

% get info for raw and processed sensor data
info.sensors = h5info(session.apdm.filename,'/Sensors');
info.processed = h5info(session.apdm.filename,'/Processed');

% number of sensors
imu.n_sensors = length(info.sensors.Groups);

% get annotation data
annot = h5read(session.apdm.filename,'/Annotations');
annot.Annotation = cellstr(annot.Annotation');

% initialization
imu.sensor_locations = cell(imu.n_sensors,1);
imu.data_types = {'Accelerometer','Gyroscope','Magnetometer','Orientation','Barometer','Temperature'};
imu.data_abbreviations = {'a','w','m','q','b','temp'};



%%  trial start/end times

% for each run
run = session.run;
for r = 1:length(run)
    
    % get start and end times
    run(r).start_time = double(annot.Time(run(r).start_apdm_annotation_no));
    run(r).end_time = run(r).start_time + (session.activityIdentification.run_seconds+1)*10^6;
    
    % get start date
    run(r).start_date = datetime(run(r).start_time*10^(-6),'ConvertFrom','posixtime');
    
end


%% read/parse sensor data

% for each sensor
for s = 1:imu.n_sensors
    
    % get sensor label
    info.sensors.Groups(s).config = h5info(session.apdm.filename,[info.sensors.Groups(s).Name,'/Configuration']);
    imu.sensor_locations{s} = info.sensors.Groups(s).config.Attributes(1).Value;

    % if first sensor
    if s == 1
        
        % get time array
        time = double(h5read(session.apdm.filename,[info.sensors.Groups(s).Name,'/Time']));

        % for each trial
        for r = 1:length(run)
            
            % get trial time array, make t0 = 0, convert to seconds
            run(r).t = (time(time >= run(r).start_time & time <= run(r).end_time) - run(r).start_time)*10^(-6);
            run(r).start_sample = find(time >= run(r).start_time & time <= run(r).end_time);
            run(r).start_sample = run(r).start_sample(1);
            run(r).end_sample = run(r).start_sample + session.activityIdentification.run_seconds * session.apdm.fs;
            run(r).sampling_frequency = mean(1./diff(run(r).t));
            
        end
        
    end
    
    % for each data type
    for d = 1:length(imu.data_types)
        
        % get data
        if strcmp(imu.data_types{d},'Orientation')
            raw = double(h5read(session.apdm.filename,[info.processed.Groups(s).Name,'/',imu.data_types{d}]));
        else
            raw = double(h5read(session.apdm.filename,[info.sensors.Groups(s).Name,'/',imu.data_types{d}]));
        end
        
        % make columns time dimension
        [r,c] = size(raw); if r > c; raw = raw'; end
        
        % for each trial
        if ~isempty(raw)
            for r = 1:length(run)

                % get trial specific data
                run(r).data.imu.locations.(imu.sensor_locations{s}).(imu.data_abbreviations{d}) = raw(:,run(r).start_sample : run(r).end_sample);

            end
        end
    
    end
    
end

%% packup

session.run = run;
session.apdm.Annotations = annot;

end