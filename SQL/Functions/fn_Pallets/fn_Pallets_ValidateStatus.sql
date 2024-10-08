/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/08/17  PK      Added fn_Pallets_ValidateStatus.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Pallets_ValidateStatus') is not null
  drop Function dbo.fn_Pallets_ValidateStatus;
Go
/*------------------------------------------------------------------------------
  Function fn_Pallets_ValidateStatus:

    function validates if the Pallet status is present in the
    given ListOfStatus values. Now, this list can be a comma seperated status list
    or a plain string of statuses

    comma seperated list would be the case when the status codes are two or more char
    codes.
    in the case of single char codes, with or without comma is the same
------------------------------------------------------------------------------*/
Create Function fn_Pallets_ValidateStatus
  (@PalletId            TRecordId,
   @PalletStatus        TStatus,
   @ListOfStatus        varchar(max))
  ----------------------------------
   returns              TInteger
as
begin
  declare @vReturnCode     TInteger,
          @vPalletStatus   TStatus;

  set @vReturnCode = 0;

  if (@PalletStatus is null)
    select @vPalletStatus = Status
    from Pallets
    where (PalletId = @PalletId);
  else
    select @vPalletStatus = @PalletStatus;

  if (charindex(@vPalletStatus, @ListOfStatus) = 0)
    set @vReturnCode = 1;

  return(coalesce(@vReturnCode, 0))
end /* fn_Pallets_ValidateStatus */

Go
