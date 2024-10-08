/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/02  SK      pr_Reservation_ActivateLPNs, pr_Reservation_ConfirmFromLPN: Included markers (HA-2070)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_ActivateLPNs') is not null
  drop Procedure pr_Reservation_ActivateLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_ActivateLPNs: When inventory in available for a
   PT or a wave we would need to consume that inventory and activate the
   pre-generated shipping labels.

  The inventory that is available could be a single SKU LPN or a multi SKU LPN
  if if is a multi-SKU LPN, then it should be allocable in whole, if single SKU
  LPN, it can be partially allocated if allowed

  The inventory available to be consumed is represented in #LPNDetails
  The Order details which can be reserved against are in #OrderDetails

  @xmlInput: Given below are the only fields used for now
    <ConfirmLPNReservations>
      <BusinessUnit></BusinessUnit>
      <UserId></UserId>
      <Warehouse></Warehouse>
    </ConfirmLPNReservations>
-------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_ActivateLPNs
  (@xmlInput  xml)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vDebug                 TFlags,
          @vRecordId              TRecordId,
          @vGivenLPNType          TTypeCode,
          @vWarehouse             TWarehouse,
          @vBusinessUnit          TBusinessUnit,
          @vUserId                TUserId,
          @xmlData                xml;

  declare @ttEntityKeysTable      TEntityKeysTable,
          @ttMarkers              TMarkers;

begin
  select @vReturnCode    = 0,
         @vRecordId      = 0,
         @vMessageName   = null,
         @xmlData        = @xmlInput;

  select @vGivenLPNType = Record.Col.value('LPNType[1]',      'TTypeCode'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
         @vUserId       = Record.Col.value('UserId[1]',       'TUserId'),
         @vWarehouse    = Record.Col.value('Warehouse[1]',    'TWarehouse'),
         @vDebug        = Record.Col.value('Debug[1]',        'TFlags')
  from @xmlData.nodes('ConfirmLPNReservations') as Record(Col);

  /* Check if in debug mode */
  if (coalesce(@vDebug, '') = '')
    exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @vBusinessUnit, @vDebug output;

  /* Temporary tables */
  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;
  select * into #BulkOrdersToRecount from @ttEntityKeysTable;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'begin', @@ProcId;

  /* Activation of LPN is driven by the type of LPN given */
  if (@vGivenLPNType in ('S' /* Ship Carton */))
    exec pr_Reservation_ActivateShipCartons @vBusinessUnit, @vUserId, @vDebug
  else
    exec pr_Reservation_ActivateFromLPNs @vBusinessUnit, @vUserId;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Activated Ship Cartons', @@ProcId;

  /*--------------------  update Activated Ship Cartons/To LPNs  ---------------*/

  exec pr_Reservation_UpdateShipCartons @vBusinessUnit, @vUserId;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Updated Ship Cartons', @@ProcId;

  /*--------------------  update From LPNs  ------------------------------------*/

  exec pr_Reservation_UpdateFromLPNs @vBusinessUnit, @vUserId;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Updated From LPNs', @@ProcId;

  /*--------------------  update Order & Bulk Order  ---------------------------*/

  exec pr_Reservation_UpdateOrders @vBusinessUnit, @vUserId;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Update Orders', @@ProcId;

  /*--------------------  Audit Logging ----------------------------------------*/

  exec pr_Reservation_AuditLogging @vBusinessUnit, @vUserId;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Audits logged', @@ProcId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Reservation_ActivateLPNs */

Go
