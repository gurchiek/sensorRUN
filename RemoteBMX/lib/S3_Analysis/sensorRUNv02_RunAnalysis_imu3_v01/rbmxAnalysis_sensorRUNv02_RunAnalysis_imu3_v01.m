function [ session ] = rbmxAnalysis_sensorRUNv02_RunAnalysis_imu3_v01(session)
%Reed Gurchiek, 2019
%
%-----------------------------DESCRIPTION----------------------------------
%
%   extract analysis metrics from segmented sacral and r/l shank
%   acceleration data during running bouts
%
%   spatiotemporal metrics via standard definitions: step time, step
%   frequency, stride time, stride frequency
%
%   com excursion is calculated using sensorRUNv02_comExcursion_algo1:
%   awaiting validation
%
%   shank impact acceleration looks for the largest acceleration in shank
%   time series in a window of length specified by
%   session.analysis.peakShankAccelWindow_s (in seconds, specified in
%   project initialization) centered at the estimated foot contact
%
%   all stride metrics from a particular bout are also aggregated for all
%   strides, right side only, and left side only according to project
%   specified aggregation methods (and corresponding functions) such as
%   mean, std as specified in the project initialization.
%
%   the option to save a .mat file of the session struct is provided.
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct with updated fields
%       New/Updated fields:
%           - run.footContact:
%               - stepTime: seconds, time difference between start and end
%               of step (start of subsequent contralateral step)
%               - stepFrequency: hz, 1/stepTime
%               - strideTime: seconds, time difference between start and
%               end of stride (start of subsequent ipsilateral step)
%               - strideFrequency: hz, 1/strideTime
%               - comExcursion: m, difference between highest and lowest
%               vertical position of COM during step
%               - shankImpactAcceleration: m/s^2, estimate peak impact-related shank
%               acceleration. Based on max resultant acceleration within the
%               window centered at the estimated foot contact where the window
%               length is specified in seconds by peakShankAccelWindow_s set in
%               the project initialization function
%           - run.batchAnalysis.(metricName).(distributionName).aggName: aggregate
%               statistics for metricName computed on distributionName with
%               aggFxn and listed with field name aggName. distributionName
%               = 'left'/'right'/'all' for left, right, or all steps.
%
%---------------------------REVISION HISTORY-------------------------------
%
% Jess Zendler, 2021, revised to:
%   - make consistent with variable naming and structure set in
%   initialization, activity identification, and event detection scripts
%   - use sampling frequency calculated from APDM data rather than explicit
%   value set at initialization
%   - remove calls to session struct once session.run is already unpacked
%   - make stride segmentation of sensor data flexible to sensor locations
%   used
%   - move computation of aggregate statistics to separate section
%   - provide ability to specify save directory
%   - removed segmenting of data by strides. this is done by post-analysis
%   scripts as needed. See for example, sensorRUNv02_VisualizeIMUData.m
%
%--------------------------------------------------------------------------
%% rbmxAnalysis_sensorRUNv02_RunAnalysis_imu3_v01

% unpack

% data and specifications
run = session.run;
fs = round(run(1).samplingFrequency);
halfwindow = ceil(fs * session.analysis.peakShankAccelWindow_s / 2);
requiredSensorNames = session.apdm.requiredSensorNames;
lShankName = requiredSensorNames{1};
rShankName = requiredSensorNames{2};
sacrumName = requiredSensorNames{3};

% COM vertical excursion algorithm
algo = str2func(session.analysis.comExcursionAlgorithm);

% names of metrics to be calculated
metrics = session.analysis.metrics;

% statistical aggregation methods
aggName = session.analysis.aggregationMethods;
aggFxn = session.analysis.aggregationFunctions;

%% STRIDE-FOR-STRIDE SEGMENTATION, METRIC COMPUTATION, REQUIRED SENSORS

% compute core metrics from minimal required IMU set (left shank, right
% shank, pelvis) and valid step / stride segmentation

