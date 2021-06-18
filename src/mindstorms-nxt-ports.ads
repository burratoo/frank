------------------------------------------------------------------------------------------
--                                                                                      --
--                                 MINDSTORMS.NXT.PORTS                                 --
--                                                                                      --
--                         Copyright (C) 2014-2021, Pat Bernardi                        --
--                                                                                      --
------------------------------------------------------------------------------------------

with Atmel.AT91SAM7S; use Atmel.AT91SAM7S;

package Mindstorms.NXT.Ports with Pure is
   type Port_Id is range 1 .. 4;


   type Port_Pin is record
      Clock : PIO_Lines;
      Data  : PIO_Lines;
   end record;

   NXT_Ports_Pins : constant array (Port_Id) of Port_Pin :=
                      ((Clock => 23, Data => 18),
                       (Clock => 28, Data => 19),
                       (Clock => 29, Data => 20),
                       (CLock => 30, Data => 2));
end Mindstorms.NXT.Ports;
