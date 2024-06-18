% *****************************************************************************
% *    Title: Decision Making Algorithm and Control Law for Autonomous Vehicle Fleet
% *    Author: Guegan Theo
% *    Tutor: Adouane Lounis
% *    School: Université de Technologie de Compiègne (UTC) - Computer Science
% *    Date: 2024
% *****************************************************************************

classdef vehicle < handle
    % The vehicle object adapts its position and speed to reach targets depending on the environment.

    properties
        %% ------ vehicle parameters ------
        x = 0;
        y = 0;
        theta = 0;
        % angle of the front wheel
        gamma = 0;
        % linear speed
        v = 0; 
        id_vehicle = 0; 
        % distance between front and back wheels
        lbase = 4; 
        
        %% ------ handler for the vehicle environment ------
        targets = [];
        obstacles = [];
        vehicles = []; 

        %% ------ controller parameters ------
        actual_target;
        distance_securite_acc = 5;
        K_x = 0.15;     
        K_d = 10;     
        K_l = 2;     
        K_o = 2;     
        K_theta = 5; 
        K_rt = 0.001;    

        %% ------ plot parameters (only for debug) ------
        L = 2.5;   
        l = 4;  
        r = 1;     
        theta_error_output=[];
        speed_output=[];
        lyap1=[];
        lyap2=[];
        lyap3=[];
        
        %default discretisation time
        dt = 0.1; 

        %Parametres Ordonancement
        id_road;
        dist_from_start;
        nbpassengers;
        plannedDemands;
        actualPath;
        priority;
    end
    
    methods
        function obj = vehicle(x, y, theta, gamma, obstacles, targets, vehicles, id_vehicle, id_road, dist_from_start)
            if nargin == 10
                %decisions-control
                obj.x = x;
                obj.y = y;
                obj.theta = theta;
                obj.gamma = gamma;
                obj.obstacles = obstacles;
                obj.vehicles = vehicles;
                obj.targets = targets;
                
                %ordonancement
                obj.id_vehicle = id_vehicle;
                obj.id_road = id_road;
                obj.dist_from_start = dist_from_start;
                obj.nbpassengers = 0;
                obj.plannedDemands = [];
                obj.actualPath = NaN;
                obj.priority = NaN;
            else
                 error('Incorrect number of arguments for vehicle constructor');
            end
         end
        
        function plot(obj)
                % plot the vehicle pos - used in debug mode
                arguments
                    obj vehicle
                end
                % right back wheel
                xArD = obj.x + obj.l/2*sin(obj.theta); 
                yArD = obj.y - obj.l/2*cos(obj.theta);
                xArDDev = xArD + obj.r*cos(obj.theta);
                yArDDev = yArD + obj.r*sin(obj.theta);
                xArDArr = xArD - obj.r*cos(obj.theta);
                yArDArr = yArD - obj.r*sin(obj.theta);

                % left back wheel
                xArG = obj.x - obj.l/2*sin(obj.theta); 
                yArG = obj.y + obj.l/2*cos(obj.theta);
                xArGDev = xArG + obj.r*cos(obj.theta);
                yArGDev = yArG + obj.r*sin(obj.theta);
                xArGArr = xArG - obj.r*cos(obj.theta);
                yArGArr = yArG - obj.r*sin(obj.theta);
                
                if obj.id_vehicle==1
                    color = "r";
                else
                    color = "b";
                end

                %vehicle lines
                line([xArG xArD],[yArG yArD])
                line([xArGDev xArGArr],[yArGDev yArGArr],'Color',color,'LineWidth',3)
                line([xArDDev xArDArr],[yArDDev yArDArr],'Color',color,'LineWidth',3)
                
                for i=0:0.2:(2*pi)
                    plot(obj.x+(obj.l/2)*cos(i),obj.y+(obj.l/2)*sin(i),'-','LineWidth',3);
                end
        end

        function plot2(obj)
            % simple plot the vehicle pos - used in debug mode
            arguments
                obj vehicle
            end

            if obj.id_vehicle==1
                    color = "r+";
                else
                    color = "b+";
            end
            plot(obj.x, obj.y, color, 'LineWidth', 2);
        end
        
        function update(obj, dt, sched)
            % Update is called every iteration and defines the
            % discretization time for the vehicle.
            % 
            % If the vehicle still has targets to reach, update calls the
            % target selection algorithm, the control law, and finally,
            % adapts the vehicle's position.

            arguments
                obj vehicle
                dt double
                sched %scheduler or NaN
            end

            obj.dt = dt;
            if isempty(obj.targets)
                return;
            end
            
            % update the actual target to reach depending on the env
            obj.target_selection()
            % compute target data and return the controller command
            control = obj.control_law();
            % update the vehicle position
            obj.set_pos(control)

            if ~isnan(sched)
                obj.updatePosition(sched);
            end
        end

        function update_acc_vehicles(obj, vehicles)
            % allow simulator to update the list of vehicles in the
            % simulation
            obj.vehicles = vehicles;
        end

        function update_obstacles_to_avoid(obj, obstacles)
            % allow simulator to update the list of obstacles in the
            % simulation
            obj.obstacles = obstacles;
        end

        %% Ordonancement ----------
        function obj = addDemand(obj,demand)
            obj.plannedDemands = [obj.plannedDemands;demand];
        end


        function obj = addPassenger(obj,nb)
            obj.nbpassengers = obj.nbpassengers + nb;
        end

        function obj = updatePosition(obj,schedul)           
            % gestion des demandes en cours
            for i = 1:length(obj.plannedDemands)
                % vérification du fait que l'on soit au point de départ
                % d'une demande
                pos = get_pos_by_id(schedul.modified_nav,obj.plannedDemands(i).id_dep);
                if obj.plannedDemands(i).visited_dep == false && ...
                    (schedul.modified_nav.States.StateVector(pos,1)-2<obj.y && obj.y<schedul.modified_nav.States.StateVector(pos,1)+2) && ...
                    (schedul.modified_nav.States.StateVector(pos,2)-2<obj.x && obj.x<schedul.modified_nav.States.StateVector(pos,2)+2)
                    disp("Visited");
                    obj.plannedDemands(i).visited_dep = true;
                end
                % vérification si on est au point d'arrivée d'une demande
                % et supression de la demande si on y est
                pos = get_pos_by_id(schedul.modified_nav,obj.plannedDemands(i).id_arr);

                if (schedul.modified_nav.States.StateVector(pos,1)-2<obj.y && obj.y<schedul.modified_nav.States.StateVector(pos,1)+2) && ...
                    (schedul.modified_nav.States.StateVector(pos,2)-2<obj.x && obj.x<schedul.modified_nav.States.StateVector(pos,2)+2) && ...
                    (obj.plannedDemands(i).visited_dep == true)
                    disp("Arrived");
                    disp(obj.plannedDemands(i));
                    obj.addPassenger(obj.plannedDemands(i).nbpassengers *(-1));
                    obj.deleteDemand(obj.plannedDemands(i),schedul);
                    obj.plannedDemands = [obj.plannedDemands(1:i-1);obj.plannedDemands(i+1:end)];
                    if isempty(obj.plannedDemands)
                        obj.plannedDemands = [];
                    end
                    obj.updatePriority();                   
                end
                    
            end
            
        end

        function deleteDemand(obj, demand,schedul)
            id_mother_road_dep = demand.id_mother_road_dep;
            id_mother_road_arr = demand.id_mother_road_arr;

            pos_dep_in_table = find(schedul.tmp_roads.Base_road == id_mother_road_dep);
            id_roads_to_rm = table2array(schedul.tmp_roads(pos_dep_in_table,["First_tmp_road","Second_tmp_road"]));

            pos_arr_in_table = find(schedul.tmp_roads.Base_road == id_mother_road_arr);
            id_roads_to_rm = [id_roads_to_rm, table2array(schedul.tmp_roads(pos_arr_in_table,["First_tmp_road","Second_tmp_road"]))];

            pairs = [];

            for i = 1:length(id_roads_to_rm)
                pos = find(schedul.modified_nav.Links.Id_route == id_roads_to_rm(i));
                pairs = [pairs; schedul.modified_nav.Links(pos,:).EndStates];
            end

            rmlink(schedul.modified_nav,pairs);
            schedul.tmp_roads(pos_dep_in_table,:) = [];
            pos_arr_in_table = find(schedul.tmp_roads.Base_road == id_mother_road_arr);
            schedul.tmp_roads(pos_arr_in_table,:) = [];
            rmstate(schedul.modified_nav,[demand.id_dep;demand.id_arr]);
        end

        function obj = updatePriority(obj)
            obj.priority = -1;
            for i = 1:size(obj.plannedDemands,1)
                if obj.plannedDemands(i).priority > obj.priority
                    obj.priority = obj.plannedDemands(i).priority;
                end
            end
            if obj.priority == -1
                obj.priority = NaN;
            end
        end
        
        function [id] = getIdVehicle(obj)
            id = obj.id_vehicle;
        end
        function [id_road]=getRoad(obj)
            id_road = obj.id_road;
        end
        function [X]=getX(obj)
            X = obj.x;
        end
        function [Y]=getY(obj)
            Y = obj.y;
        end
        function [dist]=getDistFromStart(obj)
            dist = obj.dist_from_start;
        end
        function obj = assignateNewPath(obj,path)
            obj.actualPath = path;
        end 
        function [dist] = getTotalCost(obj,demands,NavG)
            % calcul des coûts de tous les trajets possible entre la
            % position d'un véhicule et toutes les demandes
            if isempty(demands)
                error("Demands tab is empty");
            end

            pos = find(NavG.Links.Id_route == obj.id_road);

            id_dep = NavG.Links.EndStates(pos,2);
            combs = getCombs(id_dep,demands);
            dual_combs = getdualcombs(combs);
            tmp1 = [];
            tmp2 = [];
            for i = 1:size(dual_combs,1)
                [pathOutput,solutionInfo] = GetPath(NavG,get_pos_by_id(NavG,dual_combs(i,1)),get_pos_by_id(NavG,dual_combs(i,2))); 
                tmp1 = [tmp1; Path(pathOutput, solutionInfo.PathCost, NavG, obj.id_vehicle)];
                tmp2 = [tmp2;solutionInfo.PathCost];
            end
            dual_dist = table(dual_combs, tmp1, tmp2,VariableNames=["dual_combs","Path","Path_Cost"]);
            total_cost=[];
            total_path = [];
            for i = 1:size(combs,1) 
                comb = combs(i,:);
                c = [comb(1:length(comb)-1); comb(2:length(comb))]';
                cost = [];
                path = [];
                for j = 1:size(c,1)
                    pair = find(ismember(dual_dist{:, {'dual_combs'}}, [c(j,1), c(j,2)] , 'rows'));
                    cost = [cost;dual_dist(pair,3)];
                    path = [path;dual_dist(pair,2)];
                end
                total_cost = [total_cost;sum(cost)]; 
                total_path = [total_path;assoicatePaths(path,table2array(total_cost),NavG,obj.id_vehicle)];
            end
            dist = table(combs,total_path,total_cost,VariableNames=["Combinaisons","Chemin","Cout_total"]);
        end

        function [res] = getOptimalPath(obj,demands,NavG)
            % Retourne une table contenant le chemin optimal dans lequel a été ajouté le
            % nouveau trajet sous la forme suivante (combinaison des points de passages,
            % Chemin sous forme de Path, cout total)
            if isempty(demands)
                error("Demands tab isf empty");
            end
            
            dist = obj.getTotalCost(demands,NavG);
            [~, id_min] = min(dist.Cout_total); 
            min_row = dist(table2array(id_min), :);
            comb = min_row{1, 'Combinaisons'}; 
            optimal_path = min_row{1, 'Chemin'}; 
            cost_total = table2array(min_row{1, 'Cout_total'}); 
            res = table(comb, optimal_path, cost_total, 'VariableNames', {'Combinaisons', 'Chemin', 'Cout_total'});
        end

        function showCarPath(obj,NavG)
            h = show(NavG);
            set(h,XData=NavG.States.StateVector(:,1), ...
                YData=NavG.States.StateVector(:,2));
            pathStateIDs = [];
            if ~isnan(obj.actualPath)
                for i = 1:size(obj.actualPath.points,1)
                    pathStateIDs = [pathStateIDs;get_pos_by_id(NavG,recherche_dans_nodes(obj.actualPath.points(i,1),obj.actualPath.points(i,2),NavG))];
                end
            else
                pos = find(NavG.Links.Id_route == obj.id_road);
                id_dep = NavG.Links.EndStates(pos,2);
                pathStateIDs = [get_pos_by_id(NavG,id_dep)];
            end
            highlight(h,pathStateIDs,EdgeColor="#EDB120",LineWidth=4);
            highlight(h,pathStateIDs(1),NodeColor="#77AC30",MarkerSize=5);
            highlight(h,pathStateIDs(end),NodeColor="#D95319",MarkerSize=5);
        end
    end

    methods (Access = private)
        
        function target_selection(obj)
            % Define the next target to reach depending on the environment.
            % 
            % By default, the vehicle follows the path given by the
            % scheduling. If the target is already reached,
            % target_selection removes it from the vehicle's handler.
            % 
            % If the vehicle is near an obstacle, we call
            % compute_limited_cycles to get a new target that will allow
            % our vehicle to avoid the obstacle.
            %
            % Finally, if the vehicle is near and behind another one, a new
            % target is created based on an offset from the vehicle ahead by
            % calling compute_vehicle_offset.
            arguments
                obj vehicle
            end



            %% ------ Target Tracking ---------
            % transformation matrix from absolute base to target base
            tar = [obj.targets(1).theta, obj.targets(1).x, obj.targets(1).y];
            T_O_T = [cos(tar(1)) -sin(tar(1)) tar(2)
                     sin(tar(1)) cos(tar(1))  tar(3)
                     0           0            1];
            
            % position of the vehicle in target base
            vehicle_base_vehicule = T_O_T\[obj.x; obj.y; 1];
            x_vehicle_base_target = vehicle_base_vehicule(1);
            error_distance = obj.get_distance_object(obj.targets(1));
            error_theta = abs(SoustractionAnglesAtan2(obj.theta, obj.targets(1).theta));
            
            % if the target is reached, removed it
            if ( ((error_theta<=1.5) && (error_distance<=3)) || (x_vehicle_base_target>0))
                obj.targets(1)=[];
            end
            
            % we define the actual target as the second target of the list
            % for better anticipation
            if ~isempty(obj.targets)
                obj.actual_target = obj.targets(min(2, length(obj.targets)));
            else 
                return;
            end



            %% ------ ACC MODE ---------
            for i=1:size(obj.vehicles,2)
                dist=obj.get_distance_object(obj.vehicles(i));
                
                % transformation matrix from absolute base to vehicle base
                veh = [obj.theta, obj.x, obj.y];
                V_O_V = [cos(veh(1)) -sin(veh(1)) veh(2)
                         sin(veh(1)) cos(veh(1))  veh(3)
                         0           0            1];
                
                % position of the vehicle in vehicle base
                vehicle_base_vehicule = V_O_V\[obj.vehicles(i).x; obj.vehicles(i).y; 1];
                x_vehicle_base_vehicle = vehicle_base_vehicule(1);
                
                % difference of future targets of the two vehicles
                if ~isempty(obj.vehicles(i).targets)
                    diff_target = abs(obj.targets(1).theta-obj.vehicles(i).targets(1).theta);
                else
                    diff_target = abs(obj.actual_target.theta-obj.vehicles(i).actual_target.theta);
                end
                
                % if the two vehicles are going in the same direction and
                % the vehicle is behind another, we create a new target
                if (dist <= 30 && x_vehicle_base_vehicle>0 && diff_target<0.1)
                    obj.actual_target = obj.compute_vehicle_offset(obj.vehicles(i));
                end
            end



            %% ------ Obstacle Avoidance ---------
            % detect if the vehicle is in the circle of influence of the
            % vehicle
            obstacle_to_avoid=[];
            % smoother allow to activate the obtacle avoidance earlyier
            smoother = 10;
            for i=1:size(obj.obstacles,2)
                dist = obj.get_distance_object(obj.obstacles(i));
                if dist<=(obj.obstacles(i).getRayonInfluence()+smoother) 
                    obstacle_to_avoid = obj.obstacles(i);
                end
            end
            
            if ~isempty(obstacle_to_avoid)
                % remove targets from scheduling that are under obstacles
                for i=1:size(obj.targets,1)
                    dist = sqrt((obj.targets(i).x-obstacle_to_avoid.x)^2+(obj.targets(i).y-obstacle_to_avoid.y)^2);
                    if dist<=(obstacle_to_avoid.getRayonInfluence()+smoother)
                        obj.targets(i)=[];
                    end
                end
                
                % transformation matrix from absolute base to obstacle base 
                x_err = obj.targets(1).x - obstacle_to_avoid.x;
                y_err = obj.targets(1).y - obstacle_to_avoid.y;
                xi = atan2(y_err, x_err);
                obs = [xi, obstacle_to_avoid.x, obstacle_to_avoid.y];
                V_O_Obs = [cos(obs(1)) -sin(obs(1)) obs(2)
                           sin(obs(1)) cos(obs(1))  obs(3)
                           0           0            1];
                
                % position of the vehicle in obstacle base
                vehicle_base_obstacle = V_O_Obs\[obj.x; obj.y; 1];
                x_vehicle_base_obstacle = vehicle_base_obstacle(1);

                % if the obstacle is not overpass, we create a new target
                if(x_vehicle_base_obstacle<=0)
                    obj.actual_target = obj.compute_limited_cycles(obstacle_to_avoid);
                end
            end
        end
        
        function control=control_law(obj)
            % control_law adapts the speed and steering
            % angle of the vehicle based on the target defined by
            % the target selection algorithm.
            arguments
                obj vehicle
            end

            %compute the datas for the controller
            curvature_t=obj.actual_target.getCurv;
            xe = obj.actual_target.x - obj.x;
            ye = obj.actual_target.y - obj.y;
            error_x = cos(obj.theta)*xe + sin(obj.theta)*ye;
            error_y = -sin(obj.theta)*xe + cos(obj.theta)*ye;
            error_theta = SoustractionAnglesAtan2(obj.actual_target.theta, obj.theta);         
            thetaRT = atan2(ye,xe);
            error_RT = SoustractionAnglesAtan2(obj.actual_target.theta, thetaRT);
            d=sqrt(error_x^2 + error_y^2);
            if error_y > 0.1 
                curvature_t = 0;
            end
            CosE_theta = cos(error_theta);
            SinE_theta = sin(error_theta);
            SinE_RT = sin(error_RT);
            CosE_RT = cos(error_RT);

            % control law
            a=curvature_t/CosE_theta;
            b=(d^2*curvature_t*obj.K_l*SinE_RT*CosE_RT)/(obj.K_o*SinE_theta*CosE_theta);
            c=obj.K_theta*(SinE_theta/CosE_theta);
            d=(obj.K_d*error_y - obj.K_l*d*SinE_RT*CosE_theta)/(obj.K_o*CosE_theta);
            e=(obj.K_rt*SinE_RT^2)/(SinE_theta*CosE_theta);
            curv = a+b+c+d+e;
            if isnan(curv)
                curv = 0.0001;
            end
            
            % linear velocity
            vb=  obj.K_x*(obj.K_d*error_x + obj.K_l*d*SinE_RT*sin(error_theta) + obj.K_o*sin(error_theta)*curv);
            V =  obj.actual_target.v*cos(error_theta) + vb;
            % saturation of linear velocity
            vmax = 50/3.6;
            if ( (isnan(vb)) || (abs(V)> vmax)) 
                V = sign(V)*vmax/2;
            end
            
            % front wheel angle
            gamma_controller = atan(obj.lbase*curv);

            % store controller effects for plot
            VFLyap1 = 0.5*d^2*obj.K_d;
            VFLyap2 = 0.5*d^2*obj.K_l*SinE_RT^2;
            VFLyap3 = obj.K_o*(1- CosE_theta);
            obj.theta_error_output = [obj.theta_error_output;[obj.theta obj.actual_target.theta]];
            obj.speed_output = [obj.speed_output; V];
            obj.lyap1 = [obj.lyap1; VFLyap1];
            obj.lyap2 = [obj.lyap2; VFLyap2];
            obj.lyap3 = [obj.lyap3; VFLyap3];
            
            % ouput of the control law
            control = [V , gamma_controller];
        end


        function offset=compute_vehicle_offset(obj, agent)
            % compute_vehicle_offset gets the position of the vehicle 
            % given as a parameter and returns a target object with the 
            % same properties.
            arguments
                obj vehicle
                agent vehicle
            end
            
            % compute vehicle datas
            error_y = agent.y-obj.y;
            error_x = agent.x-obj.x;
            phi = atan2(error_y, error_x);
            
            % create the offset
            x_offset = agent.x-cos(phi)*obj.distance_securite_acc;
            y_offset = agent.y-sin(phi)*obj.distance_securite_acc;
            offset = target(x_offset, y_offset, agent.theta, 0, 0);
        end
        
        
        function avoid_target=compute_limited_cycles(obj, obs)
            % compute_limited_cycles gets the position of the obstacle 
            % given as a parameter and returns a target object according 
            % to the limited cycle defined around the obstacle.
            arguments
                obj vehicle
                obs obstacle
            end

            % compute obstacle datas
            error_x = obj.x - obs.x;
            error_y = obj.y - obs.y;
            limitcycles=obs.getRayonInfluence;

            % use ode to get the limit cycle
            [~,xc] = ode23(@(t, xc) EquationDiff_Tourbillon(t, xc, limitcycles), [0, 2], [error_x, error_y]);
            
            % get the 3 point of the trajectory around the obstacle as the
            % next target to reach
            i=3;
            tar = [xc(i,1)+obs.x, xc(i,2)+obs.y];
            tar_1 = [xc(i+1,1)+obs.x, xc(i+1,2)+obs.y];
            x_diff = tar_1(1) - tar(1);
            y_diff = tar_1(2) - tar(2);
            theta_target = atan2(y_diff, x_diff);
            avoid_target = target(tar(1),tar(2),theta_target,7/(obs.getRayonInfluence),0);
        end
        
        
        function set_pos(obj, control)
            % set_pos update the position of the vehicle according to the
            % output of the control law
            arguments
                obj vehicle
                control %array
            end
            
            % update vehicle coords
            obj.v = control(1);
            tmp_gamma = control(2) / 3;
            obj.x = obj.x + obj.v * cos(obj.theta) * obj.dt;
            obj.y = obj.y + obj.v * sin(obj.theta) * obj.dt;
            obj.theta = obj.theta + (tan(tmp_gamma/obj.lbase)) * obj.v * obj.dt;
            obj.gamma = tmp_gamma;
        end
        
        function dist=get_distance_object(obj, object)
            % calculate the distance between vehicle and object in
            % parameters
            dist=sqrt((obj.x-object.x)^2+(obj.y-object.y)^2);
        end

        function plot_corrector_action(obj)
            % plotting function
            figure(obj.id_vehicle*5+1);
            plot(obj.theta_error_output(:,1),'red')
            hold on;
            plot(obj.theta_error_output(:,2),'blue')
            legend('sortie','consigne')
            title('Correction angle du véhicule')
            
            figure(obj.id_vehicle*5+2);
            plot(obj.speed_output(:,1),'red')
            legend('speed output')
            title('Evolution de la vitesse')

            figure(obj.id_vehicle*5+3);
            plot(obj.lyap1(:,1),'red')
            legend('lyapunov')
            title('Evolution Lyap1')

            figure(obj.id_vehicle*5+4);
            plot(obj.lyap2(:,1),'red')
            legend('lyapunov')
            title('Evolution Lyap2')

            figure(obj.id_vehicle*5+5);
            plot(obj.lyap3(:,1),'red')
            legend('lyapunov')
            title('Evolution Lyap3')
        end 
    end
end