------------------------------------------------------------------------------------------
--                                                                                      --
--                                    FRANK.OBSTACLES                                    --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

--  This package detects obstacles in front of Frank through his eyes (aka ultrasonic
--  sensor).

package Frank.Obstacles is

   subtype Centimetres is Integer range 0 .. 255;
   --  Type to represent centimeters

   No_Object : constant Centimetres := 255;
   --  Distance that represents that there is no object in front of Frank

   --  Sensor_Data contains the ultrasonic sensor data. It can be safely read and
   --  written by multiple tasks.

   protected Sensor_Data is
      procedure Set_Distance (Distance : in Centimetres);
      --  Set the distance to the object in front of Frank

      function Distance_To_Nearist_Object return Centimetres;
      --  Return how far away the object in front of Frank is

   private
      Distance_To_Object : Centimetres;
      --  How far away the object in front of Frank is

   end Sensor_Data;

   task Gather_Obstacle_Distance with Storage_Size => 2048;
   --  Task that polls the ultrasonic sensor every second to get the distance to the
   --  object in front of the robot. One second is the quickest we can poll the sensor.

end Frank.Obstacles;

