/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/18  MS      pr_Setup_PutawayRules: Added new Proc to insert Putaway Rules (CIMSV3-1028)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Setup_PutawayRules') is not null
  drop Procedure pr_Setup_PutawayRules;
Go
/*------------------------------------------------------------------------------
  Proc pr_Setup_PutawayRules: Procedure used for setup of PA rules from init
   scripts. Currently only supports Action = I (Insert)
------------------------------------------------------------------------------*/
Create Procedure pr_Setup_PutawayRules
  (@SKUPutawayClass   TCategory,
   @LPNPutawayClass   TCategory,
   @PutawayZone       TLookupCode,
   @SequenceSeries    TInteger,
   @SeqOffset         TInteger,
   @Warehouses        TVarchar,
   @Action            TFlags,
   @BusinessUnit      TBusinessUnit = null,
   @UserId            TUserId       = null)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName;

  declare @ttWarehouses table (Warehouse    TWarehouse,
                               BusinessUnit TBusinessUnit);
begin
  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @UserId       = coalesce(@UserId, 'cimsdba');

  /* If there are no rules in #PARules, then nothing to setup, exit */
  if (object_id('tempdb..#PARules') is null) return;

  /* Get all valid Warehouses and BusinessUnits */
  insert into @ttWarehouses(Warehouse, BusinessUnit)
    select L.LookUpCode, BU.BusinessUnit
    from vwLookups L join vwBusinessUnits BU on L.BusinessUnit = BU.BusinessUnit
    where (L.LookUpCategory = 'Warehouse') and
          ((@Warehouses is null) or (dbo.fn_IsInList(L.LookupCode, @Warehouses) > 0)) and
          (BU.BusinessUnit = coalesce(@BusinessUnit, BU.BusinessUnit));

  /* Insert data into PutawayRules table from temptable */
  if (charindex('I', @Action) > 0)
    insert into PutawayRules(SequenceNo, LPNType, PAType, SKUPutawayClass, LPNPutawayClass,
                             LocationType, StorageType, LocationStatus, PutawayZone, Location, LocationClass,
                             SKUExists, Status, Warehouse, BusinessUnit, CreatedBy)
      select case
               when @SequenceSeries is not null and PR.SequenceNo is not null then
                 @SequenceSeries + PR.SequenceNo + coalesce(@SeqOffset, 0)
               when @SequenceSeries is not null then
                 @SequenceSeries + PR.RecordId + coalesce(@SeqOffset, 0)
               else
                 PR.SequenceNo + coalesce(@SeqOffset, 0)
             end,
             PR.LPNType, PR.PAType, coalesce(@SKUPutawayClass, PR.SKUPutawayClass), coalesce(@LPNPutawayClass, PR.LPNPutawayClass),
             PR.LocationType, PR.StorageType, PR.LocationStatus, coalesce(@PutawayZone, PR.PutawayZone), PR.Location, PR.LocationClass,
             PR.SKUExists, coalesce(PR.Status, 'A' /* Active */), W.Warehouse, W.BusinessUnit, @UserId
      from #PARules PR, @ttWarehouses W;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end  /* pr_Setup_PutawayRules */

Go
