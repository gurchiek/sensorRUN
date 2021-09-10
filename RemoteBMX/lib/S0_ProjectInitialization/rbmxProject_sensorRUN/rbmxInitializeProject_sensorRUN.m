function [ session ] = rbmxInitializeProject_sensorRUN(session)
%Reed Gurchiek, 2020
%   analyze apdm imu data during running activity using r/l shank and
%   pelvis data
%
%   SETTINGS (see specific functions for description):
%       -run_seconds
%       -detectionAlgorithm
%       -comExcursionAlgorith
%       -peakShankAccelWindow_s
%       -metrics
%       -aggregationMethods
%       -aggregationFunctions
%       -fs (sampling frequency)
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       struct, RemoteBMX session struct
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       struct, specified activityIdentifier, eventDetector, analyzer,
%       data details
%
%--------------------------------------------------------------------------
%% rbmxInitializeProject_sensorRUN

% activity ID
activityIdentification.name = 'sensorRUN_SupervisedRunID_imu3';
activityIdentification.function = str2func('rbmxActivityIdentification_sensorRUN_SupervisedRunID_imu3');
activityIdentification.run_seconds = 60;

% event detector
eventDetection.name = 'sensorRUN_FootContactID_imu3_v01';
eventDetection.function = str2func('rbmxEventDetection_sensorRUN_FootContactID_imu3_v01');
eventDetection.detectionAlgorithm = 'sensorRUN_footContact_algo1';

% analyzer
analysis.name = 'sensorRUN_RunAnalysis_imu3_v01';
analysis.function = str2func('rbmxAnalysis_sensorRUN_RunAnalysis_imu3_v01');
analysis.comExcursionAlgorithm = 'sensorRUN_comExcursion_algo1';
analysis.peakShankAccelWindow_s = 0.2;
analysis.metrics = {'stepTime' 'stepFrequency' 'comExcursion' 'strideTime' 'strideFrequency' 'shankImpactAcceleration'};
analysis.aggregationMethods = {'mean' 'sd'};
analysis.aggregationFunctions = {'mean' 'std'};

% get data path
ok = questdlg('Select the runners folder containing the APDM data (.h5 file)','Data Path','OK',{'OK'});
if isempty(ok); error('Initialization terminated.'); end
datapath = uigetdir;

% initialize data structure
apdm.datapath = datapath;
apdm.fs = 128;

% save
session.activityIdentification = activityIdentification;
session.eventDetection = eventDetection;
session.analysis = analysis;
session.apdm = apdm;

end