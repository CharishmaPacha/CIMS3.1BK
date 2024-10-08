/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/26  PK      Added pr_Reservation_CancelShipCartons, pr_Reservation_CancelActivatedLPNs,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_CancelActivatedLPNs') is not null
  drop Procedure pr_Reservation_CancelActivatedLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_CancelActivatedLPNs: When inventory already reserved against
   the customer orders using Actiavtion. But then they phyiscally loaded incorrect
   labels on to the truck.

   And so the activated labels should be cancelled and the inventory should be
   moved back and assigend to the respecitve bulk order and so the correct loaded
   labels can be activated etc.

  The inventory that is actiavted in the LPNs could be a single SKU LPN or a multi
  SKU LPN if if is a multi-SKU LPN, then it should be in-actiavte for all SKUs in
  the LPN.

  The inventory available to be in-actiavted and activated against the bulk is
  represented in #LPNDetails
  The Order details which can be reserved against are in #OrderDetails

  @xmlInput: Given below are the only fields used for now
    <ConfirmLPNReservations>
      <BusinessUnit></BusinessUnit>
      <UserId></UserId>
      <Warehouse></Warehouse>
    </ConfirmLPNReservations>
-------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_CancelActivatedLPNs
  (@xmlInput  xml,
   @xmlOutput xml output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,
          @vGivenLPNType          TTypeCode,
          @vWarehouse             TWarehouse,
          @vBusinessUnit          TBusinessUnit,
          @vUserId                TUserId,
          @xmlData                xml;

  declare @ttEntityKeysTable      TEntityKeysTable;

begin
  select @vReturnCode    = 0,
         @vRecordId      = 0,
         @vMessageName   = null,
         @xmlData        = @xmlInput;

  select @vGivenLPNType = Record.Col.value('LPNType[1]',      'TTypeCode'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit'),
         @vUserId       = Record.Col.value('UserId[1]',       'TUserId'),
         @vWarehouse    = Record.Col.value('Warehouse[1]',    'TWarehouse')
  from @xmlData.nodes('CancelActivatedLPNs') as Record(Col);

  /* Temporary tables */
  select * into #BulkOrdersToRecount from @ttEntityKeysTable;

  /* Cancellation of LPN is driven by the type of LPN given */
  if (@vGivenLPNType in ('S' /* Ship Carton */))
    exec pr_Reservation_CancelShipCartons @vBusinessUnit, @vUserId;

  /*--------------------  update Activated Ship Cartons/To LPNs  ---------------*/

  --exec pr_Reservation_UpdateShipCartons @vBusinessUnit, @vUserId;

  /*--------------------  update From LPNs  ------------------------------------*/

  --exec pr_Reservation_UpdateFromLPNs @vBusinessUnit, @vUserId;

  /*--------------------  update Order & Bulk Order  ---------------------------*/

  --exec pr_Reservation_UpdateOrders @vBusinessUnit, @vUserId;

  /*--------------------  Audit Logging ----------------------------------------*/

  exec pr_Reservation_CancelSLAuditLogging @vBusinessUnit, @vUserId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Reservation_CancelActivatedLPNs */

Go
