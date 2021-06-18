------------------------------------------------------------------------------------------
--                                                                                      --
--                            MINDSTORMS.NXT.BLUETOOTH.DEVICE                           --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with System; use System;

package Mindstorms.NXT.Bluetooth.Device is

   type Device_Mode is (Command_Mode, Stream_Mode);
   type Bluetooth_Status is (Running, Failed, Uninitialised);

   procedure Initialise_Device;
   procedure Reset_Device (Result : out Bluetooth_Status);
   procedure Turn_Bluetooth_Off;
   procedure Enter_Command_Mode;
   procedure Enter_Stream_Mode;
   function Current_Bluetooth_Device_Mode return Device_Mode;

   procedure Exchange_Message
     (Transmit_Message : in Address;
      Transmit_Length  : in Message_Length;
      Receive_Message  : in Address;
      Receive_Length   : in Message_Length);

private

end Mindstorms.NXT.Bluetooth.Device;
