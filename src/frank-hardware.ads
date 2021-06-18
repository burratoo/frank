------------------------------------------------------------------------------------------
--                                                                                      --
--                                    FRANK.HARDWARE                                    --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

--  Mapping Frank's sensors to the underlying NXT hardware

with Mindstorms.NXT;                    use Mindstorms.NXT;
with Mindstorms.NXT.I2C;                use Mindstorms.NXT.I2C;
with Mindstorms.NXT.Ultrasonic_Sensors; use Mindstorms.NXT.Ultrasonic_Sensors;
with Mindstorms.NXT.Touch_Sensors;      use Mindstorms.NXT.Touch_Sensors;

package Frank.Hardware is

   Port_4_Interface : aliased I2C_Interface;
   Port_4_Controller : I2C_Controller (Port_Number    => 4,
                                       Port_Interface => Port_4_Interface'Access,
                                       Mode           => LEGO);
   Ultrasonic : Ultrasonic_Sensor :=
     New_Ultrasonic_Sensor (On_Port => Port_4_Interface'Access);
   --  Ultrasonic sensor is connected to I2C port 4

   Right_Foot_Touch_Sensor : Touch_Sensor (Sensor_1);
   Left_Foot_Touch_Sensor  : Touch_Sensor (Sensor_2);
   --  The right and left foot sensors are connect to Sensor 1 and 2 respectively

end Frank.Hardware;
