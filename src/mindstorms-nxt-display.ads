------------------------------------------------------------------------------------------
--                                                                                      --
--                                MINDSTORMS.NXT.DISPLAY                                --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Interfaces; use Interfaces;

package Mindstorms.NXT.Display is

   subtype Pixel_Columns is Natural range 0 .. 99;
   subtype Pixel_Rows    is Natural range 0 .. 63;

   type Pixels is range 0 .. 1;

   type Pixel_Matrix is array (Pixel_Rows range <>, Pixel_Columns range <>) of Pixels with Pack;

   type Pixel_Coordinates is record
      X : Pixel_Columns;
      Y : Pixel_Rows;
   end record;

   procedure Clear_Framebuffer;
   procedure Clear_Screen;

   procedure Set_Current_Pixel (Coord : in Pixel_Coordinates);
   procedure Set_Current_Pixel (X : in Pixel_Columns; Y : in Pixel_Rows);

   procedure Draw_To_Framebuffer (Image : in Pixel_Matrix);
   procedure Draw_To_Framebuffer (Image  : in Pixel_Matrix;
                                  Origin : in Pixel_Coordinates);

   procedure Draw_Line (Start_Point, End_Point : in Pixel_Coordinates);

   procedure Update_Screen;
   --  Sends the framebuffer to the LCD screen

   ---------------------------

--     subtype Char_Columns is Natural range 0 .. 15;
--     subtype Char_Rows    is Natural range 0 .. 7;
--     --   0,0 is the upper left; 15,7 is lower right
--
--
--
--     --  Set current position.
--
--     procedure Put_Noupdate (C : Character);
--     procedure Put_Noupdate (S : String);
--     procedure Put_Noupdate (V : Integer);
--     procedure Put_Noupdate (V : Long_Long_Integer);
--     --  Write a character, a string and an integer.
--     --  Only CR and LF control characters are handled.
--     --  Note that the min and max values for Long_Long_Integer will wrap around
--     --  the display.
--
--
--     --  Like in Ada.Text_IO.
--
--     procedure Newline_Noupdate;
--     procedure Newline;
--     procedure New_Line_Noupdate renames Newline_Noupdate;
--     --  Like in Ada.Text_IO.
--
--     procedure Put_Hex (Val : Unsigned_32);
--     procedure Put_Hex (Val : Unsigned_16);
--     procedure Put_Hex (Val : Unsigned_8);
--     --  Write VAL using its hexadecimal representation, without
--     --  updating the LCD.
--
--     procedure Put_Exception (Addr : Unsigned_32);
--     pragma Export (C, Put_Exception);
--     --  Can be called in case of exception.

private

   X_Dim : constant := 2;
   Y_Dim : constant := 1;

   Current_Pixel : Pixel_Coordinates := (0, 0);


   Framebuffer : Pixel_Matrix (Pixel_Rows, Pixel_Columns);
   --  Framebuffer for the LCD screen. Origin at top left corner.

end Mindstorms.NXT.Display;
