------------------------------------------------------------------------------------------
--                                                                                      --
--                                 MINDSTORMS.NXT.MOTORS                                --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Atmel.AT91SAM7S.PIO; use Atmel.AT91SAM7S.PIO;
with Atmel.AT91SAM7S.AIC; use Atmel.AT91SAM7S.AIC;

with Mindstorms.NXT.AVR;  use Mindstorms.NXT.AVR;

package body Mindstorms.NXT.Motors is

   Motor_A_Tacho_Pin : constant := 15;
   Motor_A_Dir_Pin  : constant := 1;

   Motor_B_Tacho_Pin : constant := 26;
   Motor_B_Dir_Pin  : constant := 9;

   Motor_C_Tacho_Pin : constant := 0;
   Motor_C_Dir_Pin  : constant := 8;

   type Motor_Pins is array (Motor_Id) of PIO_Lines;
   Motor_Tacho_Pins : constant Motor_Pins := (Motor_A_Tacho_Pin, Motor_B_Tacho_Pin, Motor_C_Tacho_Pin);
   Motor_Dir_Pins   : constant Motor_Pins := (Motor_A_Dir_Pin, Motor_B_Dir_Pin, Motor_C_Dir_Pin);

   procedure Intialise_Motors is
   begin
      Motor_State.Initialise_Motors;
   end Intialise_Motors;

   procedure Set_All_Motor_Speeds
     (Speeds : Motor_Speeds_Type;
      Brake  : Motor_Brake_Array := (others => False))
   is
      Modes : Output_Mode_Set;
   begin
      for M in Modes'Range loop
         if Speeds (M) = 0 and then not Brake (M) then
            Modes (M) := Output_Break;
         else
            Modes (M) := Output_Float;
         end if;
      end loop;
      AVR_Gateway.Set_All_Motors (Speeds, Modes);
   end Set_All_Motor_Speeds;

   procedure Set_Motor_Speed (Motor : Motor_Id;
                              Speed : Motor_Speed_Type;
                              Brake : Boolean := False)
   is
      Mode : Output_Mode_Options := Output_Float;
   begin
      if Speed = 0 and then not Brake then
         Mode := Output_Break;
      end if;
      AVR_Gateway.Set_Motor (Motor, Speed, Mode);
   end Set_Motor_Speed;

   function Motor_Speed (For_Motor : Motor_Id) return Motor_Speed_Type is
     (AVR_Gateway.Motor_Speed (For_Motor));

   function All_Motor_Revolutions return Motor_Revolutions is
      MRS : Motor_Revolutions :=  Motor_Revolutions (Motor_State.All_Encoder_Values);
   begin
      for MR of MRS loop
         MR := MR / 360;
      end loop;
      return MRS;
   end All_Motor_Revolutions;

   procedure Reset_Encoder (For_Motor : Motor_Id) is
   begin
      Motor_State.Reset_Encoder (For_Motor);
   end Reset_Encoder;

   procedure Reset_All_Encoders is
   begin
      Motor_State.Reset_All_Encoders;
   end Reset_All_Encoders;

   protected body Motor_State is
      function Encoder_Value (For_Motor : Motor_Id) return Encoder_Count is
      begin
         return Motor_Encoders (For_Motor);
      end Encoder_Value;

      function All_Encoder_Values return Set_Of_Encoders is
      begin
         return Motor_Encoders;
      end All_Encoder_Values;

      procedure Reset_Encoder (For_Motor : Motor_Id) is
      begin
         Motor_Encoders (For_Motor) := 0;
      end Reset_Encoder;

      procedure Reset_All_Encoders is
      begin
         Motor_Encoders := (others => 0);
      end Reset_All_Encoders;

      procedure Initialise_Motors is
         Motor_Pins_Enable_Set  : PIO.Enable_Set :=
                                    (Motor_A_Tacho_Pin => Enable,
                                     Motor_A_Dir_Pin   => Enable,
                                     Motor_B_Tacho_Pin => Enable,
                                     Motor_B_Dir_Pin   => Enable,
                                     Motor_C_Tacho_Pin => Enable,
                                     Motor_C_Dir_Pin   => Enable,
                                     others            => No_Change);
         Motor_Pins_Disable_Set : PIO.Disable_Set :=
                                    (Motor_A_Tacho_Pin => Disable,
                                     Motor_A_Dir_Pin   => Disable,
                                     Motor_B_Tacho_Pin => Disable,
                                     Motor_B_Dir_Pin   => Disable,
                                     Motor_C_Tacho_Pin => Disable,
                                     Motor_C_Dir_Pin   => Disable,
                                     others            => No_Change);
      begin
         PIO.Interrupt_Disable_Register := Motor_Pins_Disable_Set;
         PIO.Input_Filter_Enable_Register := Motor_Pins_Enable_Set;
         PIO.Pull_Up_Disable_Register := Motor_Pins_Disable_Set;
         PIO.Output_Disable_Register := Motor_Pins_Disable_Set;
         PIO.PIO_Enable_Register := Motor_Pins_Enable_Set;

         Reset_All_Encoders;

         AIC.Interrupt_Enable_Command_Register.Interrupt :=
           (P_PIOA  => Enable,
            others => No_Change);
         PIO.Interrupt_Enable_Register :=
           (Motor_A_Tacho_Pin => Enable,
            Motor_B_Tacho_Pin => Enable,
            Motor_C_Tacho_Pin => Enable,
            others            => No_Change);
      end Initialise_Motors;

      procedure Interface_Handler is
         Interrupt_Status : constant PIO.Change_Set := PIO.Interrupt_Status_Register;
         Pin_Value        : constant PIO.Binary_Set := PIO.Pin_Data_Status_Register;
      begin
         for Motor in Motor_Id'Range loop
            if Interrupt_Status (Motor_Tacho_Pins (Motor)) = Change_Occured then
               if Pin_Value (Motor_Tacho_Pins (Motor)) xor  Pin_Value (Motor_Dir_Pins (Motor)) then
                  Motor_Encoders (Motor) := Motor_Encoders (Motor) + 1;
               else
                  Motor_Encoders (Motor) := Motor_Encoders (Motor) - 1;
               end if;
            end if;
         end loop;
      end Interface_Handler;
   end Motor_State;
end Mindstorms.NXT.Motors;
