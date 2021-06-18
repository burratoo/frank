------------------------------------------------------------------------------------------
--                                                                                      --
--                                  MINDSTORMS.NXT.AVR                                  --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Ada.Real_Time; use Ada.Real_Time;

with Interfaces; use Interfaces;

with Mindstorms.NXT.Buttons; use Mindstorms.NXT.Buttons;
with Mindstorms.NXT.Motors;  use Mindstorms.NXT.Motors;
with System; use System;

package Mindstorms.NXT.AVR is

   subtype Sensor_Value_Type is Integer;
   type Sensors_Values is array (Sensor_Id) of Sensor_Value_Type;

   type AVR_AD_Value is mod 2#10# with Size => 16;
   type Power_Options is (On, Power_Off, Firmware_Mode) with Size => 8;
   for Power_Options use (On => 0, Power_Off => 16#5A#, Firmware_Mode => 16#A5#);

   -------------------------------
   -- Public Interface with AVR --
   -------------------------------

   function Battery_Voltage return Float;
   function Sensor_Value (Sensor : Sensor_Id) return Sensor_Value_Type;

   subtype AVR_PWM_Frequency is Unsigned_8 range 1 .. 32;
   type Output_Mode_Options is (Output_Break, Output_Float);
   type Output_Mode_Set is array (Motor_Id) of Output_Mode_Options with Pack, Size => 8;
   type Sensor_Supply_Options is (Off, Off_While_Measuring, On) with Size => 2;
   type Sensors_Supply_Modes is array (Sensor_Id)
     of Sensor_Supply_Options with Pack;

   for Output_Mode_Options use (Output_Break => 0, Output_Float => 1);
   for Sensor_Supply_Options use (Off => 0, Off_While_Measuring => 1, On => 2);

   type Battery_Type is (AA, Accu_Pack);
   type AVR_Major is range 0 .. 3;
   type AVR_Minor is range 0 .. 7;

   type Battery_Infomation is record
      Battery           : Battery_Type;
      AVR_Major_Version : AVR_Major;
      AVR_Minor_Version : AVR_Minor;
      Battery_Level     : AVR_AD_Value;
   end record with Size => 16;

   type AVR_AD_Values is array (Sensor_Id) of AVR_AD_Value;

   for Battery_Type use (AA => 0, Accu_Pack => 1);

   for Battery_Infomation use record
      Battery           at 0 range 15 .. 15;
      AVR_Major_Version at 0 range 13 .. 14;
      AVR_Minor_Version at 0 range 10 .. 12;
      Battery_Level     at 0 range 0 .. 9;
   end record;

   --  Communcation Types

   type Data_For_AVR is record
      Power         : Power_Options;
      PWM_Frequency : Unsigned_8;
      PWM_Values    : Motor_Speeds_Type;
      Empty_Byte    : Unsigned_8;
      Output_Mode   : Output_Mode_Set;
      Sensor_Supply : Sensors_Supply_Modes;
      Checksum      : Unsigned_8;
   end record;

   for Data_For_AVR use record
      Power         at 0 range 0 .. 7;
      PWM_Frequency at 1 range 0 .. 7;
      PWM_Values    at 2 range 0 .. 23;
      Empty_Byte    at 5 range 0 .. 7;
      Output_Mode   at 6 range 0 .. 7;
      Sensor_Supply at 7 range 0 .. 7;
      Checksum      at 8 range 0 .. 7;
   end record;

   type Data_For_ARM is record
      AD_Values     : AVR_AD_Values;
      Button_Values : Unsigned_16;
      Battery_State : Battery_Infomation;
      Checksum      : Unsigned_8;
   end record;

   for Data_For_ARM use record
      AD_Values     at 0 range 0 .. 63;
      Button_Values at 8 range 0 .. 15;
      Battery_State at 10 range 0 .. 15;
      Checksum      at 12 range 0 .. 7;
   end record;

   type Button_Filter is range 0 .. 10;
   type Button_Filters is array (Physical_Buttons) of Button_Filter;

   protected AVR_Gateway is

      function Battery_Level return AVR_AD_Value;
      function Button_States return Set_Of_Button_States;
      function Sensor_Value (Sensor : Sensor_Id) return Sensor_Value_Type;
      function Sensor_Readings return Sensors_Values;

      procedure Set_Power_State (Power    : Power_Options;
                                 PWM_Mode : Unsigned_8);

      procedure Set_All_Motors (Speeds : Motor_Speeds_Type; Modes : Output_Mode_Set);
      procedure Set_Motor (Motor : Motor_Id; Speed : Motor_Speed_Type; Mode : Output_Mode_Options);
      function Motor_Speed (For_Motor : Motor_Id) return Motor_Speed_Type;

      function Retrieve_Data_For_AVR return Data_For_AVR;
      procedure Store_Date_From_AVR (Data : Data_For_ARM);

   private
      Battery_State    : Battery_Infomation;
      State_Of_Buttons : Set_Of_Button_States;
      Deglitcher       : Button_Filters := (others => 0);
      Sensor_Values    : Sensors_Values;
      Power            : Power_Options := On;
      Motor_Speeds     : Motor_Speeds_Type := (others => 0);
      PWM_Frequency    : Unsigned_8 := 8;
      Output_Mode      : Output_Mode_Set := (others => Output_Break);
      Sensor_Supply    : Sensors_Supply_Modes := (others => Off);
   end AVR_Gateway;

   -------------------
   -- AVR Constants --
   -------------------

   --  PWM Frequency Constants

   Default_PWM_Frequency  : constant := 8;
   Off_PWM_Frequency      : constant := 0;
   Firmware_PWM_Frequency : constant := 16#5A#;

private

   --  Button Values

   Select_Button_Value : constant := 16#700#;
   Left_Button_Value   : constant := 16#50#;
   Right_Button_Value  : constant := 16#90#;
   Back_Button_Value   : constant := 16#280#;

   --  Battery

   Battery_Voltage_Multiplier : constant := 13.848 / 1_000;

   --  Communication values

   AVR_Init_String : constant String :=
                       Character'Val (16#CC#) & "Let's samba nxt arm in arm, (c)LEGO System A/S";
   --  String to initialise the AVR so it knows that the ARM is up and running.

   Initialisation_Delay : constant Time_Span := Milliseconds (20);
   AVR_Initialise_Delay : constant Time_Span := Milliseconds (20);
   --  Initialisation

   IO_Gap_Delay : constant Time_Span := Milliseconds (2);

   -----------------------
   -- AVR Communication --
   -----------------------

   --  Types used to comunicate with the AVR

   task AVR_Communicator with Storage_Size => 1024, Priority => 28;
   --

   --------------------------
   -- Function Expressions --
   --------------------------

   function Battery_Voltage return Float is
      (Float (AVR_Gateway.Battery_Level) * Battery_Voltage_Multiplier);

   function Sensor_Value (Sensor : Sensor_Id) return Sensor_Value_Type is
      (AVR_Gateway.Sensor_Value (Sensor));

end Mindstorms.NXT.AVR;
