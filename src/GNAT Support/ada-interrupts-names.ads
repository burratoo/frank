------------------------------------------------------------------------------------------
--                                                                                      --
--                                 ADA.INTERRUPTS.NAMES                                 --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Atmel.AT91SAM7S; use Atmel.AT91SAM7S;

package Ada.Interrupts.Names is

   PIOA_Interrupt : constant Interrupt_ID := PIOA_Id;
   SPI_Interrupt  : constant Interrupt_ID := SPI_Id;
   TWI_Interrupt  : constant Interrupt_ID := TWI_Id;
   US1_Interrupt  : constant Interrupt_ID := US1_Id;
   SSC_Interrupt  : constant Interrupt_ID := SSC_Id;

end Ada.Interrupts.Names;
