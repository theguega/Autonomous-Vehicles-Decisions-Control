classdef VehicleCarla < vehicle
    properties
        CarlaVehicle
        Simulator
        isDeclared
        isEngaged
    end
    methods
        function this = VehicleCarla(simulator, obstacles, nb_cars_since_beginning,id_road,isEgo)
            point0 = simulator.MapDetail.Map(string(id_road)).waypoints{1};
            point1 = simulator.MapDetail.Map(string(id_road)).waypoints{2};
            pos0= point0.transform.location;
            pos1= point1.transform.location;
            theta = atan2(-pos1.y + pos0.y, pos1.x - pos0.x);
            this@vehicle(pos0.x, -pos0.y, theta, 0, obstacles, repmat(target(0,0,0,0,0), 0, 0), [], nb_cars_since_beginning, id_road, 0);
            this.CarlaVehicle = Vehicle(simulator,isEgo);
            this.Simulator = simulator;
            this.CarlaVehicle.setPosAndHeading(this.x, this.y, this.theta);
            this.addTargetRoad(id_road);
            this.isDeclared=false;
            this.isEngaged=false;
        end
        function teleportToFirstTarget(this)
            % Call this after adding targets to the vehicle to sync the
            % "decision" vehicle and the CARLA vehicle's position and angle
            this.x = this.targets(1).x;
            this.y = this.targets(1).y;
            this.theta = this.targets(1).theta;
            this.CarlaVehicle.setPosAndHeading(this.x, this.y, this.theta);
        end
        function update(this, dt, sched)
            this.actualPath.cost = this.updatecost();
            if nargin <= 2
                sched = NaN;
            end
            if length(this.targets)<=2
                if ~isnan(this.actualPath) & ~isempty(this.actualPath.roads)
                    if this.isEngaged==true
                        road = this.Simulator.MapDetail.Map(string(this.id_road));
                        this.isEngaged=false;
                        this.isDeclared=false;
                        this.Simulator.MapDetail.Junctions(string(road.junctionId))=this.Simulator.MapDetail.Junctions(string(road.junctionId))-10;
                        this.id_road=this.actualPath.roads(1);
                        this.actualPath.roads= this.actualPath.roads(2:end);
                        this.addTargetRoad(this.id_road);
                    else
                        nextroad = this.actualPath.roads(1);
                        road = this.Simulator.MapDetail.Map(string(nextroad));
                        if road.junctionId>0
                            if isKey(this.Simulator.MapDetail.Junctions, string(road.junctionId))==false
                                this.Simulator.MapDetail.Junctions(string(road.junctionId))= 0;
                            end
                            if road.signType == "206" %stop sign
                                if this.isDeclared==false
                                    this.Simulator.MapDetail.Junctions(string(road.junctionId))=this.Simulator.MapDetail.Junctions(string(road.junctionId))+1;
                                    this.isDeclared=true;
                                end
                                if this.Simulator.MapDetail.Junctions(string(road.junctionId))<=1
                                    this.Simulator.MapDetail.Junctions(string(road.junctionId))=this.Simulator.MapDetail.Junctions(string(road.junctionId))+9;
                                    
                                    this.id_road=this.actualPath.roads(1);
                                    this.actualPath.roads= this.actualPath.roads(2:end);
                                    this.addTargetRoad(this.id_road);
                                    this.isEngaged=true;
                                end
                            elseif road.signType == "205" %yield sign
                                if this.isDeclared==false
                                    this.Simulator.MapDetail.Junctions(string(road.junctionId))=this.Simulator.MapDetail.Junctions(string(road.junctionId))+3;
                                    this.isDeclared=true;
                                end
                                if this.Simulator.MapDetail.Junctions(string(road.junctionId))<=4
                                        this.Simulator.MapDetail.Junctions(string(road.junctionId))=this.Simulator.MapDetail.Junctions(string(road.junctionId))+7;
                                        this.id_road=this.actualPath.roads(1);
                                        this.actualPath.roads= this.actualPath.roads(2:end);
                                        this.addTargetRoad(this.id_road);
                                        this.isEngaged=true;
                                end
                            elseif this.CarlaVehicle.Actor.get_traffic_light_state().name == "Green" | this.CarlaVehicle.Actor.get_traffic_light_state().name == "Unknown" | this.CarlaVehicle.Actor.get_traffic_light_state().name == "Off" 
                                if this.isDeclared==false
                                    this.Simulator.MapDetail.Junctions(string(road.junctionId))=this.Simulator.MapDetail.Junctions(string(road.junctionId))+5;
                                    this.isDeclared=true;
                                end
                                if this.Simulator.MapDetail.Junctions(string(road.junctionId))<=14
                                        this.Simulator.MapDetail.Junctions(string(road.junctionId))=this.Simulator.MapDetail.Junctions(string(road.junctionId))+5;
                                        this.id_road=this.actualPath.roads(1);
                                        this.actualPath.roads= this.actualPath.roads(2:end);
                                        this.addTargetRoad(this.id_road);
                                        this.isEngaged=true;
                                end
                            end
                        else
                            this.id_road=this.actualPath.roads(1);
                            this.actualPath.roads= this.actualPath.roads(2:end);
                            this.addTargetRoad(this.id_road);
                        end
                    end
                end
            end
            update@vehicle(this, dt, sched);
            this.CarlaVehicle.setPosAndHeading(this.x, this.y, this.theta);
        end
        function addTargetRoad(this, roadId)
            roadList = this.Simulator.MapDetail.Map(string(roadId)).waypoints;
            startWaypoint = 1;

            if isempty(this.targets)
                t0x = roadList{1}.transform.location.x;
                t0y = -roadList{1}.transform.location.y;
                t1x = roadList{2}.transform.location.x;
                t1y = -roadList{2}.transform.location.y;
                theta_target = atan2(t1y - t0y, t1x - t0x);
                this.targets(1) = target(t0x, t0y, theta_target, 0, 0);
                startWaypoint = 2;
            end

            for i = startWaypoint:length(roadList)-1
                road = roadList{i};
                t0x = this.targets(end).x;
                t0y = this.targets(end).y;
                t1x = road.transform.location.x;
                t1y = -road.transform.location.y;
                theta_target = atan2(t1y - t0y, t1x - t0x);
                this.targets(end+1) = target(t1x, t1y, theta_target, 30/3.6, 0);
            end
        end

        function cost = updatecost(this)
            cost=0;
            for i=1:length(this.actualPath.roads)
                id_road = this.actualPath.roads(i);
                road = this.Simulator.MapDetail.Map(string(id_road));
                cost = cost+road.lengthMeters;
            end
        end
    end
end