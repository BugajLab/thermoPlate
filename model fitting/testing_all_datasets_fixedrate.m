%% SETUP

%clear 
clc; clear all;

%preallocate letters
letters = cell(8,1);
letters{1} = 'A';
letters{2} = 'B';
letters{3} = 'C';
letters{4} = 'D';
letters{5} = 'E';
letters{6} = 'F';
letters{7} = 'G';
letters{8} = 'H';

%set number of timepoints to fit on
T = 250; 
time_step = 22.37485;

%preallocate space for data
timecourses = cell(8,1);

%make 'on wells' for each timecourse (units degrees C above ambient)
on_wells = cell(8,1);
zee = zeros(8,12,T);
sz = size(zee);
owa = zee;
owa(4,3,1:162) = 10; 
owa(1,7,1:162) = 10;
owa(7,7,1:162) = 10;
owa(4,11,1:162) = 10; 
owb = zee; 
owb(4,4,1:162) = 15;
owb(5,11,1:162) = 10;
owc = zee;
owc(4,6,1:162) = 15; 
owd = zee;
owd(7,7,1:162) = 15;
owe = zee; 
owe(2,3,1:162) = 15;
owe(7,2,1:162) = 10;
owe(5,9,1:162) = 10;
owe(6,9,1:162) = 10;
owe(6,10,1:162) = 10;
owf = zee;
owf(4,4,1:162) = 10;
owf(4,5,1:162) = 10;
owf(5,4,1:162) = 10;
owf(5,5,1:162) = 10;
owg = zee;
owg(1,6,1:162) = 15;
owg(2,10,1:162) = 15;
owg(3,2,1:162) = 10;
owg(6,2,1:162) = 10;
owg(4,4,1:82) = 10;
owg(6,8,1:162) = 10;
owg(7,7,1:162) = 10;
owg(2,1,56:162) = 10;
owg(8,12,56:162) = 10;
owg(8,4,1:162) = 10;
owg(5,12,1:162) = 10;
owg = owg(:,:,1:163);
owh = zee;
owh(2,3,1:162) = 10;
owh(2,4,1:162) = 10;
owh(3,3,1:162) = 10;
owh(3,4,1:162) = 10;
owh(7,6,1:162) = 10;
owh(7,7,1:162) = 10;
owh(4,10,1:162) = 15;
owh(2,8,1:108) = 10;
owh(7,11,1:81) = 10;
owh(7,2,56:204) = 10;
owh = owh(:,:,1:204);

on_wells{1} = owa;
on_wells{2} = owb;
on_wells{3} = owc;
on_wells{4} = owd;
on_wells{5} = owe;
on_wells{6} = owf;
on_wells{7} = owg;
on_wells{8} = owh;

%initial conditions
initial_conditions = zeros(8,1);
initial_conditions(1) = 0.007; %passive movement of heat between non heated wells
initial_conditions(2) = 0.01; %diffusion up from a heated well
initial_conditions(3) = 0.006; %diffusion down from a heated well
initial_conditions(4) = 0.008; %diffusion left from a heated well
initial_conditions(5) = 0.003; %diffusion right from a heated well
initial_conditions(6) = 0.0018; %diffusion out from edge of plate
initial_conditions(7) = 0.0005; %loss from every well
initial_conditions(8) = 0.22; %fixed rate of heating

%preallocate space for parameters from fits
parameters = zeros(8,8);

%% FITTING DATA

for i = 1:length(letters)
    tic
    %load timecourse
    letter_i = letters{i};
    data = load(['timecourse_' letter_i '.mat']);
    data_i = data.data;
    data_i = data_i(:,:,1:min(T,length(data_i)));
    
    %subtract first frame to normalize to ambient
    ff = data_i(:,:,1);
    ff_rep = repmat(ff,[1,1,250]);
    data_i = data_i-ff_rep;
    
    timecourses{i} = data_i;
    ow_i = on_wells{i};
    
    %fit
    [parameters_i,~] = temp_fit_heating_fixedrate(data_i,time_step,ow_i,initial_conditions);
    parameters(:,i) = parameters_i; 
    
    disp([letter_i ' fit'])
    toc
end

%% DISPLAYING FITS

