/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/04/27  RV      pr_ShipLabel_GetLabelsToPrintProcess: Made changes to return ZPL to print from Shipping Docs page
                      pr_ShipLabel_GetPalletDataXML: Initial version (S2G-750)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetPalletDataXML') is not null
  drop Procedure pr_ShipLabel_GetPalletDataXML;
Go
/*------------------------------------------------------------------------------
Proc pr_ShipLabel_GetPalletDataXML: This procedure calling from bartender.
  Procedures takes as input a list of Pallets as XML and returns a dataset with the ShipLabelData for Pallet.

InputXML:
<root>
  <EntityKey>Pallet</EntityKey>
</root>
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetPalletDataXML
  (@Pallets          XML,
   @PalletId         TRecordId     = null,
   @Operation        TOperation    = null,
   @BusinessUnit     TBusinessUnit = null,
   @LabelFormatName  TName         = null)
as
  declare @ReturnCode           TInteger,
          @MessageName          TMessageName,
          @UserId               TUserId,
          @vPallet              TPallet,
          @vRecordId            TRecordId;

  declare @ttPallets     TEntityKeysTable;
  declare @ttPalletData  TPalletShipLabelData;

begin
SET NOCOUNT ON;
  select @ReturnCode   = 0,
         @Messagename  = null,
         @UserId       = System_User,
         @BusinessUnit = coalesce(@BusinessUnit, 'TD'),
         @vRecordId    = 0;

  insert into @ttPallets (EntityKey)
    select Record.Col.value('(./text())[1]', 'varchar(50)')
    from @Pallets.nodes('/root/EntityKey') as Record(Col)

  while (exists (select * from @ttPallets where RecordId > @vRecordId))
    begin
      select top 1
             @vPallet   = EntityKey,
             @vRecordId = RecordId
      from @ttPallets
      where (RecordId > @vRecordId);

      insert into @ttPalletData
        exec pr_ShipLabel_GetPalletData @vPallet, @PalletId, @BusinessUnit;
    end

  /* Return the data */
  select * from @ttPalletData;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_ShipLabel_GetPalletDataXML */

Go
