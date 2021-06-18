------------------------------------------------------------------------------------------
--                                                                                      --
--                                   FRANK_THE_ROBOT                                    --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

--  Entry point for the main Ada task. For Frank the main task runs the robot's user
--  interface. Library level tasks that are created during the elaboration of the program
--  are responsible for the control and communication functions of Frank.

with Frank.User_Interface;

procedure Frank_The_Robot with Priority => 7 is
begin
   Frank.User_Interface.Run_Loop;
end Frank_The_Robot;
