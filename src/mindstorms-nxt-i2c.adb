------------------------------------------------------------------------------------------
--                                                                                      --
--                                  MINDSTORMS.NXT.I2C                                  --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;
with Interfaces;    use Interfaces;

with System.Storage_Elements; use System.Storage_Elements;

with Atmel.AT91SAM7S;     use Atmel.AT91SAM7S;
with Atmel.AT91SAM7S.PIO; use Atmel.AT91SAM7S.PIO;

with Ada.Unchecked_Conversion;
with System.Address_To_Access_Conversions;

package body Mindstorms.NXT.I2C is

   LEGO_Clock_Delay : constant Time_Span := Microseconds (200); --  Microseconds (52);
   --  For a clock rate of 9600bit/s
   I2C_Clock_Delay  : constant Time_Span := Microseconds (5);
   --  For a clock rate of 100kbit/s

   procedure Read_Data
     (From_Port           : in out I2C_Interface;
      From_Device         : in I2C_Device_Address;
      From_Register       : in I2C_Register;
      Length              : in Positive;
      Data                : in Address;
      Operation_Succesful : out Boolean) is
   begin
      From_Port.New_Transaction
        ((Device   => From_Device,
          Register => From_Register,
          Length   => Length,
          Data     => Data,
          Kind     => Read));
      From_Port.Wait (Operation_Succesful);
   end Read_Data;

   procedure Write_Data
     (To_Port             : in out I2C_Interface;
      To_Device           : in I2C_Device_Address;
      To_Register         : in I2C_Register;
      Length              : in Positive;
      Data                : in Address;
      Operation_Succesful : out Boolean) is
   begin
      To_Port.New_Transaction
        ((Device   => To_Device,
          Register => To_Register,
          Length   => Length,
          Data     => Data,
          Kind     => Write));
      To_Port.Wait (Operation_Succesful);
   end Write_Data;

   protected body I2C_Interface is
      procedure New_Transaction (T : I2C_Transaction) is
      begin
         Current_Transaction := T;
         Release_Task := True;
      end New_Transaction;

      function Get_Transaction_Details return I2C_Transaction is
      begin
         return Current_Transaction;
      end Get_Transaction_Details;

      entry Wait (Is_Successful : out Boolean) when Release_Task is
      begin
         Release_Task := False;
         Is_Successful := Transaction_Success;
      end Wait;

      procedure Transaction_Finished (Successfully : in Boolean) is
      begin
         Transaction_Success := Successfully;
         Release_Task := True;
      end Transaction_Finished;

   end I2C_Interface;

   task body I2C_Controller is

      SCL_Delay : constant Time_Span :=
                      (if Mode = Normal then I2C_Clock_Delay
                       else LEGO_Clock_Delay);

      SCL_Pin   : constant PIO_Lines := NXT_Ports_Pins (Port_Number).Clock;
      SDA_Pin   : constant PIO_Lines := NXT_Ports_Pins (Port_Number).Data;

      subtype Bit is Unsigned_8 range 0 .. 1;

      procedure Enter_Read_SDA_Mode with Inline_Always;
      procedure Exit_Read_SDA_Mode with Inline_Always;

      function Read_SCL return Bit;
      function Read_SDA return Bit;
      procedure Read_Byte (Byte : out Unsigned_8; End_Of_Buffer : in Boolean);
      procedure Start_Transaction (Address       : in I2C_Device_Address;
                                   Operation     : in I2C_Operation;
                                   Is_Successful : out Boolean);
      --  Initiates a new data transfer with the direction indicated by
      --  Operation.

      procedure Send_Start_Condition;
      procedure Send_Stop_Condition;
      procedure Toggle_Clock with Inline_Always;
      procedure Write_SCL (B : in Bit) with Inline_Always;
      procedure Write_SDA (B : Bit);
      procedure Write_Byte (Byte : in Unsigned_8; Is_Successful : out Boolean);

      package Byte_Access is
        new System.Address_To_Access_Conversions (Unsigned_8);

      use Byte_Access;

      -------------------------
      -- Enter_Read_SDA_Mode --
      -------------------------

      procedure Enter_Read_SDA_Mode is
         Disable_State : Disable_Set := (others => No_Change);
      begin
         Disable_State (SDA_Pin) := Disable;
         PIO.Output_Disable_Register   := Disable_State;

         Write_SDA (1); -- Resets SDA back to its default value

      end Enter_Read_SDA_Mode;

      ------------------------
      -- Exit_Read_SDA_Mode --
      ------------------------

      procedure Exit_Read_SDA_Mode is
         Enable_State  : Enable_Set := (others  => No_Change);
      begin
         Enable_State (SDA_Pin) := Enable;
         PIO.Output_Enable_Register := Enable_State;
         Write_SDA (1); -- Resets SDA back to its default value
      end Exit_Read_SDA_Mode;

      --------------
      -- Read_SCL --
      --------------

      function Read_SCL return Bit is
        (if PIO.Pin_Data_Status_Register (SCL_Pin) then 1 else 0);

      --------------
      -- Read_SDA --
      --------------

      function Read_SDA return Bit is
         (if PIO.Pin_Data_Status_Register (SDA_Pin) then 1 else 0);

      procedure Read_Byte (Byte : out Unsigned_8; End_Of_Buffer : in Boolean) is
      begin
         Enter_Read_SDA_Mode;
         Byte := 0;
         for J in 1 .. 8 loop
            Byte := Shift_Left (Byte, 1);
            delay until Clock + SCL_Delay; -- Delay to give the transmitting device time to take hold of the bus
            Toggle_Clock; -- goes high
            Byte := Byte or Read_SDA;
            delay until Clock + SCL_Delay;
            Toggle_Clock; -- goes low
         end loop;
         Exit_Read_SDA_Mode;


         if End_Of_Buffer then
            --  Send NACK

            --  Write byte then delay to give time for the line to go high

            Write_SDA (1);
            delay until Clock + SCL_Delay;
            Toggle_Clock; -- SCL goes high for 9th clock
            delay until Clock + SCL_Delay;
            Toggle_Clock; -- end of message acknowledgment
            delay until Clock + SCL_Delay;

         else
            --  Send ACK
            Write_SDA (0);
            delay until Clock + SCL_Delay;
            Toggle_Clock; -- SCL goes high for 9th clock
            delay until Clock + SCL_Delay;
            Toggle_Clock; -- end of message acknowledgment
            Write_SDA (1); -- release SDA
            delay until Clock + SCL_Delay;
         end if;
      end Read_Byte;

      -------------------------
      -- Send_Device_Address --
      -------------------------

      procedure Start_Transaction (Address       : in I2C_Device_Address;
                                   Operation     : in  I2C_Operation;
                                   Is_Successful : out Boolean)
      is
         Addr : Unsigned_8 := Address;
      begin

         Send_Start_Condition;

         if Operation = Read then
            Addr := Addr or 1;
         end if;
         Write_Byte (Addr, Is_Successful);
      end Start_Transaction;

      --------------------------
      -- Send_Start_Condition --
      --------------------------

      procedure Send_Start_Condition is
      begin
         Write_SCL (1); -- Ensure that the clock is high
         delay until Clock + SCL_Delay;
         Write_SDA (0);
         delay until Clock + SCL_Delay;
         Write_SCL (0);
      end Send_Start_Condition;

      -------------------------
      -- Send_Stop_Condition --
      -------------------------

      procedure Send_Stop_Condition is
      begin
         Write_SCL (1);
         delay until Clock + SCL_Delay / 2;
         Write_SDA (1);
         delay until Clock + SCL_Delay;
      end Send_Stop_Condition;

      ------------------
      -- Toggle_Clock --
      ------------------

      procedure Toggle_Clock is
      begin
         case Read_SCL is
            when 0 =>
               Write_SCL (1);
            when 1 =>
               Write_SCL (0);
         end case;
      end Toggle_Clock;


      ----------------
      -- Write_Byte --
      ----------------

      procedure Write_Byte (Byte          : in Unsigned_8;
                            Is_Successful : out Boolean)
      is
         B : Unsigned_8 := Byte;
      begin
         for J in 1 .. 8 loop
            Write_SDA (Shift_Right (B and 16#80#, 7));
            delay until Clock + SCL_Delay;
            Toggle_Clock; -- goes high
            delay until Clock + SCL_Delay;
            Toggle_Clock; -- goes low
            B := Shift_Left (B, 1);
         end loop;

         --  Look for acknowledgement

         Enter_Read_SDA_Mode;
         delay until Clock + SCL_Delay;
         Toggle_Clock; --  goes high for the ninth clock
         if Read_SDA = 1 then
            Is_Successful := False; -- nack
         end if;

         delay until Clock + SCL_Delay;
         Toggle_Clock; -- Master acknowledgement more or less, clock goes low

         Exit_Read_SDA_Mode;
         delay until Clock + SCL_Delay;

         --  Should return back succesful here
         Is_Successful := True;
      end Write_Byte;

      ---------------
      -- Write_SCL --
      ---------------

      procedure Write_SCL (B : in Bit) is
         Pin_Selection : Enable_Set := (others => No_Change);
      begin
         Pin_Selection (SCL_Pin) := Enable;
         case B is
            when 0 =>
               PIO.Clear_Output_Data_Register := Pin_Selection;
            when 1 =>
               PIO.Set_Output_Data_Register := Pin_Selection;
         end case;
      end Write_SCL;

      ---------------
      -- Write_SDA --
      ---------------

      procedure Write_SDA (B : Bit) is
         Pin_Selection : Enable_Set := (others => No_Change);
      begin
         Pin_Selection (SDA_Pin) := Enable;
         case B is
            when 0 =>
               PIO.Clear_Output_Data_Register := Pin_Selection;
            when 1 =>
               PIO.Set_Output_Data_Register := Pin_Selection;
         end case;
      end Write_SDA;


      Transaction : I2C_Transaction;
      Current_Byte_Address : Address;

   begin
      --  Initialise interface
      delay until Clock + Milliseconds (10);

      Initialisation : declare
         Output_State : Enable_Set := (others  => No_Change);
      begin
         Output_State (SCL_Pin) := Enable;
         Output_State (SDA_Pin) := Enable;
         PIO.Set_Output_Data_Register := Output_State;
         PIO.Output_Enable_Register   := Output_State;
         PIO.Multi_Driver_Enable_Register (SCL_Pin) := Enable;
--           PIO.Pull_Up_Enable_Register := Output_State;
         PIO.Pull_Up_Enable_Register (SCL_Pin) := Enable;
         PIO.Pull_Up_Disable_Register (SDA_Pin) := Disable;

         --  Port 4 has an RS485 interface attached to it. Need to make sure
         --  the drive is disable (can't send the chip into low power mode
         --  because the receive and drive enable pins are connected to the
         --  same pin on the SAM7S.

         if Port_Number = 4 then
            declare
               RS485_Mode_Pin : constant := 7;
            begin
               PIO.Clear_Output_Data_Register := (RS485_Mode_Pin => Enable,
                                                  others         => No_Change);
               PIO.Output_Enable_Register := (RS485_Mode_Pin => Enable,
                                              others         => No_Change);
            end;
         end if;
      end Initialisation;

      --  Wait for a new transaction and then process it

      loop
         I2C_Transaction : declare
            Operation_Successful : Boolean;
            Failed_Transcation   : exception;
         begin
            Port_Interface.Wait (Operation_Successful);
            Transaction := Port_Interface.Get_Transaction_Details;

            --  Send/receive data

            --  1. Start new transaction and write Device Address

            Start_Transaction (Transaction.Device, Write, Operation_Successful);

            if not Operation_Successful then
               raise Failed_Transcation;
            end if;

            --  2. Write Device Register

            Write_Byte (Transaction.Register, Operation_Successful);
            if not Operation_Successful then
               raise Failed_Transcation;
            end if;

            --  3. Then take read or write path until all data is received.

            case Transaction.Kind is
            when Write =>
               Current_Byte_Address := Transaction.Data;
               for J in 1 .. Transaction.Length loop
                  Write_Byte (To_Pointer (Current_Byte_Address).all,
                              Operation_Successful);
                  Current_Byte_Address := Current_Byte_Address + 1;
                  if not Operation_Successful then
                     raise Failed_Transcation;
                  end if;
               end loop;

            when Read =>
               --  If in LEGO mode need to complete the previous write message
               --  (whereas normally only a repeated start condition would be
               --  needed). Plus an adition clock cycle after it is needed.

               if Mode = LEGO then
                  Send_Stop_Condition;
                  Toggle_Clock;
                  delay until Clock + SCL_Delay;
                  Toggle_Clock;
                  delay until Clock + SCL_Delay;
               end if;

               Start_Transaction (Transaction.Device, Read,
                                  Operation_Successful);
               if not Operation_Successful then
                  raise Failed_Transcation;
               end if;

               Current_Byte_Address := Transaction.Data;
               for J in 1 ..  Transaction.Length - 1 loop
                  Read_Byte (To_Pointer (Current_Byte_Address).all,
                             End_Of_Buffer => False);
                  Current_Byte_Address := Current_Byte_Address + 1;
               end loop;

               Read_Byte (To_Pointer (Current_Byte_Address).all,
                          End_Of_Buffer => True);
            end case;

            --  4. Send stop bit.
            Send_Stop_Condition;

            Port_Interface.Transaction_Finished (Successfully => True);
         exception
            when Failed_Transcation =>
               Port_Interface.Transaction_Finished (Successfully => False);
         end I2C_Transaction;

         delay until Clock + Milliseconds (1);

      end loop;
   end I2C_Controller;


end Mindstorms.NXT.I2C;
