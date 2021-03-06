%% ====================================================
% file name:    GetSurfNorm.m
% author:       Xihan Ma
% description:  solve for surface normal using ch101 sensor readings
% input:        sensor distances (1x4 vector)
% output:       surface normal w.r.t eef frame (1x3 vector)
% =====================================================
function [norm] = GetSurfNorm(dist,R,L)
% params
if nargin < 2
    R = 58;         % [mm] sensor ring array radius
    L = 125;        % [mm] offset between sensor & probe tip
elseif nargin < 3
    L = 125;
end

Pt = [0,0,0];   % [mm] probe tip w.r.t eef frame

if length(dist) ~= 4
    norm = nan(1,3); disp('not enough valid sensor distance')
    return 
end

if ~isnan(dist(1))
    P0 = [0, -R, -L + dist(1)]; % [mm] port0 w.r.t eef frame
else
    P0 = nan(1,3);
end
if ~isnan(dist(2))
    P1 = [-R, 0, -L + dist(2)]; % [mm] port1 w.r.t eef frame
else
    P1 = nan(1,3);
end
if ~isnan(dist(3))
    P2 = [0, R, -L + dist(3)];  % [mm] port2 w.r.t eef frame
else
    P2 = nan(1,3);
end
if ~isnan(dist(4))
    P3 = [R, 0, -L + dist(4)];  % [mm] port3 w.r.t eef frame
else
    P3 = nan(1,3);
end

norm01 = cross(P0-Pt,P1-Pt);
if isnan(norm01)
    norm01 = [0,0,0];
end
norm12 = cross(P1-Pt,P2-Pt);
if isnan(norm12)
    norm12 = [0,0,0];
end
norm23 = cross(P2-Pt,P3-Pt);
if isnan(norm23)
    norm23 = [0,0,0];
end
norm30 = cross(P3-Pt,P0-Pt);
if isnan(norm30)
    norm30 = [0,0,0];
end

norm = norm01 + norm12 + norm23 + norm30;
norm = normalize(norm,'norm');
