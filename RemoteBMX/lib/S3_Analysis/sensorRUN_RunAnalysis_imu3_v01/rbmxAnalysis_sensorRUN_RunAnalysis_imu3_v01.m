function [ session ] = rbmxAnalysis_sensorRUN_RunAnalysis_imu3_v01(session)
%Reed Gurchiek, 2019
%   extract analysis metrics from segmented sacral and r/l shank
%   acceleration data during running bouts
%
%   com excursion is calculated using sensorRUN_comExcursion_algo1:
%   awaiting validation
%
%   shank impact acceleration looks for the largest acceleration in shank
%   time series in a window of length specified by
%   session.analysis.peakShankAccelWindow_s (in seconds, specified in
%   project initialization) centered at the estimated foot contact
%
%   all stride metrics from a particular bout are also aggregated according
%   to project specified aggregation methods (and corresponding functions)
%   as specified in the project initialization.
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       same input struct but with updated fields:
%           -run.footContact field now contains stride/step
%           times/frequencies, com excursion, and shank impact acceleration
%
%--------------------------------------------------------------------------
%% rbmxAnalysis_sensorRUN_RunAnalysis_imu3_v01

% unpack
fs = session.apdm.fs;
halfwindow = ceil(fs * session.analysis.peakShankAccelWindow_s / 2);
run = session.run;
algo = str2func(session.analysis.comExcursionAlgorithm);

% metrics
metrics = session.analysis.metrics;

% aggregation methods
aggName = session.analysis.aggregationMethods;
aggFxn = session.analysis.aggregationFunctions;

%% STRIDE-FOR-STRIDE ANALYSIS
%Run 1 Foot Contact End
Sindex = [session.run(1).footContact.index];
Eindex = [session.run(1).footContact.stepEndIndex];
rEnd = [session.run(1).data.imu.locations.pelvis.end_sample];
rStart = [session.run(1).data.imu.locations.pelvis.start_sample];
fcEnd1 = find(Sindex >= rStart & Sindex < rEnd);

% Run 2 Foot Contact End
Sindex2 = [session.run(2).footContact.index];
Eindex2 = [session.run(2).footContact.stepEndIndex];
rEnd2 = [session.run(2).data.imu.locations.pelvis.end_sample];
rStart2 = [session.run(2).data.imu.locations.pelvis.start_sample];
fcEnd2 = find(Sindex2 >= rStart2 & Sindex2 < rEnd2);

