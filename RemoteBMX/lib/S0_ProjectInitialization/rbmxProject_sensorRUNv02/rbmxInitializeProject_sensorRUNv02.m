function [ session ] = rbmxInitializeProject_sensorRUNv02(session)
%Reed Gurchiek, 2020
%
%-----------------------------DESCRIPTION----------------------------------
% SensorRunv02 Project: 
%
% Designed to analyze running bouts using right/left shank and sacrum 
% accelerometer data to detect foot contact and segment strides. The
% analysis uses the RemoteBMX pipeline [1].
% 
% [1] Gurchiek et al., 2019, Sci Rep, 9(1)
%
% See README for more information on how to use
% and modify this project.
%  
% SETTINGS for executing the project are set in the script below or via
% user input at prompts. See specific functions for additional info.
%   apdm:
%    - dataTypes: set in script; names for sensor data types
%    - dataAbbreviations: set in script; 
%   activityIdentification: 
%    - name:    set in script; folder of activity identification scripts. 
%               Assumed to be housed within RemoteBMX/lib/S1_ActivityIdentification. 
%    - function: set in script; primary activity identification script. Used 
%               to read/parse data and identify bouts of running for subsequent 
%               event detection and analysis. Best practice is function = 
%               "rbmxActivityIdentification_name.m"
%    - method:  set in user prompt; method for determining start and stop 
%               of running bout(s)to analyze. Options:
%                    - 'WholeTrial': use entire dataset. For example, when
%               using APDMs in streaming mode and starting and stopping
%               trials while participant is running (i.e., whole trial
%               contains only running)
%                    - 'EventsStartStop': use APDM button event markers to
%               identify start and stop of bouts. For example, when running
%               sensors in logging mode and using sensor button event
%               marker to indicate start and stop of different running
%               conditions.
%                    - 'EventsStart': use APDM button event markers to identify
%               start of bouts. Stop of bout is automatically set as
%               startTime + runDuration_s. Same use case as 'EventsStartStop' except
%               button events only used to indicate the start of a new
%               running condition and all running bouts are same duration.
%                    - 'ManualStartStop': use graphical interface to select start and
%               stop of bouts. Use this mode for example, when data is a
%               mix of running and other activity and no button events
%               exist to mark the bouts.
%                   - 'ManualStart': use graphical interface to select start
%               of bouts. Stop of bout is automatically set as
%               startTime + runDuration_s. Same use case as ManualStartStop
%               but run durations are identical in length.
%       
%    - runDuration_s: set in user prompts; seconds; duration for analysis following 
%               start of running bout. 
%               Options: 
%                   - number > 0: duration of each bout, such that end_bout_time = ...
%                           start_bout_time + runDuration_s
%                   - -1: not used 
%               
%   eventDetection: 
%    - name:    set in script; name folder containing event detection scripts. 
%               Assumed to be housed within RemoteBMX/lib/S2_EventDetection. 
%    - function: set in script; name of primary eventDetection script. Used to identify foot 
%               contacts during running in order to segment strides. Best 
%               practice is that function = "rbmxEventDetection_name.m"
%    - detectionAlgorithm: set in script; name of foot contact detection function 
%
%   analysis: 
%    - name:    set in script; name of folder containing analysis scripts. 
%               Assumed to be housed within RemoteBMX/lib/S3_Analysis. 
%    - function: set in script; primary analysis script. Used to compute step 
%               and stride-related analyses and organize data for further post 
%               analyses. Best practice is function = "rbmxAnalysis_name.m"
%    - comExcursionAlgorithm: set in script; name of function to estimate 
%               center of mass vertical displacement. 
%    - peakShankAccelWindow_s: set in script; seconds; time window centered on 
%               foot contact used to search for maximum resultant shank 
%               acceleration. 0.2 seconds determined by trial-and-error.
%    - metrics: set in script; names of metrics to be computed for each 
%               step/stride. These will be used for headers in output
%               reports and field names for outputs.
%    - aggregationMethods: set in script; names of statistical methods used for
%               aggregating step/stride metrics. These will be used for 
%               headers in output reports and field names for outputs.
%    - aggregationFunctions: set in script; names of functions used to compute 
%               aggregate statistics. By default, aggregation functions are 
%               applied across all strides, right side only, and left side only.
%               Required to match a built-in Matlab function (e.g., mean.m or std.m) 
%               or  custom function in the path (e.g., lib/helpers/cv.m to 
%               compute coefficient of variation). 
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       struct, RemoteBMX session struct
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct with updated fields
%       New fields:
%           - activityIdentification: struct; settings for running activity
%           identification (see field descriptions in Settings) 
%           - eventDetection: struct; settings for foot contact event
%           detection (see field descriptions in Settings) 
%           - analysis: struct; settings for step-by-step / stride-by-stride 
%           analysis (see field descriptions in Settings) 
%           - apdm: struct;
%               - datapath: folder containing .h5 file containing APDM
%               sensor data to analyze 
%               - filename: name of .h5 file of APDM sensor data
%               - dataTypes: names of sensor data types
%               - dataAbbreviations: abbreviations associated with sensor
%               data types
%
%---------------------------REVISION HISTORY-------------------------------
%
% Jess Zendler, 2021: 
%   - add methods specification options for activityIdentification
%   - remove hard-coded APDM sampling frequency (it is now 
%   calculated from the APDM data)
%   - renamed run_seconds to runDuration_s and changed from hard-coded to 
%       user-supplied based on method

