------------------------------------------------------------------------------------------
--                                                                                      --
--                                    FRANK.POSITION                                    --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Frank.Hardware;               use Frank.Hardware;

with Mindstorms.NXT.AVR;           use Mindstorms.NXT.AVR;
with Mindstorms.NXT.Touch_Sensors; use Mindstorms.NXT.Touch_Sensors;

with Ada.Real_Time;                use Ada.Real_Time;

package body Frank.Position is

   ----------------------
   -- Position_Tracker --
   ----------------------

   task body Position_Tracker is
      Left_Step_Counter  : Natural := 0;
      Right_Step_Counter : Natural := 0;
      --  Number of left and right steps taken by Frank

      Previous_Left_Touch_Reading  : Boolean := False;
      Previous_Right_Touch_Reading : Boolean := False;
      --  State of the feet touch sensors the last time the task executed it's run-loop

      --  Current_Position   : Room_Coordinates := (0, 0);

      Task_Cycle_Length : Time_Span := Milliseconds (4);
      --  The frequency the Position_Tracker run-loop runs at

      Next_Release_Time : Time := Clock;
      --  The next time the task will run
   begin
      loop
         --  Calculate next cycle time

         Next_Release_Time := Next_Release_Time + Task_Cycle_Length;

         --  Determine if Frank's left or right foot has completed a new step. We consider
         --  a step has been taken if a foot sensor previously reported no-touch now
         --  reports a touch.

         declare
            Current_Left_Touch_State : Boolean := Is_Pressed (Left_Foot_Touch_Sensor);
            Current_Right_Touch_State : Boolean := Is_Pressed (Right_Foot_Touch_Sensor);
            --  Current value of the feet touch sensors
         begin
            if Current_Left_Touch_State and then not Previous_Left_Touch_Reading then
               Left_Step_Counter := Left_Step_Counter + 1;
            end if;

            if Current_Right_Touch_State and then not Previous_Left_Touch_Reading then
               Right_Step_Counter := Right_Step_Counter + 1;
            end if;

            Previous_Left_Touch_Reading := Current_Left_Touch_State;
            Previous_Right_Touch_Reading := Current_Right_Touch_State;
         end;

         --  Update Odometer

         Robot_Position.Set_Odometer ((Right_Step_Counter + Left_Step_Counter));

         --  Wait for next cycle

         delay until Next_Release_Time;
      end loop;
   end Position_Tracker;

   --------------------
   -- Robot_Position --
   --------------------

   protected body Robot_Position is
   --        function Position return Room_Coordinates;
   --        function Heading return Bearing;

      -------------------
      -- Read_Odometer --
      -------------------

      function Read_Odometer return Natural is
      begin
         return Odometer;
      end Read_Odometer;

      ---------------------------
      -- Reset_Motion_Tracking --
      ---------------------------

      procedure Reset_Motion_Tracking is
      begin
         Odometer := 0;
      end Reset_Motion_Tracking;

      ------------------
      -- Set_Odometer --
      ------------------

      procedure Set_Odometer (Distance_Traveled : Natural) is
      begin
         Odometer := Distance_Traveled;
      end Set_Odometer;

   end Robot_Position;

end Frank.Position;
