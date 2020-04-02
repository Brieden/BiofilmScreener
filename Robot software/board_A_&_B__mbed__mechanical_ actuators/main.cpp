/* Includes ------------------------------------------------------------------*/
#include "mbed.h"                              /* mbed specific header files. */
#include "DevSPI.h"                                   /* Helper header files. */
#include "XNucleoIHM02A1.h"         /* Expansion Board specific header files. */

/* Ports     ------------------------------------------------------------------*/
Serial pc(USBTX,USBRX);
DigitalIn light_barrier_x(D7);
DigitalIn light_barrier_y(D8);

//const char board_id = 'A';
const char board_id = 'B'; 

/* Motor Control Expansion Board. */
XNucleoIHM02A1 *x_nucleo_ihm02a1;

/* Initialization parameters of the motors connected to the expansion board. */
L6470_init_t init[L6470DAISYCHAINSIZE] = {
    /* First Motor. */
        45.0,                          /* Motor supply voltage in V. */
        200,                           /* Min number of steps per revolution for the motor. */
        2.1,                           /* Max motor phase voltage in A. */
        45.0,                          /* Max motor phase voltage in V. */
            0,                         /* Motor initial speed [step/s]. 300*/
        200.0,                         /* Motor acceleration [step/s^2] (comment for infinite acceleration mode). */
        200.0,                         /* Motor deceleration [step/s^2] (comment for infinite deceleration mode). */
        600.0,                         /* Motor maximum speed [step/s]. */
        0.0,                           /* Motor minimum speed [step/s]. */
        800.0,                         /* Motor full-step speed threshold [step/s]. */
        3.06,                          /* Holding kval [V]. */
        3.06,                          /* Constant speed kval [V]. */
        3.06,                          /* Acceleration starting kval [V]. */
        3.06,                          /* Deceleration starting kval [V]. */
        61.52,                         /* Intersect speed for bemf compensation curve slope changing [step/s]. */
        392.1569e-6,                   /* Start slope [s/step]. */
        643.1372e-6,                   /* Acceleration final slope [s/step]. */
        643.1372e-6,                   /* Deceleration final slope [s/step]. */
        0,                             /* Thermal compensation factor (range [0, 15]). */
        3.06 * 1000 * 1.10,            /* Ocd threshold [ma] (range [375 ma, 6000 ma]). */
        3.06 * 1000 * 1.00,            /* Stall threshold [ma] (range [31.25 ma, 4000 ma]). */
        StepperMotor::STEP_MODE_1_128, /* Step mode selection. */
        0xFF,                          /* Alarm conditions enable. */
        0x2E88                         /* Ic configuration. */
};

/* Main ----------------------------------------------------------------------*/
int main()
{
    pc.baud(115200);
    /*----- Initialization. -----*/
    /* Initializing Motor Control Expansion Board. */
    if(board_id == 'A') {
    x_nucleo_ihm02a1 = new XNucleoIHM02A1(&init[0], &init[0], A4, A5, D4, D10, D11, D12, D13);
    }

    if(board_id == 'B') {
    x_nucleo_ihm02a1 = new XNucleoIHM02A1(&init[0], &init[0], A4, A5, D4, A2, D11, D12, D13);
    }
    
    /* Building a list of motor control components. */
    L6470 **motors = x_nucleo_ihm02a1->get_components();

    while(1) {
        char serial_port_message_string[] = "nan-000000-000000";
        char serial_port_command_string[] = "nan";
        char serial_port_argument_string_x[] = "-000000";
        char serial_port_argument_string_y[] = "-000000";
        int  serial_port_argument_int_x = 0;
        int  serial_port_argument_int_y = 0;

        pc.scanf("%s", serial_port_message_string);

        strncpy(serial_port_command_string, serial_port_message_string, 3);
        strncpy(serial_port_argument_string_x, serial_port_message_string + 3, 7);
        strncpy(serial_port_argument_string_y, serial_port_message_string + 3 + 7, 7);
//        pc.printf("%s \n",serial_port_command_string);        
        serial_port_argument_int_x = atoi(serial_port_argument_string_x);
        serial_port_argument_int_y = atoi(serial_port_argument_string_y);


        if (strcmp(serial_port_command_string,"gid")==0) {
            pc.printf("%c \n", board_id);
        } 
        
        else if (strcmp(serial_port_command_string,"gls")==0) {
            int lb_state_x = light_barrier_x;
            int lb_state_y = light_barrier_y;
            pc.printf("%+07d %+07d \n", lb_state_x, lb_state_y);
        }
                
        else if (strcmp(serial_port_command_string,"gsp")==0) {
            pc.printf("%+07d %+07d \n", motors[0]->get_speed(), motors[1]->get_speed());
        }
        
        else if (strcmp(serial_port_command_string,"ssp")==0) {
            motors[0]->set_max_speed(serial_port_argument_int_x);
            motors[1]->set_max_speed(serial_port_argument_int_y);
            pc.printf("%+07d %+07d \n", motors[0]->get_max_speed(), motors[1]->get_max_speed());
        }
        
        else if (strcmp(serial_port_command_string,"sac")==0) {
            motors[0]->set_deceleration(serial_port_argument_int_x);
            motors[0]->set_acceleration(serial_port_argument_int_x);
            motors[1]->set_deceleration(serial_port_argument_int_y);
            motors[1]->set_acceleration(serial_port_argument_int_y);
            pc.printf("%+07d %+07d \n", motors[0]->get_acceleration(), motors[1]->get_acceleration());
        }
        
        else if (strcmp(serial_port_command_string,"mov")==0) {
            if ((motors[0]->get_speed()+ motors[1]->get_speed()) != 0) {
                pc.printf("Error: new move command while moving\n");    
            }
            else{
                if (serial_port_argument_int_x >= 0){
                    motors[0]->move(StepperMotor::FWD,  abs(serial_port_argument_int_x));
                }
                else {
                    motors[0]->move(StepperMotor::BWD,  abs(serial_port_argument_int_x));
                }
                
                if (serial_port_argument_int_y >= 0){
                    if(board_id == 'A') {
                        motors[1]->move(StepperMotor::FWD,  abs(serial_port_argument_int_y));
                    }
                    else {                    
                        motors[1]->move(StepperMotor::BWD,  abs(serial_port_argument_int_y));
                    }
                }
                else {
                    if(board_id == 'A') {
                        motors[1]->move(StepperMotor::BWD,  abs(serial_port_argument_int_y));
                    }
                    else {
                        motors[1]->move(StepperMotor::FWD,  abs(serial_port_argument_int_y));
                    }
                }
                pc.printf("%+07d %+07d \n", serial_port_argument_int_x, serial_port_argument_int_y);
            }
        }

        else{
            pc.printf("Error: Unknown command: %s with value %d and %d \n", serial_port_command_string, serial_port_argument_int_x, serial_port_argument_int_y);    
        }
    }
}

