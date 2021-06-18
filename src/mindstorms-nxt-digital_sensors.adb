------------------------------------------------------------------------------------------
--                                                                                      --
--                            MINDSTORMS.NXT.DIGITAL_SENSORS                            --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

package body Mindstorms.NXT.Digital_Sensors is

   ------------------
   -- Setup_Sensor --
   ------------------

   procedure Setup_Sensor
     (Sensor  : in out Digital_Sensor;
      Port    : access I2C_Interface;
      Address : in I2C_Device_Address) is
   begin
      Sensor.Sensor_Address := Address;
      Sensor.Sensor_Port    := Port;
   end Setup_Sensor;

   ---------------
   -- Read_Data --
   ---------------

   procedure Read_Data
     (From_Sensor   : in out Digital_Sensor;
      From_Register : in I2C_Register;
      Data          : in Address;
      Data_Length   : in Positive;
      Is_Successful : out Boolean) is
   begin
      Read_Data
        (From_Port           => From_Sensor.Sensor_Port.all,
         From_Device         => From_Sensor.Sensor_Address,
         From_Register       => From_Register,
         Length              => Data_Length,
         Data                => Data,
         Operation_Succesful => Is_Successful);
   end Read_Data;

   procedure Write_Data
     (To_Sensor     : in out Digital_Sensor;
      To_Register   : in I2C_Register;
      Data          : in Address;
      Data_Length   : in Positive;
      Is_Successful : out Boolean) is
   begin
      Write_Data
        (To_Port             => To_Sensor.Sensor_Port.all,
         To_Device           => To_Sensor.Sensor_Address,
         To_Register         => To_Register,
         Length              => Data_Length,
         Data                => Data,
         Operation_Succesful => Is_Successful);
   end Write_Data;

end Mindstorms.NXT.Digital_Sensors;
