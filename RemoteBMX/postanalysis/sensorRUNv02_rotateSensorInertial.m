function [ session ] = sensorRUNv02_rotateSensorInertial(session)
%Jess Zendler, 2021
%
%-----------------------------DESCRIPTION----------------------------------
%
% Rotate APDM sensor data into inertial (world) frame after processing with
% sensorRUNv02 or similar project.
%
% User is prompted to select the sensor locations for which data should be rotated.
% Raw acceleration (run.data.imu.locations.(location_name).a) and angular
% velocity (...(location_name).w) will be rotated for the selected sensors
% for all running bouts and stored as new fields.
%
%----------------------------------INPUTS----------------------------------
%
%   session:
%       struct, RemoteBMX session struct following completion sensorRUNv02
%       analysis pipeline
%
%---------------------------------OUTPUTS----------------------------------
%
%   session:
%       RemoteBMX session struct with updated fields
%       New fields:
%           - run.data.imu.locations.(location_name).a_inertial, .w_inertial: 
%                   linear acceleration and angular velocity rotated
%                   into the inertial (world) frame  for selected sensors
%
%---------------------------REVISION HISTORY-------------------------------
%
%%--------------------------------------------------------------------------
%% sensorRUNv02_rotateSensorInertial

% unpack
run = session.run;
sensorLocations = session.apdm.sensorLocations;

%% Rotate sensor data

% select sensors of interest
isensor = listdlg('ListString',sensorLocations,'SelectionMode','multiple','PromptString','Select sensors to rotate');
n_rotSensors = length(isensor);
rotSensors = cell(1,n_rotSensors);
for i = 1: n_rotSensors
    rotSensors{i} = sensorLocations{isensor(i)};
end

% for each sensor
for s = 1:n_rotSensors
    
    sensorName = rotSensors{s};
    
    %for each bout
    for r = 1:length(run)
        
        a_sensor = run(r).data.imu.locations.(sensorName).a; % acceleration in sensor frame
        w_sensor = run(r).data.imu.locations.(sensorName).w; % angular velocity in sensor frame
        q = run(r).data.imu.locations.(sensorName).q;% quaternion
        
        [a_inertial, w_inertial] = inertial_frame_simple(a_sensor',w_sensor',q');
        
        run(r).data.imu.locations.(sensorName).a_inertial = a_inertial'; % acceleration in inertial frame
        run(r).data.imu.locations.(sensorName).w_inertial = w_inertial'; % ang velocity in inertial frame
    end
end

%% pack up

session.run = run;

%% subfunctions

    function [a_inertial, w_inertial] = inertial_frame_simple(a,w,q)
        %
        % Rotate APDM sensor data into inertial (world) frame
        %
        % Function, subfunctions, and comments from DTPitchProcessing.m by Stephen Cain
        % Assembled by Jess Zendler 2021
        %%
        % This function resolves the measured raw acceleration and angular
        % velocities in an inertial (world) frame.
        % a, w, q, and time are direct from the sensor raw data, where a is the
        % measured acceleration, w is the measured angular velocity, and q is the
        % orientation of the sensor in quaternion form.
        
        a_inertial = quaternRot(q,a); % acceleration in world fixed frame
        w_inertial = quaternRot(q,w); % angular velocity in world fixed frame
        
        function xp = quaternRot(q,x)
            %Function to apply quaternion rotation
            
            %Inputs:
            %1. q - quaternion (nx4) defining rotation to be applied
            %2. x - 3-element vector (nx3) to be transformed by quaternion
            
            %Outputs:
            %1. xp - transformed vector (nx3)
            
            %Pad x with column of zeros (quaternion format)
            x = [zeros(size(x,1),1), x];
            
            %Account for case where x=(1x3), q=(nx4)
            if size(x,1)==1 && size(q,1)~=1
                x = ones(size(q,1),1) * x;
            end
            
            %Apply rotation
            xt = quaternProd(q, quaternProd(x, quaternConj(q)));
            
            %Extract rotated vector
            xp = xt(:,2:4);
        end
        
        function ab = quaternProd(a,b)
            %Function to take quaternion product of a x b
            
            %Inputs:
            %1. a - first quaternion (nx4)
            %2. b - second quaternion (nx4)
            
            %Outputs:
            %1. ab - quanternion product of a x b (nx4)
            
            ab(:,1) = a(:,1).*b(:,1) - a(:,2).*b(:,2)-a(:,3).*b(:,3)-a(:,4).*b(:,4);
            ab(:,2) = a(:,1).*b(:,2) + a(:,2).*b(:,1)+a(:,3).*b(:,4)-a(:,4).*b(:,3);
            ab(:,3) = a(:,1).*b(:,3) - a(:,2).*b(:,4)+a(:,3).*b(:,1)+a(:,4).*b(:,2);
            ab(:,4) = a(:,1).*b(:,4) + a(:,2).*b(:,3)-a(:,3).*b(:,2)+a(:,4).*b(:,1);
            
        end
        
        function qConj = quaternConj(q)
            %Function to calculate conjugate of quaternion
            
            %Inputs:
            %1. q - input quaternion (nx4)
            
            %Outputs:
            %1. qConj - quaternion conjugate of q
            
            qConj = [q(:,1) -q(:,2) -q(:,3) -q(:,4)];
        end
        
    end

end