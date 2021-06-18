------------------------------------------------------------------------------------------
--                                                                                      --
--                           MINDSTORMS.NXT.BLUETOOTH.MESSAGES                          --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Ada.Unchecked_Conversion;

with Interfaces; use Interfaces;
with System;     use System;

package Mindstorms.NXT.Bluetooth.Messages is
   type Message_Type is
     (Begin_Inquiry,
      Cancel_Inquiry,
      Connect,
      Open_Port,
      Lookup_Name,
      Add_Device,
      Remove_Device,
      Dump_List,
      Close_Connection,
      Accept_Connection,
      Pin_Code,
      Open_Stream,
      Start_Heartbeat,
      Heartbeat,
      Inquiry_Running,
      Inquiry_Result,
      Inquiry_Stopped,
      Lookup_Name_Result,
      Lookup_Name_Failure,
      Connect_Result,
      Reset_Indication,
      Request_Pin_Code,
      Request_Connection,
      List_Result,
      List_Item,
      List_Dump_Stopped,
      Close_Connection_Result,
      Open_Port_Result,
      Set_Discoverable,
      Close_Port,
      Close_Port_Result,
      Pin_Code_Acknowledge,
      Set_Discoverable_Acknowledged,
      Set_Friendly_Name,
      Set_Friendly_Name_Acknowledged,
      Get_Link_Quality,
      Link_Quality_Result,
      Set_Factory_Settings,
      Set_Factory_Settings_Acknowledge,
      Get_Local_Address,
      Get_Local_Address_Result,
      Get_Friendly_Name,
      Get_Discoverable,
      Get_Port_Open,
      Get_Friendly_Name_Result,
      Get_Discoverable_Result,
      Get_Port_Open_Result,
      Get_Version,
      Get_Version_Result,
      Get_Brick_Status_Byte_Result,
      Set_Brick_Status_Byte_Result,
      Get_Brick_Status_Byte,
      Set_Brick_Status_Byte,
      Get_Operating_Mode,
      Set_Operating_Mode,
      Operating_Mode_Result,
      Get_Connection_Status,
      Get_Connection_Status_Result,
      Goto_DFU_Mode,
      Bad_Message,
      No_Message) with Size => 8;

   type Endpoint_Id is range 0 .. 10;
   type Inquiry_Timeout_Type is range 16#01# .. 16#30#;

   type Connection_Handle is mod 7;
   type Operating_Mode is (Stream_Breaking_Mode, Do_Not_Break_Streaming_Mode);

   type List_Result_Options is (Success, Could_Not_Save, Store_Is_Full, Entry_Removed,
                        Unkown_Address);

   type Disconnect_Status is (Successful, Link_Loss, No_Service_Level_Connection,
                              Timeout, Other);

   type Link_Quality is range 0 .. 16#FF#;

   type Connection_Status is (Ready, Initialised, Connected, Connecting, Stream_Open);
   type Set_Of_Connection_Status is array (Connection_Handle) of Connection_Status;

   type Checksum_Place_Holder is array (0 .. 1) of Unsigned_8;

   type Command_Message (Type_Of_Message : Message_Type := Begin_Inquiry) is record
      Length : Message_Length;

      --  ZCSx : Unsigned_16;
      --  Not used directly, but use instead to pad out the record to provide
      --  space for the message checksum which comes immediately after all the
      --  fields, which varies between the type's variants.

      case Type_Of_Message is
         when Begin_Inquiry =>
            Max_Devices     : Endpoint_Id;
            Inquiry_Timeout : Inquiry_Timeout_Type;
            Inquiry_Class   : Bluetooth_Device_Class;
            ZCS0            : Unsigned_16;

         when Connect | Lookup_Name | Remove_Device | Lookup_Name_Failure |
              Request_Pin_Code | Request_Connection | Get_Local_Address_Result =>
            Address         : Bluetooth_Address;
            ZCS1            : Unsigned_16;

         when Add_Device | Inquiry_Result | Lookup_Name_Result | List_Item =>
            Device : Device_Information;
            ZCS2   : Unsigned_16;

         when Close_Connection | Open_Stream | Close_Port | Get_Link_Quality =>
            Handle : Connection_Handle;
            ZCS3   : Unsigned_16;

         when Accept_Connection =>
            Accept_Connection : Boolean;
            ZCS4   : Unsigned_16;

         when Pin_Code =>
            Pin_Device_Address : Bluetooth_Address;
            Pin_Code           : Pin_Code_String;
            ZCS5               : Unsigned_16;

         when Set_Discoverable =>
            Visable : Boolean;
            ZCS6    : Unsigned_16;

         when Set_Friendly_Name | Get_Friendly_Name_Result  =>
            Friendly_Name : Friendly_Device_Name;
            ZCS7          : Unsigned_16;

         when Set_Brick_Status_Byte | Get_Brick_Status_Byte_Result =>
            Status_Byte_1 : Unsigned_8;
            Status_Byte_2 : Unsigned_8;
            ZCS8          : Unsigned_16;

         when Set_Operating_Mode | Operating_Mode_Result =>
            Mode : Operating_Mode;
            ZCS9 : Unsigned_16;
         when Connect_Result =>
            Successful     : Boolean;
            Connect_Handle : Connection_Handle;
            ZCS10           : Unsigned_16;

         when List_Result | Set_Brick_Status_Byte_Result =>
            Status : List_Result_Options;
            ZCS11  : Unsigned_16;

         when Close_Connection_Result =>
            Close_Result : Disconnect_Status;
            ZCS12        : Unsigned_16;

         when Open_Port_Result | Close_Port_Result =>
            Port_Operation_Successful     : Boolean;
            Port_Handle                   : Connection_Handle;
            Written_To_Persistent_Storage : Boolean;
            ZCS13                         : Unsigned_16;

         when Set_Discoverable_Acknowledged | Set_Friendly_Name_Acknowledged =>
            Success : Boolean;
            ZCS14   : Unsigned_16;

         when Link_Quality_Result =>
            Quality         : Link_Quality;
            ZCS15           : Unsigned_16;

         when Get_Discoverable_Result =>
            Is_Discoverable : Boolean;
            ZCS16           : Unsigned_16;

         when Get_Port_Open_Result =>
            Port_Open       : Boolean;
            ZCS17           : Unsigned_16;

         when Get_Version_Result =>
            Major_Version   : Unsigned_8;
            Minor_Version   : Unsigned_8;
            ZCS18           : Unsigned_16;

         when Get_Connection_Status_Result =>
            Connection_Statuses : Set_Of_Connection_Status;
            ZCS19               : Unsigned_16;
         when others =>
            ZCS20 : Unsigned_16;
      end case;
   end record with Alignment => 1;

   function Calculate_Message_Length
     (Message : in Command_Message) return Message_Length;

   type Raw_Message is array (Message_Index range <>) of Unsigned_8;

   for List_Result_Options use
     (Success        => 16#50#,
      Could_Not_Save => 16#51#,
      Store_Is_Full  => 16#52#,
      Entry_Removed  => 16#53#,
      Unkown_Address => 16#54#);

   for Command_Message use record
      Length          at 0 range 0 .. 7;
      Type_Of_Message at 1 range 0 .. 7;

      --  Begin Inquiry
      Max_Devices     at 2 range 0 .. 7;
      Inquiry_Timeout at 3 range 0 .. 8;
      Inquiry_Class   at 5 range 0 .. 31;

      --  Connect, Lookup_Name, Remove_Device, Lookup_Name_Failure,
      --  Request_Pin_Code, Request_Connection, Get_Local_Address_Result
      Address at 2 range 0 .. 47;

      --  Add Device, Inquiry_Result, Lookup_Name_Result, List_Item
      Device at 2 range 0 .. 215;

      --  Close_Connection, Open_Stream, Close_Port, Get_Link_Quality
      Handle at 2 range 0 .. 7;

      --  Accept_Connection
      Accept_Connection at 2 range 0 .. 7;

      --  Pin_Code
      Pin_Device_Address at 2 range 0 .. 47;
      Pin_Code           at 9 range 0 .. 127;
      ZCS5               at 25 range 0 .. 15;

      --  Set_Discoverable
      Visable at 2 range 0 .. 7;

      --  Set_Friendly_Name, Get_Friendly_Name_Result
      Friendly_Name at 2 range 0 .. 127;

      --  Set_Brick_Status_Byte, Get_Brick_Status_Byte_Result
      Status_Byte_1 at 2 range 0 .. 7;
      Status_Byte_2 at 3 range 0 .. 7;

      --  Set_Operating_Mode, Operating_Mode_Result
      Mode at 2 range 0 .. 7;

      --  Conect_Result
      Successful     at 2 range 0 .. 7;
      Connect_Handle at 3 range 0 .. 7;

      --  List_Status, Set_Brick_Status_Byte_Result
      Status at 2 range 0 .. 7;

      --  Close_Connection_Result
      Close_Result at 2 range 0 .. 7;

      -- Port_Open_Result, Close_Port_Result
      Port_Operation_Successful     at 2 range 0 .. 7;
      Port_Handle                   at 3 range 0 .. 7;
      Written_To_Persistent_Storage at 4 range 0 .. 7;

      -- Set_Discoverable_Acknowledged, Set_Friendly_Name_Acknowledged =>
      Success at 2 range 0 .. 7;

      --  Link_Quality_Result
      Quality at 2 range 0 .. 7;

      --  Get_Discoverable_Result
      Is_Discoverable at 2 range 0 .. 7;

      --  Get_Port_Open_Result
      Port_Open at 2 range 0 .. 7;

      --  Get_Version_Result
      Major_Version at 2 range 0 .. 7;
      Minor_Version at 3 range 0 .. 7;

      --  Get_Connection_Status_Result
      Connection_Statuses at 2 range 0 .. 55;
   end record;

   function To_Unsigned_8 is new Ada.Unchecked_Conversion (Message_Type, Unsigned_8);

   function Calculate_Message_Length
     (Message : in Command_Message) return Message_Length is (Message_Length (Message'Size / 8));
end Mindstorms.NXT.Bluetooth.Messages;
