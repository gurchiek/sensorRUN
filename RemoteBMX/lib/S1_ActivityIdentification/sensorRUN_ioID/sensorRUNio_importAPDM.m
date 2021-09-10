function [ session ] = sensorRUNio_importAPDM(session)
%Reed Gurchiek, 2019
%   description
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       struct, should have an apdm field which contains the filename (.h5
%       file). The apdm field should also contain the fs parameter which 
%       specifies the apdm sampling rate (should be same for all sensors).
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       same session struct as input but now with sensor data housed in:
%           run.data.imu.locations.(locationName)
%
%--------------------------------------------------------------------------
%% sensorRUNio_importAPDM

% for each run
for r = 1:length(session.run)

    % get info for raw and processed sensor data
    info.sensors = h5info(session.run(r).filename,'/Sensors');
    info.processed = h5info(session.run(r).filename,'/Processed');

    % number of sensors
    imu.n_sensors = length(info.sensors.Groups);

    % get annotation data
    annot = h5read(session.run(r).filename,'/Annotations');
    annot.Annotation = cellstr(annot.Annotation');
    session.run(r).Annotations = annot;

    % initialization
    imu.sensor_locations = cell(imu.n_sensors,1);
    imu.data_types = {'Accelerometer','Gyroscope','Magnetometer','Orientation','Barometer','Temperature'};
    imu.data_abbreviations = {'a','w','m','q','b','temp'};


    %% get time array

    % for each sensor
    t_start = 0;
    t_end = inf;
    for s = 1:imu.n_sensors

        % get sensor label
        info.sensors.Groups(s).config = h5info(session.run(r).filename,[info.sensors.Groups(s).Name,'/Configuration']);
        imu.sensor_locations{s} = info.sensors.Groups(s).config.Attributes(1).Value;
        
        % get time
        session.run(r).data.imu.locations.(imu.sensor_locations{s}).original_time = double(h5read(session.run(r).filename,[info.sensors.Groups(s).Name,'/Time'])) * 10^-6;
        
        % update t_start?
        if session.run(r).data.imu.locations.(imu.sensor_locations{s}).original_time(1) > t_start
            t_start = session.run(r).data.imu.locations.(imu.sensor_locations{s}).original_time(1);
        end
        
        % update t_end?
        if session.run(r).data.imu.locations.(imu.sensor_locations{s}).original_time(end) < t_end
            t_end = session.run(r).data.imu.locations.(imu.sensor_locations{s}).original_time(end);
        end
        
    end
    
    %% read/parse data

    % for each sensor
    for s = 1:imu.n_sensors

        % start/end samples
        session.run(r).data.imu.locations.(imu.sensor_locations{s}).start_sample = find(session.run(r).data.imu.locations.(imu.sensor_locations{s}).original_time >= t_start);
        session.run(r).data.imu.locations.(imu.sensor_locations{s}).start_sample = session.run(r).data.imu.locations.(imu.sensor_locations{s}).start_sample(1);
        session.run(r).data.imu.locations.(imu.sensor_locations{s}).end_sample = find(session.run(r).data.imu.locations.(imu.sensor_locations{s}).original_time <= t_end);
        session.run(r).data.imu.locations.(imu.sensor_locations{s}).end_sample = session.run(r).data.imu.locations.(imu.sensor_locations{s}).end_sample(end);

        % for each data type
        for d = 1:length(imu.data_types)

            % get data
            if strcmp(imu.data_types{d},'Orientation')
                raw = double(h5read(session.run(r).filename,[info.processed.Groups(s).Name,'/',imu.data_types{d}]));
            else
                raw = double(h5read(session.run(r).filename,[info.sensors.Groups(s).Name,'/',imu.data_types{d}]));
            end

            % make columns time dimension
            [nrows,ncols] = size(raw); if nrows > ncols; raw = raw'; end

            % for each trial
            if ~isempty(raw)

                % get trial specific data
                session.run(r).data.imu.locations.(imu.sensor_locations{s}).(imu.data_abbreviations{d}) = raw(:,session.run(r).data.imu.locations.(imu.sensor_locations{s}).start_sample : session.run(r).data.imu.locations.(imu.sensor_locations{s}).end_sample);
                
            end

        end
        

    end

        
end

% Run 1
figure(1)
plot(session.run(1).data.imu.locations.(imu.sensor_locations{1}).original_time, session.run(1).data.imu.locations.(imu.sensor_locations{1}).a(1,:));

[start, stop] = ginput(2);

for s = 1:imu.n_sensors
    session.run(1).data.imu.locations.(imu.sensor_locations{s}).Stime = start(1);
    session.run(1).data.imu.locations.(imu.sensor_locations{s}).Etime = start(2);
    session.run(1).data.imu.locations.(imu.sensor_locations{s}).start_sample = find(session.run(1).data.imu.locations.(imu.sensor_locations{s}).original_time >= session.run(1).data.imu.locations.(imu.sensor_locations{s}).Stime);
    session.run(1).data.imu.locations.(imu.sensor_locations{s}).start_sample = session.run(1).data.imu.locations.(imu.sensor_locations{s}).start_sample(1);
    
    session.run(1).data.imu.locations.(imu.sensor_locations{s}).end_sample = find(session.run(1).data.imu.locations.(imu.sensor_locations{s}).original_time <= session.run(1).data.imu.locations.(imu.sensor_locations{s}).Etime);
    session.run(1).data.imu.locations.(imu.sensor_locations{s}).end_sample = session.run(1).data.imu.locations.(imu.sensor_locations{s}).end_sample(end);
    
end
%}
%session.run(1).data.imu.locations.pelvis.start_sample = 1;
%session.run(1).data.imu.locations.pelvis.end_sample = 13383;
s1 = session.run(1).data.imu.locations.pelvis.original_time(session.run(1).data.imu.locations.pelvis.start_sample);
e1 = session.run(1).data.imu.locations.pelvis.original_time(session.run(1).data.imu.locations.pelvis.end_sample);

