------------------------------------------------------------------------------------------
--                                                                                      --
--                                 MINDSTORMS.NXT.MOTORS                                --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Atmel.AT91SAM7S; use Atmel.AT91SAM7S;

with Ada.Interrupts.Names; use Ada.Interrupts.Names;

package Mindstorms.NXT.Motors is
   type Motor_Id is (Motor_A, Motor_B, Motor_C);
   type Motor_Speed_Type is range -100 .. 100 with Size => 8 ;
   type Motor_Speeds_Type is array (Motor_Id) of Motor_Speed_Type;
   type Motor_Brake_Array is array (Motor_Id) of Boolean;

   procedure Set_All_Motor_Speeds (Speeds : Motor_Speeds_Type;
                                   Brake  : Motor_Brake_Array := (others => False));
   procedure Set_Motor_Speed (Motor : Motor_Id;
                              Speed : Motor_Speed_Type;
                              Brake : Boolean := False);
   function Motor_Speed (For_Motor : Motor_Id) return Motor_Speed_Type;

   --  The motor encoders store number of complete revolutions and the current
   --  angle from an intial state. Include facilities to reset these values.

   procedure Intialise_Motors;

   subtype Revolutions is Integer;
   subtype Encoder_Count is Integer;

   type Set_Of_Encoders is array (Motor_Id) of Encoder_Count;
   type Motor_Revolutions is array (Motor_Id) of Revolutions;

   function Complete_Revolutions (For_Motor : Motor_Id) return Revolutions;
   function All_Motor_Revolutions return Motor_Revolutions;
   function Encoder_Value (For_Motor : Motor_Id) return Encoder_Count;
   function All_Encoder_Values return Set_Of_Encoders;

   procedure Reset_Encoder (For_Motor : Motor_Id);
   procedure Reset_All_Encoders;

private

   protected Motor_State is
      procedure Initialise_Motors;

      function Encoder_Value (For_Motor : Motor_Id) return Encoder_Count;
      function All_Encoder_Values return Set_Of_Encoders;

      procedure Reset_Encoder (For_Motor : Motor_Id);
      procedure Reset_All_Encoders;

   private

      procedure Interface_Handler;
      pragma Attach_Handler (Interface_Handler, PIOA_Interrupt);

      Motor_Encoders : Set_Of_Encoders := (others => 0);
   end Motor_State;

   function Complete_Revolutions (For_Motor : Motor_Id) return Revolutions is
     (Motor_State.Encoder_Value (For_Motor) / 360);

   function Encoder_Value (For_Motor : Motor_Id) return Encoder_Count is
     (Motor_State.Encoder_Value (For_Motor));

   function All_Encoder_Values return Set_Of_Encoders is
     (Motor_State.All_Encoder_Values);

end Mindstorms.NXT.Motors;
