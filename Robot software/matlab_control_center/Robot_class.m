classdef Robot_class < handle
%
    properties (Access = private) 
    % Protected member properties: just accessebel by member functions
    % :param position: Position of the stages in mm
    % :type position: 1x4 float array
        length_stage = [846000, 613000];
        position = [835000, 10000, 835000, 10000]; 
    end
    
    properties
    % :param board_A/B: Serial port name like 'COM3' 
    % :param digCamControl_logdir: filedirectory of the logfile from the camera control solution
    % :param digCamControl_log: Content of the logfile updated for is_a_photo_taken()
    % :type board_A/B: 1x1 string
    % :type digCamControl_logdir: 1x1 string
    % :type digCamControl_log: 1x1 string
        board_A = [];
        board_B = [];
        reference_position = [835000, 10000, 835000, 10000];
        conv_factor_steps_to_mum = 4.296875;
        verbose = 0;
    end
    
    methods 
        function obj = Robot_class(board_A_input, board_B_input)
        % class constructor 
            fprintf('Start Robot class initialized\n');
            obj.board_A = board_A_input;
            obj.board_B = board_B_input;
            % check the startposition
 %szsSAESIAE
            if obj.in_start_position() ~= 1
                obj.find_start();
%                 disp(obj.lightbarriers_state());
%                  error('Error: can not go on')
            end
            obj.set_low_speed();
            fprintf('Start finding reference position\n');
            obj.find_reference_position(1) 
            obj.go_to_start();
            fprintf('Robot class initialized\n');
        end
        
        function find_start(obj)
            fprintf('Go slowly to start pos\n');
            obj.set_low_speed();
            obj.position = [0, 613000, 0, 613000];
            obj.move_to_change_lightbarrier_state_neu(obj.conv_factor_steps_to_mum*500, 1);
            obj.position = obj.reference_position;
            fprintf('Went to start pos\n');
        end

        
        function out = find_reference_position(obj, first_try)
        % 10mm, 5mm, 2mm, 1mm, 0.5mm, 0.2mm, 0.1mm, 0.05mm
        % 30 sec 
            if nargin < 2
                first_try = 0;
            end

            if first_try
                obj.move_to_change_lightbarrier_state_neu(  -600, 0);
                obj.move_to_change_lightbarrier_state_neu(   300, 1);
                obj.move_to_change_lightbarrier_state_neu(  -100, 0);
                obj.move_to_change_lightbarrier_state_neu(    60, 1);
                obj.move_to_change_lightbarrier_state_neu(   -30, 0);
                obj.move_to_change_lightbarrier_state_neu(    10, 1);
                obj.position = obj.reference_position;
            end
            
            start_position = -80;
            obj.move('light',  [obj.reference_position(1) + start_position, obj.reference_position(2) - start_position]);
            obj.move('camera', [obj.reference_position(3) + start_position ,obj.reference_position(4) - start_position]);
            obj.wait_for_no_movement();
            
            if sum(obj.lightbarriers_state()) > 0
                warning("find reference out of range");
                disp(obj.lightbarriers_state());
            end
            obj.move_to_change_lightbarrier_state_neu(obj.conv_factor_steps_to_mum*4, 1);
            out = obj.position;
            obj.position = obj.reference_position;
        end
            
        function move_to_change_lightbarrier_state_neu(obj, distance, new_lightbarrier_state)
        % This function moves all stages to the new    
            lightbarrier_state = obj.lightbarriers_state();
            
            while sum(lightbarrier_state) ~= new_lightbarrier_state * 4
                positions = obj.position();
                new_light_x_position  = positions(1); 
                new_light_y_position  = positions(2); 
                new_camera_x_position = positions(3); 
                new_camera_y_position = positions(4); 

                if lightbarrier_state(1) ~= new_lightbarrier_state
                    new_light_x_position = new_light_x_position + distance;
                end

                if lightbarrier_state(2) ~= new_lightbarrier_state
                    new_light_y_position = new_light_y_position - distance;
                end

                if lightbarrier_state(3) ~= new_lightbarrier_state
                    new_camera_x_position = new_camera_x_position + distance;
                end

                if lightbarrier_state(4) ~= new_lightbarrier_state
                    new_camera_y_position = new_camera_y_position - distance;
                end
                obj.move('camera', [new_camera_x_position, new_camera_y_position]);
                obj.move('light' , [new_light_x_position,  new_light_y_position]);

