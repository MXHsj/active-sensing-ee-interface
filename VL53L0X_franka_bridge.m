%% read VL53L0X sensor values from serial input, publish to ROS topic
clc; clear; close all

%% ----------------- ROS network -----------------
rosshutdown
% [~, local_ip] = system('ipconfig');
setenv('ROS_MASTER_URI','http://130.215.14.145:11311') % ip of robot desktop
setenv('ROS_IP','130.215.192.168')   % ip of this machine
rosinit
% define publisher
VL53L0X_dist_pub = rospublisher('VL53L0X/distance', 'std_msgs/Float64MultiArray');
VL53L0X_norm_pub = rospublisher('VL53L0X/normal', 'std_msgs/Float64MultiArray');
VL53L0X_dist_msg = rosmessage(VL53L0X_dist_pub);
VL53L0X_norm_msg = rosmessage(VL53L0X_norm_pub);
VL53L0X_dist_msg.Data = [nan, nan, nan, nan];
VL53L0X_norm_msg.Data = [nan, nan, nan];

%% 
port = 'COM9';
IDs = [1 2 3 4];
if exist('sensors','var')
    clear sensors
end
sensors = serialport(port,9600,'DataBits',8,'Parity','none','StopBits',1);
load('data/sensor_mean.mat');

port_flag = zeros(1,length(IDs),'logical');
dist = zeros(1,length(IDs));

en_buffer = false;
buffer_size = 15; dist_buffer = [];
freq = 30;
rate = rateControl(freq);

while 1
%     tic
    latest = char(readline(sensors));
    % check sensor ID
    for i = 1:length(IDs)
        port_flag(i) = contains(latest,[num2str(IDs(i)),':']);
    end
    % extract distance
    range_ind = strfind(latest, 'Range: ');
    if ~isempty(range_ind)
        dist(port_flag) = str2double(latest(range_ind+length('Range: '):range_ind+length('Range: ')+2));
    else
        dist(port_flag) = nan;
    end
    
    % filtering
    if en_buffer
        dist_buffer = [dist_buffer; dist];
        if length(dist_buffer) > buffer_size
            dist_buffer(1,:) = [];
        end
        dist_filtered = FilterRawDist(dist_buffer);
    else
        dist_filtered = dist;
    end
    
    % ========== compensate for inividual sensors ==========
%     dist_filtered(1) = dist_filtered(1) - 20;
%     dist_filtered(2) += dist_filtered(2) - 15;
%     dist_filtered(3) = dist_filtered(3) - 5;
%     dist_filtered(4) = dist_filtered(4) + 5;
    correct(:,1) = CompSensorErr(dist_filtered,sensor_mean);
    dist_filtered=correct;
    % ======================================================
    
    % get surface normal
    norm = GetSurfNorm(dist_filtered); % amplify magnitude  
%     tilt = max(min(dot([0,0,-1],norm)/(1*vecnorm(norm)),1),-1);
    % vis
    fprintf('sensor1: %f[mm]\tsensor2: %f[mm]\tsensor3: %f[mm]\tsensor4: %f[mm]\n', ...
            dist_filtered(1),dist_filtered(2),dist_filtered(3),dist_filtered(4))
    % publish message
    VL53L0X_dist_msg.Data = dist_filtered;
    VL53L0X_norm_msg.Data = norm;
    send(VL53L0X_dist_pub, VL53L0X_dist_msg);
    send(VL53L0X_norm_pub, VL53L0X_norm_msg);
    waitfor(rate);
%     toc;
end
