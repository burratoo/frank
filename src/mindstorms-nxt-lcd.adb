------------------------------------------------------------------------------------------
--                                                                                      --
--                                  MINDSTORMS.NXT.LCD                                  --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Atmel.AT91SAM7S;     use Atmel.AT91SAM7S;
with Atmel.AT91SAM7S.PIO; use Atmel.AT91SAM7S.PIO;

with System;              use System;

package body Mindstorms.NXT.LCD is

   LCD_Command_Data_Pin : constant := IO_Line_A_SPI_MISO;

   procedure Command (Do_This : Unsigned_8) is
      C : Unsigned_8 := Do_This;
   begin
      PIO.Clear_Output_Data_Register :=
        (LCD_Command_Data_Pin => Enable,
         others               => No_Change);

      Transmit_Data
        (To_Device              => Display_Driver_Id,
         Send_Message           => C'Address,
         Send_Message_Length    => 1,
         Recieve_Message        => Null_Address,
         Recieve_Message_Length => 0);
   end Command;

   procedure Set_All_Pixels_On (On : Boolean) is
      C : Unsigned_8 := 16#A4#;
   begin
      if On then
         C := C or 1;
      end if;
      Command (C);
   end Set_All_Pixels_On;

   procedure Set_Inverse_Display (On : Boolean) is
      C : Unsigned_8 := 16#A6#;
   begin
      if On then
         C := C or 1;
      end if;
      Command (C);
   end Set_Inverse_Display;

   procedure Set_Display_Enable (On : Boolean) is
      C : Unsigned_8 := 16#AE#;
   begin
      if On then
         C := C or 1;
      end if;
      Command (C);
   end Set_Display_Enable;

   procedure Set_Bias_Ratio (Bias_Ration : Unsigned_8) is
   begin
      Command (16#E8# or Bias_Ration);
   end Set_Bias_Ratio;

   procedure Set_Pot (Pm : Unsigned_8) is
   begin
      Command (16#81#);
      Command (Pm);
   end Set_Pot;

   procedure Set_Ram_Address_Control (Ac : Unsigned_8) is
   begin
      Command (16#84# or Ac);
   end Set_Ram_Address_Control;

   procedure Set_Map_Control (M : Unsigned_8) is
   begin
      Command (16#C0# or M * 2);
   end Set_Map_Control;

   procedure Reset is
   begin
      Command (16#E2#);
   end Reset;

   procedure Set_Column (Column : Driver_Columns) is
   begin
      Command (16#00# or Unsigned_8 (Column mod 16));
      Command (16#10# or Unsigned_8 (Column / 16));
   end Set_Column;

   procedure Set_Page_Address (Page : Driver_Pages) is
   begin
      Command (16#b0# or Unsigned_8 (Page));
   end Set_Page_Address;

   procedure Set_Scroll (Line : Unsigned_8) is
   begin
      Command (16#40# or (Line and 63));
   end Set_Scroll;

   procedure Write (Page : Driver_Pages; Start : Driver_Columns; Graph : LCD_line) is
   begin
      Set_Column (Start);
      Set_Page_Address (Page);

      --  ??? Check the length.

      PIO.Set_Output_Data_Register :=
        (LCD_Command_Data_Pin => Enable,
         others               => No_Change);

      Transmit_Data
        (To_Device              => Display_Driver_Id,
         Send_Message           => Graph'Address,
         Send_Message_Length    => Graph'Length,
         Recieve_Message        => Null_Address,
         Recieve_Message_Length => 0);
   end Write;

   procedure Power_On is
   begin
      --  Obtain the MISO pin since it is not used by the SPI unit, but instead
      --  to indicate whether the SAM7 is sending a command or data packet.

      PIO.PIO_Enable_Register :=
        (LCD_Command_Data_Pin => Enable,
         others               => No_Change);
      PIO.Output_Enable_Register :=
        (LCD_Command_Data_Pin => Enable,
         others               => No_Change);

      Reset;
      Set_Bias_Ratio (3);
      Set_Pot (16#60#);
      Set_Ram_Address_Control (0);
      Set_Map_Control (2);
      Set_Scroll (0);
      Set_Display_Enable (True);
   end Power_On;

end Mindstorms.NXT.LCD;
