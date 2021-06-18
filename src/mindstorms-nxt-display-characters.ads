------------------------------------------------------------------------------------------
--                                                                                      --
--                           MINDSTORMS.NXT.DISPLAY.CHARACTERS                          --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

package Mindstorms.NXT.Display.Characters is

   procedure Draw_Character (C : in Character);
   procedure Draw_Character (C      : in Character;
                             Origin : in Pixel_Coordinates);

   procedure Draw_String (S : in String);
   procedure Draw_String (S      : in String;
                          Origin : in Pixel_Coordinates);

   procedure Draw_Integer (I      : in Integer;
                           Origin : in Pixel_Coordinates);

   procedure Draw_Hex (Val : in Unsigned_32; Origin : in Pixel_Coordinates);

end Mindstorms.NXT.Display.Characters;
