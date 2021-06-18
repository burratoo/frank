------------------------------------------------------------------------------------------
--                                                                                      --
--                             MINDSTORMS.NXT.TOUCH_SENSORS                             --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Mindstorms.NXT.AVR;

package body Mindstorms.NXT.Touch_Sensors is

   Touch_Threshold : constant := 512;

   function Is_Pressed (Sensor : Touch_Sensor) return Boolean is
   begin
      return AVR.AVR_Gateway.Sensor_Value (Sensor.Sensor_Port) < Touch_Threshold;
   end Is_Pressed;

end Mindstorms.NXT.Touch_Sensors;
