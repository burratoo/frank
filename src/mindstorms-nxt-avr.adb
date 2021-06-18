------------------------------------------------------------------------------------------
--                                                                                      --
--                                  MINDSTORMS.NXT.AVR                                  --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Atmel.AT91SAM7S.TWI; use Atmel.AT91SAM7S.TWI;

package body Mindstorms.NXT.AVR is

   AVR_TWI_Adress : constant TWI_Device_Address := 1;
   --  The AVR's TWI address

   AVR_Internal_Address_Size : constant := 0;
   --  The AVR has no internal device address

   function Verify_AVR_Message (Message : Data_For_ARM) return Boolean;

   function Verify_AVR_Message (Message : Data_For_ARM) return Boolean is
      type Message_As_Bytes is array (1 .. Data_For_ARM'Size / 8) of Unsigned_8;

      Message_Bytes : Message_As_Bytes with Address => Message'Address;
      Checksum      : Unsigned_8 := 0;
   begin
      for Byte of Message_Bytes loop
         Checksum := Checksum + Byte;
      end loop;

      return (Checksum = 16#FF#);
   end Verify_AVR_Message;

   protected body AVR_Gateway is
      function Battery_Level return AVR_AD_Value is
      begin
         return Battery_State.Battery_Level;
      end Battery_Level;

      function Button_States return Set_Of_Button_States is
      begin
         return State_Of_Buttons;
      end Button_States;

      function Sensor_Value (Sensor : Sensor_Id) return Sensor_Value_Type is
      begin
         return Sensor_Values (Sensor);
      end Sensor_Value;

      function Sensor_Readings return Sensors_Values is
      begin
         return Sensor_Values;
      end Sensor_Readings;

      procedure Set_All_Motors (Speeds : Motor_Speeds_Type; Modes : Output_Mode_Set) is
      begin
         Motor_Speeds := Speeds;
         Output_Mode  := Modes;
      end Set_All_Motors;

      procedure Set_Motor (Motor : Motor_Id; Speed : Motor_Speed_Type; Mode : Output_Mode_Options) is
      begin
         Motor_Speeds (Motor) := Speed;
         Output_Mode (Motor)  := Mode;
      end Set_Motor;

      procedure Set_Power_State (Power    : Power_Options;
                                 PWM_Mode : Unsigned_8) is
      begin
         AVR_Gateway.Power := Power;
         AVR_Gateway.PWM_Frequency := PWM_Mode;
      end Set_Power_State;

      function Retrieve_Data_For_AVR return Data_For_AVR is
         Message : Data_For_AVR := (Power         => Power,
                                    PWM_Frequency => PWM_Frequency,
                                    PWM_Values    => Motor_Speeds,
                                    Empty_Byte    => 0,
                                    Output_Mode   => Output_Mode,
                                    Sensor_Supply => Sensor_Supply,
                                    Checksum      => 0);

         type Message_As_Bytes is array (1 .. Data_For_AVR'Size / 8) of Unsigned_8;
         Message_Bytes : Message_As_Bytes with Address => Message'Address;
      begin
         --  Calculate message checksum
         for Byte of Message_Bytes (1 .. Message_Bytes'Last - 1) loop
            Message.Checksum := Message.Checksum + Byte;
         end loop;
         Message.Checksum := not Message.Checksum;
         return Message;
      end Retrieve_Data_For_AVR;

      procedure Store_Date_From_AVR (Data : Data_For_ARM) is
         BV : Unsigned_16 := Data.Button_Values;
         Current_Button_State : Set_Of_Button_States := (others => Open);

      begin
         for J in Data.AD_Values'Range loop
            Sensor_Values (J) := Sensor_Value_Type (Data.AD_Values (J));
         end loop;

         if BV > Select_Button_Value then
            Current_Button_State (Select_Button) := Closed;
            BV := BV - Select_Button_Value;
         end if;

         if BV > Back_Button_Value then
            Current_Button_State (Back_Button) := Closed;
         elsif BV > Right_Button_Value then
            Current_Button_State (Right_Button) := Closed;
         elsif BV > Left_Button_Value then
            Current_Button_State (Left_Button) := Closed;
         end if;

         for B in Current_Button_State'Range loop
            case Current_Button_State (B) is
               when Open =>
                  if Deglitcher (B) > 0 then
                     Deglitcher (B) := Deglitcher (B) - 1;
                  end if;

               when Closed =>
                  if Deglitcher (B) < 10 then
                     Deglitcher (B) := Deglitcher (B) + 1;
                  end if;
            end case;

            if State_Of_Buttons (B) = Closed and then Deglitcher (B) < 3 then
               State_Of_Buttons (B) := Open;
            elsif State_Of_Buttons (B) = Open and then Deglitcher (B) > 7 then
               State_Of_Buttons (B) := Closed;
            end if;
         end loop;


         Battery_State := Data.Battery_State;
      end Store_Date_From_AVR;

      function Motor_Speed (For_Motor : Motor_Id) return Motor_Speed_Type is
        (Motor_Speeds (For_Motor));
   end AVR_Gateway;

   task body AVR_Communicator is
      type Communication_Direction is (Sending, Receiving);

      Comms        : Communication_Direction := Receiving;
      Release_Time : Time;

      Message_To_AVR   : Data_For_AVR;
      Message_From_AVR : Data_For_ARM;
   begin
--        delay until Clock + Initialisation_Delay;

      --  Set TWI interface for link speed of 380kHz, using a master clock speed
      --  of 48MHz.

      Atmel.AT91SAM7S.TWI.Initialise_Interface
        (Clock_Divider      => 5,
         Clock_Low_Divider  => 15,
         Clock_High_Divider => 15);

      --  Initialisation Code
      Send_Message (To               => AVR_TWI_Adress,
                    Internal_Address => No_Internal_Address,
                    Address_Size     => AVR_Internal_Address_Size,
                    Message          => AVR_Init_String'Address,
                    Message_Length   => AVR_Init_String'Size / 8);

      --  Task loop: the AVR communication task alternates each microsecond
      --  between sending a message to the AVR and receiving a message from it.

      delay until Clock + AVR_Initialise_Delay;
      loop
         case Comms is
            when Sending =>
               Message_To_AVR := AVR_Gateway.Retrieve_Data_For_AVR;
               Send_Message (To               => AVR_TWI_Adress,
                             Internal_Address => No_Internal_Address,
                             Address_Size     => AVR_Internal_Address_Size,
                             Message          => Message_To_AVR'Address,
                             Message_Length   => Message_To_AVR'Size / 8);
               Comms := Receiving;

            when Receiving =>
               Receive_Message (From             => AVR_TWI_Adress,
                                Internal_Address => No_Internal_Address,
                                Address_Size     => AVR_Internal_Address_Size,
                                Message          => Message_From_AVR'Address,
                                Message_Length   => Message_From_AVR'Size / 8);
               if Verify_AVR_Message (Message => Message_From_AVR) then
                  AVR_Gateway.Store_Date_From_AVR (Data => Message_From_AVR);
               end if;

               Comms := Sending;
         end case;

         Release_Time := Clock + IO_Gap_Delay;
         delay until Release_Time;

      end loop;
   end AVR_Communicator;
end Mindstorms.NXT.AVR;
