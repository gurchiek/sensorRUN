function [ ] = sensorRUN_VisualizeIMUData(session)
%Reed Gurchiek, 2020
%
%--------------------------------------------------------------------------
%% sensorRUN_VisualizeIMUData

% select run
nruns = numel(session.run);
runlist = cell(1,nruns);
for r = 1:nruns; runlist{r} = ['Run ' num2str(r)]; end
r = listdlg('ListString',runlist,'PromptString','Select a run bout:','SelectionMode','single');

% select sensor location
locations = {'Right Shank' 'Left Shank' 'Pelvis'};
loc = {'Rshank','Lshank','pelvis'};
l = listdlg('ListString',locations,'PromptString','Select an IMU location:','SelectionMode','single');
location = locations{l};
loc = loc{l};

% gyro or accel data
sensor = questdlg('Plot gyroscope or accelerometer data?','Sensor Selection','Accelerometer','Gyroscope','Accelerometer');
if ~isempty(sensor)
    if sensor(1) == 'A'
        sens = 'a';
        units = 'g';
        dataname = 'Acceleration';
    else
        sens = 'w';
        units = 'rad/s';
        dataname = 'Angular Rate';
    end
    
    % low pass?
    lp = questdlg('Lowpass filter data?','Lowpass','Yes','No','No');
    if isempty(lp)
        lp = 0;
    elseif lp(1) == 'N'
        lp = 0;
    else
        lp = inputdlg('Input lowpass cutoff frequency:','Cutoff Frequency',[1 50],{'6'});
        if isempty(lp)
            lp = 0;
        else
            lp = str2double(lp{1});
        end
    end
    
    % certain axis or magnitude?
    ax = listdlg('ListString',{'Axis 1' 'Axis 2' 'Axis 3' 'Magnitude'},'PromptString','Select axis:','SelectionMode','single');
    
    % get indices of foot contacts
    if location(1) == 'R'
        strideIndices = find([session.run(r).footContact.validStride] & strcmp('right',{session.run(r).footContact.side}));
    elseif location(1) == 'L'
        strideIndices = find([session.run(r).footContact.validStride] & strcmp('left',{session.run(r).footContact.side}));
    elseif location(1) == 'P'
        strideIndices = find([session.run(r).footContact.validStride]);
    end
    
    % for each stride
    ts = zeros(length(strideIndices),101);
    i = 1;
    for c = strideIndices
        
        % get time series
        ind = session.run(r).footContact(c).index:session.run(r).footContact(c).strideEndIndex;
        if ax <= 3
            ts0 = session.run(r).data.imu.locations.(loc).(sens)(ax,ind);
        else
            ts0 = vecnorm(session.run(r).data.imu.locations.(loc).(sens)(:,ind));
        end
        
        % lowpass?
        if lp > 0
            ts0 = bwfilt(ts0,lp,session.apdm.fs,'low',4);
        end
        
        % express as percentage of stride cycle
        x = linspace(0,100,length(ind));
        ts(i,:) = interp1(x,ts0,0:100,'pchip');
        i = i+1;
        
    end
    
    % plot
    [ens,ub,lb] = ensavg(ts,'mean','std',1);
    figure
    plot(0:100,ts','Color',[0.5 0.5 0.5])
    hold on
    plot(0:100,ens,'r','LineWidth',2)
    shade(0:100,ub,lb,'r',0.1)
    xlabel('Percent Stride')
    ylabel([dataname ' [' units ']'])
    title([runlist{r} ': ' location ': ' sensor])
    
end