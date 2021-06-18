------------------------------------------------------------------------------------------
--                                                                                      --
--                                MINDSTORMS.NXT.DISPLAY                                --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Mindstorms.NXT.LCD; use Mindstorms.NXT.LCD;

with Ada.Unchecked_Conversion;

package body Mindstorms.NXT.Display is

   -------------------------
   -- Draw_To_Framebuffer --
   -------------------------

   procedure Draw_To_Framebuffer (Image : in Pixel_Matrix) is
   begin
      Draw_To_Framebuffer (Image, Current_Pixel);
      --  Need to update Current_Pixel
   end Draw_To_Framebuffer;

   procedure Draw_To_Framebuffer (Image  : in Pixel_Matrix;
                                  Origin : in Pixel_Coordinates)
   is
      Offset_X, Offset_Y : Integer;
      -- Uses Integer since the offset may be negative.

   begin
      for Y in Image'Range (Y_Dim) loop
         Offset_Y := Origin.Y - Image'First (Y_Dim);
         if Y + Offset_Y > Pixel_Rows'Last then
            exit;
         end if;

         for X in Image'Range (X_Dim) loop
            Offset_X := Origin.X - Image'First (X_Dim);
            if X + Offset_X > Pixel_Columns'Last then
               exit;
            end if;
            Framebuffer (Y + Offset_Y, X + Offset_X) := Image (Y, X);
         end loop;
      end loop;

   end Draw_To_Framebuffer;

   -----------------------
   -- Set_Current_Pixel --
   -----------------------

   procedure Set_Current_Pixel (Coord : in Pixel_Coordinates) is
   begin
      Current_Pixel := Coord;
   end Set_Current_Pixel;

   procedure Set_Current_Pixel (X : in Pixel_Columns; Y : in Pixel_Rows) is
   begin
      Current_Pixel := (X, Y);
   end Set_Current_Pixel;

   -------------------
   -- Update_Screen --
   -------------------

   procedure Update_Screen is
--        use Mindstorms.NXT.LCD.Font;
      Line : LCD_Line (LCD_Columns);
   begin
      for J in LCD_Rows loop
         Line := (others => 0);
         for L in LCD_Subrows loop
            for K in Framebuffer'Range (X_Dim) loop
               Line (K) := Line (K) or Shift_Left (Unsigned_8 (Framebuffer (J * 8 + L, K)), L);
            end loop;
         end loop;
         Write (J, 0, Line);
      end loop;
   end Update_Screen;

   -----------------------
   -- Clear_Framebuffer --
   -----------------------

   procedure Clear_Framebuffer is
   begin
      Framebuffer := (others => (others => 0));
      Set_Current_Pixel (0, 0);
   end Clear_Framebuffer;

   ------------------
   -- Clear_Screen --
   ------------------

   procedure Clear_Screen is
   begin
      Clear_Framebuffer;
      Update_Screen;
   end Clear_Screen;

   procedure Draw_Line (Start_Point, End_Point : in Pixel_Coordinates) is
   --  Bresenham line algorithm

      dX : constant Pixel_Columns := abs (End_Point.X - Start_Point.X);
      dY : constant Pixel_Rows    := abs (End_Point.Y - Start_Point.Y);

      Err : Integer := dX - dY;
      Er2 : Integer;

      Step_X : constant Integer := (if Start_Point.X - End_Point.X < 0 then 1 else -1);
      Step_Y : constant Integer := (if Start_Point.Y - End_Point.Y < 0 then 1 else -1);

      X : Pixel_Columns := Start_Point.X;
      Y : Pixel_Rows    := Start_Point.Y;
   begin
      loop
         Framebuffer (Y, X) := 1;

         exit when X = End_Point.X and Y = End_Point.Y;

         Er2 := 2 * Err;
         if Er2 > -dY then
            Err := Err - dY;
            X := X + Step_X;
         end if;
         if Er2 < DX then
            Err := Err + dX;
            Y := Y + Step_Y;
         end if;
      end loop;

   end Draw_Line;


   ---------------------------------------------------------------------------

