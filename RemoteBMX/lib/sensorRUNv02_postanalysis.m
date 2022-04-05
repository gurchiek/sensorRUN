% sensorRUNv02_postanalysis.m
%
% J. Zendler, 2021
% 
% Post-analysis of output of sensorRUNv02 project.  User can select 
%   post-analysis pipeline from menu. Menu will autopopulate
%   with all functions placed in "sensorRUNv02_postanalysis" directory within
%   the SensorRUN main folder. 
%
% Function will loop so that user can select multiple analysis options. 
%
%----------------------------------INPUTS----------------------------------
%
%  "session" output from sensorRUN loaded in current workspace, or 
%   .mat file containing analysis results from sensorRUN.m
%
%---------------------------------OUTPUTS----------------------------------
%
%   Depends on post analysis function selected. See function for details.
%
%% sensorRUNv02_postanalysis

% Select dataset for post-analysis
viz = questdlg('Use current workspace "session" or import previous analysis .mat file?','Data to Analyze','Use Workspace Session','Import Session from .mat','Use Workspace Session');

if ~isempty(viz)
    if viz(1) == 'I'
        % get session to import
        ok = questdlg('Select the analysis*.mat file to import','Select Analysis','OK','OK');
        if ~isempty(ok)
            % load
            [file,path] = uigetfile();  
            load(fullfile(path,file));         
        end
    end
end
    
%% Select post-analysis pipeline
%
% get analysis options
rbmxpath = replace(which('RemoteBMX.m'),'RemoteBMX.m',''); 

% post-analysis folder located at same level as RemoteBMX directory
cd(rbmxpath)
cd ..
postpath = 'postanalysis'; 
cd(postpath)
post = dir('*.m');
postlist = cell(1,length(post));
for p = 1:length(postlist)
    postlist{p} = post(p).name;
end

% Loop until cancel
while 1
ipost = listdlg('ListString',postlist,'SelectionMode','Single','PromptString','Select Post Analysis Pipeline');
postanalysis = postlist{ipost};
feval(postanalysis(1:end-2),session);
   
% continue?
    cont = questdlg('Additional analyses?','Additional Analysis','Yes','No','No');
    if isempty(cont)
        break
    elseif cont(1) == 'N'
        break
    end
    
end

