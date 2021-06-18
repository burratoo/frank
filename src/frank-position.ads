------------------------------------------------------------------------------------------
--                                                                                      --
--                                    FRANK.POSITION                                    --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

--  This package tracks Frank's position as he moves around

package Frank.Position is

   subtype Room_Dimension is Integer;
   --  Room dimension

   type Bearing is mod 360;
   --  Bearing the robot is heading in

   type Room_Coordinates is record
      X, Y : Room_Dimension;
   end record;
   --  Representation of where Frank is in the room

   --  Robot_Position contains the position state of Frank. It can be safely read and
   --  written by multiple tasks.

   protected Robot_Position is
      --  function Position return Room_Coordinates;
      --  Where Frank is in the room

      --  function Heading return Bearing;
      --  The direction Frank is heading

      procedure Set_Odometer (Distance_Traveled : Natural);
      --  Set the number of sets Frank has taken

      function Read_Odometer return Natural;
      --  Number of steps Frank has taken

      procedure Reset_Motion_Tracking;
      --  Reset all position data to zero
   private
      -- Current_Position : Room_Coordinates := (0, 0);
      -- Current_Heading  : Bearing := 0;
      Odometer : Natural := 0;
      --  Number of steps Frank has taken

   end Robot_Position;

   task Position_Tracker with Storage_Size => 1024;
   --  Tracks the number of steps Frank has taken. It polls the feet touch sensors every
   --  4 milliseconds to determine each unique step.

end Frank.Position;
