function [ out ] = cv(dist)
%Jess Zendler, 2021
%   cv calculates the coefficient of variation from an n x 1 array of
%   values dist as mean(dist) / std(dist).
%
%---------------------------INPUTS-----------------------------------------
%
%   dist:
%       n x 1 array on which to compute coefficient of variation
%
%--------------------------OUTPUTS-----------------------------------------
%
%   out:
%       scalar, coefficient of variation of dist
%
%%--------------------------------------------------------------------------
%% cv
%
x = mean(dist);
y = std(dist);
out = y/x;

end