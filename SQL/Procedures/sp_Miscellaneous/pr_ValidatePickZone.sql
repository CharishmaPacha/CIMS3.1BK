/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/06/25  AY      Added pr_ValidatePickZone
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ValidatePickZone') is not null
  drop Procedure pr_ValidatePickZone;
Go
/*------------------------------------------------------------------------------
  Stored Procedure pr_ValidatePickZone
    Given a character, a step, and a charset, returns the successive character
    (alpha, numeric, or alphanumeric) and any overflow.
------------------------------------------------------------------------------*/
Create Procedure pr_ValidatePickZone
  (@PickZone       TZoneId,
  --------------------------------
   @ValidPickZone  TZoneId output)
as
  declare @vReturnCode       TInteger;
begin
  select @vReturnCode = 0;

  /* Verify whether the given PickZone is valid, if provided only */
  if (nullif(@PickZone, '') is not null)
    begin
      select @ValidPickZone = ZoneId
      from vwPickingZones
      where (ZoneId = @PickZone);

      if (@ValidPickZone is null)
        exec @vReturnCode = pr_Messages_ErrorHandler 'InvalidPickZone';
    end
  else
    set @ValidPickZone = null;

  return(coalesce(@vReturnCode, 0));
end /* pr_ValidatePickZone */

Go
