------------------------------------------------------------------------------------------
--                                                                                      --
--                             MINDSTORMS.NXT.TOUCH_SENSORS                             --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Mindstorms.NXT.Ports; use Mindstorms.NXT.Ports;

package Mindstorms.NXT.Touch_Sensors is
   type Touch_Sensor (Sensor_Port : Sensor_Id) is limited private;

   function Is_Pressed (Sensor : Touch_Sensor) return Boolean;

private
   type Touch_Sensor (Sensor_Port : Sensor_Id) is null record;

end Mindstorms.NXT.Touch_Sensors;
