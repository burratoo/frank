------------------------------------------------------------------------------------------
--                                                                                      --
--                                    FRANK.CONTROL                                     --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Frank.Hardware;               use Frank.Hardware;
with Frank.Obstacles;              use Frank.Obstacles;

with Mindstorms.NXT.Motors;        use Mindstorms.NXT.Motors;
with Mindstorms.NXT.Touch_Sensors; use Mindstorms.NXT.Touch_Sensors;

with Ada.Real_Time;                use Ada.Real_Time;

package body Frank.Control is

   -------------------------
   -- Frank_Control_Logic --
   -------------------------

   task body Frank_Control_Logic is
      Task_Cycle_Length : Time_Span := Milliseconds (100);
      --  The period between successive runs of the task's run-loop

      Next_Release_Time : Time := Clock;
      --  Time the task will execute its next cycle

      Left_Foot_Motor  : constant Motor_Id := Motor_C;
      Right_Foot_Motor : constant Motor_Id := Motor_B;
      Head_Motor       : constant Motor_Id := Motor_A;
      --  Role names for each LEGO Mindstorms NXT motor

      Walk_Motor_Speed : constant Motor_Speed_Type := 60;
      --  Speed of the motors when Frank is walking

      Align_Feet_Speed : constant Motor_Speed_Type := 40;
      --  Speed of the motors when the feet are adjusted so that they are pressing the
      --  touch sensors.

      Right_Foot_Offset : constant Encoder_Count := 180;
      --  The difference in encoder counts between the left and right feet

      Flat_Foot_Count : constant Encoder_Count := 210;
      -- The value of the feet encoders such that Frank is standing upright

      Revolutions_For_Turning : constant Revolutions := 10;
      --  The number of motor revolutions required for turning 90 degrees

      Closest_Obstacle_Distance_Allowed : constant Centimetres := 30;
      --  The closest Frank is allowed to an obstacle in centimetres

      Distance_To_Nearest_Object : Centimetres := 0;
      --  Distance to the nearest object in front of Frank

      Left_Obstacle_Distance     : Centimetres := 0;
      --  Distance to the nearest object to the left of Frank

      Right_Obstacle_Distance    : Centimetres := 0;
      --  Distance to the nearest object to the right of Frank

      Next_State : Frank_States;
      --  The next state in the state table to transition Frank to after reseting the feet

   begin
      loop
         --  State table

         case Frank_State.State is
            when Resting =>
               --  Nothing to do when Frank is resting

               null;

            when Begin_Walking =>
               --  To begin walking first reset the feet so they are flat and then align
               --  the feet for walking (moving the feet 180 degrees out of phase).

               Frank_State.Update_State
                 (New_State => Reset_Feet);
               Next_State := Align_Feet_For_Walking;

            when Reset_Feet =>
               --  To reset the feet, spin each motor separately until the feet touch
               --  sensor is triggered.

               if not Is_Pressed (Left_Foot_Touch_Sensor) then
                  Set_All_Motor_Speeds (Speeds =>
                                          (Left_Foot_Motor => Align_Feet_Speed,
                                           others          => 0));

               elsif not Is_Pressed (Right_Foot_Touch_Sensor) then
                  Set_All_Motor_Speeds (Speeds =>
                                          (Right_Foot_Motor => Align_Feet_Speed,
                                           others           => 0));

               else

                  Set_All_Motor_Speeds (Speeds => (others => 0));

                  --  Delay a short period to ensure the motors have stopped before the
                  --  encoders are cleared.

                  delay until Clock + Milliseconds (5);
                  Reset_All_Encoders;

                  --  Transition the state table to the preselected Next_State

                  Frank_State.Update_State
                    (New_State => Next_State);

               end if;

            when Align_Feet_For_Walking =>
               --  To walk, Frank's feet need to be 180 degrees out of phase. To achieve
               --  this run the right foot motor until the motor encoder reads 180.

               Set_All_Motor_Speeds (Speeds =>
                                       (Right_Foot_Motor => Align_Feet_Speed,
                                        others           => 0));

               while Encoder_Value (Right_Foot_Motor) mod 180 /= 0 loop
                  delay until Clock + Milliseconds (1);
               end loop;

               Set_All_Motor_Speeds (Speeds => (others => 0));

               --  Transition to the Walking state to start walking

               Frank_State.Update_State
                 (New_State => Walking);

            when Walking =>
               --  If the object in front of Frank is beyond the danger zone (or if there
               --  is no object at all), run the feet motors at walking speed.

               if Distance_To_Nearest_Object > Closest_Obstacle_Distance_Allowed then
                  Set_All_Motor_Speeds (Speeds =>
                                          (Right_Foot_Motor => Walk_Motor_Speed,
                                           Left_Foot_Motor  => Walk_Motor_Speed,
                                           others           => 0));

               --  Otherwise if Frank gets to close to an obstacle stop and perform the
               --  obstacle avoidance procedure.

               else
                  Set_All_Motor_Speeds (Speeds => (others => 0));
                  Frank_State.Update_State
                    (New_State => Avoiding_Obstacle_1);

               end if;

            when Avoiding_Obstacle_1 =>
               --  First phase of avoiding an obstacle is to look right.

               Reset_Encoder (Head_Motor);
               Set_All_Motor_Speeds (Speeds => (Head_Motor => 50, others => 0));

               --  Frank's head looks right when the encoder value reaches 150

               while Encoder_Value (Head_Motor) < 150 loop
                  --  ??? why is this delay here
                  delay until Clock + Milliseconds (1);
               end loop;

               Set_All_Motor_Speeds (Speeds => (others => 0));

               Frank_State.Update_State
                 (New_State => Avoiding_Obstacle_2);

            when Avoiding_Obstacle_2 =>
               --  Second phase of avoiding an obstacle is to read the ultrasonic sensor
               --  to see if there's an object to our right. We do this in a second
               --  phase to give the ultrasonic sensor time to get a reading in the
               --  new direction.

               Right_Obstacle_Distance := Distance_To_Nearest_Object;

               --  Once we have a distance reading, move Frank's head to the left

               Set_All_Motor_Speeds (Speeds => (Head_Motor => 50, others => 0));
               while Encoder_Value (Head_Motor) < 450 loop
                  delay until Clock + Milliseconds (1);
                  --  ??? why is this delay here
               end loop;

               Set_All_Motor_Speeds (Speeds => (others => 0));

               Frank_State.Update_State
                 (New_State => Avoiding_Obstacle_3);

            when Avoiding_Obstacle_3 =>
               --  Final phase of avoiding an obstacle is to read the ultrasonic sensor
               --  to see if there's an object to our left.

               Left_Obstacle_Distance := Distance_To_Nearest_Object;

               --  Once we have a distance reading, move Frank's to look forward

               Set_All_Motor_Speeds (Speeds => (Head_Motor => 50, others => 0));
               while Encoder_Value (Head_Motor) < 600 loop
                  delay until Clock + Milliseconds (1);
                  --  ??? why is this delay here
               end loop;

               Set_All_Motor_Speeds (Speeds => (others => 0));

               --  Move Frank in the direction with the least obstruction. If the left and
               --  right offer the same choice, arbitrarily pick left.

               if Left_Obstacle_Distance >= Right_Obstacle_Distance then
                  Next_State := Turning_Left;
                  Frank_State.Update_State
                    (New_State => Reset_Feet);
               else
                    Frank_State.Update_State
                      (New_State => Reset_Feet);
                  Next_State := Turning_Right;
               end if;

            when Turning_Left =>
               --  To turn left first make sure the left foot is flat first. Then run the
               --  right motor the require number of revolutions to turn Frank 90 degrees
               --  to the left.

               if Encoder_Value (Left_Foot_Motor) < Flat_Foot_Count then
                  Set_All_Motor_Speeds (Speeds =>
                                          (Left_Foot_Motor => Walk_Motor_Speed,
                                           others          => 0));
               elsif Complete_Revolutions (For_Motor => Right_Foot_Motor) <
                 Revolutions_For_Turning
               then
                  Set_All_Motor_Speeds (Speeds =>
                                          (Right_Foot_Motor => Walk_Motor_Speed,
                                           others           => 0));
               else
                  --  Transition to the Walking state once the turn is completed

                  Set_All_Motor_Speeds ((others => 0));
                  Frank_State.Update_State (New_State => Begin_Walking);
               end if;

            when Turning_Right =>
               --  To turn right first make sure the right foot is flat first. Then run
               --  the left motor the require number of revolutions to turn Frank 90
               --  degrees to the right.

               if Encoder_Value (Right_Foot_Motor) < Flat_Foot_Count then
                  Set_All_Motor_Speeds (Speeds =>
                                          (Right_Foot_Motor => Walk_Motor_Speed,
                                           others           => 0));
               elsif Complete_Revolutions (For_Motor => Left_Foot_Motor) <
                 Revolutions_For_Turning
               then
                  Set_All_Motor_Speeds (Speeds =>
                                          (Left_Foot_Motor => Walk_Motor_Speed,
                                           others          => 0));
               else
                  Set_All_Motor_Speeds ((others => 0));
                  Frank_State.Update_State (New_State => Begin_Walking);
               end if;

            when Stop_Walking =>
               --  Stop Frank from walking by stopping the feet motors. Reset afterwards
               --  so Frank is standing flat on his feet.

               Set_All_Motor_Speeds (Speeds => (others => 0));
               Frank_State.Update_State
                 (New_State => Resting);
         end case;

         --  Delay task until next cycle

         Next_Release_Time := Next_Release_Time + Task_Cycle_Length;
         delay until Next_Release_Time;
      end loop;
   end Frank_Control_Logic;

   -----------------
   -- Frank_State --
   -----------------

   protected body Frank_State is

      ----------------------
      -- Start_Frank_Walk --
      ----------------------

      procedure Start_Frank_Walk is
      begin
         Current_State := Begin_Walking;
      end Start_Frank_Walk;

      -----------
      -- State --
      -----------

      function State return Frank_States is
      begin
         return Current_State;
      end State;

      ---------------------
      -- Stop_Frank_Walk --
      ---------------------

      procedure Stop_Frank_Walk is
      begin
         Current_State := Stop_Walking;
      end Stop_Frank_Walk;

      ------------------
      -- Update_State --
      ------------------

      procedure Update_State
        (New_State            : Frank_States;
         Distance_To_Obstacle : Obstacles.Centimetres) is
      begin
         Current_State    := New_State;
         Object_Distance  := Distance_To_Obstacle;
      end Update_State;

      ------------------
      -- Update_State --
      ------------------

      procedure Update_State (New_State : Frank_States) is
      begin
         Current_State := New_State;
      end Update_State;

   end Frank_State;

end Frank.Control;
