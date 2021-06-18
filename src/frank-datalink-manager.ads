------------------------------------------------------------------------------------------
--                                                                                      --
--                               FRANK.DATALINK.MANAGER                                 --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

--  This package manages the datalink connection to the upstream device

with System; use System;

package Frank.Datalink.Manager is

   type Datalink_State is
     (Off, Initialise_Bluetooth, Reset_Device,
      Bluetooth_Ready, Open_Stream, Stream_Opened, Turn_Off);
   --  The state the datalink can be in


   task Datalink_Agent with Storage_Size => 2048, Priority => 1;
   --  Task that implements the Datalink Manager state machine

   --  The Datalink_Manager protected object stores the state of the Bluetooth datalink
   --  and user operations to communicate changes to the state to the Datalink_Manager
   --  task.

   protected Datalink_Manager is

      ---------------------
      -- Client Routines --
      ---------------------

      function State_Of_Manager return Datalink_State;
      --  ReturnS the current Datalink manager state

      procedure Initalise;
      --  Initialise the Datalink Manager

      procedure Reset_Device;
      --  Reset the Bluetooth module

      procedure Accept_New_Connection;
      --  Accept a new Bluetooth connection

      procedure Turn_Off_Bluetooth;
      --  Turn off the Bluetooth module

      -----------------------------
      -- Datalink Agent Routines --
      -----------------------------

      entry Wait_For_Change_Of_State (New_State : out Datalink_State);
      --  Wait until the Datalink Manager changes state. Return the new state of the
      --  Datalink Manager.

      procedure Set_State (New_State : in Datalink_State);
      --  Set the state of the Datalink Manager to the passed New_State

   private

      Manager_State : Datalink_State;
      --  State of the datalink

      Changed_State : Boolean := False;
      --  Flags when the datalink has changed state to allow the Datalink_Agent to run
      --  and manage the new state.

   end Datalink_Manager;

end Frank.Datalink.Manager;
