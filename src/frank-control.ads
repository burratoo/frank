------------------------------------------------------------------------------------------
--                                                                                      --
--                                    FRANK.CONTROL                                     --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

--  This package contains Frank's control logic

with Frank.Obstacles;
with Frank.Position;

package Frank.Control is

   --  The states of Frank

   type Frank_States is
     (Resting,
      --  Frank is not moving and is waiting for the operator to tell it to start walking

      Begin_Walking,
      --  State to tell Frank to start walking

      Reset_Feet,
      --  Move both feet such that they are both touching their respective feet touch
      --  sensors.

      Align_Feet_For_Walking,
      --  Move the right foot so that it is 180 degrees out of phase of the left foot

      Walking,
      --  Frank is walking!

      Avoiding_Obstacle_1,
      --  Phase 1 of avoiding an obstacle: move head to the right and detect distance
      --  to closest object.

      Avoiding_Obstacle_2,
      --  Phase 2 of avoiding an obstacle: move head to the left and detect distance
      --  to closest object.

      Avoiding_Obstacle_3,
      --  Phase 3 of avoiding an obstacle: turn Frank left or right depending on which
      --  direction has an object further away.

      Turning_Left,
      --  Frank is turning left

      Turning_Right,
      --  Frank is turning right

      Stop_Walking);
      --  Frank has stopped walking

   task Frank_Control_Logic with Storage_Size => 2048;
   --  A cyclic task that implements Frank's control loop. It is responsible for making
   --  the robot walk and to turn around if it encounters an obstacles. The control loop
   --  runs every 100ms.

   --  The Frank_State protected object provides the means for the User Interface and
   --  Frank_Control_Logic tasks to safely exchange data and commands.

   protected Frank_State is

      --------------------------
      -- UI Callable Routines --
      --------------------------

      function State return Frank_States;
      --  Return the State that Frank is currently in

      procedure Start_Frank_Walk;
      --  Have the robot start walking

      procedure Stop_Frank_Walk;
      --  Have the robot stop walking

      procedure Update_State (New_State : in Frank_States);
      --  Move Frank into the the new state

      -----------------------------
      -- Datalink Agent Routines --
      -----------------------------

      procedure Update_State
        (New_State            : in Frank_States;
         Distance_To_Obstacle : in Obstacles.Centimetres);
      --  Update the state of the robot to New_State and record the distance to the
      --  nearest obstacle.

   private
      Current_State : Frank_States := Resting;
      --  The current controll state Frank is in

      Object_Distance : Obstacles.Centimetres;
      --  Distance to the nearest obstacle in front of Frank

   end Frank_State;

end Frank.Control;
