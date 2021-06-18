------------------------------------------------------------------------------------------
--                                                                                      --
--                                MINDSTORMS.NXT.BLUETOOTH                              --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with System; use System;

package Mindstorms.NXT.Bluetooth is

   type Bluetooth_Address is private;
   type Device_Information is private;
   type Bluetooth_Device_Class is private;

   type Device_List is array (Natural range <>) of Device_Information;
   subtype Pin_Code_String is String (1 .. 16);
   subtype Bluetooth_String is String (1 .. 16);
   subtype Message_Index is Unsigned_8 range 0 .. 255;
   subtype Message_Length is Message_Index range 0 .. 255;
   subtype Friendly_Device_Name is String (1 .. 16);

   procedure Initialise_Bluetooth;
   procedure Reset_Bluetooth;
   procedure Turn_Bluetooth_Off;

   procedure Set_My_Friendly_Name (Name : in String);
   function My_Friendly_Name return Friendly_Device_Name;

   procedure Set_Discoverable (State : in Boolean);
   procedure Accept_New_Connection
     (Pin                    : in  String;
      BT_Address             : out Bluetooth_Address;
      Connection_Established : out Boolean);

   procedure Open_Data_Stream;

   procedure Exchange_Messages
     (Transmit_Message  : in Address;
      Transmit_Length   : in Natural;
      Receive_Message   : in Address;
      Receive_Length    : in Natural;
      Message_Formatted : in Boolean := False);

   function Datalink_Established return Boolean;

private
   type LAP_Type is mod 2 ** 24 with Size => 24;
   type Bluetooth_Device_Class is mod 2 ** 32;
   subtype Device_Name is String (1 .. 16);

   type Bluetooth_Address is record
      LAP : LAP_Type;
      UAP : Unsigned_8;
      NAP : Unsigned_16;
   end record; -- with Bit_Order => High_Order_First, Scalar_Storage_Order => High_Order_First;

   type Device_Information is record
      Device_Address  : Bluetooth_Address;
      Name            : Device_Name;
      Device_Class    : Bluetooth_Device_Class;
   end record;

   --  Hardware representation for use in messages

   for Device_Information use record
      Device_Address at 0 range 0 .. 47;
      Name           at 7 range 0 .. 127;
      Device_Class   at 23 range 0 .. 31;
   end record;

   for Bluetooth_Address use record
      LAP at 0 range 0 .. 23;
      UAP at 3 range 0 .. 7;
      NAP at 4 range 0 .. 15;
   end record;

end Mindstorms.NXT.Bluetooth;
