------------------------------------------------------------------------------------------
--                                                                                      --
--                                MINDSTORMS.NXT.BUTTONS                                --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Mindstorms.NXT.AVR; use Mindstorms.NXT.AVR;

package body Mindstorms.NXT.Buttons is

   function Active_Button return Button_Name is
      Buttons_Set : Set_Of_Button_States := Button_States;
   begin
      for Button in Buttons_Set'Range loop
         if Buttons_Set (Button) = Closed then
            return Button;
         end if;
      end loop;
      return No_Button;
   end Active_Button;

   function Button_States return Set_Of_Button_States is
     (AVR_Gateway.Button_States);

end Mindstorms.NXT.Buttons;
