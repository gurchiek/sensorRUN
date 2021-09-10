%% RemoteBMX
%{
  Reed Gurchiek, 2019
   
    -RemoteBMX is a pipeline for biomechanical analysis of human movement
    in remote environments (i.e. daily life)

    -citation: Gurchiek et al., 2019, Sci Rep, 9(1)

    -see README for more information

%}

%% INITIALIZATION

session = rbmx_ProjectInitialization();

%% ACTIVITY IDENTIFICATION

session = session.activityIdentification.function(session);

%% EVENT DETECTION

session = session.eventDetection.function(session);

%% ANALYSIS

session = session.analysis.function(session);
