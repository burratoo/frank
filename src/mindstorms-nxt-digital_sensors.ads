------------------------------------------------------------------------------------------
--                                                                                      --
--                            MINDSTORMS.NXT.DIGITAL_SENSORS                            --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Mindstorms.NXT.I2C; use Mindstorms.NXT.I2C;

with System; use System;

package Mindstorms.NXT.Digital_Sensors is
   type Digital_Sensor is abstract tagged limited private;

   procedure Setup_Sensor
     (Sensor  : in out Digital_Sensor;
      Port    : access I2C_Interface;
      Address : in I2C_Device_Address);

   procedure Read_Data
     (From_Sensor   : in out Digital_Sensor;
      From_Register : in I2C_Register;
      Data          : in Address;
      Data_Length   : in Positive;
      Is_Successful : out Boolean);

   procedure Write_Data
     (To_Sensor     : in out Digital_Sensor;
      To_Register   : in I2C_Register;
      Data          : in Address;
      Data_Length   : in Positive;
      Is_Successful : out Boolean);

private
   type Digital_Sensor is abstract tagged limited record
      Sensor_Address : I2C_Device_Address;
      Sensor_Port    : access I2C_Interface;
   end record;

end Mindstorms.NXT.Digital_Sensors;
