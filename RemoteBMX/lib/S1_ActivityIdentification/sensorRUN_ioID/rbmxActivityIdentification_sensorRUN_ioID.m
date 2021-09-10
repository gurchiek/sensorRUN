function [ session ] = rbmxActivityIdentification_sensorRUN_ioID(session)
%Reed Gurchiek, 2019
%   read imu data during running activity. Subject folders should have only
%   two .h5 files corresponding the apdm imu data during the Indoor and
%   Outdoor trials. The filename for the indoor running trial should have
%   Indoor in the name and the filename for the outdoor running trial
%   should have Outdoor in the name
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct
%       new fields:
%           -session.run: 1xn struct, contains information for n running
%           bouts
%
%--------------------------------------------------------------------------
%% rbmxActivityIdentification_sensorRUN_ioID

% get indoor .h5 file to analyze
path = session.apdm.datapath;
filename = dir(fullfile(path,'*Indoor*.h5'));
filename = filename.name;
session.run(1).type = 'indoor';
session.run(1).filename = fullfile(path,filename);
session.run(1).h5name = filename;
%}
% get outdoor .h5 file to analyze
path = session.apdm.datapath;
filename = dir(fullfile(path,'*Outdoor*.h5'));
filename = filename.name;
session.run(2).type = 'outdoor';
session.run(2).filename = fullfile(path,filename);
session.run(2).h5name = filename;
%}
%% IMPORT

session = sensorRUNio_importAPDM(session);

end