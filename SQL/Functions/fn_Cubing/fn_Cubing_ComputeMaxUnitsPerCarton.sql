/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Cubing_ComputeMaxUnitsPerCarton') is not null
  drop Function fn_Cubing_ComputeMaxUnitsPerCarton;
Go
/*------------------------------------------------------------------------------
  Func fn_Cubing_ComputeMaxUnitsPerCarton
------------------------------------------------------------------------------*/
Create Function fn_Cubing_ComputeMaxUnitsPerCarton
  (@CartonSpace    TFloat,
   @SpacePerUnit   TFloat,
   @NestingFactor  TFloat)
  -----------------------------------
   returns         TInteger
as
begin
  declare @vMaxUnitsPerCarton  TInteger;

  select @vMaxUnitsPerCarton = case when (@CartonSpace >= @SpacePerUnit)
                                      then floor((@CartonSpace - @SpacePerUnit) / (@SpacePerUnit * @NestingFactor)) + 1
                                    else 0
                               end;

  return(@vMaxUnitsPerCarton);
end /* fn_Cubing_ComputeMaxUnitsPerCarton */

Go
