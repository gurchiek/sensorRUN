function [ session ] = rbmxActivityIdentification_sensorRUNv02_SupervisedRunID_imu3(session)
%Reed Gurchiek, 2019
%
%-----------------------------DESCRIPTION----------------------------------
%
%   Read APDM imu data (.hdf5 file, APDM format version 5) during running
%   activity and segment for analysis. Imu data for analysis is segmented
%   as specified by user in response to project initialization queries.
%   Multiple bouts can be segmented within a single session. See
%   rbmxInitializeProject_projectName for explanation of the running bout
%   identification methods.
%
%   Generates a graph of sensor #1 acceleration axis 1 raw data vs. time
%   for the user to review and verify before continuing with analysis.
%
%   Prompts user to identify the sensor names (left shank, right shank,
%   sacrum) for required data inputs.
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct with updated fields.
%       New fields:
%           - apdm. ...
%                 - annotations: struct; 'Annotation' dataset from .h5 file
%                    - Time: N x 1 array; time in posix and microseconds associated
%                    with N APDM button event markers or Motion Studio
%                   annotations
%                    - SensorID: ID of sensor generating APDM button events
%                    - Annotation: N x 1 cell array; labels of N APDM
%                    button events / annotations
%                 - requiredSensorNames: 1 x 3 cell array; {leftShank_name,
%                   rightShank_name, sacrum_name}; names in .h5 file
%                   associated with the sensors required for event detection
%                   and analysis
%                 - sensorLocations: list of APDM sensor location labels
%
%           - run: 1xn struct, contains information for n running
%                  bouts
%                 Fields:
%                 - startTime_s: seconds; relative time within datafile
%                   associated with start of bout, where the first data point
%                   in file is time = 0;
%                 - endTime_s: seconds; relative time within datafile
%                   associated with stop of bout
%                 - time_s: nx1 array; seconds; relative time vector for
%                   running bout, where first time_s = 0 is start of running bout
%                 - samplingFrequency: numerical; hz; sampling frequency of
%                   running bout calculated from time data; should be identical
%                   across running bouts
%                 - startSample: scalar; data sample within datafile associated
%                   with start of bout
%                 - endSample: scalar; data sample within datafile associated
%                   with stop of bout
%                 - data.imu.locations.(location_name): struct; raw data
%                   associated with sensor location_name for running bout;
%                   each field is c x k array, where bout is k samples in
%                   length.
%                       - Field names are set by imu.dataAbbreviations in script
%                           a: 3xk array, m/s^2, linear acceleration in sensor frame
%                           w: 3xk array, rad/s, angular velocity in sensor frame
%                           m: 3xk array, uT, magnetic field in sensor frame
%                           q: 4xk array, sensor orientation quaternion
%                           b: 1xk array, kPa, barometer
%                           temp: 1xk array, deg C, temperature
%                       - Data types can be verified by querying .h5 file info
%                       '/Sensors.Groups(1).Datasets.Name'
%                       - Units can be verified by querying .h5 file info
%                       '/Sensors.Groups(1).Datasets.Name.Attributes.Units'
%
%---------------------------REVISION HISTORY-------------------------------
% 
% Jess Zendler, 2021:
%   - accept different methods of running bout identification as specified
%   in rbmxInitializeProject_sensorRUNv02
%   - remove call to importAPDM. All data import is in this script.
%   - add quality control figures:
%       - plot sensor data for whole trial
%       - plot selected start / stop of running bouts
%   - rename variables for consistent naming structure, including removing
%   noun_noun in favor nounNoun and appending units to variables as _units
%   - simplified reading and parsing of data
%
%--------------------------------------------------------------------------
%% rbmxActivityIdentification_sensorRUNv02_SupervisedRunID_imu3

% Unpack
apdm = session.apdm;
activityIdentification = session.activityIdentification;

%% IMPORT APDM DATA

% get .h5 file to analyze
fullfilename = fullfile(apdm.datapath,apdm.filename);

% get info for raw and processed sensor data
info.sensors = h5info(fullfilename,'/Sensors');
info.processed = h5info(fullfilename,'/Processed');

