------------------------------------------------------------------------------------------
--                                                                                      --
--                                    FRANK.DATALINK                                    --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Frank.Position;           use Frank.Position;

with Mindstorms.NXT.AVR;
with Mindstorms.NXT.Bluetooth;

with Ada.Real_Time;            use Ada.Real_Time;
with System;                   use System;

package body Frank.Datalink is

   ---------------
   --  Datalink --
   ---------------

   task body Datalink is
      Task_Cycle_Period : Time_Span := Milliseconds (100);
      --  The period between successive runs of the task's run-loop

      Next_Release_Time : Time := Clock;
      --  Time the task will execute its next cycle

      Message           : Datalink_Message;
      --  Message to be sent to remote host

   begin
      loop
         --  Create the message from Frank's state and transmit it to the host if a
         --  datalink has been established.

         if Datalink_Established then
            Message := (Frank_State        => Frank_State.State,
                        Distance_To_Object => Sensor_Data.Distance_To_Nearist_Object,
                        Distance_Traveled  => Robot_Position.Read_Odometer,
                        Battery_Voltage    => Mindstorms.NXT.AVR.Battery_Voltage);

            Mindstorms.NXT.Bluetooth.Exchange_Messages
              (Transmit_Message  => Message'Address,
               Transmit_Length   => Message'Size / 8,
               Receive_Message   => Null_Address,
               Receive_Length    => 0);

         end if;

         --  Delay task until next cycle

         Next_Release_Time := Next_Release_Time + Task_Cycle_Period;
         delay until Next_Release_Time;
      end loop;
   end Datalink;

end Frank.Datalink;
