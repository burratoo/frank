------------------------------------------------------------------------------------------
--                                                                                      --
--                               FRANK.DATALINK.MANAGER                                 --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Ada.Real_Time;

with Mindstorms.NXT.Bluetooth; use Mindstorms.NXT.Bluetooth;

package body Frank.Datalink.Manager is

   --------------------
   -- Datalink_Agent --
   --------------------

   task body Datalink_Agent is
      State : Datalink_State;
      --  The new state of the Datalink Manager

      Connected_To : Bluetooth_Address;
      --  The address of the host Bluetooth device that we have connected to

   begin
      loop
         --  Wait for another task to change the state of the Datalink Manager

         Datalink_Manager.Wait_For_Change_Of_State (State);

         --  Another task has requested the state to be changed. Perform the actions
         --  associated with that new state.

         case State is
            when Initialise_Bluetooth =>
               Initialise_Bluetooth;
               Datalink_Manager.Set_State (Bluetooth_Ready);

            when Reset_Device =>
               Reset_Bluetooth;
               Datalink_Manager.Set_State (Bluetooth_Ready);

            when Open_Stream =>
               declare
                  Established_Connection : Boolean;
               begin
                  Set_Discoverable (True);

                  Accept_New_Connection
                    (Pin                    => "0000",
                     BT_Address             => Connected_To,
                     Connection_Established => Established_Connection);

                  if Established_Connection then
                     Open_Data_Stream;
                     Datalink_Manager.Set_State (Stream_Opened);
                  else
                     Datalink_Manager.Set_State (Bluetooth_Ready);
                  end if;
               end;

            when Turn_Off =>
               Datalink_Manager.Set_State (Off);
               Turn_Bluetooth_Off;

            when others =>
               null;

         end case;
      end loop;
   end Datalink_Agent;

   -----------------------
   --  Datalink Manager --
   -----------------------

   protected body Datalink_Manager is

      ---------------------------
      -- Accept_New_Connection --
      ---------------------------

      procedure Accept_New_Connection is
      begin
         Manager_State := Open_Stream;
         Changed_State := True;
      end Accept_New_Connection;

      ----------------
      -- Initialise --
      ----------------

      procedure Initalise is
      begin
         Manager_State := Initialise_Bluetooth;
         Changed_State := True;
      end Initalise;

      ------------------
      -- Reset_Device --
      ------------------

      procedure Reset_Device is
      begin
         Manager_State := Reset_Device;
         Changed_State := True;
      end Reset_Device;

      ---------------
      -- Set_State --
      ---------------

      procedure Set_State (New_State : in Datalink_State) is
      begin
         Manager_State := New_State;
      end Set_State;

      ----------------------
      -- State_Of_Manager --
      ----------------------

      function State_Of_Manager return Datalink_State is
      begin
         return Manager_State;
      end State_Of_Manager;

      ------------------------
      -- Turn_Off_Bluetooth --
      ------------------------

      procedure Turn_Off_Bluetooth is
      begin
         Manager_State := Turn_Off;
         Changed_State := True;
      end Turn_Off_Bluetooth;

      ------------------------------
      -- Wait_For_Change_Of_State --
      ------------------------------

      entry Wait_For_Change_Of_State
        (New_State : out Datalink_State) when Changed_State
      is
      begin
         Changed_State := False;
         New_State     := Manager_State;
      end Wait_For_Change_Of_State;

   end Datalink_Manager;

end Frank.Datalink.Manager;
