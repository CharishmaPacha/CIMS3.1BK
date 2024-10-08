/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/06/18  PK      pr_LPNs_SetPallet: Included Picking Pallet Type as well in Validations.
                       added fn_LPNs_ValidateStatus.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_LPNs_ValidateStatus') is not null
  drop Function dbo.fn_LPNs_ValidateStatus;
Go
/*------------------------------------------------------------------------------
  Function fn_LPNs_ValidateStatus:

    function validates if the LPN status is present in the
    given ListOfStatus values. Now, this list can be a comma seperated status list
    or a plain string of statuses

    comma seperated list would be the case when the status codes are two or more char
    codes.
    in the case of single char codes, with or without comma is the same
------------------------------------------------------------------------------*/
Create Function fn_LPNs_ValidateStatus
  (@LPNId               TRecordId,
   @LPNStatus           TStatus,
   @ListOfStatus        varchar(max))
  ----------------------------------
   returns              TInteger
as
begin
  declare @vReturnCode  TInteger,
          @vLPNStatus   TStatus;

  set @vReturnCode = 0;

  if (@LPNStatus is null)
    select @LPNStatus = Status
    from LPNs
    where (LPNId = @LPNId);

  if (charindex(@LPNStatus, @ListOfStatus) = 0)
    set @vReturnCode = 1;

  return(coalesce(@vReturnCode, 0));
end /* fn_LPNs_ValidateStatus */

Go
