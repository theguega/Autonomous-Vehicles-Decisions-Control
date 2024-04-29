classdef vehicle < handle
    properties
        x = 0;
        y = 0;
        theta = 0;
        v = 0; %linear speed
        w = 0; %angular speed
        
        dt = 0.1; % discretisation time
        
        %plot parameters
        L = 2.5;     % Empattement
        d = 3;  % Largeur des essieux
        r = 1;     % Rayon des roues
        
        %targets and obstacles
        targets = [];
        obstacles = [];
        actual_target;
        
        %controllers parameters
        to_avoid = obstacle(0,0,0,0); %obstacle to avoid
        distance_to_avoid=0; % distance between nearest obstacle and the vehicle
        RayonCycleLimite=0;
        controller = 1;
    end
    
    methods
        %constructor
        function obj = vehicle(x, y, theta, obstacles, targets)
            obj.x = x;
            obj.y = y;
            obj.theta = theta;
            obj.targets = targets;
            obj.obstacles = obstacles;
        end
        
        %plot the vehicle pos
        function plot(obj)
            xArD = obj.x + obj.d/2*sin(obj.theta); % right back wheel
            yArD = obj.y - obj.d/2*cos(obj.theta);
            xArDDev = xArD + obj.r*cos(obj.theta);
            yArDDev = yArD + obj.r*sin(obj.theta);
            xArDArr = xArD - obj.r*cos(obj.theta);
            yArDArr = yArD - obj.r*sin(obj.theta);
            
            xArG = obj.x - obj.d/2*sin(obj.theta); % left back wheel
            yArG = obj.y + obj.d/2*cos(obj.theta);
            xArGDev = xArG + obj.r*cos(obj.theta);
            yArGDev = yArG + obj.r*sin(obj.theta);
            xArGArr = xArG - obj.r*cos(obj.theta);
            yArGArr = yArG - obj.r*sin(obj.theta);
            
            %vehicle lines
            plot(obj.x,obj.y,'r+');
            line([xArG xArD],[yArG yArD])
            line([xArGDev xArGArr],[yArGDev yArGArr],'Color','r','LineWidth',2)
            line([xArDDev xArDArr],[yArDDev yArDArr],'Color','r','LineWidth',2)
            
            for i=0:0.2:(2*pi)
                plot(obj.x+(obj.d/2)*cos(i),obj.y+(obj.d/2)*sin(i),'-','LineWidth',2);
            end
        end
        
        function update(obj, dt)
            obj.dt = dt;
            obj.actual_target=obj.targets(1,:); %first by default
            
            if obj.get_distance_point(obj.actual_target) < 1
                obj.targets = obj.targets(2:end, :); %remove first target of the list if already reached
                obj.actual_target = obj.targets(1,:);
            end
            
            control = obj.controller_selection(); %return controller command
            obj.set_pos(control);
        end
        
        
        
        
        %choose the right controller depending on the situation and give the correponding output
        function control=controller_selection(obj)
            %reset obstacle to avoid
            obj.to_avoid = obstacle(0,0,0,0);
            obj.distance_to_avoid=-1;
            obj.controller=1; % attraction by default
            
            %check if there is an obstacle to avoid
            for i=1:size(obj.obstacles,2)
                dist = sqrt( (obj.obstacles(i).getX() - obj.x)^2 + (obj.obstacles(i).getY() - obj.y)^2);
                disp(dist)
                disp(obj.obstacles(i).getRayonInfluence()+obj.getd())
                if dist<=(obj.obstacles(i).getRayonInfluence()+obj.getd())
                    obj.distance_to_avoid=dist;
                    %if the actual obstacle is neareast than the previous one
                    if dist<=obj.distance_to_avoid
                        obj.to_avoid=obj.obstacles(i);
                        obj.distance_to_avoid=dist;
                        obj.controller=2;
                    end
                end
            end
            
            % get appropriates data depending on controller type
            if obj.controller==2
                datas=obj.var_obstacle_avoidance();
                control=obj.control_obstacle_avoidance(datas);
            else
                datas=obj.var_attraction();
                control=obj.control_attraction(datas);
            end
        end
        
        function datas=var_attraction(obj)
            %compute the datas for the attraction controller
            error_x = obj.actual_target(1) - obj.x;
            error_y = obj.actual_target(2) - obj.y;
            
            datas = [error_x; error_y];
        end
        
        function control=control_attraction(obj, datas)
            E = [datas(1);datas(2)];
            l1 = 0.4;
            K = [0.1;0.1];
            M = [cos(obj.theta), -l1*sin(obj.theta);
                 sin(obj.theta), l1*cos(obj.theta)];
            
            command = K.*(M\E);
            
            V = command(1); % with this command, linear speed is proportionnal to error : big error = faster
            %insert PID here instead of V=command(1)
            W = command(2);
            
            lyapunov = 0.5*(datas(1)^2+datas(2)^2);
            control = [V, W, lyapunov];
        end
        
        
        
        function datas=var_obstacle_avoidance(obj)
            %compute the datas for the obstacle avoidance controller
            error_x = obj.x - obj.to_avoid.getX();
            error_y = obj.y - obj.to_avoid.getY();
            
            %transformation matrix
            X_D_O = obj.actual_target(1) - obj.to_avoid.getX();
            Y_D_O = obj.actual_target(2) - obj.to_avoid.getY();
            alpha = atan2(Y_D_O, X_D_O);
            T_O_A = inv([cos(alpha) -sin(alpha) 0 obj.to_avoid.getX()
                         sin(alpha)  cos(alpha) 0 obj.to_avoid.getY()
                         0           0          1 0
                         0           0          0 1]);
            
            obstacle_coords = T_O_A\[obj.x; obj.y; 0; 1];
            X_obst = obstacle_coords(1);
            
            % get rayoncyclelimite
            if (X_obst <= 0)
                obj.RayonCycleLimite=(obj.to_avoid.getRayonInfluence()+obj.getd())-0.3;
            else
                obj.RayonCycleLimite=obj.RayonCycleLimite+0.03;
            end
            
            x_dot = error_y + error_x * ((obj.RayonCycleLimite^2) - (error_x^2) - (error_y^2));
            y_dot = -error_x + error_y * ((obj.RayonCycleLimite^2) - (error_x^2) - (error_y^2));
            theta_dot = atan2(y_dot, x_dot);
            
            X0 = [x_dot, y_dot];
            xc = ode23(@(t, y) EquationDiff_Tourbillon(t, y, obj.RayonCycleLimite), [0, 0.2], X0);
            theta_controller = atan2((xc.y(2, 2) - xc.y(1, 2)), (xc.y(2, 1) - xc.y(1, 1)));
            error_theta=SoustractionAnglesAtan2(theta_dot, obj.theta);
            
            datas = [error_theta; theta_controller; 1];
        end
        
        
        function control=control_obstacle_avoidance(~, datas)
            error_theta = datas(1);
            theta_controller = datas(2);
            
            Kp = 15;
            V = 0.5;
            %insert PID here instead of V=0.5
            W = theta_controller + Kp*error_theta;
            
            lyapunov = 0.5*rad2deg(error_theta)^2/10;
            control = [V, W, lyapunov];
        end
        
        
        function set_pos(obj, control)
            %update the position of the vehicle
            obj.v = control(1);
            obj.w = control(2);
            
            obj.x = obj.x + obj.v * cos(obj.theta) * obj.dt;
            obj.y = obj.y + obj.v * sin(obj.theta) * obj.dt;
            obj.theta = obj.theta + obj.w * obj.dt;
        end
        
        
        %---------------------------------------------------- getters ----------------------------------------------------
        
        function dist=get_distance_object(obj, object)
            dist=sqrt((obj.x-object.getX())^2+(obj.y-object.getY())^2); % distance between vehicle and object in arguments
        end
        
        function dist=get_distance_point(obj, point)
            dist=sqrt((obj.x-point(1))^2+(obj.y-point(2))^2); %distance between vehcile and point=(x,y)
        end
        
        function x = getX(obj)
            x = obj.x;
        end
        
        function y = getY(obj)
            y = obj.y;
        end
        
        function theta = getTheta(obj)
            theta = obj.theta;
        end
        
        function v = getV(obj)
            v = obj.v;
        end
        
        function w = getW(obj)
            w = obj.w;
        end
        
        function d = getd(obj)
            d = obj.d;
        end
        
        function obstacles = getobstacles(obj)
            obstacles = obj.obstacles;
        end
    end
end