session.run(1).data.imu.locations.pelvis.t = (session.run(1).data.imu.locations.pelvis.original_time(session.run(1).data.imu.locations.(imu.sensor_locations{s}).original_time...
    >= s1 & session.run(1).data.imu.locations.(imu.sensor_locations{s}).original_time <= e1) - s1);


% Run 2
figure(2)
plot(session.run(2).data.imu.locations.(imu.sensor_locations{1}).original_time, session.run(2).data.imu.locations.(imu.sensor_locations{1}).a(1,:));

[start2,stop2] = ginput(2);

for t = 1:imu.n_sensors
    session.run(2).data.imu.locations.(imu.sensor_locations{t}).Stime = start2(1);
    session.run(2).data.imu.locations.(imu.sensor_locations{t}).Etime = start2(2);
    session.run(2).data.imu.locations.(imu.sensor_locations{t}).start_sample = find(session.run(2).data.imu.locations.(imu.sensor_locations{t}).original_time >= session.run(2).data.imu.locations.(imu.sensor_locations{t}).Stime);
    session.run(2).data.imu.locations.(imu.sensor_locations{t}).start_sample = session.run(2).data.imu.locations.(imu.sensor_locations{t}).start_sample(1);
    
    session.run(2).data.imu.locations.(imu.sensor_locations{t}).end_sample = find(session.run(2).data.imu.locations.(imu.sensor_locations{t}).original_time <= session.run(2).data.imu.locations.(imu.sensor_locations{t}).Etime);
    session.run(2).data.imu.locations.(imu.sensor_locations{t}).end_sample = session.run(2).data.imu.locations.(imu.sensor_locations{t}).end_sample(end);
end
s2 = session.run(2).data.imu.locations.pelvis.original_time(session.run(2).data.imu.locations.pelvis.start_sample);
e2 = session.run(2).data.imu.locations.pelvis.original_time(session.run(2).data.imu.locations.pelvis.end_sample);

session.run(2).data.imu.locations.pelvis.t = (session.run(2).data.imu.locations.pelvis.original_time(session.run(2).data.imu.locations.(imu.sensor_locations{t}).original_time...
    >= s2 & session.run(2).data.imu.locations.(imu.sensor_locations{t}).original_time <= e2) - s2);
%}

