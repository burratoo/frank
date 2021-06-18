------------------------------------------------------------------------------------------
--                                                                                      --
--                                    MINDSTORMS.NXT                                    --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Atmel; use Atmel;
with Interfaces; use Interfaces;

package Mindstorms.NXT with Pure is

   type Sensor_Id is (Sensor_1, Sensor_2, Sensor_3, Sensor_4);

private
   Clock_Frequency : constant := 48_054_850;
end Mindstorms.NXT;