%                obj.wait_for_no_movement;
                lightbarrier_state = obj.lightbarriers_state();

                if obj.verbose 
                    disp(["lightbarrierstate:", lightbarrier_state])
                    disp(["position", obj.position])
                end
            end
        end

        function out = in_start_position(obj)
            if sum(obj.lightbarriers_state) ~= 4
                warning('Warning: Please move all stages to the startposition');
                out = 0;
            else
                out = 1;
            end
        end
                
        function out = getposition(obj)
        % get the position of the robot 
        % :rtype: 
            out = obj.position;
        end 
        
        function go_to_zero(obj)
            disp('go_to_zero');
            obj.move('camera', [0,0]);
            obj.move('light', [0,0]);
        end
        
        function go_to_corner(obj)
            disp('go_to_corner');
            obj.move('camera', [0,obj.length_stage(2)]);
            obj.move('light', [0,obj.length_stage(2)]);
        end
        
        function go_to_end(obj)
            disp('go_to_end');
            obj.move('camera', [obj.length_stage(1),obj.length_stage(2)]);
            obj.move('light', [obj.length_stage(1),obj.length_stage(2)]);
        end
        
        function go_to_start(obj)
            disp('go_to_start');
            obj.move('camera', [obj.length_stage(1),0]);
            obj.move('light', [obj.length_stage(1),0]);
        end
        function go_to_reference_position(obj)
            disp('go_to_refrenz_point');
            obj.move('camera', [obj.reference_position(3),obj.reference_position(4)]);
            obj.move('light', [obj.reference_position(1),obj.reference_position(2)]);
        end
        
        function go_to_middel(obj)
            disp('go_to_refrenz_point');
            obj.move('camera', [obj.length_stage(1)/2,obj.length_stage(2)/2]);
            obj.move('light', [obj.length_stage(1)/2,obj.length_stage(2)/2]);
        end
        
        function move(obj, level, position_new_in_mum)
        % Prepare and Send the command to move the stage
        % :param position_absolut_mum: position in Mikron
        % :param leve: lightsource level or camera level
        % :type position_absolut_mum: 2D vector

            obj.check_is_the_position_reachable(position_new_in_mum);
            position_new_in_mum_x = position_new_in_mum(1);
            position_new_in_mum_y = position_new_in_mum(2);
            
            % set the level
           if strcmp(level,'light')
                board = obj.board_A;
                position_current_in_mum_x = obj.position(1);
                position_current_in_mum_y = obj.position(2);
            elseif strcmp(level,'camera')
                board = obj.board_B;
                position_current_in_mum_x = obj.position(3);
                position_current_in_mum_y = obj.position(4);
            end
            
            % calculate the steps and send the comment to the board
            % positioning y-axes
            movement_in_mum_x = position_new_in_mum_x - position_current_in_mum_x;
            movement_in_mum_y = position_new_in_mum_y - position_current_in_mum_y;
            movement_in_steps_x = obj.convert_distance_from_mum_to_steps(movement_in_mum_x);
            movement_in_steps_y = obj.convert_distance_from_mum_to_steps(movement_in_mum_y);

            command = 'mov';
            argument_x = sprintf('%0+7i',movement_in_steps_x);
            argument_y = sprintf('%0+7i',movement_in_steps_y);
            message  = [command, argument_x, argument_y];
            obj.com_port_send_receive(board, message);

           if strcmp(level,'light')
                obj.position(1) = position_current_in_mum_x + obj.convert_distance_from_steps_to_mum(movement_in_steps_x);
                obj.position(2) = position_current_in_mum_y + obj.convert_distance_from_steps_to_mum(movement_in_steps_y);
           elseif strcmp(level,'camera')
                obj.position(3) = position_current_in_mum_x + obj.convert_distance_from_steps_to_mum(movement_in_steps_x);
                obj.position(4) = position_current_in_mum_y + obj.convert_distance_from_steps_to_mum(movement_in_steps_y);
           end
        end

        function check_is_the_position_reachable(obj, position_in_mum)
            if  position_in_mum(1)>obj.length_stage(1) || position_in_mum(2)>obj.length_stage(2)
                error('Error: position is too hight and not reachable');
            elseif position_in_mum(1)<0 || position_in_mum(2)<0
                error('Error: position is too low and not reachable');
            end

            
        end
        
        function distance_in_steps = convert_distance_from_mum_to_steps(obj, distance_in_mum) 
        % 110mm travel per motor revolution \
        % 200 steps per motor revolution     | --> 4.296875 mum/microstep
        % 128 microstep per step            /
            distance_in_steps = int32(distance_in_mum / obj.conv_factor_steps_to_mum);
        end

        function distance_in_mum = convert_distance_from_steps_to_mum(obj, distance_in_steps) 
        % 110mm travel per motor revolution \
        % 200 steps per motor revolution     | --> 4.296875 mum/microstep
        % 128 microstep per step            /
            distance_in_mum = distance_in_steps * obj.conv_factor_steps_to_mum;
        end
        
        function set_low_speed(obj)
            obj.com_port_send_receive(obj.board_A, 'ssp+000400+000400');
            obj.com_port_send_receive(obj.board_B, 'ssp+000400+000400');
            obj.com_port_send_receive(obj.board_A, 'sac+000050+000050');
            obj.com_port_send_receive(obj.board_B, 'sac+000050+000050');
        end
        
        function set_high_speed(obj)
            obj.com_port_send_receive(obj.board_A, 'ssp+004000+000900');
            obj.com_port_send_receive(obj.board_B, 'ssp+004000+002000');
            obj.com_port_send_receive(obj.board_A, 'sac+003000+001000');
            obj.com_port_send_receive(obj.board_B, 'sac+003000+001000');
        end

        function set_normal_speed(obj)
            obj.com_port_send_receive(obj.board_A, 'ssp+000900+000600');
            obj.com_port_send_receive(obj.board_B, 'ssp+000900+000600');
            obj.com_port_send_receive(obj.board_A, 'sac+003000+000500');
            obj.com_port_send_receive(obj.board_B, 'sac+003000+000500');
        end
        
        function test(obj)
            obj.set_high_speed();
            obj.go_to_reference_position();
            obj.wait_for_no_movement();
            obj.com_port_send_receive(obj.board_A, 'ssp+004000+000900');
            obj.com_port_send_receive(obj.board_B, 'ssp+004000+002000');
            obj.com_port_send_receive(obj.board_A, 'sac+008001+000001');
            obj.com_port_send_receive(obj.board_B, 'sac+008001+000001');
            obj.go_to_zero();
        end

        
        function out = lightbarriers_state(obj)
        % Get the state of all 4 lightbarriers.
        % :rtype: 
            message = 'gls-000000-000000';
            lightb_light = obj.com_port_send_receive(obj.board_A, message);
            lightb_camera = obj.com_port_send_receive(obj.board_B, message);
            a = sscanf(lightb_light, '%7d %7d');
            b = sscanf(lightb_camera, '%7d %7d');

            out = [a(1), a(2), b(1), b(2)];
        end
        
        function wait_for_no_movement(obj)
        % repeats the query of no movement until all no movement
            while (obj.no_movement == 0)
            end
        end
        
        function out = no_movement(obj)
        % Get the state of all 4 speed and checks if everything is
        % not moving. 
        % :rtype out: binary 
            message = 'gsp-000000-000000';
            speed_light = obj.com_port_send_receive(obj.board_A, message);
            speed_camera = obj.com_port_send_receive(obj.board_B, message);

            a = sscanf(speed_light, '%7d %7d');
            b = sscanf(speed_camera, '%7d %7d');

            if a(1)==0 && a(2)==0 && b(1)==0 && b(2)==0
                out = 1;
            else
                out = 0;
            end
        end

        function answer = com_port_send_receive(obj, com_port_name, command)
        % Sends a command to an Microcontroller board and receive the
        % answer. The command are 
        % :param com_port_name: Serial port name like 'COM3' 
        % :param command: The command should be conforming to the 
        %                 Sven's serial communication codex
        % :type com_port_name: str
        % :type command: str
        % :rtype: 
            s = serial(com_port_name);
            set(s,'BaudRate',115200);
            fopen(s);
            fprintf(s,command);
            answer = fscanf(s);
            if obj.verbose
                fprintf("send message: %s to %s\n", command, com_port_name);
                fprintf("received answer: %s \n\n", answer);
            end
            if contains(answer, 'Error')
                fprintf("send message: %s \n", command);
                fprintf("received answer: %s \n", answer);
                error('Error: The answer from board %s has an error', com_port_name)
            end
            if length(answer)<=14
                fprintf("send message: %s \n", command);
                fprintf("received answer: %s \n", answer);
                error('Error: The answer from board %s is too short', com_port_name)
            end
            fclose(s);
            delete(s);
            clear s;
        end
               
    end 
    end 
    
%end
