------------------------------------------------------------------------------
--                                                                          --
--                           GNAT RAVENSCAR for NXT                         --
--                                                                          --
--                       Copyright (C) 2010, AdaCore                        --
--                                                                          --
-- This is free software; you can  redistribute it  and/or modify it under  --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion. This is distributed in the hope that it will be useful, but WITH-  --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNARL; see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- As a special exception,  if other files  instantiate  generics from this --
-- unit, or you link  this unit with other files  to produce an executable, --
-- this  unit  does not  by itself cause  the resulting  executable  to  be --
-- covered  by the  GNU  General  Public  License.  This exception does not --
-- however invalidate  any other reasons why  the executable file  might be --
-- covered by the  GNU Public License.                                      --
--                                                                          --
------------------------------------------------------------------------------

--  Based on the sound driver provided by the LeJOS project.

with Interfaces;  use Interfaces;
with System;

package Mindstorms.NXT.Audio is
   pragma Elaborate_Body;

   procedure Mute;
   --  prevent sound from coming out of the speaker

   procedure Unmute;
   --  allow sound from the speaker

   Maximum_Volume : constant := 100;

   subtype Allowed_Volume is Integer range 0 .. Maximum_Volume;
   --  Zero is muted, i.e., no sound output

   procedure Play_Tone
     (Frequency : Unsigned_32;
      Interval  : Unsigned_32;
      Volume    : Allowed_Volume);
   --  Plays a tone of the specified Frequency for the specified Interval.

   --  The min, max, and default frequencies used for playing input samples (as
   --  opposed to generated tones)

   Maximum_Rate : constant := 22_050;
   Minimum_Rate : constant := 2_000;
   Default_Rate : constant := 8_000;

   subtype Sampling_Rates is Unsigned_32 range Minimum_Rate .. Maximum_Rate;

   procedure Play_Sample
     (Input        : System.Address;
      Input_Length : Unsigned_32;
      Volume       : Allowed_Volume;
      Rate         : Sampling_Rates := Default_Rate);
   --  Plays the sound sample starting at Input, of extent Input_Length. We
   --  don't use an explicit array type for Input because in practice the input
   --  values will come via the linker so the user won't know how big the array
   --  should be. We don't use an explicit access type because that would
   --  require the user to do the conversion from the address provided by the
   --  linker, hence it would not be any safer and not convenient for the user.
   --
   --  The address provided by Input is expected to be the starting address of
   --  a sound sample, such as that of a wav file. Note that only 8-bit PCM
   --  values are supported.
   --  Input_Length is given in terms of bytes.
   --  The value of Rate should match what was actually used to create the
   --  input sample, so when playing wav files the value specified should come
   --  from the input wav file metadata. See NXT.Audio.Wav, for example.

   function Time_Remaining return Integer;
   --  Returns the approximate number of milliseconds remaining in the
   --  currently playing tone or sample.
   --  Returns zero when no tone or sample is playing.

end Mindstorms.NXT.Audio;