% get annotation data
annot = h5read(fullfilename,'/Annotations');
annot.Annotation = cellstr(annot.Annotation');

% initialization of sensor data
n_sensors = length(info.sensors.Groups); % number of sensors
sensorLocations = cell(n_sensors,1); % sensor locations from APDM labels
dataTypes = apdm.dataTypes;
dataAbbreviations = apdm.dataAbbreviations;


% get sensor locations and identify sensors for required body segments
for s = 1:n_sensors
    
    % get sensor label
    info.sensors.Groups(s).config = h5info(fullfilename,[info.sensors.Groups(s).Name,'/Configuration']);
    sensorLocations{s} = info.sensors.Groups(s).config.Attributes(1).Value;
end

iLeftShank = listdlg('ListString',sensorLocations,'SelectionMode','Single','PromptString','Select Left Shank Sensor');
leftShankName = sensorLocations{iLeftShank};

iRightShank = listdlg('ListString',sensorLocations,'SelectionMode','Single','PromptString','Select Right Shank Sensor');
rightShankName = sensorLocations{iRightShank };

iSacrum = listdlg('ListString',sensorLocations,'SelectionMode','Single','PromptString','Select Sacrum Sensor');
sacrumName = sensorLocations{iSacrum};

requiredSensorNames = {leftShankName, rightShankName, sacrumName};

% get time array
time_posix = double(h5read(fullfilename,[info.sensors.Groups(1).Name,'/Time'])); %time in microseconds, posix time

%% Quality check
% plot left and right shank resultant accel (scaled for visualization)
% alongside left and right force from treadmill

% make t0 = 0 and convert time to seconds for easier review
time_s = (time_posix - time_posix(1))*10^(-6);

% extract resultant acceleration data from shank sensors and plot vs. time
leftShank = vecnorm(double(h5read(fullfilename,[info.sensors.Groups(iLeftShank).Name,'/',dataTypes{1}])));
rightShank = vecnorm(double(h5read(fullfilename,[info.sensors.Groups(iRightShank).Name,'/',dataTypes{1}])));

% quality check
figure(1)
hold on
plot(time_s,leftShank,'DisplayName','Left Shank Accel');
plot(time_s,rightShank,'DisplayName','Right Shank Accel');
xlabel('relative time (s)')
title('Quality Check - Press any key to continue')
legend
pause()

% review data and continue or cancel. If continue, figure will remain up for
% next steps. This same figure is used for Start/Stop time selection for
% 'Manual' methods and to display Start/Stop markers for bouts for all methods.
pause()
cont = questdlg('Would you like to continue with analysis?','Quality Check','Continue','Quit','Continue');
if cont(1) == 'Q'
    error('Analysis cancelled by user') %this is not the best way to do this
elseif isempty(cont)
    error('Analysis cancelled by user')
end

% Update figure name
figure(1)
title('Quality Check')

%%  Determine Trial Start/Stop Times

% Selection of trial start/stop times is based on 'method' as defined in
% project initialization:
%
% 'WholeTrial': no selection required because entire trial is used as single running bout
% 'EventsStartStop': Get start and stop times from APDM button events with accompanying events file.
% 'EventsStart': Same as 'EventsStartStop' except that endTime_s = startTime_s + runDuration_s
% 'ManualStartStop': Use GUI to select start and stop of each bout.
% 'ManualStart': Same as 'ManualStartStop' except that endTime_s = startTime_s + runDuration_s

n_runs = 1; %default to 1 running bout

switch activityIdentification.method
    
    case 'WholeTrial' %Whole Trial
        
        %1 running bout
        run(1).startTime_s = time_s(1); %start is first data point
        run(1).endTime_s = time_s(end);%stop is last data point
        
    case 'ManualStart' %Manual identification of start, use runDuration_s for end
        
        % indicate number of running bouts within session are to be analyzed
        msgbox('Examine running trial to determine number of running bouts. Press any key when ready to proceed')
        pause()
        n_runs = str2double(inputdlg('How many running bouts to analyze?','N Running Bouts',[1 50],{'1'})); % default is 1 bout
        
        % select start of bouts within session using crosshairs
        uiwait(msgbox('In the next step you will select the start time of each bout on the graph. Before each selection you can use the Zoom and Pan functions to find the location to select. When ready, press any key to convert to crosshairs to select the point. Zoom and Pan will then become available for the subsequent point.'))
        
        for r = 1:n_runs
            title(['Select Start of Bout ' num2str(r) '. Press any key to get selection crosshairs.']);
            pause() %you can zoom/pan on the figure until you find the first
            [x,~] = ginput(1); %use crosshairs to select start
            run(r).startTime_s =  x;
            run(r).endTime_s = run(r).startTime_s + activityIdentification.runDuration_s; % compute stop time from start time + runDuration_s
        end
        
    case 'ManualStartStop' % Manual selection of start and stop of bouts
        
        % indicate number of running bouts within session are to be analyzed
        msgbox('Examine running trial to determine number of running bouts. Press any key when ready to proceed')
        pause()
        n_runs = str2double(inputdlg('How many running bouts to analyze?','N Running Bouts',[1 50],{'1'})); % default is 1 bout
        
        uiwait(msgbox('In the next step you will select the start and stop time of each bout on the graph. Before each selection you can use the Zoom and Pan functions to find the location to select. When ready, press any key to convert to crosshairs to select the point. Zoom and Pan will then become available for the subsequent point.'))
        
        for i = 1:n_runs*2
            iseven = rem(i,2) == 0; % check if index is odd or even. odd index is a start, even index is a stop
            if iseven
                bout_no = i/2;
                title(['Select End of Bout ' num2str(bout_no) '. Press any key to get selection crosshairs.']);
            else
                bout_no = (i+1)/2;
                title(['Select Start of Bout ' num2str(bout_no) '. Press any key to get selection crosshairs.']);
            end
            
            pause() %you can zoom/pan on the figure until you find the first
            [x(i),~] = ginput(1); %use crosshairs to select start and stop
        end
        
        for r = 1:n_runs
            run(r).startTime_s =  x(2*r-1);
            run(r).endTime_s = x(2*r);
        end
        
    case 'EventsStart' %Events start only, take start APDM button events or streaming annotations
        
        %make list of annotations for user to review
        annotationName = annot.Annotation; % Name of annotation
        annotTime_posix = double(annot.Time); % Annotation time in posix and microseconds
        annotTime_s = (annotTime_posix - time_posix(1))*(10^-6); %convert annotation time to relative seconds for easier review
        sensorID = annot.SensorID; % ID of sensor creating annotation. ID = 0 indicates annotation from Motion Studio
        vars = {'Annotation', 'Sensor ID', 'Relative time (s)'};
        annotationTable = table(annotationName, sensorID, annotTime_s,'VariableNames',vars); 
        
        % display table for easy review of all annotations available
        ok = questdlg('Review APDM annotations in next step. Press any key when ready to proceed to selection','APDM Events','OK',{'OK'});
        fig = uifigure(2);
        uit = uitable(fig,'Data',annotationTable);
        uit.Position = [20 20 500 320];
        pause() % press any key to continue to selection step
        
        % select annotations corresponding to START of bouts
        iannot = listdlg('ListString',annotationName,'SelectionMode','Multiple',...
            'PromptString','Select Bout Starts');
        close(fig)
        
        % find start time and end time for each bout using selected annotations
        n_runs = length(iannot);
        
        for r = 1:n_runs
            
            % get annotation number corresponding to run start and start time
            startAnnot = iannot(r);
            run(r).startTime_s = annotTime_s(startAnnot);
            
            % end time is start time + run_seconds
            run(r).endTime_s = run(r).startTime_s + activityIdentification.runDuration_s;
            
        end
        
    case 'EventsStartStop' %Events start and stop, take start from events annotations
        
        %make list of annotations for user to review
        annotationName = annot.Annotation; % Name of annotation
        annotTime_posix = double(annot.Time); % Annotation time in posix and microseconds
        annotTime_s = (annotTime_posix - time_posix(1))*(10^-6); %convert annotation time to relative seconds for easier review
        sensorID = annot.SensorID; % ID of sensor creating annotation. ID = 0 indicates annotation from Motion Studio
        vars = {'Annotation', 'Sensor ID', 'Relative time (s)'};
        annotationTable = table(annotationName, sensorID, annotTime_s,'VariableNames',vars); %
        
         % Display table for easy review of all annotations available
        ok = questdlg('Review APDM annotations in next step. Press any key when ready to proceed to selection','APDM Events','OK',{'OK'});
        fig = uifigure('Name','Review APDM Annotations for Starts and Stops. Press any key to continue.');
        uit = uitable(fig,'Data',annotationTable);
        uit.Position = [20 20 500 320];
        pause() % press any key to continue to selection step
      
        % select annotations corresponding to start AND stop of bouts
        iannotStart = listdlg('ListString',annotationName,'SelectionMode','Multiple',...
            'PromptString','Select Bout Starts');
        
        % select annotations corresponding to start AND stop of bouts
        iannotStop = listdlg('ListString',annotationName,'SelectionMode','Multiple',...
            'PromptString','Select Bout Stops');
        
        close(fig)
        
        % Find start time and end time for each bout using selected annotations
        
        % check that number of start annotations = number of stop annotations
        if length(iannotStart) ~= length(iannotStop)
            error('Number of start annotations must equal number of stop annotations')
        end
        
        n_runs = length(iannotStart);
        
        for r = 1:n_runs
            
            % get annotations number and times corresponding to run
            % start and stop
            
            startAnnot = iannotStart(r);
            run(r).startTime_s = annotTime_s(startAnnot);
            
            endAnnot = iannotStop(r);
            run(r).endTime_s = annotTime_s(endAnnot);
            
        end
         
end

% Add Start and Stop of Bouts to Plot

for r = 1:n_runs
    
    startString = ['Start of Bout ' num2str(r)];
    endString = ['End of Bout ' num2str(r)];
    plot(run(r).startTime_s,0,'ko','DisplayName',startString)
    plot(run(r).endTime_s,0,'kx','DisplayName',endString)
    
end

%display quality control figure legend and turn off hold
legend
title('Quality Check');
hold off

%%  Read/parse data

% Get time vector, start and end samples, sampling frequency for each running bout

for r = 1:length(run)
    
    % get trial time array, make t0 = 0
    run(r).time_s = time_s(time_s >= run(r).startTime_s & time_s <= run(r).endTime_s) - run(r).startTime_s;
    run(r).samplingFrequency = mean(1./diff(run(r).time_s)); % Automatically identify sampling frequency rather than relying on user input
    indices = find(time_s >= run(r).startTime_s & time_s <= run(r).endTime_s);
    run(r).startSample = indices(1);
    run(r).endSample = indices(end);
    
end

% Get sensor data, for each sensor x data type x running bout

for s = 1:n_sensors
    
    % get sensor label
    info.sensors.Groups(s).config = h5info(fullfilename,[info.sensors.Groups(s).Name,'/Configuration']);
    sensorLocations{s} = info.sensors.Groups(s).config.Attributes(1).Value;
    
    % for each data type
    for d = 1:length(dataTypes)
        
        % get data
        if strcmp(dataTypes{d},'Orientation')
            raw = double(h5read(fullfilename,[info.processed.Groups(s).Name,'/',dataTypes{d}]));
        else
            raw = double(h5read(fullfilename,[info.sensors.Groups(s).Name,'/',dataTypes{d}]));
        end
        
        % make columns time dimension
        [r,c] = size(raw); if r > c; raw = raw'; end
        
        % for each bout
        if ~isempty(raw)
            for r = 1:length(run)
                
                % get bout specific data
                run(r).data.imu.locations.(sensorLocations{s}).(dataAbbreviations{d}) = raw(:,run(r).startSample : run(r).endSample);
                
            end
        end
        
    end
end

%% Packup

session.run = run;
session.apdm.annotations = annot;
session.apdm.requiredSensorNames = requiredSensorNames;
session.apdm.sensorLocations = sensorLocations;

end