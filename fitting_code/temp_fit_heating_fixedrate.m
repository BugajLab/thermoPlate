function [parameters,w_error] = temp_fit_heating_fixedrate(data,timestep,on_wells,intial_condtions)

%% Normalize data
sz = size(data);

%% Generate weights

% % weight = zeros(8,12,sz(3));
% % weight = zeros(8,12);
% % for i = 2:sz(3)
% %     for r = 1:8
% %         for c = 1:12
% %             %find nearest heated well and calculate distance
% %              on_wells_c = on_wells(:,:,i);
% %              on_wells_c = on_wells(:,:,1);
% %              [h_r,h_c,~] = find(on_wells_c>0);
% %              n_h_wells = numel(h_r);
% %              dis = zeros(n_h_wells,1);
% % 
% %                 for w = 1:n_h_wells
% % 
% %                      heat_row = h_r(w);
% %                      heat_col = h_c(w);
% %                      dis(w) = ((r-heat_row)^2 + (c-heat_col)^2)^(1/2);
% % 
% %                 end
% %              min_dis = min(dis);
% %          if isempty(min_dis) == 0
% %              if min_dis<2.9
% %                  weight(r,c,i) = sqrt(min_dis);
% % weight(r,c) = sqrt(min_dis);
% %              elseif r == 1 || r == 8 || c == 1 || c ==12
% %                  weight(r,c,i) = sqrt(min_dis);
% % weight(r,c) = sqrt(min_dis);
% %              else
% %                  weight(r,c,i) = min_dis;
% % weight(r,c) = min_dis;
% %              end
% %          elseif isempty(min_dis) == 1
% %              weight(r,c,i) = 1;
% % weight(r,c) = 1;
% %          end
% %         end
% %     end 
% % end
% % weight(on_wells(:,:,1)>0) = 1;
% % weight = weight.^-1;
% % weight = repmat(weight,[1,1,sz(3)]);
% % weight(:,:,1) = zeros(8,12);

% weight(:,:,2:sz(3)) = (weight(:,:,2:sz(3)).^-1);
% weight = ones(8,12,sz(3));
% weight(on_wells>0) = 0;

weight = ones(8,12,sz(3));
%weight(on_wells>0) = 0;

%% Minimize error between sim and data

error = @(p)mean2(weight.*((heating_eval_fixedrate(p,timestep,on_wells)-data).^2)); 
[parameters,w_error]=fminsearch(error,intial_condtions);