for i = 1:8
    
    parameters_i = parameters(:,i); %use to show parameters from data
    %parameters_i = mean(parameters,2); %use to show mean parameters
    ow_i = on_wells{i};
    data_i = timecourses{i};
    timecourse = heating_eval_fixedrate(parameters_i,time_step,ow_i);
    diff = timecourse(:,:,2:end)-data_i(:,:,2:end);
    diff_v = diff(:);
    sz_diff = size(diff);
    lims = [0,15];
    
    figure
    for t = 2:5:(sz_diff(3)+1)
    
    subplot(1,3,1)
    imagesc(data_i(:,:,t),lims)
    axis equal
    title(['data' num2str(t)])
    colorbar
    
    subplot(1,3,2)
    imagesc(timecourse(:,:,t),lims)
    axis equal
    title('simulated')
    colorbar
    
    subplot(1,3,3)
    imagesc(diff(:,:,t-1),[-1,1])
    axis equal
    title('difference')
    colorbar
    
    pause(0.05)
    end
    
    figure
    for r = 1:8
        for c = 1:12

    plot(reshape(diff(r,c,:),[sz_diff(3),1]))
    hold on
        end
    end


end

%% simulating with parameters from other sets
sims = cell(10,8);
diffs = cell(10,8);
mean_errors = zeros(10,8);
u1 = zeros(10,8);
u5 = zeros(10,8);

%reorganizing in order of complexity
comp = [3,4,2,6,1,5,7,8,9,10];

for i_ind = 1:10
    i = comp(i_ind);
    
    %grab parameters

    if i == 10
        parameters_i = mean(parameters,2); %simulate with average parameters
    elseif i ~= 9
        parameters_i = parameters(:,i);
    end
    
    for j_ind = 1:8
        
        j = comp(j_ind);
            if i == 9 %leave out the parameters from this dataset in the average
                parameters_i = parameters;
                parameters_i(:,j) = [];
                parameters_i = mean(parameters_i,2);
            end
    
    %Load data and simulate
    ow_j = on_wells{j};
    data_j = timecourses{j};
    timecourse = heating_eval_fixedrate(parameters_i,time_step,ow_j);
    diff = timecourse(:,:,:)-data_j(:,:,:);
    
    %calculate errors
    diff_vals = diff(:,:,2:end);
    diff_vals = diff_vals(:);
    abs_diff = abs(diff_vals);
    abs_diff5 = abs_diff;
    abs_diff5(abs_diff5>0.5) = [];
    abs_diff1 = abs_diff;
    abs_diff1(abs_diff1>1) = [];

    %record
    sims{i_ind,j_ind} = timecourse;
    diffs{i_ind,j_ind} = diff;
    mean_errors(i_ind,j_ind) = mean2(abs_diff);
    u5(i_ind,j_ind) = length(abs_diff5)/length(abs_diff);
    u1(i_ind,j_ind) = length(abs_diff1)/length(abs_diff);
    
    disp([num2str(i) num2str(j) 'into' num2str(i_ind) num2str(j_ind)])
        
    end
end

figure
imagesc(mean_errors,[0.1,0.5])
colorbar
title('Mean Error')
axis equal

figure
imagesc(u5,[0.60,1])
colorbar
title('Fraction under 0.5')
axis equal

figure
imagesc(u1,[0.93,1])
colorbar
title('Fraction under 1')
axis equal

mean(mean_errors,2)
mean(u5,2)
mean(u1,2)

%% Downsample and report

    down_time = 1; %time of downsampling in minutes
    
    down_sims = cell(10,8);
    down_diffs = cell(10,8);
    down_datas = cell(10,8);
    down_on_wells = cell(8,1);
    
    down_ers = zeros(10,8);
    down_u1 = zeros(10,8);
    down_u5 = zeros(10,8);

