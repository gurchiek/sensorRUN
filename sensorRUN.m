%% sensorRUN
% Reed Gurchiek, 2020
% 
%   analyze running bouts using right/left shank and sacrum accelerometer
%   data. The analysis uses the RemoteBMX pipeline [1] for the analysis and
%   allows additional reporting and display options. 
%
%   [1] Gurchiek et al., 2019, Sci Rep, 9(1)

%% ANALYSIS

% analyze new running session or import existing analysis
new = questdlg('Analyze new running session or import existing analysis?','New Analysis','Analyze New','Import Existing','Analyze New');
if ~isempty(new)
    
    if new(1) == 'A'
        
        % call remote bmx
        RemoteBMX
        
    else
        
        % get session to import
        ok = questdlg('Select the analysis*.mat file to import','Select Analysis','OK','OK');
        if ~isempty(ok)
            
            % load
            [file,path] = uigetfile();
            load(fullfile(path,file));
            
        end
        
    end
    
end

%% REPORTING AND VISUALIZATION

% loop forever
while 1
    
    % continue?
    cont = questdlg('Generate report or visualize IMU data?','Report & Visualization','Generate Report','Visualize IMU Data','Cancel','Cancel');
    if isempty(cont)
        break
    elseif cont(1) == 'C'
        break
    else
        
        % answer request
        feval(['sensorRUN_' replace(cont,' ','')],session);
        
    end
    
end
    