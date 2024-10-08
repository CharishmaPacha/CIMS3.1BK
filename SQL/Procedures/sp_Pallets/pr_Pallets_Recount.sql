/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/09/08  YJ      Added Procedure pr_Pallets_Recount (ACME-311)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_Recount') is not null
  drop Procedure pr_Pallets_Recount;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_Recount: Update all the counts on the given list of pallets.
    Note that the pallets given may not be unique.
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_Recount
  (@PalletsToUpdate     TEntityKeysTable Readonly,
   @Businessunit        TBusinessunit,
   @UserId              TUserId)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,
          @vPalletId       TRecordId,
          @vPallet         TPallet,
          @vRecordId       TRecordId

begin
  SET NOCOUNT ON;

  select @vReturnCode = 0,
         @vPalletId   = 0;

  /* Loop through all the records to call UpdateCount Procedure */
  while exists(select * from @PalletsToUpdate where EntityId > @vPalletId)
    begin
      select top 1 @vPalletId  = EntityId,
                   @vPallet    = EntityKey,
                   @vRecordId  = RecordId
      from @PalletsToUpdate
      where (EntityId > @vPalletId);

      /* Calling the procedure */
      exec pr_Pallets_UpdateCount @vPalletId, @vPallet, '*' /* UpdateOption */
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Pallets_Recount */

Go