for i = 1:10 %parameters
      
    for j = 1:8 %datasets
    
    %Load data and simulate
    data_j = timecourses{comp(j)};
    timecourse_ij = sims{i,j};
    diff_ij = diffs{i,j};
    sz_j = size(data_j);
    ow_j = on_wells{comp(j)};
    
    %downsample
    n_frames = floor(((sz_j(3)-1)*time_step)/(down_time*60)); 
    take_frames = zeros(1,n_frames);
    time_up = time_step*[0:sz_j(3)-1];
    time_down = 60*down_time*[0:n_frames-1]; 
    
    for t = 1:n_frames
        
        d = time_down(t); 
        time_diff = abs(time_up-d); 
        [~,mindex] = min(time_diff); 
        take_frames(t) = mindex;
         
    end
    
    diff_ij = diff_ij(:,:,take_frames);
    timecourse_ij = timecourse_ij(:,:,take_frames);
    data_ij = data_j(:,:,take_frames);
    ow_j = ow_j(:,:,take_frames);
    
    %calculate errors
    diff_vals = diff_ij(:,:,2:end);
    diff_vals = diff_vals(:);
    abs_diff = abs(diff_vals);
    abs_diff5 = abs_diff;
    abs_diff5(abs_diff5>0.5) = [];
    abs_diff1 = abs_diff;
    abs_diff1(abs_diff1>1) = [];
    
    down_sims{i,j} = timecourse_ij;
    down_diffs{i,j} = diff_ij;
    down_datas{i,j} = data_ij;
    down_on_wells{j} = ow_j;
    
    down_ers(i,j) = mean2(abs_diff);
    down_u1(i,j) = length(abs_diff1)/length(abs_diff);
    down_u5(i,j) = length(abs_diff5)/length(abs_diff);
    disp([num2str(i) num2str(j)])
        
    end
end

figure
imagesc(down_ers,[0.1,0.5])
colorbar
title('Mean Error')
axis equal

figure
imagesc(down_u5,[0.60,1])
colorbar
title('Fraction under 0.5')
axis equal

figure
imagesc(down_u1,[0.93,1])
colorbar
title('Fraction under 1')
axis equal

mean(down_ers,2)
mean(down_u5,2)
mean(down_u1,2)

%% Display downsampled data

i = 3;
j = 3; 

data_c = down_datas{i,j};
sim_c = down_sims{i,j};
diff_c = down_diffs{i,j};
sz = size(data_c);
ow_c = on_wells{j};
lims = [0,15];
    
    figure
    for t = 1:1:(sz(3))
    
    subplot(1,3,1)
    imagesc(data_c(:,:,t),lims)
    axis equal
    title(['data' num2str(t)])
    colorbar
    
    subplot(1,3,2)
    imagesc(sim_c(:,:,t),lims)
    axis equal
    title('simulated')
    colorbar
    
    subplot(1,3,3)
    imagesc(diff_c(:,:,t),[-1,1])
    axis equal
    title('difference')
    colorbar
    
    pause(0.05)
    end
    
    figure
    for r = 1:8
        for c = 1:12

    plot(reshape(diff_c(r,c,:),[sz(3),1]))
    hold on
        end
    end
    
%pick trace
line1= data_c(4,4,:);
line1 = line1(:);
line2 = sim_c(4,4,:);
line2 = line2(:);
set = ow_c(4,4,:);
set = set(:);
time = time_step*[0:length(set)-1];
plot(line1,'b');hold on; plot(line2,'g','LineWidth',2); hold on; plot(set,'k')

%% Save to table for R

    %we want columns:
    %well
    %time (seconds)
    %data set
    %data set from which the parameters were sourced
    %set temp (zero for non heated well, set point for heated wells)
    %real temp
    %fit temp
    %error
    
    row = [];
    column = [];
    time = [];
    fit_parameters = [];
    data_set = [];
    set_temp = [];
    real_temp = [];
    fit_temp = [];
    error = [];
    
    wells_lut = ['A','B','C','D','E','F','G','H'];
    
