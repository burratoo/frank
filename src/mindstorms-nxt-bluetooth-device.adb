------------------------------------------------------------------------------------------
--                                                                                      --
--                            MINDSTORMS.NXT.BLUETOOTH.DEVICE                           --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Atmel.AT91SAM7S;                   use Atmel.AT91SAM7S;
with Atmel.AT91SAM7S.ADC;               use Atmel.AT91SAM7S.ADC;
with Atmel.AT91SAM7S.PIO;               use Atmel.AT91SAM7S.PIO;
with Atmel.AT91SAM7S.TC;                use Atmel.AT91SAM7S.TC;
with Atmel.AT91SAM7S.USART;             use Atmel.AT91SAM7S.USART;

with Mindstorms.NXT.Bluetooth.Messages; use Mindstorms.NXT.Bluetooth.Messages;

with Ada.Real_Time;                     use Ada.Real_Time;
with System.Storage_Elements;           use System.Storage_Elements;

package body Mindstorms.NXT.Bluetooth.Device is

   Bluetooth_Reset_Pin : constant := 11;
   ARM_To_Bluetooth_Comman_Pin : constant := 27;

   Bluetooth_To_ARM_Command : constant ADC_Channel_Id := 6;
   USART_Interface          : constant := 1;

   Message_Length_Index : constant := 1;

   USART_Baud_Rate : constant := 460_800;

   procedure Initialise_Device is
   begin

      --  Initialise USART1 since this package is the only one that can use it

      USART.Initialise_Interface
        (Interface_Id         => USART_Interface,
         USART_Settings       =>
           (USART_Mode                         => Hardware_Handshaking,
            Clock_Selection                    => Master_Clock,
            Character_Length                   => 8,
            Synchronous_Mode_Select            => Asynchronous_Mode,
            Parity                             => None,
            Number_Of_Stop_Bits                => One,
            Channel_Mode                       => Normal,
            Order_Of_Bits                      => Low_Order_First,
            Nine_Bit_Character_Length          => False,
            Clock_Output_Select                => Not_Driven,
            Oversampling_Mode                  => O8bits,
            Inhibit_Non_Acknowledge            => False,
            Disable_Successive_Non_Acknowledge => False,
            Max_Iterations                     => 0,
            Infrared_Receive_Line_Filter       => Disable),
         Receiver_Timeout => 1000,
         Baud_Rate =>
           (Clock_Divider   => Unsigned_16 (Clock_Frequency / 8 / USART_Baud_Rate),
            Fractional_Part => Fractional_Part_Type (((Clock_Frequency / 8)
              - ((Clock_Frequency / 8 / USART_Baud_Rate) * USART_Baud_Rate))
              / (USART_Baud_Rate + 4) / 8)));


      --  Frustratingly, the digital BC4_CMD signal is connected to one of the
      --  SAM7S's analog-only inputs (probably due to a lack of digital inputs).
      --  Thus the need to use the ADC to sample the value of the single. To
      --  make things easier, a Timer Counter is set up to automate the sampling
      --  process.

      --  Check to ensure that dependent interfaces are initialised. These are
      --  initialised outside the package since they may be shared by other
      --  services.

      if not (ADC.Interface_Is_Ready and TC.Interface_Is_Ready) then
         raise Program_Error;
      end if;


      --  Initialise TC Channel 1

      TC.Initialise_Channel
        (Channel  => 1,
         Settings =>
           (Clock_Selection           => Timer_Clock1,
            Counter_Increment_On_Edge => Rising,
            Burst_Signal_Selection    => None,
            Counter_Mode              => Waveform_Mode,
            Counter_Clock_Stopped_When_RegC_Compare  => False,
            Counter_Clock_Disabled_When_RegC_Compare => False,
            External_Event_Edge_Selection            => None,
            External_Event_Signal_Selection          => TIOB,
            External_Event_Trigger                   => Disable,
            Waveform_Selection                       => UP_Mode_With_Automatic_Tigger_On_Register_C_Compare,
            Register_A_Compare_Effect_On_TIOA        => Set,
            Register_C_Compare_Effect_On_TIOA        => Clear,
            Software_Trigger_Effect_On_TIOA          => Set,
            others                                   => None),
         Register_A => Unsigned_16 ((Clock_Frequency / 2) / 4000),
         Register_B => 0,
         Register_C => Unsigned_16 ((Clock_Frequency / 2) / 2000));

      TC.Start_Timer (Channel => 1);

      --  Enable ADC Channel 6

      ADC.Enable_Channel (Channel => Bluetooth_To_ARM_Command);

      --  Setup External Pins

      PIO.PIO_Enable_Register :=
        (Bluetooth_Reset_Pin         => Enable,
         ARM_To_Bluetooth_Comman_Pin => Enable,
         others                      => No_Change);

      PIO.Pull_Up_Disable_Register :=
        (ARM_To_Bluetooth_Comman_Pin => Disable,
         others                      => No_Change);

      PIO.Set_Output_Data_Register :=
        (Bluetooth_Reset_Pin => Enable,
         others              => No_Change);

      PIO.Clear_Output_Data_Register :=
        (ARM_To_Bluetooth_Comman_Pin => Enable,
         others                      => No_Change);

      PIO.Output_Enable_Register :=
        (Bluetooth_Reset_Pin         => Enable,
         ARM_To_Bluetooth_Comman_Pin => Enable,
         others                      => No_Change);
   end Initialise_Device;

   procedure Reset_Device (Result : out Bluetooth_Status) is
      Result_Message : Command_Message (Reset_Indication);
   begin
      Result := Failed;

      --  Check that the USART has been initialised
      if not USART.Interface_Is_Ready (Interface_Id => 1) then
         Result := Uninitialised;
         return;
      end if;

      Enter_Command_Mode;

      --  Reset Bluecore by pulling down reset line for 100 ms.

      PIO.Clear_Output_Data_Register :=
        (Bluetooth_Reset_Pin => Enable,
         others              => No_Change);

      delay until Clock + Milliseconds (100);

      PIO.Set_Output_Data_Register :=
        (Bluetooth_Reset_Pin => Enable,
         others              => No_Change);

      --  Wait for the reset response from the bluecore.

      for J in reverse 0 .. 100 loop
         Exchange_Message (Transmit_Message => Null_Address,
                           Transmit_Length  => Message_Length'First,
                           Receive_Message  => Result_Message'Address,
                           Receive_Length   => Calculate_Message_Length (Result_Message));
         if Result_Message.Type_Of_Message = Reset_Indication then
            Result := Running;
            exit;
         end if;
      end loop;

   end Reset_Device;

   procedure Turn_Bluetooth_Off is
   begin
      PIO.Clear_Output_Data_Register :=
        (Bluetooth_Reset_Pin => Enable,
         others              => No_Change);
      USART.Reset_Interface (USART_Interface);
   end Turn_Bluetooth_Off;

   procedure Enter_Command_Mode is
   begin
      PIO.Clear_Output_Data_Register :=
        (ARM_To_Bluetooth_Comman_Pin => Enable,
         others                      => No_Change);
   end Enter_Command_Mode;

   procedure Enter_Stream_Mode is
   begin
      PIO.Set_Output_Data_Register :=
        (ARM_To_Bluetooth_Comman_Pin => Enable,
         others                      => No_Change);
   end Enter_Stream_Mode;

   function Current_Bluetooth_Device_Mode return Device_Mode is
   begin
      return (if ADC.Read_Channel (Bluetooth_To_ARM_Command) > 16#80# then
                 Stream_Mode else Command_Mode);
   end Current_Bluetooth_Device_Mode;

   pragma Warnings (Off, "*alignment*");

   procedure Exchange_Message
     (Transmit_Message : in Address;
      Transmit_Length  : in Message_Length;
      Receive_Message  : in Address;
      Receive_Length   : in Message_Length) is
   begin
      if Transmit_Message /= Null_Address then
         --  Calculate transmit checksum

         declare
            Raw_Transmit_Message : Raw_Message (1 .. Transmit_Length)
              with Address => Transmit_Message;
            Checksum     : Unsigned_16 := 0;
         begin
            for Byte of Raw_Transmit_Message (2 .. Transmit_Length - 2) loop
               Checksum := Checksum - Unsigned_16 (Byte);
            end loop;

            --  Store checksum with high byte first

            Raw_Transmit_Message (Transmit_Length - 1) :=
              Unsigned_8 (Shift_Right (Value => Checksum, Amount => 8) and 16#FF#);
            Raw_Transmit_Message (Transmit_Length) := Unsigned_8 (Checksum and 16#FF#);

            --  Update length field, noting that this field does not include
            --  itself.

            Raw_Transmit_Message (Message_Length_Index) := Transmit_Length - 1;
         end;
      end if;

      --  Clear the first byte of receive message if such a message exists. This
      --  indicates whether we have received a message or if a timeout waiting
      --  for a message occured.

      if Receive_Message /= Null_Address and Receive_Length > 0 then
         declare
            Receive_Message_Length : Unsigned_8 with Address => Receive_Message;
         begin
            Receive_Message_Length := 0;
         end;
      end if;

      --  TEMP: Place dummy information in receive message
--        if Receive_Message /= Null_Address and Receive_Length > 0 then
--           declare
--              RM : array (1 .. Receive_Length) of Unsigned_8 with Address => Receive_Message;
--           begin
--              for Byte of RM loop
--                 Byte := 1;
--                 end loop;
--           end;
--        end if;
--
      --  In the first part of the exchange, send the transmit messsage and wait
      --  for the first recieve byte to be received. This byte will have the
      --  length of the transfer. Note that if Receive_Message is null, no
      --  message will be received.

      USART.Exchange_Data
        (Using_Interface        => USART_Interface,
         Send_Message           => Transmit_Message,
         Send_Message_Length    => Unsigned_16 (Transmit_Length),
         Recieve_Message        => Receive_Message,
         Recieve_Message_Length => 1);

      if Receive_Message /= Null_Address then
         declare
            Raw_Receive_Message  : Raw_Message (1 .. Receive_Length)
              with Address => Receive_Message;
            Wire_Message_Length  : Unsigned_8 := Raw_Receive_Message (Message_Length_Index);
            Checksum             : Unsigned_16 := 0;
         begin
            --  The received message will have only one byte which should equate
            --  to the length of the message being sent

            if Wire_Message_Length = 0 then
               Raw_Receive_Message (2) := To_Unsigned_8 (No_Message);

            elsif Wire_Message_Length > Receive_Length then
               Raw_Receive_Message := (1      => 0,
                                       2      => To_Unsigned_8 (Bad_Message),
                                       others => <>);
               return;
            end if;

            --  Read in the rest of the message now the length of the message is known

--              loop
               USART.Exchange_Data
                 (Using_Interface        => USART_Interface,
                  Send_Message           => Null_Address,
                  Send_Message_Length    => 0,
                  Recieve_Message        => Receive_Message + 1,
                  Recieve_Message_Length => Unsigned_16 (Wire_Message_Length));
--                 exit when Receive_Bytes_Remaining (USART_Interface) = 0;
--              end loop;

            --  Check recieved message checksum; set the first field (the
            --  message's length field) to zero if the message fails these tests
            --  and the second field to Bad_Message (16#FF#). Note that the
            --  message length excludes the first byte.

            --  Extract checksum with high byte first

            Checksum :=
              Shift_Left (Unsigned_16 (Raw_Receive_Message (Wire_Message_Length)), Amount => 8);
            Checksum := Checksum +
              Unsigned_16 (Raw_Receive_Message (Wire_Message_Length + 1));


            for Byte of Raw_Receive_Message (1 .. Wire_Message_Length - 1) loop
               Checksum := Checksum + Unsigned_16 (Byte);
            end loop;

            if Checksum /= 0 then
               Raw_Receive_Message := (1      => 0,
                                       2      => To_Unsigned_8 (Bad_Message),
                                       others => <>);
            end if;
         end;
      end if;
   end Exchange_Message;
   pragma Warnings (On, "*alignment*");

end Mindstorms.NXT.Bluetooth.Device;
