function [timecourse] = heating_eval_fixedrate(parameters,timestep,on_wells)

%% assign parameters

hp = parameters(1); %passive movement of heat between non heated wells
ht = parameters(2); %diffusion up from a heated well
hb = parameters(3); %diffusion down from a heated well
hl = parameters(4); %diffusion left from a heated well
hr = parameters(5); %diffusion right from a heated well
he = parameters(6); %diffusion out from edge of plate
loss = parameters(7); %loss from every well
hd = 0; %no diagonal transfer
heat_rate = parameters(8); %fixed rate of heating
sz = size(on_wells);
%% prepare lut of parameters, upsample 'on_wells' and prepare to run sim

%prepare generic convolution lookup table
h_well_lut = [hd , hd , ht , hd , hd;
              hd , hd , ht , hd , hd ;
              hl , hl , 0 , hr , hr ;
              hd ,hd , hb , hd , hd ;
              hd ,hd , hb , hd , hd];

conv_internal = [hd, hp, hd;
                    hp,0,hp;
                    hd,hp,hd];
con_lut0 = repmat(conv_internal,[8,12]);
%top + bottom
top = he*repmat([0,1,0],[1,12]);
con_lut0(1,:) = top;
con_lut0(24,:) = top;

%left + right
left = he*repmat([0;1;0],[8,1]);
con_lut0(:,1) = left;
con_lut0(:,36) = left;

%generating lookup table
con_lut_all = repmat(con_lut0,[1,1,sz(3)]);

for i = 2:sz(3)
        con_lut = con_lut0;

        on_wells_c = on_wells(:,:,i);
        [h_r,h_c,~] = find(on_wells_c>0);
        n_h_wells = numel(h_r);

         for w = 1:n_h_wells

             row = h_r(w);
             col = h_c(w);

             %check if heated well is at the edge
             if row == 1 && col == 1
                 con_lut(2:4,2:4) = h_well_lut(3:5,3:5);
             elseif row == 1 && col == 12
                 con_lut(2:4,33:35) = h_well_lut(3:5,1:3);
             elseif row == 8 && col == 1
                 con_lut(21:23,2:4) = h_well_lut(1:3,3:5);
             elseif row == 8 && col ==12 
                 con_lut(21:23,33:35) = h_well_lut(1:3,1:3);
             elseif row == 1
                    col_min = col*3 - 3;
                    col_max = col*3 + 1;
                    con_lut(2:4,col_min:col_max) = h_well_lut(3:5,1:5);
             elseif row == 8
                    col_min = col*3 - 3;
                    col_max = col*3 + 1;
                    con_lut(21:23,col_min:col_max) = h_well_lut(1:3,1:5);
             elseif col == 1
                 row_min = row*3 - 3;
                 row_max = row*3 + 1; 
                 con_lut(row_min:row_max,2:4) = h_well_lut(1:5,3:5);
             elseif col == 12
                 row_min = row*3 - 3;
                 row_max = row*3 + 1; 
                 con_lut(row_min:row_max,33:35) = h_well_lut(1:5,1:3);
             else %assign whole h_well_lut
                 col_min = col*3 - 3;
                 col_max = col*3 + 1;
                 row_min = row*3 - 3;
                 row_max = row*3 + 1; 
                 con_lut(row_min:row_max,col_min:col_max) = h_well_lut;
             end
         end

    %loop over all wells to assign middle values
    for r = 1:8
        for c = 1:12

            conv = con_lut(r*3-2:r*3,c*3-2:c*3);
            middle = -1*sum(conv,'all');
            conv(2,2) = middle;
            con_lut(r*3-2:r*3,c*3-2:c*3) = conv; 

        end
    end
con_lut_all(:,:,i) = con_lut;
end

    %upsampling onwells and lookup table
    total_time = ceil((sz(3)-1)*timestep); %note that total time is both the time in seconds and the number of frames we'll get
    on_wells_1s = zeros(sz(1),sz(2),total_time);
    con_lut_1s = zeros(24,36,total_time);
    
    for i = 1:sz(3)-1
        step_range = (round((i-1)*timestep)+1):(round(i*timestep));
        on_wells_1s(:,:,step_range) = repmat(on_wells(:,:,i+1),[1,1,numel(step_range)]);
        con_lut_1s(:,:,step_range) = repmat(con_lut_all(:,:,i+1),[1,1,numel(step_range)]);
    end

%preallocate
timecourse_1s = zeros(8,12,total_time);
%% run simulation

    for i = 2:total_time
        
        pad =  padarray(timecourse_1s(:,:,i-1),[1,1],0,'both');
        dtdt = zeros(8,12);
        con_lut_i = con_lut_1s(:,:,i);
        
            %loop over all the wells
            for r = 1:8
                for c = 1:12

                    conv = con_lut_i(r*3-2:r*3,c*3-2:c*3);
                    neighbors = pad(r:r+2,c:c+2);
                    dtdt(r,c) = sum(conv.*neighbors,'all')-loss*(neighbors(2,2));
                    

                end
            end
            
        timecourse_1s(:,:,i) = timecourse_1s(:,:,i-1)+dtdt; %NOT multiplying by timestep because it's one second
        
        %heat up heated wells
        on_wells_c = on_wells_1s(:,:,i);
        [h_r,h_c,~] = find(on_wells_c>0);
        
        for hw = 1:length(h_r)
            
            cd = on_wells_c(h_r(hw),h_c(hw)) - timecourse_1s(h_r(hw),h_c(hw),i-1);%current difference from set-point

            if cd > 0 %temp below setpoint
               
                timecourse_1s(h_r(hw),h_c(hw),i) = timecourse_1s(h_r(hw),h_c(hw),i)+heat_rate;
            end
            
        end
        
    end
%% downsample 'timecourse_1s' to match initial desired output

timecourse = zeros(sz);

for i = 1:sz(3)-1
    step_sample = (round((i-1)*timestep)+1);
    timecourse(:,:,i) = timecourse_1s(:,:,step_sample);
end

timecourse(:,:,sz(3)) = timecourse_1s(:,:,total_time);
