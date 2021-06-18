------------------------------------------------------------------------------------------
--                                                                                      --
--                           MINDSTORMS.NXT.ULTRASONIC_SENSORS                          --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Interfaces; use Interfaces;

package body Mindstorms.NXT.Ultrasonic_Sensors is

   function New_Ultrasonic_Sensor
     (On_Port : access I2C_Interface) return Ultrasonic_Sensor is
   begin
      return New_Sensor : Ultrasonic_Sensor do
         Setup_Sensor (Sensor  => New_Sensor,
                       Port    => On_Port,
                       Address => Ultrasonic_Sensor_Address);
      end return;
   end New_Ultrasonic_Sensor;

   procedure Get_Distance
     (From_Sensor        : in out Ultrasonic_Sensor;
      Distance_To_Object : out Distance;
      Valid              : out Boolean)
   is
      D : Unsigned_8;
      --  Since the distance measurement is only 1 byte big
   begin
      Read_Data
        (From_Sensor   => From_Sensor,
         From_Register => Measurement_Byte_0_Register,
         Data          => D'Address,
         Data_Length   => 1,
         Is_Successful => Valid);
      Distance_To_Object := Distance (D);
   end Get_Distance;

   overriding procedure Read_Data
     (From_Sensor   : in out Ultrasonic_Sensor;
      From_Register : in I2C_Register;
      Data          : in Address;
      Data_Length   : in Positive;
      Is_Successful : out Boolean) is
   begin
      delay until From_Sensor.Release_Time;
      From_Sensor.Release_Time := Clock + Sensor_Access_Delay;

      Read_Data (From_Sensor   => Digital_Sensor (From_Sensor),
                 From_Register => From_Register,
                 Data          => Data,
                 Data_Length   => Data_Length,
                 Is_Successful => Is_Successful);
   end Read_Data;

end Mindstorms.NXT.Ultrasonic_Sensors;
