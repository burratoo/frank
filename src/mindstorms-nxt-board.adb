------------------------------------------------------------------------------------------
--                                                                                      --
--                                  MINDSTORMS.NXT.BOARD                                --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Atmel.AT91SAM7S;     use Atmel.AT91SAM7S;
with Atmel.AT91SAM7S.ADC; use Atmel.AT91SAM7S.ADC;
with Atmel.AT91SAM7S.PIO; use Atmel.AT91SAM7S.PIO;
with Atmel.AT91SAM7S.PMC; use Atmel.AT91SAM7S.PMC;
with Atmel.AT91SAM7S.SPI; use Atmel.AT91SAM7S.SPI;
with Atmel.AT91SAM7S.TC;  use Atmel.AT91SAM7S.TC;

with Mindstorms.NXT.AVR;
with Mindstorms.NXT.LCD;
with Mindstorms.NXT.Display;
with Mindstorms.NXT.Motors;

package body Mindstorms.NXT.Board is

   ----------------------
   -- Initialise_Board --
   ----------------------

   procedure Initialise_Board is
   begin
      PMC.Peripheral_Clock_Enable_Register :=
        (P_PIOA => Enable,
         others => No_Change);

      --  Setup ADC Interface

      Atmel.AT91SAM7S.ADC.Initialise_Interface
        (Settings =>
           (Hardware_Trigger     => Enable,
            Trigger_Selection    => TIOA1,
            Resolution           => Eight_Bit,
            Sleep_Mode           => Disable,
            Prescaler            => 16#3F#,
            Startup_Time         => 16#2#,
            Sample_And_Hold_Time => 16#9#));

      --  Setup TC Interface

      Atmel.AT91SAM7S.TC.Initialise_Interface
        (Settings =>
           (External_Clock_Signal => (others => TCLK)));

      --  Setup the LCD and SPI interface it requires

      Atmel.AT91SAM7S.SPI.Initialise_Interface
        (SPI_Settings                =>
           (Master_Slave_Mode          => Master,
            Peripheral_Select          => Fixed,
            Chip_Select_Decode         => Direct,
            Mode_Fault_Detection       => Disable,
            Local_Loopback             => Disable,
            Peripheral_Chip_Select     => LCD.Display_Driver_Id,
            Delay_Between_Chip_Selects => 6),
         Chip_Select_Pin_Assignments =>
           (LCD.Display_Driver_Pin => (Pin => IO_Line_B_SPI_CS2_Pin_10,
                                       Pin_Function => B),
            others                 => (Pin => 0, Pin_Function => PIO_Function)));

      Atmel.AT91SAM7S.SPI.Setup_Chip_Select_Pin
        (For_Pin              => LCD.Display_Driver_Pin,
         Chip_Select_Settings =>
           (Clock_Polarity                    => Inactive_High,
            Clock_Phase                       => Data_Changed_First,
            Chip_Select_Active_After_Transfer => False,
            Bits_Per_Transfer                 => 8,
            Serial_Clock_Divider              => 16#18#,
            DLYBS                             => 16#18#,
            DLYBCT                            => 16#18#));

      Mindstorms.NXT.LCD.Power_On;
      Mindstorms.NXT.Display.Clear_Screen;

      --  Initialise motor controller

      Mindstorms.NXT.Motors.Intialise_Motors;
   end Initialise_Board;

begin
   Mindstorms.NXT.Board.Initialise_Board;
end Mindstorms.NXT.Board;