% for each run
for r = 1:length(run)

    % estimate vertical COM position
    com_position = algo(session.run(r).data.imu.locations.pelvis.a(:,session.run(r).data.imu.locations.pelvis.start_sample:session.run(r).data.imu.locations.pelvis.end_sample),session.run(r).data.imu.locations.pelvis.t(1:end),session.apdm.fs);
    
    % for each foot contact
    for k = 1:length(session.run(r).footContact)
        
        % if valid step
        if session.run(r).footContact(k).validStep
            
            % spatiotemporals
            session.run(r).footContact(k).stepTime = (session.run(r).footContact(k).stepEndIndex - session.run(r).footContact(k).index) / fs;
            session.run(r).footContact(k).stepFrequency = 1 / session.run(r).footContact(k).stepTime;
            
            % get com_excursion
            session.run(r).footContact(k).comExcursion = ...
                max(com_position(session.run(r).footContact(k).index:session.run(r).footContact(k).stepEndIndex)) - ...
                min(com_position(session.run(r).footContact(k).index:session.run(r).footContact(k).stepEndIndex));
            
            % Raw Shank (Accel, Velocity, Orientation)
            
            if session.run(r).footContact(k).side(1) == 'l'
                session.run(r).rawStepLShankAccel{1,k} = session.run(r).data.imu.locations.Lshank.a(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
                session.run(r).rawStepLShankVelo{1,k} = session.run(r).data.imu.locations.Lshank.w(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
                session.run(r).rawStepLShankOrient{1,k} = session.run(r).data.imu.locations.Lshank.q(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
            else
                session.run(r).rawStepLShankAccel{1,k} = session.run(r).data.imu.locations.Lshank.a(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
                session.run(r).rawStepLShankVelo{1,k} = session.run(r).data.imu.locations.Lshank.w(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
                session.run(r).rawStepLShankOrient{1,k} = session.run(r).data.imu.locations.Lshank.q(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
            end
            
            if session.run(r).footContact(k).side(1) == 'r'
                session.run(r).rawStepRShankAccel{1,k} = session.run(r).data.imu.locations.Rshank.a(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
                session.run(r).rawStepRShankVelo{1,k} = session.run(r).data.imu.locations.Rshank.w(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
                session.run(r).rawStepRShankOrient{1,k} = session.run(r).data.imu.locations.Rshank.q(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
            else
                session.run(r).rawStepRShankAccel{1,k} = session.run(r).data.imu.locations.Rshank.a(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
                session.run(r).rawStepRShankVelo{1,k} = session.run(r).data.imu.locations.Rshank.w(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
                session.run(r).rawStepRShankOrient{1,k} = session.run(r).data.imu.locations.Rshank.q(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
            end
            
            % Raw Foot (Accel, Velocity, Orientation)
            if session.run(r).footContact(k).side(1) == 'l'
                session.run(r).rawStepLFootAccel{1,k} = session.run(r).data.imu.locations.Lfoot.a(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
                session.run(r).rawStepLFootVelo{1,k} = session.run(r).data.imu.locations.Lfoot.w(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
                session.run(r).rawStepLFootOrient{1,k} = session.run(r).data.imu.locations.Lfoot.q(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
            else
                session.run(r).rawStepLFootAccel{1,k} = session.run(r).data.imu.locations.Lfoot.a(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
                session.run(r).rawStepLFootVelo{1,k} = session.run(r).data.imu.locations.Lfoot.w(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
                session.run(r).rawStepLFootOrient{1,k} = session.run(r).data.imu.locations.Lfoot.q(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
            end
            
            if session.run(r).footContact(k).side(1) == 'r'
                session.run(r).rawStepRFootAccel{1,k} = session.run(r).data.imu.locations.Rfoot.a(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
                session.run(r).rawStepRFootVelo{1,k} = session.run(r).data.imu.locations.Rfoot.w(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
                session.run(r).rawStepRFootOrient{1,k} = session.run(r).data.imu.locations.Rfoot.q(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
            else
                session.run(r).rawStepRFootAccel{1,k} = session.run(r).data.imu.locations.Rfoot.a(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
                session.run(r).rawStepRFootVelo{1,k} = session.run(r).data.imu.locations.Rfoot.w(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
                session.run(r).rawStepRFootOrient{1,k} = session.run(r).data.imu.locations.Rfoot.q(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
            end
            
            % Raw Thigh (Accel, Velocity, Orientation)
            
            if session.run(r).footContact(k).side(1) == 'l'
                session.run(r).rawStepLThighAccel{1,k} = session.run(r).data.imu.locations.Lthigh.a(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
                session.run(r).rawStepLThighVelo{1,k} = session.run(r).data.imu.locations.Lthigh.w(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
                session.run(r).rawStepLThighOrient{1,k} = session.run(r).data.imu.locations.Lthigh.q(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
            else
                session.run(r).rawStepLThighAccel{1,k} = session.run(r).data.imu.locations.Lthigh.a(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
                session.run(r).rawStepLThighVelo{1,k} = session.run(r).data.imu.locations.Lthigh.w(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
                session.run(r).rawStepLThighOrient{1,k} = session.run(r).data.imu.locations.Lthigh.q(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
            end
            
            if session.run(r).footContact(k).side(1) == 'r'
                session.run(r).rawStepRThighAccel{1,k} = session.run(r).data.imu.locations.Rthigh.a(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
                session.run(r).rawStepRThighVelo{1,k} = session.run(r).data.imu.locations.Rthigh.w(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
                session.run(r).rawStepRThighOrient{1,k} = session.run(r).data.imu.locations.Rthigh.q(:,session.run(r).footContact(k).index(1:2:end):session.run(r).footContact(k).stepEndIndex(1:2:end));
            else
                session.run(r).rawStepRShankAccel{1,k} = session.run(r).data.imu.locations.Rthigh.a(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
                session.run(r).rawStepRShankVelo{1,k} = session.run(r).data.imu.locations.Rthigh.w(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
                session.run(r).rawStepRShankOrient{1,k} = session.run(r).data.imu.locations.Rthigh.q(:,session.run(r).footContact(k).index(2:2:end):session.run(r).footContact(k).stepEndIndex(2:2:end));
            end
            
            % Raw Trunk Values (Accel, Velocity, Orientation)
            session.run(r).rawStepTrunkAccel{1,k} = session.run(r).data.imu.locations.sternum.a(:,session.run(r).footContact(k).index:session.run(r).footContact(k).stepEndIndex);
            session.run(r).rawStepTrunkVelo{1,k} = session.run(r).data.imu.locations.sternum.w(:,session.run(r).footContact(k).index:session.run(r).footContact(k).stepEndIndex);
            session.run(r).rawStepTrunkOrient{1,k} = session.run(r).data.imu.locations.sternum.q(:,session.run(r).footContact(k).index:session.run(r).footContact(k).stepEndIndex);

        
        % if valid stride
        if session.run(r).footContact(k).validStride
            
            % spatiotemporals
            session.run(r).footContact(k).strideTime = (session.run(r).footContact(k).strideEndIndex - session.run(r).footContact(k).index) / fs;
            session.run(r).footContact(k).strideFrequency = 1 / session.run(r).footContact(k).strideTime;
            
        end
        
        % shank impact acceleration is the peak near the foot contact.
        % estimate here is based on max resultant acceleration within the 
        % window centered at the estimated foot contact where the window
        % length is specified in seconds by peakShankAccelWindow_s set in
        % the project initialization function
        shank = 'Rshank';
        if session.run(r).footContact(k).side(1) == 'l'; shank = 'Lshank'; end
        session.run(r).footContact(k).shankImpactAcceleration = ...
            max(vecnorm(session.run(r).data.imu.locations.(shank).a(:,session.run(r).footContact(k).index - halfwindow:session.run(r).footContact(k).index + halfwindow)));
        
    end
    
    % -----------------batch analysis--------------------
    
    % for each metric
    for m = 1:length(metrics)
        
        % get distribution
        dist = [session.run(r).footContact.(metrics{m})];
       %{ 
        if isequal(session.run(r).footContact.side,'right')
            distR = [session.run(r).footContact.(metrics{m})];
        end
        
        if isequal(session.run(r).footContact.side,'left')
            distL = [session.run(r).footContact.(metrics{m})];
        end
        %}
        % for each aggregation method
        for a = 1:length(aggName)
            
            % characterize
            %session.run(r).batchAnalysis.(metrics{m}).left.(aggName{a}) = feval(aggFxn{a},distL);
            %session.run(r).batchAnalysis.(metrics{m}).right.(aggName{a}) = feval(aggFxn{a},distR);
            session.run(r).batchAnalysis.(metrics{m}).(aggName{a}) = feval(aggFxn{a},dist);
        end
        
    end
    
end

%% SAVE
qsave = questdlg('Save analysis results?','Save','Yes','No','Yes');
if ~isempty(qsave)
    
    if qsave(1) == 'Y'
        %for j = 1:length(run)
        outputname = inputdlg('Save As:','Save As',[1 100],{['analysis_' replace(date,'-','') '_' session.run(r).h5name(1:end-3) '.mat']});
        save(fullfile(session.apdm.datapath,outputname{1}),'session');
        %end
    end
    
end

end
