function [ ] = sensorRUNv02_VisualizeIMUData(session)
%Reed Gurchiek, 2020
%
%   Plot IMU sensor data by stride with ensemble mean and standard deviation. 
%
%   Dialogs provided to select running bouts, sensor locations (e.g., left shank), 
%   sensor data and axis(es) (incl. resultant magnitude), and optional low pass
%   filter.
%
%   Currently dialog selections apply to all selected bouts & locations. 
%   That is, the same datatypes/axes/filtering will be produced for each
%   selected sensor for each selected running bout.
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct
%
%---------------------------------OUTPUTS----------------------------------
%
%   figure(s):
%       for each run x sensor x axis selected
%       x-axis: percent of stride cycle
%       y-axis: g or rad/s for accelerometer or gyroscope data, respectively
%       grey lines: individual strides
%       red line: mean
%       red shade: +/- 1 std deviation
%
%---------------------------REVISION HISTORY-------------------------------
%
% Jess Zendler, 2021:
%   - select running bouts to plot
%   - allow user to select any available sensor data type/channel for plot
%   - add filtering to title of plots, if applicable
%
%--------------------------------------------------------------------------
%% sensorRUNv02_VisualizeIMUData

% unpack
run = session.run;

% select which bouts to plot
nruns = numel(run);
runList = cell(1,nruns);
for r = 1:nruns
    runList{r} = ['Run ' num2str(r)];
end
runSelect = listdlg('ListString',runList,'PromptString','Select a run bout:','SelectionMode','multiple');
nruns = length(runSelect);

%% Select data to plot for each bout. Same data will be plotted for all selected bouts.

plotInfo_ind = 0;

r = runSelect(1); % use first selected running bout to identify available sensor data

% select sensor locations
locationList = fieldnames(run(r).data.imu.locations);
locationSelect = listdlg('ListString',locationList,'PromptString','Select locations to plot','SelectionMode','multiple');
nlocations = length(locationSelect);

% select sensor datatype x channel data for each location
for l = 1:nlocations
    
    locationName = locationList{locationSelect(l)};
    sensorList = fieldnames(run(r).data.imu.locations.(locationName)); % available sensor datatypes for location
    
    % compile list of all channels available for sensor location, add
    % option for vector magnitude for each sensor type
    
    ind = 0; % restart sensor channel list for each location
    
    for s = 1:length(sensorList)
        
        sensorName = sensorList{s};
        nchannels = length(run(r).data.imu.locations.(locationName).(sensorName)(:,1));%number of rows = number of channels for sensor
        
        for c = 1:nchannels + 1 % add extra "channel" for magnitude
            
            ind = ind + 1; % index to next cell of sensorChannelList
            sensorStore{ind,1} = sensorName;
            if c == nchannels + 1
                sensorChannelList{ind} = [sensorName ' mag']; % add extra "vector magnitude" channel
                sensorStore{ind,2} = 'mag';
            else
                sensorChannelList{ind} = [sensorName ' axis' num2str(c)]; % channels for each axis of data
                sensorStore{ind,2} = num2str(c);
            end
            
        end
    end
    
    % select sensor data type x channel data
    channelSelect = listdlg('ListString',sensorChannelList,...
        'PromptString',['Select data for ' locationName],'SelectionMode','multiple');
    
    % store: bout #, location, data type, channel for plotting
    for c = 1:length(channelSelect)
        plotInfo_ind = plotInfo_ind + 1;
        plotInfo{plotInfo_ind,1} = locationName; % location
        plotInfo{plotInfo_ind,2} = sensorStore{channelSelect(c),1}; % data type
        plotInfo{plotInfo_ind,3} = sensorStore{channelSelect(c),2}; % channel
    end
end

%% Optional low pass filter. Note: applies to all data selected for bout
lowpass = questdlg('Lowpass filter data?','Lowpass','Yes','No','No');
if isempty(lowpass)
    lp = 0;
elseif lowpass(1) == 'N'
    lp = 0;
else
    lowpassco = inputdlg('Input lowpass cutoff frequency:','Cutoff Frequency',[1 50],{'6'});
    if isempty(lowpassco)
        lp = 0;
    else
        lp = str2double(lowpassco{1});
    end
end

%% Generate plots

[rows,~] = size(plotInfo); % number of plots to create for each bout
possiblefields = fieldnames(run(1));
ifields = listdlg('ListString',possiblefields,'SelectionMode','Single','PromptString','Select Field Containing IMU Foot Contact Data');
footContactField = possiblefields{ifields};
    
% for each bout
for n = 1:nruns
    
    r = runSelect(n); % index of selected bout within session
    
    % for each selected sensor location x datatype x channel
    for i = 1:rows
        
        locationName = plotInfo{i,1};
        dataType = plotInfo{i,2};
        axisType = plotInfo{i,3};
        
        % get indices of foot contacts
        if locationName(1) == 'R' || locationName(1) == 'r' % assume right-sided sensors begin with r or R, plot with right steps
            strideIndices = find([run(r).(footContactField).validStride] & strcmp('right',{run(r).(footContactField).side}));
        elseif locationName(1) == 'L' || locationName(1) == 'l' % assume left-sided sensors begin with l or L, plot with left steps
            strideIndices = find([run(r).(footContactField).validStride] & strcmp('left',{run(r).(footContactField).side}));
        else % assume all other sensors are midline sensors, plot with left and right steps
            strideIndices = find([run(r).(footContactField).validStride]);
        end
       
        % get time vector and ydata for each stride
        ts = zeros(length(strideIndices),101);
        k = 1;
        
        for c = strideIndices
            ind = run(r).(footContactField)(c).index:run(r).(footContactField)(c).strideEndIndex;
            if axisType(end) ~= 'g' % if axis type is not 'mag', plot selected channel (row of data)
                axis = str2double(axisType(end));
                axisName = ['axis ' num2str(axis)];
                ts0 = run(r).data.imu.locations.(locationName).(dataType)(axis,ind);
            else % if axis is 'mag', plot vector magnitude of all channels (rows of data)
                ts0 = vecnorm(run(r).data.imu.locations.(locationName).(dataType)(:,ind));
                axisName = 'resultant magnitude';
            end
            
            % lowpass filter, if selected
            if lp > 0
                fs = round(run(r).samplingFrequency);
                ts0 = bwfilt(ts0,lp,fs,'low',4);
            end
            
            % express as percentage of stride cycle
            x = linspace(0,100,length(ind));
            ts(k,:) = interp1(x,ts0,0:100,'pchip');
            k = k+1;
            
        end
        
        % populate ylabel for acceleration and angular velocity dat
        if dataType(1) == 'a'
            units = 'g';
            dataname = 'Acceleration';
        elseif dataType(1) == 'w'
            units = 'rad/s';
            dataname = 'Angular Rate';
        else
            units = ' ';
            dataname = ' ';
        end
        
        % plot
        [ens,ub,lb] = ensavg(ts,'mean','std',1); % compute average and standard deviation across strides for plotting
        figure
        plot(0:100,ts','Color',[0.5 0.5 0.5]) % plot individual strides in grey
        hold on
        plot(0:100,ens,'r','LineWidth',2) % plot ensemble average in thick red
        shade(0:100,ub,lb,'r',0.1) % plot +/- 1 std deviation in shaded red
        xlabel('Percent Stride')
        ylabel([dataname ' [' units ']'])
        if lp > 0
        title([runList{r} ': ' locationName ', ' dataType ' ' axisName ', low pass filter ' num2str(lp) ' Hz'])
        else
             title([runList{r} ': ' locationName ', ' dataType ' ' axisName])
        end
        hold off
    end
end
end
