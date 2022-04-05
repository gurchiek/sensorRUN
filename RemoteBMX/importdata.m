%% IMPORT APDM DATA

% get .h5 file to analyze
apdmFullfilename = fullfile(apdm.datapath,apdm.filename);

% get info for raw and processed sensor data
info.sensors = h5info(apdmFullfilename,'/Sensors');
info.processed = h5info(apdmFullfilename,'/Processed');

% get annotation data
annot = h5read(apdmFullfilename,'/Annotations');
annot.Annotation = cellstr(annot.Annotation');
apdm.annot = annot;

% initialization of sensor data
n_sensors = length(info.sensors.Groups); % number of sensors
sensorLocations = cell(n_sensors,1); % sensor locations from APDM labels
dataTypes = apdm.dataTypes;
dataAbbreviations = apdm.dataAbbreviations;

% get sensor locations and store
for s = 1:n_sensors
    info.sensors.Groups(s).config = h5info(apdmFullfilename,[info.sensors.Groups(s).Name,'/Configuration']); % get sensor label
    sensorLocations{s} = info.sensors.Groups(s).config.Attributes(1).Value;% store sensor label
end
apdm.sensorLocations{s} = sensorLocations;