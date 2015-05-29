-------------------------------------------------------------------------------
-- $Id: common_types_pkg.vhd,v 1.1 2002/12/06 16:01:55 goran Exp $
-------------------------------------------------------------------------------
-- Common_Types -  package and package body
-------------------------------------------------------------------------------
--
--                  ****************************
--                  ** Copyright Xilinx, Inc. **
--                  ** All rights reserved.   **
--                  ****************************
--
-------------------------------------------------------------------------------
-- Filename:        common_types_pkg.vhd
-- Version:         v1.00a
-- Description:     A package with common type definition and help functions
--                  
--                  
-------------------------------------------------------------------------------
-- Structure:   
--              common_types_pkg.vhd
--
-------------------------------------------------------------------------------
-- Author:          BLT (from goran's microblaze_types_pkg.vhd)
-- History:
--  BLT          6-29-2001      -- First version
--
-------------------------------------------------------------------------------
-- Naming Conventions:
--      active low signals:                     "*_n"
--      clock signals:                          "clk", "clk_div#", "clk_#x" 
--      reset signals:                          "rst", "rst_n" 
--      generics:                               "C_*" 
--      user defined types:                     "*_TYPE" 
--      state machine next state:               "*_ns" 
--      state machine current state:            "*_cs" 
--      combinatorial signals:                  "*_com" 
--      pipelined or register delay signals:    "*_d#" 
--      counter signals:                        "*cnt*"
--      clock enable signals:                   "*_ce" 
--      internal version of output port         "*_i"
--      device pins:                            "*_pin" 
--      ports:                                  - Names begin with Uppercase 
--      processes:                              "*_PROCESS" 
--      component instantiations:               "<ENTITY_>I_<#|FUNC>
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package Common_Types is

  type RLOC_POS_TYPE is
    record
      X : natural;
      Y : natural;
    end record RLOC_POS_TYPE;

  type TARGET_FAMILY_TYPE is (VIRTEX, VIRTEX2);
  function log2(x : natural) return integer;
  function String_To_Int(S : string) return integer;
  function Get_RLOC_Name (Target : TARGET_FAMILY_TYPE;
                          Y      : integer;
                          X      : integer) return string;

end package Common_Types;

-------------------------------------------------------------------------------
-- Package Body section
-------------------------------------------------------------------------------

package body Common_Types is

  -- log2 function returns the number of bits required to encode x choices
  
  function log2(x : natural) return integer is
    variable i  : integer := 0;   
  begin 
    if x = 0 then return 0;
    else
      while 2**i < x loop
        i := i+1;
      end loop;
      return i;
    end if;
  end function log2;
  
  --itoa function converts integer to a text string
  --this function is required since 'image doesn't work
  --in synplicity
  
  -- valid range for input to the function is -9999 to 9999

  function itoa (int : integer) return string is
    type table is array (0 to 9) of string (1 to 1);
    constant LUT     : table :=
      ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9");
    variable str1            : string(1 to 1);
    variable str2            : string(1 to 2);
    variable str3            : string(1 to 3);
    variable str4            : string(1 to 4);
    variable str5            : string(1 to 5);
    variable abs_int         : natural;
    
    variable thousands_place : natural;
    variable hundreds_place  : natural;
    variable tens_place      : natural;
    variable ones_place      : natural;
    variable sign            : integer;
    
  begin
    abs_int := abs(int);
    if abs_int > int then sign := -1;
    else sign := 1;
    end if;
    thousands_place :=  abs_int/1000;
    hundreds_place :=  (abs_int-thousands_place*1000)/100;
    tens_place :=      (abs_int-thousands_place*1000-hundreds_place*100)/10;
    ones_place :=      
      (abs_int-thousands_place*1000-hundreds_place*100-tens_place*10);
    
    if sign>0 then
      if thousands_place>0 then
        str4 := LUT(thousands_place) & LUT(hundreds_place) & LUT(tens_place) &
                LUT(ones_place);
        return str4;
      elsif hundreds_place>0 then 
        str3 := LUT(hundreds_place) & LUT(tens_place) & LUT(ones_place);
        return str3;
      elsif tens_place>0 then
        str2 := LUT(tens_place) & LUT(ones_place);
        return str2;
      else
        str1 := LUT(ones_place);
        return str1;
      end if;
    else
      if thousands_place>0 then
        str5 := "-" & LUT(thousands_place) & LUT(hundreds_place) & 
          LUT(tens_place) & LUT(ones_place);
        return str5;
      elsif hundreds_place>0 then 
        str4 := "-" & LUT(hundreds_place) & LUT(tens_place) & LUT(ones_place);
        return str4;
      elsif tens_place>0 then
        str3 := "-" & LUT(tens_place) & LUT(ones_place);
        return str3;
      else
        str2 := "-" & LUT(ones_place);
        return str2;
      end if;
    end if;  
  end function itoa;

  function Get_RLOC_Name (Target : TARGET_FAMILY_TYPE;
                          Y      : integer;
                          X      : integer) return string is
    variable Col : integer;
    variable Row : integer;
    variable S : integer;
  begin
    if Target = VIRTEX then
      Row := -Y;
      Col := X/2;
      S   := 1 - (X mod 2);
      return 'R' & itoa(Row) &
             'C' & itoa(Col) &
             ".S" & itoa(S);
    elsif Target = VIRTEX2 then
      return 'X' & itoa(X) & 'Y' & itoa(Y);
    end if;
  end function Get_RLOC_Name;
  
  type POS_RECORD is
    record
      X : natural;
      Y : natural;
    end record POS_RECORD;

  -----------------------------------------------------------------------------
  -- 
  -----------------------------------------------------------------------------
  type CHAR_TO_INT_TYPE is array (character) of integer;
  constant STRHEX_TO_INT_TABLE : CHAR_TO_INT_TYPE :=
    ('0'     => 0,
     '1'     => 1,
     '2'     => 2,
     '3'     => 3,
     '4'     => 4,
     '5'     => 5,
     '6'     => 6,
     '7'     => 7,
     '8'     => 8,
     '9'     => 9,
     'A'|'a' => 10,
     'B'|'b' => 11,
     'C'|'c' => 12,
     'D'|'d' => 13,
     'E'|'e' => 14,
     'F'|'f' => 15,
     others  => -1);

  -----------------------------------------------------------------------------
  -- Converts a string of hex character to an integer
  -- accept negative numbers
  -----------------------------------------------------------------------------
  function String_To_Int(S : String) return Integer is
    variable Result : integer := 0;
    variable Temp   : integer := S'Left;
    variable Negative : integer := 1;
  begin
    for I in S'Left to S'Right loop
      -- ASCII value - 42 TBD
      if (S(I) = '-') then
        Temp     := 0;
        Negative := -1;
      else
        Temp := STRHEX_TO_INT_TABLE(S(I));
        if (Temp = -1) then
          assert false
            report "Wrong value in String_To_Int conversion " & S(I)
            severity error;
        end if;
      end if;
      Result := Result * 16 + Temp;
    end loop;
    return (Negative * Result);
  end function String_To_Int;
  
  
 --   function Get_RLOC ( Target : TARGET_FAMILY_TYPE;
 --                       Module : MODULE_TYPE;
 --                       Index  : natural) return string is
 --   begin  -- function Get_RLOC
  
 --   end function Get_RLOC;

end package body Common_Types;