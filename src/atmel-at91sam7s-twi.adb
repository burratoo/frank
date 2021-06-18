------------------------------------------------------------------------------------------
--                                                                                      --
--                                 ATMEL.AT91SAM7S.TWI                                  --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Ada.Unchecked_Conversion;

with Atmel.AT91SAM7S.AIC;
with Atmel.AT91SAM7S.PIO;
with Atmel.AT91SAM7S.PMC;

with System.Address_To_Access_Conversions;
with System.Storage_Elements;              use System.Storage_Elements;

package body Atmel.AT91SAM7S.TWI is

   package Access_Buffer_Address is new
     System.Address_To_Access_Conversions (Unsigned_8);
   use Access_Buffer_Address;

   ---------
   -- and --
   ---------

   function "and" (L, R : Status_Register_Type) return Status_Register_Type is
      function To_Register is new Ada.Unchecked_Conversion
        (Source => Status_Register_Type,
         Target => Register);
      function To_Status_Type is new Ada.Unchecked_Conversion
        (Source => Register,
         Target => Status_Register_Type);
   begin
      return To_Status_Type (To_Register (L) and To_Register (R));
   end "and";

   --------------------------
   -- Initialise_Interface --
   --------------------------

   procedure Initialise_Interface
     (Clock_Divider      : Clock_Divider_Type;
      Clock_Low_Divider  : Unsigned_8;
      Clock_High_Divider : Unsigned_8) is
   begin
      Two_Wire_Interface.Initialise_Interface
        (Clock_Divider      => Clock_Divider,
         Clock_Low_Divider  => Clock_Low_Divider,
         Clock_High_Divider => Clock_High_Divider);
   end Initialise_Interface;

   ---------------------
   -- Receive_Message --
   ---------------------

   procedure Receive_Message
     (From             : in TWI_Device_Address;
      Internal_Address : in TWI_Internal_Address;
      Address_Size     : in Internal_Device_Address_Range;
      Message          : in Address;
      Message_Length   : in Natural) is
   begin
      Two_Wire_Interface.Transmit_Data
        (With_Device      => From,
         Internal_Address => Internal_Address,
         Address_Size     => Address_Size,
         Data             => Message,
         Data_Length      => Message_Length,
         Direction        => Read);
      Two_Wire_Interface.Wait_For_Transmission;
   end Receive_Message;

   ------------------
   -- Send_Message --
   ------------------

   procedure Send_Message
     (To               : in TWI_Device_Address;
      Internal_Address : in TWI_Internal_Address;
      Address_Size     : in Internal_Device_Address_Range;
      Message          : in Address;
      Message_Length   : in Natural) is
   begin
      Two_Wire_Interface.Transmit_Data
        (With_Device      => To,
         Internal_Address => Internal_Address,
         Address_Size     => Address_Size,
         Data             => Message,
         Data_Length      => Message_Length,
         Direction        => Write);
      Two_Wire_Interface.Wait_For_Transmission;
   end Send_Message;

   ------------------------
   -- Two_Wire_Interface --
   ------------------------

   protected body Two_Wire_Interface is

      --------------------------
      -- Initialise_Interface --
      --------------------------

      procedure Initialise_Interface
        (Clock_Divider      : Clock_Divider_Type;
         Clock_Low_Divider  : Unsigned_8;
         Clock_High_Divider : Unsigned_8) is
      begin
         AIC.Interrupt_Disable_Command_Register.Interrupt :=
           (P_TWI  => Disable,
            others => No_Change);
         Interrupt_Disable_Register := (others => Disable);

         --  Turn on TWI clocks

         PMC.Peripheral_Clock_Enable_Register :=
           (P_TWI  => Enable,
            P_PIOA => Enable,
            others => No_Change);

         --  Set up pins

         PIO.Multi_Driver_Enable_Register :=
           (IO_Line_A_TWI_Data  => Enable,
            IO_Line_A_TWI_Clock => Enable,
            others              => No_Change);

         PIO.PIO_Disable_Register :=
           (IO_Line_A_TWI_Data  => Disable,
            IO_Line_A_TWI_Clock => Disable,
            others              => No_Change);

         PIO.Peripheral_A_Select_Register :=
           (IO_Line_A_TWI_Data  => PIO.Use_Peripheral,
            IO_Line_A_TWI_Clock => PIO.Use_Peripheral,
            others              => PIO.No_Change);

         --  Setup TWI Hardware

         Control_Register :=
           (Start                    => No,
            Stop                     => No,
            Master_Transfer_Enabled  => False,
            Master_Transfer_Disabled => True,
            Software_Reset           => True);

         Clock_Waveform_Generator_Register :=
           (Clock_Low_Divider  => Clock_Low_Divider,
            Clock_High_Divider => Clock_High_Divider,
            Clock_Divider      => Clock_Divider);

         Control_Register :=
           (Start                    => No,
            Stop                     => No,
            Master_Transfer_Enabled  => True,
            Master_Transfer_Disabled => False,
            Software_Reset           => False);

         --  Setup Interrupts

         AIC.Source_Mode_Register (P_TWI) :=
           (Priority_Level   => 7,
            Interrupt_Source => AIC.High_Level_Sensitive);

         AIC.Interrupt_Enable_Command_Register.Interrupt :=
           (P_TWI  => Enable,
            others => No_Change);

         Transfer_Completed := True;
      end Initialise_Interface;

      -----------------------
      -- Interface_Handler --
      -----------------------

      procedure Interface_Handler is
         TWI_Status : constant Status_Register_Type :=
                        (Status_Register and Interrupt_Mask_Register);
         --  A copy of the TWI Status Register that ignores the interrupts that we have
         --  masked.
      begin

         --  The TWI unit received a message byte

         if TWI_Status.Receive_Holding_Register_Ready then

            --  We have recieved a byte so copy it to the message buffer if we have space

            if Buffer_Length > 0 then

               To_Pointer (Buffer).all := Receive_Holding_Register.Data;
               Buffer := Buffer + 1;
               Buffer_Length := Buffer_Length - 1;

               if Buffer_Length = 1 then
                  --  Message buffer is almost full so stop transmission

                  Control_Register :=
                    (Start                    => No,
                     Stop                     => Yes,
                     Master_Transfer_Enabled  => False,
                     Master_Transfer_Disabled => False,
                     Software_Reset           => False);

               --  Recieve transfer complete since the message buffer is full

               elsif Buffer_Length = 0 then
                  Interrupt_Disable_Register := (others => Disable);
                  Transfer_Completed := True;
               end if;

            --  We have no space in the message buffer, raise an error since this should
            --  not have occurred as we are meant to stop the transfer before this can
            --  occur.
            elsif Buffer_Length = 0 then
               raise Program_Error;
            end if;

         --  The TWI unit is ready to send a message byte

         elsif TWI_Status.Transmit_Holding_Register_Ready then

            --  Transmit the next message byte

            if Buffer_Length > 0 then
               if Buffer_Length = 1 then
                  --  Stop the transmission after we transmit the last byte

                  Control_Register :=
                    (Start                    => No,
                     Stop                     => Yes,
                     Master_Transfer_Enabled  => False,
                     Master_Transfer_Disabled => False,
                     Software_Reset           => False);
                  --  Interrupt_Disable_Register :=
                  --    (Transmit_Holding_Register_Ready => Disable,
                  --     others                          => No_Change);
               end if;

               Transmit_Holding_Register.Data := To_Pointer (Buffer).all;
               Buffer := Buffer + 1;
               Buffer_Length := Buffer_Length - 1;

            --  The message buffer is empty so stop the transmission

            else
               Transfer_Completed := True;
               Interrupt_Disable_Register :=
                 (Transmit_Holding_Register_Ready => Disable,
                  others                          => No_Change);
            end if;

            --  elsif TWI_Status.Transmission_Completed then
            --     if Buffer_Length > 0 then
            --        raise Program_Error;
            --     end if;
            --     Transfer_Completed := True;
            --     Interrupt_Disable_Register := (others => Disable);
         end if;

         --  The TWI unit did not get an acknowledgment from the device. Abandon the
         --  transmission.

         if TWI_Status.Not_Acknowledged then
            Transfer_Completed := True;
            Interrupt_Disable_Register := (others => Disable);
            --  raise Program_Error;
         end if;
      end Interface_Handler;

      -------------------
      -- Transmit_Data --
      -------------------

      procedure Transmit_Data
        (With_Device      : in TWI_Device_Address;
         Internal_Address : in TWI_Internal_Address;
         Address_Size     : in Internal_Device_Address_Range;
         Data             : in Address;
         Data_Length      : in Natural;
         Direction        : in Communication_Direction) is
      begin

         --  Setup the protected object for the transfer

         Transfer_Completed := False;

         Buffer := Data;
         Buffer_Length := Data_Length;

         --  Setup the TWI hardware for the transfer

         Master_Mode_Register :=
           (Internal_Device_Address_Size => Address_Size,
            Master_Read_Direction        => Direction,
            Device_Address               => With_Device);

         if Address_Size > 0 then
            Internal_Address_Register.Internal_Address := Internal_Address;
         end if;

         --  Start the transfer. The Interface_Handler will handle the transfer of data
         --  between the message and TWI buffers.

         case Direction is
            when Read =>
               Control_Register :=
                 (Start                    => Yes,
                  Stop                     => No,
                  Master_Transfer_Enabled  => False,
                  Master_Transfer_Disabled => False,
                  Software_Reset           => False);
               Interrupt_Enable_Register :=
                 (Receive_Holding_Register_Ready  => Enable,
                  Not_Acknowledged                => Enable,
                  others                          => No_Change);
            when Write =>
               Transmit_Holding_Register.Data := To_Pointer (Buffer).all;
               Buffer := Buffer + 1;
               Buffer_Length := Buffer_Length - 1;
               Interrupt_Enable_Register :=
                 (Transmit_Holding_Register_Ready => Enable,
                  Not_Acknowledged                => Enable,
                  others                          => No_Change);
         end case;
      end Transmit_Data;

      ---------------------------
      -- Wait_For_Transmission --
      ---------------------------

      entry Wait_For_Transmission when Transfer_Completed is
      begin
         null;
      end Wait_For_Transmission;

   end Two_Wire_Interface;

end Atmel.AT91SAM7S.TWI;
