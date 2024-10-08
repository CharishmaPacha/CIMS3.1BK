/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/18  TK      pr_LPNs_Insert: UniqueId should include InventoryClass as well (HA-1672)
  2020/06/22  TK      pr_LPNs_Insert: Initial Revision (HA-833)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Insert') is not null
  drop Procedure pr_LPNs_Insert;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Insert: This proc inserts given set of LPNs from #LPNs (TLPNDetails)
    into LPNs table
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Insert
  (@BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName;

  declare @ttGeneratedIds table (LPNId TRecordId, RecordId TRecordId);
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* If there is not temp table created then return */
  if object_id('tempdb..#LPNs') is null
    return;

  /* Insert the required information provided from temp table */
  insert into LPNs(LPN, LPNType, Status, OnhandStatus, SKUId, SKU, LocationId, Location,
                   InventoryClass1, InventoryClass2, InventoryClass3, Ownership, DestWarehouse,
                   UniqueId, Reference, BusinessUnit, CreatedBy)
    output Inserted.LPNId, Inserted.Reference into @ttGeneratedIds
    select LPN, LPNType, LPNStatus, OnhandStatus, SKUId, SKU, LocationId, Location,
           InventoryClass1, InventoryClass2, InventoryClass3, Ownership, Warehouse,
           case when UniqueId is not null then UniqueId
                when LPNType = 'L' then LPN + '-' + coalesce(SKU, '') + '-' + coalesce(InventoryClass1, '') + '-' +
                                        coalesce(InventoryClass2, '') + '-' + coalesce(InventoryClass3, '') + '-' + coalesce(Lot, '')
                else LPN
           end /* UniqueId */, RecordId, @BusinessUnit, @UserId
    from #LPNs;

  /* Update Temp table with the LPNId generated above */
  update TL
  set LPNId = GI.LPNId
  from #LPNs TL
    join @ttGeneratedIds GI on (TL.RecordId = GI.RecordId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Insert */

Go
