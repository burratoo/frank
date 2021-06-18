------------------------------------------------------------------------------------------
--                                                                                      --
--                                  MINDSTORMS.NXT.I2C                                  --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Mindstorms.NXT.Ports; use Mindstorms.NXT.Ports;

with System; use System;

package Mindstorms.NXT.I2C is

   type I2C_Mode is (Normal, LEGO);

   type I2C_Interface is limited private;
   task type I2C_Controller
     (Port_Number    : Port_Id;
      Port_Interface : access I2C_Interface;
      Mode           : I2C_Mode) with Storage_Size => 1024, Priority => 25;

   subtype I2C_Register is Unsigned_8;
   subtype I2C_Device_Address is Unsigned_8;

   procedure Read_Data
     (From_Port           : in out I2C_Interface;
      From_Device         : in I2C_Device_Address;
      From_Register       : in I2C_Register;
      Length              : in Positive;
      Data                : in Address;
      Operation_Succesful : out Boolean);

   procedure Write_Data
     (To_Port             : in out I2C_Interface;
      To_Device           : in I2C_Device_Address;
      To_Register         : in I2C_Register;
      Length              : in Positive;
      Data                : in Address;
      Operation_Succesful : out Boolean);

private

   type I2C_Operation is (Write, Read);

   type I2C_Transaction is record
      Device   : I2C_Device_Address;
      Register : I2C_Register;
      Length   : Positive;
      Data     : Address;
      Kind     : I2C_Operation;
   end record;

   protected type I2C_Interface is
      procedure New_Transaction (T : I2C_Transaction);
      function Get_Transaction_Details return I2C_Transaction;
      entry Wait (Is_Successful : out Boolean);
      procedure Transaction_Finished (Successfully : in Boolean);
   private
      Release_Task        : Boolean := False;
      Current_Transaction : I2C_Transaction;
      Transaction_Success : Boolean;
   end I2C_Interface;

end Mindstorms.NXT.I2C;
