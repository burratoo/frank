------------------------------------------------------------------------------------------
--                                                                                      --
--                                    FRANK.DATALINK                                    --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

--  This package communicates Frank's state to a host over Frank's Bluetooth connection.

with Frank.Control;   use Frank.Control;
with Frank.Obstacles; use Frank.Obstacles;

package Frank.Datalink is

   task Datalink with Storage_Size => 1024, Priority => 10;
   --  Task that uploades Frank's state to a remote host every 100ms

private

   type Datalink_Message is record
      Frank_State        : Frank_States;
      Distance_To_Object : Centimetres;
      Distance_Traveled  : Natural;
      Battery_Voltage    : Float;
   end record;
   -- Format of the message that will be sent to the host

end Frank.Datalink;