% for each run
for r = 1:length(run)
    
    % reset step counters for each running bout
    nStepsL = 0;
    nStepsR = 0;
    
    % estimate vertical COM position
    sacrumAcceleration = run(r).data.imu.locations.(sacrumName).a;
    sacrumTime = run(r).time_s(1:length(sacrumAcceleration(1,:)));
    comPosition = algo(sacrumAcceleration,sacrumTime,fs);
    
    % for each foot contact
    for k = 1:length(run(r).footContact)
        
        if run(r).footContact(k).index ~= -1
            
            % if valid step
            if run(r).footContact(k).validStep
                
                % compute step temporals (time, frequency)
                run(r).footContact(k).stepTime = (run(r).footContact(k).stepEndIndex - run(r).footContact(k).index) / fs;
                run(r).footContact(k).stepFrequency = 1 / run(r).footContact(k).stepTime;
                
                % get COM excursion (max - min of vertical COM position)
                run(r).footContact(k).comExcursion = ...
                    max(comPosition(run(r).footContact(k).index:run(r).footContact(k).stepEndIndex)) - ...
                    min(comPosition(run(r).footContact(k).index:run(r).footContact(k).stepEndIndex));
                
                % compute peak shank acceleration as the peak near the foot contact.
                shank = rShankName;
                if run(r).footContact(k).side(1) == 'l'
                    shank = lShankName;
                end
                run(r).footContact(k).shankImpactAcceleration = ...
                    max(vecnorm(run(r).data.imu.locations.(shank).a(:,run(r).footContact(k).index - halfwindow:run(r).footContact(k).index + halfwindow)));
                
                % update count number of steps
                if run(r).footContact(k).side(1) == 'l'
                    nStepsL = nStepsL + 1;
                elseif run(r).footContact(k).side(1) == 'r'
                    nStepsR = nStepsR + 1;
                end
                
                % compute stride temporals (time, frequency)
                % note that this creates a new
                % stride measure for each foot contact, which basically
                % double counts strides
                
                if run(r).footContact(k).validStride % if valid stride
                    
                    % spatiotemporals
                    run(r).footContact(k).strideTime = (run(r).footContact(k).strideEndIndex - run(r).footContact(k).index) / fs;
                    run(r).footContact(k).strideFrequency = 1 / run(r).footContact(k).strideTime;
                    
                end
            end
            
        end
    end
    
    % save step counts for running bout
    run(r).nStepsL = nStepsL;
    run(r).nStepsR = nStepsR;
    
end

%% Calculate aggregate statistics on metrics

for r = 1:length(run)
    
    % for each metric
    for m = 1:length(metrics)
        
        % initialize distributions for metric m x run r 
        dist = []; % all
        distL = []; % left steps
        distR = []; % right steps
        
        % add valid steps with metrics to distributions
        for k = 1:length(run(r).footContact)
            if run(r).footContact(k).index ~= -1
                if run(r).footContact(k).validStep
                    value = run(r).footContact(k).(metrics{m});
                    if ~isempty(value) && ~isnan(value)
                        dist = [dist; value];
                        if run(r).footContact(k).side(1) == 'l'
                            distL = [distL;value];
                        elseif run(r).footContact(k).side(1) == 'r'
                            distR = [distR;value];
                        end
                    end
                end
            end
        end
                 
        % provide a count of number of steps/strides used for statistic
        run(r).batchAnalysis.(metrics{m}).left.count = length(distL);
        run(r).batchAnalysis.(metrics{m}).right.count = length(distR);
        run(r).batchAnalysis.(metrics{m}).all.count = length(dist);
        
        % for each aggregation method
        for a = 1:length(aggName)
            
            % characterize
            run(r).batchAnalysis.(metrics{m}).left.(aggName{a}) = feval(aggFxn{a},distL);
            run(r).batchAnalysis.(metrics{m}).right.(aggName{a}) = feval(aggFxn{a},distR);
            run(r).batchAnalysis.(metrics{m}).all.(aggName{a}) = feval(aggFxn{a},dist);
        end
        
    end
end

%% PACK UP
session.run = run;

%% SAVE SESSION OUTPUT

qsave = questdlg('Save .mat file of analysis results?','Save','Yes','No','Yes');

if qsave(1) == 'Y'
    disp('Select folder to save .mat file');
    savePath = uigetdir(session.apdm.datapath,'Select Folder To Save .mat File');
    disp('Enter name for .mat file');
    outputname = inputdlg('Save As:','Save As',[1 100],{['analysis_' replace(date,'-','') '_' session.apdm.filename(1:end-3) '.mat']});
    save(fullfile(savePath,outputname{1}),'session');
end


end