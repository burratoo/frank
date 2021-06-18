------------------------------------------------------------------------------------------
--                                                                                      --
--                                 ADA.INTERRUPTS.NAMES                                 --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

package Ada.Interrupts.Names with Preelaborate is
   PIOA_Interrupt : constant Interrupt_Id := P_PIOA;
   SPI_Interrupt  : constant Interrupt_Id := P_SPI;
   TWI_Interrupt  : constant Interrupt_Id := P_TWI;
   US1_Interrupt  : constant Interrupt_Id := P_US1;
   SSC_Interrupt  : constant Interrupt_Id := P_SSC;
end Ada.Interrupts.Names;
