------------------------------------------------------------------------------------------
--                                                                                      --
--                           MINDSTORMS.NXT.BLUETOOTH.MESSAGES                          --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Mindstorms.NXT.Bluetooth.Device;   use Mindstorms.NXT.Bluetooth.Device;
with Mindstorms.NXT.Bluetooth.Messages; use Mindstorms.NXT.Bluetooth.Messages;

with Ada.Real_Time;                     use Ada.Real_Time;
with System;                            use System;

package body Mindstorms.NXT.Bluetooth is

   Handle : Connection_Handle;
   type Byte_Array is array (Message_Length range <>) of Unsigned_8;

   function To_Bluetooth_String (S : String) return Bluetooth_String is
      BS : Bluetooth_String;
   begin
      if S'Length > Friendly_Device_Name'Last then
        BS := S (S'First .. S'First + BS'Length - 1);
      else
         BS (BS'First .. BS'First + S'Length - 1) := S;
         for C of BS (BS'First + S'Length .. BS'Last) loop
            C := Character'Val (0);
         end loop;
      end if;
      return BS;
   end To_Bluetooth_String;

   procedure Initialise_Bluetooth is
      Restart_Result : Bluetooth_Status;
   begin
      NXT.Bluetooth.Device.Initialise_Device;
      NXT.Bluetooth.Device.Reset_Device (Restart_Result);
      if Restart_Result /= Running then
         raise Program_Error;
      end if;
   end Initialise_Bluetooth;

   procedure Reset_Bluetooth is
      Restart_Result : Bluetooth_Status;
   begin
      NXT.Bluetooth.Device.Reset_Device (Restart_Result);
      if Restart_Result /= Running then
         raise Program_Error;
      end if;
   end Reset_Bluetooth;

   procedure Turn_Bluetooth_Off is
   begin
      Device.Turn_Bluetooth_Off;
   end Turn_Bluetooth_Off;

   procedure Set_My_Friendly_Name (Name : in String) is
      Friendly_Name_Msg : Command_Message (Set_Friendly_Name);
      Friendly_Msg_Ack  : Command_Message (Set_Friendly_Name_Acknowledged);
   begin
      Friendly_Name_Msg.Friendly_Name := To_Bluetooth_String (Name);

      NXT.Bluetooth.Device.Exchange_Message
        (Transmit_Message => Friendly_Name_Msg'Address,
         Transmit_Length  => Calculate_Message_Length (Friendly_Name_Msg),
         Receive_Message  => Friendly_Msg_Ack'Address,
         Receive_Length   => Calculate_Message_Length (Friendly_Msg_Ack));

      if Friendly_Msg_Ack.Type_Of_Message /= Set_Friendly_Name_Acknowledged then
         raise Program_Error;
      end if;
   end Set_My_Friendly_Name;

   function My_Friendly_Name return Friendly_Device_Name is
      Friendly_Name_Msg : Command_Message (Get_Friendly_Name);
      Friendly_Msg_Rsp  : Command_Message (Get_Friendly_Name_Result);
   begin
      NXT.Bluetooth.Device.Exchange_Message
        (Transmit_Message => Friendly_Name_Msg'Address,
         Transmit_Length  => Calculate_Message_Length (Friendly_Name_Msg),
         Receive_Message  => Friendly_Msg_Rsp'Address,
         Receive_Length   => Calculate_Message_Length (Friendly_Msg_Rsp));

      if Friendly_Msg_Rsp.Type_Of_Message /= Get_Friendly_Name_Result then
         raise Program_Error;
      end if;
      return Friendly_Msg_Rsp.Friendly_Name;
   end My_Friendly_Name;

   procedure Set_Discoverable (State : in Boolean) is
      Send_Message : Command_Message (Set_Discoverable);
      Receive_Message : Command_Message (Set_Discoverable_Acknowledged);
   begin
      Send_Message.Visable := State;

      NXT.Bluetooth.Device.Exchange_Message
        (Transmit_Message => Send_Message'Address,
         Transmit_Length  => Calculate_Message_Length (Send_Message),
         Receive_Message  => Receive_Message'Address,
         Receive_Length   => Calculate_Message_Length (Receive_Message));

      if Receive_Message.Type_Of_Message /= Set_Discoverable_Acknowledged then
         raise Program_Error;
      end if;
   end Set_Discoverable;

   procedure Accept_New_Connection
     (Pin                    : in  String;
      BT_Address             : out Bluetooth_Address;
      Connection_Established : out Boolean)
   is
      Outgoing_Message  : Command_Message;
      Incomming_Message : Command_Message;

      Outgoing_Message_Address : Address := Outgoing_Message'Address;
      Incomming_Message_Length : constant Message_Length := Message_Length (Command_Message'Size / 8);
      --  This constant is needed since any size measurements made through
      --  Calculate_Message_Length will give the size of the current variant,
      --  which is not what is wanted since we do not know what we are receiving.
   begin
      Outgoing_Message := (Type_Of_Message => Open_Port,
                           Length => 3, ZCS20 => 0);

      loop
         NXT.Bluetooth.Device.Exchange_Message
           (Transmit_Message => Outgoing_Message_Address,
            Transmit_Length  => Calculate_Message_Length (Outgoing_Message),
            Receive_Message  => Incomming_Message'Address,
            Receive_Length   => Incomming_Message_Length);

         case Incomming_Message.Type_Of_Message is
            when Bad_Message =>
               raise Program_Error;
--                 Connection_Established := False;
--                 return;

            when Open_Port_Result =>
               Outgoing_Message_Address := Null_Address;
               if not Incomming_Message.Port_Operation_Successful then
                  raise Program_Error;
               end if;

            when Request_Pin_Code =>
               Outgoing_Message_Address := Outgoing_Message'Address;
               Outgoing_Message := (Type_Of_Message    => Pin_Code,
                                    Pin_Device_Address => Incomming_Message.Address,
                                    Pin_Code           => To_Bluetooth_String (Pin),
                                    Length             => 3, ZCS5  => 0);
            when Pin_Code_Acknowledge =>
               Outgoing_Message_Address := Null_Address;

            when Request_Connection =>
               BT_Address := Incomming_Message.Address;

               Outgoing_Message_Address := Outgoing_Message'Address;
               Outgoing_Message := (Type_Of_Message   => Accept_Connection,
                                    Accept_Connection => True,
                                    Length            => 3, ZCS4 => 0);

            when Connect_Result =>
               if Incomming_Message.Successful then
                  Handle := Incomming_Message.Connect_Handle;
                  Connection_Established := True;
               else
                  Connection_Established := False;
               end if;
               return;

            when others =>
               Outgoing_Message_Address := Null_Address;
         end case;
      end loop;
   end Accept_New_Connection;

   procedure Open_Data_Stream is
      Outgoing_Message : Command_Message (Open_Stream) := (Type_Of_Message => Open_Stream,
                                                           Handle          => Handle,
                                                           Length          => 0, ZCS3 => 0);
   begin
      NXT.Bluetooth.Device.Exchange_Message
        (Transmit_Message => Outgoing_Message'Address,
         Transmit_Length  => Calculate_Message_Length (Outgoing_Message),
         Receive_Message  => Null_Address,
         Receive_Length   => 0);

      Enter_Stream_Mode;

      while Current_Bluetooth_Device_Mode = Command_Mode loop
         null;
      end loop;
   end Open_Data_Stream;

   procedure Send_Message (Message : in Address;
                           Length  : in Message_Length) is
      Outgoing_Message  : Byte_Array (1 .. 1 + Length + 2);
      pragma Warnings (Off, "*alignment*");
      Transmit_Array    : Byte_Array (1 .. Length)
        with Address => Message;
      pragma Warnings (On, "*alignment*");

   begin
      Outgoing_Message (1) := Length + 2;
      Outgoing_Message (2 .. Length + 1) := Transmit_Array;

      Mindstorms.NXT.Bluetooth.Device.Exchange_Message
        (Transmit_Message  => Outgoing_Message'Address,
         Transmit_Length   => Outgoing_Message'Size / 8,
         Receive_Message   => Null_Address,
         Receive_Length    => 0);
   end Send_Message;

   procedure Receive_Message (Message : in Address;
                              Length  : in Message_Length) is
      Incomming_Message : Byte_Array (1 .. 1 + Length + 2);
      Incomming_Length : Message_Length;

      pragma Warnings (Off, "*alignment*");
      Receive_Array     : Byte_Array (1 .. Length)
        with Address => Message;
      pragma Warnings (On, "*alignment*");

   begin
      Mindstorms.NXT.Bluetooth.Device.Exchange_Message
        (Transmit_Message  => Null_Address,
         Transmit_Length   => 0,
         Receive_Message   => Incomming_Message'Address,
         Receive_Length    => Incomming_Message'Size / 8);

      Incomming_Length := Incomming_Message (1) - 2;

      if Incomming_Length > Length then
         Incomming_Length := Length;
      end if;

      if Incomming_Length > 0 then
         Receive_Array (1 .. Incomming_Length) := Incomming_Message (2 .. Incomming_Length + 1);
      end if;
   end Receive_Message;

   procedure Exchange_Messages
     (Transmit_Message  : in Address;
      Transmit_Length   : in Natural;
      Receive_Message   : in Address;
      Receive_Length    : in Natural;
      Message_Formatted : in Boolean := False)
   is
      Tx_Length, Rx_Length : Message_Length;
   begin
      if (Transmit_Length > Natural (Message_Length'Last)) or
        (Receive_Length > Natural (Message_Length'Last))
      then
         raise Program_Error;
      end if;

      Tx_Length := Message_Length (Transmit_Length);
      Rx_Length := Message_Length (Receive_Length);

      if Message_Formatted then
         Mindstorms.NXT.Bluetooth.Device.Exchange_Message
           (Transmit_Message  => Transmit_Message,
            Transmit_Length   => Tx_Length,
            Receive_Message   => Receive_Message,
            Receive_Length    => Rx_Length);
         return;
      end if;

      if Transmit_Message = Null_Address then
         Bluetooth.Receive_Message (Receive_Message, Rx_Length);
      elsif Receive_Message = Null_Address then
         Send_Message (Transmit_Message, Tx_Length);
      else
         declare
            Outgoing_Message  : Byte_Array (1 .. 1 + Tx_Length + 2);
            Incomming_Message : Byte_Array (1 .. 1 + Rx_Length + 2);

            Incomming_Length : Message_Length;

            pragma Warnings (Off, "*alignment*");
            Transmit_Array    : Byte_Array (1 .. Tx_Length)
              with Address => Transmit_Message;
            Receive_Array     : Byte_Array (1 .. Rx_Length)
              with Address => Receive_Message;
            pragma Warnings (On, "*alignment*");

         begin
            Outgoing_Message (1) := Tx_Length + 2;
            Outgoing_Message (2 .. Tx_Length + 1) := Transmit_Array;

            Mindstorms.NXT.Bluetooth.Device.Exchange_Message
              (Transmit_Message  => Outgoing_Message'Address,
               Transmit_Length   => Outgoing_Message'Size / 8,
               Receive_Message   => Incomming_Message'Address,
               Receive_Length    => Incomming_Message'Size / 8);

            --  Remove checksum from message length

            Incomming_Length := Incomming_Message (1) - 2;

            if Incomming_Length > Rx_Length then
               Incomming_Length := Rx_Length;
            end if;

            if Incomming_Length > 0 then
               Receive_Array (1 .. Incomming_Length) := Incomming_Message (2 .. Incomming_Length + 1);
            end if;
         end;
      end if;
   end Exchange_Messages;

   function Datalink_Established return Boolean is
      (Current_Bluetooth_Device_Mode = Stream_Mode);
end Mindstorms.NXT.Bluetooth;
