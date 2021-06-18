------------------------------------------------------------------------------------------
--                                                                                      --
--                                    FRANK.OBSTACLES                                    --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Frank.Hardware;

with Mindstorms.NXT.Ultrasonic_Sensors; use Mindstorms.NXT.Ultrasonic_Sensors;

with Ada.Real_Time;                     use Ada.Real_Time;

package body Frank.Obstacles is

   ------------------------------
   -- Gather_Obstacle_Distance --
   ------------------------------

   task body Gather_Obstacle_Distance is
      Task_Cycle_Length : Time_Span := Milliseconds (50);
      --  The period between successive runs of the task's run-loop

      Next_Release_Time : Time := Clock;
      --  Time the task will execute its next cycle

      Obstacle_Distance : Centimetres := Centimetres'Last;
      --  Distance to the closest obstacle

      Valid : Boolean;
      --  Was the last ultrasonic sensor reading valid
   begin
      -- Delay to give the robot time to initialise it's interfaces

      delay until Clock + Seconds (1);

      loop
         --  Read the ultrasonic sensor and update Sensor_Data if the result is valid

         Get_Distance (From_Sensor        => Hardware.Ultrasonic,
                       Distance_To_Object => Obstacle_Distance,
                       Valid              => Valid);
         if Valid then
            Sensor_Data.Set_Distance (Obstacle_Distance);
         end if;

         --  Delay task until next cycle

         delay until Next_Release_Time;
         Next_Release_Time := Next_Release_Time + Task_Cycle_Length;
      end loop;
   end Gather_Obstacle_Distance;

   -----------------
   -- Sensor_Data --
   -----------------

   protected body Sensor_Data is

      --------------------------------
      -- Distance_To_Nearist_Object --
      --------------------------------

      function Distance_To_Nearist_Object return Centimetres is
      begin
         return Distance_To_Object;
      end Distance_To_Nearist_Object;

      ------------------
      -- Set_Distance --
      ------------------

      procedure Set_Distance (Distance : in Centimetres) is
      begin
         Distance_To_Object := Distance;
      end Set_Distance;

   end Sensor_Data;

end Frank.Obstacles;
