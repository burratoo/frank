------------------------------------------------------------------------------------------
--                                                                                      --
--                             MINDSTORMS.NXT.DISPLAY.FONTS                             --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Mindstorms.NXT.Display.Fonts;

package body Mindstorms.NXT.Display.Characters is
   procedure Draw_Character (C : in Character) is
   begin
      Draw_Character (C, Current_Pixel);
   end Draw_Character;

   procedure Draw_Character (C      : in Character;
                             Origin : in Pixel_Coordinates) is
   begin
      Draw_To_Framebuffer (Image  => Fonts.Monaco_9pt (C),
                           Origin => Origin);
   end Draw_Character;

   procedure Draw_String (S : in String) is
   begin
      Draw_String (S, Current_Pixel);
   end Draw_String;

   procedure Draw_String (S      : in String;
                          Origin : in Pixel_Coordinates)
   is
      O : Pixel_Coordinates := Origin;
   begin
      for C of S loop
         Draw_To_Framebuffer (Image  => Fonts.Monaco_9pt (C),
                              Origin => O);
         if O.X + Fonts.Glyph_5x9'Length (X_Dim) <= Pixel_Columns'Last then
            O.X := O.X + Fonts.Glyph_5x9'Length (X_Dim);
         else
            exit;
         end if;
      end loop;
   end Draw_String;

   procedure Draw_Integer (I      : in Integer;
                           Origin : in Pixel_Coordinates) is
      Val : Integer := I;
      Res : String (1 .. 9) := (others => ' ');
      Pos : Natural := Res'Last;
   begin
      if Val >= 0 then
         Val := -Val;
      end if;
      loop
         Res (Pos) := Character'Val (Character'Pos ('0') - (Val mod (-10)));
         Val := Val / 10;
         exit when Val = 0;
         Pos := Pos - 1;
      end loop;
      if I < 0 then
         Draw_String ('-' & Res (Pos .. Res'Last), Origin);
      else
         Draw_String (Res (Pos .. Res'Last), Origin);
      end if;
   end Draw_Integer;

   Hexdigits : constant array (0 .. 15) of Character := "0123456789ABCDEF";

   -------------
   -- Put_Hex --
   -------------

   procedure Draw_Hex (Val : in Unsigned_32; Origin : in Pixel_Coordinates) is
      Char_Location : Pixel_Coordinates := Origin;
   begin
      for I in reverse 0 .. 7 loop
         Draw_Character (Hexdigits (Natural (Shift_Right (Val, 4 * I) and 15)), Char_Location);
         Char_Location.X := Char_Location.X + 6;
      end loop;
   end Draw_Hex;

end Mindstorms.NXT.Display.Characters;