--     Font_Width : constant := 6;
--
--     Max_X : constant Natural := 100 / Font_Width;
--
--     Current_Column : Char_Columns;
--     Current_Row    : Char_Rows;
--
--     Screen : array (Char_Columns, Char_Rows) of Character;
--
--     ------------------
--     -- Set_Position --
--     ------------------
--
--     procedure Set_Position (Column : Char_Columns; Row : Char_Rows) is
--     begin
--        Current_Column := Column;
--        Current_Row := Row;
--     end Set_Position;
--
--     ----------------------
--     -- Newline_Noupdate --
--     ----------------------
--
--     procedure Newline_Noupdate is
--     begin
--        Current_Column := 0;
--        if Current_Row = Pixel_Rows'Last then
--           for I in 0 .. Pixel_Rows'Last - 1 loop
--              for J in Char_Columns loop
--                 Screen (J, I) := Screen (J, I + 1);
--              end loop;
--           end loop;
--           for J in Char_Columns loop
--              Screen (J, LCD_Rows'Last) := ' ';
--           end loop;
--        else
--           Current_Row := Current_Row + 1;
--        end if;
--     end Newline_Noupdate;

   ------------------
   -- Put_Noupdate --
   ------------------

--     procedure Put_Noupdate (C : Character) is
--  --        use Mindstorms.NXT.LCD.Font;
--        X : Pixel_Columns := Current_Column * Font_Width;
--     begin
--        if C in Font5x8'Range then
--           Screen (Current_Column, Current_Row) := C;
--           if Current_Column = Char_Columns'Last then
--              Newline_Noupdate;
--           else
--              Current_Column := Current_Column + 1;
--           end if;
--        else
--           case C is
--              when ASCII.CR =>
--                 Current_Column := 0;
--              when ASCII.LF =>
--                 Newline_Noupdate;
--              when others =>
--                 null;
--           end case;
--        end if;
--     end Put_Noupdate;
--
--     ---------
--     -- Put --
--     ---------
--
--     procedure Put (C : Character) is
--     begin
--        Put_Noupdate (C);
--        Update_Screen;
--     end Put;
--
--     ------------------
--     -- Put_Noupdate --
--     ------------------
--
--     procedure Put_Noupdate (S : String) is
--     begin
--        for I in S'Range loop
--           Put_Noupdate (S (I));
--        end loop;
--     end Put_Noupdate;
--
--     ---------
--     -- Put --
--     ---------
--
--     procedure Put (S : String) is
--     begin
--        Put_Noupdate (S);
--        Update_Screen;
--     end Put;
--
--     --------------
--     -- Put_Line --
--     --------------
--
--     procedure Put_Line (S : String) is
--     begin
--        Put_Noupdate (S);
--        Newline_Noupdate;
--        Update_Screen;
--     end Put_Line;
--
--     -------------
--     -- Newline --
--     -------------
--
--     procedure Newline is
--     begin
--        Newline_Noupdate;
--        Update_Screen;
--     end Newline;
--
--     Hexdigits : constant array (0 .. 15) of Character := "0123456789ABCDEF";
--
--     -------------
--     -- Put_Hex --
--     -------------
--
--     procedure Put_Hex (Val : Unsigned_32) is
--     begin
--        for I in reverse 0 .. 7 loop
--           Put_Noupdate (Hexdigits (Natural (Shift_Right (Val, 4 * I) and 15)));
--        end loop;
--     end Put_Hex;
--
--     -------------
--     -- Put_Hex --
--     -------------
--
--     procedure Put_Hex (Val : Unsigned_16) is
--     begin
--        for I in reverse 0 .. 3 loop
--           Put_Noupdate (Hexdigits (Natural (Shift_Right (Val, 4 * I) and 15)));
--        end loop;
--     end Put_Hex;
--
--     -------------
--     -- Put_Hex --
--     -------------
--
--     procedure Put_Hex (Val : Unsigned_8) is
--     begin
--        for I in reverse Integer range 0 .. 1 loop
--           Put_Noupdate (Hexdigits (Natural (Shift_Right (Val, 4 * I) and 15)));
--        end loop;
--     end Put_Hex;
--
--     ------------------
--     -- Put_Noupdate --
--     ------------------
--
--     procedure Put_Noupdate (V : Integer) is
--        Val : Integer := V;
--        Res : String (1 .. 9);
--        Pos : Natural := Res'Last;
--     begin
--        if Val < 0 then
--           Put_Noupdate ('-');
--        else
--           Val := -Val;
--        end if;
--        loop
--           Res (Pos) := Character'Val (Character'Pos ('0') - (Val mod (-10)));
--           Val := Val / 10;
--           exit when Val = 0;
--           Pos := Pos - 1;
--        end loop;
--        for I in Pos .. Res'Last loop
--           Put_Noupdate (Res (I));
--        end loop;
--     end Put_Noupdate;
--
--     ------------------
--     -- Put_Noupdate --
--     ------------------
--
--     procedure Put_Noupdate (V : Long_Long_Integer) is
--        Val : Long_Long_Integer := V;
--        Res : String (1 .. 20);
--        Pos : Natural := Res'Last;
--     begin
--        if Val < 0 then
--           Put_Noupdate ('-');
--        else
--           Val := -Val;
--        end if;
--        loop
--           Res (Pos) := Character'Val (Character'Pos ('0') - (Val mod (-10)));
--           Val := Val / 10;
--           exit when Val = 0;
--           Pos := Pos - 1;
--        end loop;
--        for I in Pos .. Res'Last loop
--           Put_Noupdate (Res (I));
--        end loop;
--     end Put_Noupdate;
--
--     -------------------
--     -- Put_Exception --
--     -------------------
--
--     procedure Put_Exception (Addr : Unsigned_32) is
--     begin
--        Set_Position (0, 0);
--        Put_Noupdate ("ERR@");
--        Put_Hex (Addr);
--     end Put_Exception;
end Mindstorms.NXT.Display;
