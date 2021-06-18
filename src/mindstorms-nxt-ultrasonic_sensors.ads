------------------------------------------------------------------------------------------
--                                                                                      --
--                           MINDSTORMS.NXT.ULTRASONIC_SENSORS                          --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Mindstorms.NXT.Digital_Sensors; use Mindstorms.NXT.Digital_Sensors;
with Mindstorms.NXT.I2C;             use Mindstorms.NXT.I2C;

with Ada.Real_Time;                  use Ada.Real_Time;
with System;                         use System;

package Mindstorms.NXT.Ultrasonic_Sensors is
   type Ultrasonic_Sensor (<>) is new Digital_Sensor with private;
   subtype Distance is Integer range 0 .. 255;
   No_Object : constant Distance := 255;

   function New_Ultrasonic_Sensor
     (On_Port : access I2C_Interface) return Ultrasonic_Sensor;

   procedure Get_Distance
     (From_Sensor        : in out Ultrasonic_Sensor;
      Distance_To_Object : out Distance;
      Valid              : out Boolean);

private
   Sensor_Access_Delay : constant Time_Span := Milliseconds (5);

   type Ultrasonic_Sensor is new Digital_Sensor with record
      Release_Time : Time := Time_First;
   end record;

   overriding procedure Read_Data
     (From_Sensor   : in out Ultrasonic_Sensor;
      From_Register : in I2C_Register;
      Data          : in Address;
      Data_Length   : in Positive;
      Is_Successful : out Boolean);
   --  Override the Digital_Sensors implementation since the LEGO sensor needs
   --  a short delay between messages.

   Ultrasonic_Sensor_Address : constant := 2;

   --  Sensor Register Addresses
   Measurement_Byte_0_Register : constant := 16#42#;

end Mindstorms.NXT.Ultrasonic_Sensors;
