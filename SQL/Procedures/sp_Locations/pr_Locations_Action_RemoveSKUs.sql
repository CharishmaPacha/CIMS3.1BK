/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/15  VS      pr_Locations_RemoveSKUFromPicklane, pr_Locations_RemoveSKUs, pr_Locations_Action_RemoveSKUs:
  2021/05/13  AJM     pr_Locations_Action_RemoveSKUs: Initial Revision (CIMSV3-1394)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Action_RemoveSKUs') is not null
  drop Procedure pr_Locations_Action_RemoveSKUs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Action_RemoveSKUs: This is procedure used to disassociate SKUs
    with zero quantity from Picklane locations.

  We are taking the LPNs as inputs to remove the zero quantity SKUs in picklane location
  because logical LPNs will have only one LPN detail for each SKU.
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Action_RemoveSKUs
  (@xmlData          xml,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @ResultXML        TXML    = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vLPNId                      TRecordId,
          @vLPN                        TLPN,
          @vSKUId                      TRecordId,
          @vSKU                        TSKU,
          @vLocationId                 TRecordId,
          @vLocation                   TLocation,
          @vInnerPacks                 TInnerPacks,
          @vQuantity                   TQuantity,
          @vReasonCode                 TReasonCode;

  declare @ttSKUsToRemove Table
          (RecordId                    TRecordId  Identity (1,1),
           LPNId                       TRecordId,
           LPN                         TLPN,
           LPNType                     TTypecode,
           SKUId                       TRecordId,
           SKU                         TSKU,
           LocationId                  TRecordId,
           Location                    TLocation,
           InnerPacks                  TInnerPacks,
           Quantity                    TQuantity);

begin /* pr_Locations_Action_RemoveSKUs */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vRecordId       = 0,
         @vRecordsUpdated = 0,
         @vAuditActivity  = '';

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Insert the selected LPNs SKU & Locations info into temp table to proceed them in bellow */
  insert into @ttSKUsToRemove(LPNId, LPN, LPNType, SKUId, SKU, LocationId, Location, InnerPacks, Quantity)
    select L.LPNId, L.LPN, L.LPNType, L.SKUId, L.SKU, L.LocationId, L.Location, L.InnerPacks, L.Quantity
    from #ttSelectedEntities ttSE
      join LPNs L on (ttSE.EntityId = L.LPNId)

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Remove Non Zero Qty SKUs and Non Logical LPNs */
  delete from STR
  output 'E', 'Location_RemoveSKUs_InvalidLPNType', Deleted.LPNId, Deleted.LPN
  into #ResultMessages (MessageType, MessageName, EntityId, EntityKey)
  from @ttSKUsToRemove STR
  where (LPNType <> 'L'/* Logical LPN */);

  delete from STR
  output 'E', 'Location_RemoveSKUs_NonZeroQtySKUs', Deleted.LPNId, Deleted.LPN, Deleted.SKU, Deleted.Location
  into #ResultMessages (MessageType, MessageName, EntityId, EntityKey, Value1, Value2)
  from @ttSKUsToRemove STR
  where (Quantity > 0);

  /* Get the total count of locations from #table */
  select @vTotalRecords = count(*) from @ttSKUsToRemove;

  /* begin Loop */
  while (exists (select * from @ttSKUsToRemove where RecordId > @vRecordId))
    begin
      /* Get the top 1 SKUs info on the LPN */
      select top 1 @vRecordId      = RecordId,
                   @vLPNId         = LPNId,
                   @vLPN           = LPN,
                   @vSKUId         = SKUId,
                   @vSKU           = SKU,
                   @vLocationId    = LocationId,
                   @vLocation      = Location,
                   @vInnerPacks    = InnerPacks,
                   @vQuantity      = Quantity
      from @ttSKUsToRemove
      where  (RecordId > @vRecordId)
      order by RecordId

      /* Remove Zero Qty SKUs*/
      exec @vReturncode = pr_Locations_RemoveSKUFromPicklane @vSKUId,
                                                             @vLocationId,
                                                             @vLPNId,
                                                             @vInnerPacks,
                                                             @vQuantity,
                                                             'RemoveSKU',
                                                             @UserId,
                                                             @vReasonCode;

      /* Get the records updated count when removed the zero qty SKUs*/
      if (@vReturnCode = 0)
        select @vRecordsUpdated += 1
     end

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_Action_RemoveSKUs */

Go
