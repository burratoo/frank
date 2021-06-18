------------------------------------------------------------------------------------------
--                                                                                      --
--                                MINDSTORMS.NXT.BUTTONS                                --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

package Mindstorms.NXT.Buttons is

   type Button_State is (Open, Closed);

   type Button_Name is (No_Button, Select_Button, Left_Button, Right_Button, Back_Button);
   subtype Physical_Buttons is Button_Name range Select_Button .. Back_Button;

   type Set_Of_Button_States is array (Physical_Buttons) of Button_State with Pack;

   function Button_States return Set_Of_Button_States;
   function Active_Button return Button_Name;

end Mindstorms.NXT.Buttons;

