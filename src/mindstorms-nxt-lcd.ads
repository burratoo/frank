------------------------------------------------------------------------------------------
--                                                                                      --
--                                  MINDSTORMS.NXT.LCD                                  --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Atmel.AT91SAM7S.SPI; use Atmel.AT91SAM7S.SPI;
with Interfaces;          use Interfaces;

package Mindstorms.NXT.LCD is

   --  Viewable pixels.
   subtype LCD_Columns is Natural range 0 .. 99;
   subtype LCD_Rows    is Natural range 0 .. 7;
   --  0,0 is upper left; 99,7 is lower right

   subtype LCD_Subrows is Natural range 0 .. 7;

   type LCD_Line is array (LCD_Columns range <>) of Unsigned_8;

   --  Raw number of columns and pages.
   subtype Driver_Columns is Natural range 0 .. 255;
   subtype Driver_Pages   is Natural range 0 .. 15;

   Display_Driver_Id  : constant Peripheral_Chip_Select_Id := Chip_Select_2;
   Display_Driver_Pin : constant Peripheral_Chip_Select_Pin := CS2;

   procedure Command (Do_This : in Unsigned_8);
   --  Send a command to the lcd.

   procedure Write (Page : Driver_Pages; Start : Driver_Columns; Graph : LCD_Line);

   procedure Set_All_Pixels_On   (On : in Boolean);
   procedure Set_Inverse_Display (On : in Boolean);
   --  High level commands.

   procedure Power_On;
   --  Power up and initialize LCD.

end Mindstorms.NXT.LCD;
