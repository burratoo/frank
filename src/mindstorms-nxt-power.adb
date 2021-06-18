------------------------------------------------------------------------------------------
--                                                                                      --
--                                 MINDSTORMS.NXT.POWER                                 --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Mindstorms.NXT.AVR; use Mindstorms.NXT.AVR;

with Ada.Real_Time; use Ada.Real_Time;

package body Mindstorms.NXT.Power is
   procedure Turn_Off_ARM is
   begin
      AVR_Gateway.Set_Power_State (Power    => Power_Off,
                                   PWM_Mode => Off_PWM_Frequency);
      delay until Clock + Milliseconds (100);
   end Turn_Off_ARM;

   procedure Enter_Firmware_Mode is
   begin
      AVR_Gateway.Set_Power_State (Power    => Firmware_Mode,
                                   PWM_Mode => Firmware_PWM_Frequency);
   end Enter_Firmware_Mode;
end Mindstorms.NXT.Power;
