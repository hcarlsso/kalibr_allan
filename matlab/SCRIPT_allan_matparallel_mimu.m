%% Initalization
close all
clear all
%%
% Read in our toolboxes
addpath('functions/allan_v3')

% Our bag information
%mat_path = '../data/imu_mtig700.mat';
%mat_path = '../data/imu_tango.mat';
% mat_path = '../data/imu_visensor.mat';
mat_path = '../data/MPU-9150/data_processed.mat';

% IMU information (todo: move this to the yaml file)
%update_rate = 400;
%update_rate = 100;
update_rate = 1000; % hz


%% Data processing
% Load the mat file (should load "data_imu" matrix)
fprintf('opening the mat file.\n')
load(mat_path);


%% Process the timeseries data

% Find the frequency of the imu unit
% delta = mean(diff(ts_imua.Time(1:10)));
% update_rate = 1/delta;
delta = 1/update_rate;
fprintf('imu frequency of %.2f.\n',update_rate);
fprintf('sample period of %.5f.\n',delta);

% Calculate our tau range (max is half of the total measurements)
% taumax = floor((length(ts_imua.Time)-1)/2);
% tau = delta*logspace(log10(delta),log10(taumax),200);
%tau = delta*linspace(1,taumax,1000);
% b = 2; % base octave
% b = 1.5; % base  half octave 
b = 1.25; % base  quater octave
m_max = 1e3/delta % 60 sec
m = unique(floor(b .^(0:floor(mylog(b, m_max)))))
tau = delta*m
taumax = max(tau);
% taumax will determine the number of measurements 

N_tot = size(inertial_data_double_rot,2)
N = m(end)*10
% N = N_tot;
N_hours = N_tot/update_rate/3600
N_hours = N/update_rate/3600
slice = (1:N) + 140000 + 2.5e6;

%%

fprintf('Slice data.\n')
time_data = time_stamp_corr(slice);
inertial_data = inertial_data_double_rot(:,slice);

fprintf('loaded %.e time samples.\n', N)
%%

semilogy(diff(time_data));
grid on

%% 
% Load our time series information
% Detrend the measurements
fprintf('loading timeseries.\n')
inds = reshape(1:size(inertial_data,1),6,[]);
inds_a = reshape(inds(1:3,:),[],1);
inds_w = reshape(inds(4:6,:),[],1);
ts_imu = timeseries(detrend(inertial_data'),time_data');



%% Calculate the acceleration allan deviation of the time series data!
N_jobs = size(inertial_data,1);
data = cell(N_jobs,1);
for n = 1:N_jobs
    data{n}.rate = update_rate;
    data{n}.freq = ts_imu.data(:,n)';
end


fprintf('calculating allan deviation.\n');
tic;
cluster = parcluster();
jobs = cell(N_jobs,1);
disp("submit jobs")
for n = 1:N_jobs
    jobs{n} = batch(cluster,@allan,1,{data{n},tau});
end

% Wait for the jobs to finish
disp("wait")
for n = 1:N_jobs
    wait(jobs{n})
end

disp("get results")
% Get results into a cell array
res = cell(N_jobs,1);
for n = 1:N_jobs
     temp = fetchOutputs(jobs{n});
     res{n} = temp{1};
end

% Finally cleanup
disp("Clean up")
for n = 1:N_jobs    
    delete(jobs{n})
end
toc

%% Save workspace
filename = ['results_',datestr(now,30),'.mat'];
fprintf('saving to: %s\n',filename);
save(['../data/MPU-9150/',filename],'update_rate','tau','taumax','res')
fprintf('done saving!\n');