%--------------------------------------------------------------------------
%% rbmxInitializeProject_sensorRUNv02

% Step 1: Activity identification
activityIdentification.name = 'sensorRUNv02_SupervisedRunID_imu3';
activityIdentification.function = str2func('rbmxActivityIdentification_sensorRUNv02_SupervisedRunID_imu3');

% Get APDM data file
ok = questdlg('Select the APDM data file (.h5 file)','Data File','OK',{'OK'});
if isempty(ok); error('Initialization terminated.'); end
[filename, datapath] = uigetfile('*.h5','Select APDM file');

% Set sensor data fields
apdm.dataTypes = {'Accelerometer','Gyroscope','Magnetometer','Orientation','Barometer','Temperature'};
apdm.dataAbbreviations = {'a','w','m','q','b','temp'};

% identify method of activity identification
methodList = {'Whole Trial','Events Start', 'Events Start and Stop','Manual Start','Manual Start and Stop'};
imethod = listdlg('ListString',methodList,'SelectionMode','Single','PromptString','Select method to identify running data');

switch imethod
    case 1 % use whole trial. Selecting start and stop for analysis not needed. Running bouts = 1
        activityIdentification.method = 'WholeTrial';
        activityIdentification.runDuration_s = -1;
        
    case 2 % Start only from APDM button events, Stop determined by running bout duration
        activityIdentification.method = 'EventsStart';
        activityIdentification.runDuration_s  = str2double(inputdlg('Specify bout duration in seconds','Bout duration',[1 50],{'60'})); %   duration applies to all bouts
        
    case 3 % Start and Stop from APDM button events
        activityIdentification.method = 'EventsStartStop';
        activityIdentification.runDuration_s = -1;
        
    case 4 % Start from manual selection, Stop determined by running bout duraiton
        activityIdentification.method = 'ManualStart';
        activityIdentification.runDuration_s  = str2double(inputdlg('Specify bout duration in seconds','Bout duration',[1 50],{'60'})); %   duration applies to all bouts
        
    case 5 % Start and Stop from manual selection
        activityIdentification.method = 'ManualStartStop';
        activityIdentification.runDuration_s = -1;
end

% Step 2: Event detection
eventDetection.name = 'sensorRUNv02_FootContactID_imu3_v01';
eventDetection.function = str2func('rbmxEventDetection_sensorRUNv02_FootContactID_imu3_v01');
eventDetection.detectionAlgorithm = 'sensorRUNv02_footContact_algo1';

% Step 3: Analysis
analysis.name = 'sensorRUNv02_RunAnalysis_imu3_v01';
analysis.function = str2func('rbmxAnalysis_sensorRUNv02_RunAnalysis_imu3_v01');
analysis.comExcursionAlgorithm = 'sensorRUNv02_comExcursion_algo1';
analysis.peakShankAccelWindow_s = 0.2;
analysis.metrics = {'stepTime' 'stepFrequency' 'comExcursion' 'strideTime' 'strideFrequency' 'shankImpactAcceleration'};
analysis.aggregationMethods = {'mean' 'sd' 'cv' };
analysis.aggregationFunctions = {'mean' 'std' 'cv' };

% Initialize data structure
apdm.datapath = datapath;
apdm.filename = filename; 

% Pack Up
session.activityIdentification = activityIdentification;
session.eventDetection = eventDetection;
session.analysis = analysis;
session.apdm = apdm;

end