for i = 1:10
    for j = 1:8
        
       data_c = down_datas{i,j};
       sim_c = down_sims{i,j};
       diff_c = down_diffs{i,j};
       ow_c = down_on_wells{j}; 
       sz = size(data_c); 
       
       for t = 1:sz(3)
           
           for r = 1:8 %will loop over rows and save 12 at a time
                   
                   %this isn't optimal but whatever
                   row_c = repmat(wells_lut(r),[12,1]);
                   col_c = [1:12]';
                   time_c = down_time*(t-1)*ones(12,1);
                   fit_parameters_c = i*ones(12,1);
                   data_set_c = j*ones(12,1);
                   set_temp_c = ow_c(r,:,t)';
                   real_temp_c = data_c(r,:,t)';
                   fit_temp_c = sim_c(r,:,t)';
                   error_c = diff_c(r,:,t)';
                   
                    row = [row ; row_c];
                    column = [column ; col_c];
                    time = [time ; time_c];
                    fit_parameters = [fit_parameters ; fit_parameters_c];
                    data_set = [data_set ; data_set_c];
                    set_temp = [set_temp ; set_temp_c];
                    real_temp = [real_temp ; real_temp_c];
                    fit_temp = [fit_temp ; fit_temp_c];
                    error = [error ; error_c];
           end
           
       end
        disp([num2str(i),num2str(j)])
    end
end
    
    size(row)
    size(column)
    size(time)
    size(fit_parameters)
    size(data_set)
    size(set_temp)
    size(real_temp)
    size(fit_temp)
    size(error)
   
table_of_you = table(row,column,time,fit_parameters,data_set,set_temp,real_temp,fit_temp,error);
writetable(table_of_you,['thermoplate_fitting.csv'])
    
%% saving stacks to display in imageJ    
    
data = readtable('thermoplate_fitting.csv') ;   


%9 columns are
%row,column,time,fit_parameters,data_set,set_temp,real_temp,fit_temp,error

% idx = Asteroids_data.a >= 0.9 & Asteroids_data.a <= 1.1 & Asteroids_data.e <= 0.3;
% newTbl = Asteroids_data(idx,:);

real = cell(10,8);
on_wells = cell(10,8);
sims = cell(10,8);
error = cell(10,8);

for i = 1:10 %parameter source
    for j = 1:8 %dataset
        
        id_ij = data.fit_parameters == i & data.data_set == j;
        data_ij = data(id_ij,:);
        T = max(data_ij.time);
        
        real_ij = zeros(8,12,T);
        on_wells_ij = zeros(8,12,T);
        sims_ij = zeros(8,12,T);
        error_ij = zeros(8,12,T);
        
        for t = 1:T
            
            id_t = data_ij.time == t;
            data_t = data_ij(id_t,:);
            
            
            real_ij(:,:,t) = reshape(data_t.real_temp,[12,8])';
            on_wells_ij(:,:,t) = reshape(data_t.set_temp,[12,8])';
            sims_ij(:,:,t) = reshape(data_t.fit_temp,[12,8])';
            error_ij(:,:,t) = reshape(data_t.error,[12,8])';
            
            if t == 1
            imwrite(uint8(10*real_ij(:,:,t)),['dataset' num2str(j) '_parameters' num2str(i) '_real_temp' '.tif'])
            imwrite(uint8(10*on_wells_ij(:,:,t)),['dataset' num2str(j) '_parameters' num2str(i) '_set_temp' '.tif'])
            imwrite(uint8(10*sims_ij(:,:,t)),['dataset' num2str(j) '_parameters' num2str(i) '_sim_temp' '.tif'])
            imwrite(uint8(25*error_ij(:,:,t)+125),['dataset' num2str(j) '_parameters' num2str(i) '_error' '.tif'])
            else
            imwrite(uint8(10*real_ij(:,:,t)),['dataset' num2str(j) '_parameters' num2str(i) '_real_temp' '.tif'],'writemode', 'append')
            imwrite(uint8(10*on_wells_ij(:,:,t)),['dataset' num2str(j) '_parameters' num2str(i) '_set_temp' '.tif'],'writemode', 'append')
            imwrite(uint8(10*sims_ij(:,:,t)),['dataset' num2str(j) '_parameters' num2str(i) '_sim_temp' '.tif'],'writemode', 'append')
            imwrite(uint8(25*error_ij(:,:,t)+125),['dataset' num2str(j) '_parameters' num2str(i) '_error' '.tif'],'writemode', 'append')
            end
            
        end
        
        real{i,j} = real_ij;
        on_wells{i,j} = on_wells_ij;
        sims{i,j} = sims_ij;
        error{i,j} = error_ij;
        
        i
        j
    end
end
    
    