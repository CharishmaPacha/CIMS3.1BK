/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/24  TK      pr_API_6River_Inbound_PickTaskPicked & pr_API_6River_PreparePicksToConfirm: Added transactions (CID-1736)
  2021/02/10  TK      pr_API_6River_Inbound_PickTaskPicked & pr_API_6River_PreparePicksToConfirm:
  pr_API_6River_Inbound_PickTaskPicked: Consider UnitsPicked from Picks node when nothing picked (CID-1659)
  2021/01/19  TK      pr_API_6River_Inbound_PickTaskPicked: Should be able to confirm single pick with multiple CoOs
  2021/01/15  TK      pr_API_6River_Inbound_PickTaskPicked & pr_API_6River_Inbound_ContainerTakenOff: Fixed issues faced during integration testing
  2020/12/31  TK      pr_API_6River_Inbound_PickTaskPicked: Confirm partial picks as short based upon a control variable (CID-1612)
  2020/12/14  TK      pr_API_6River_Inbound_PickTaskPicked: Ignore completed picks (CID-1601)
  2020/11/30  TK      pr_API_6River_Inbound_PickTaskPicked: Changes made to handle short picks (CID-1545)
  pr_API_6River_Inbound_PickTaskPicked: Fixed issues while processing the response received from 6River (CID-1545)
  pr_API_6River_Inbound_PickTaskPicked: Initial Revision (CID-1545)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_6River_Inbound_PickTaskPicked') is not null
  drop Procedure pr_API_6River_Inbound_PickTaskPicked;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_6River_Inbound_PickTaskPicked: When the user has confirmed a pick in 6River,
    a confirmation is sent to CIMS as pickTaskPicked confirm Picks info returned from API
------------------------------------------------------------------------------*/
Create Procedure pr_API_6River_Inbound_PickTaskPicked
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,
          @vTranCount                   TCount,
          @vErrorMsg                    TMessage,

          @vRawInput                    TVarchar,

          @vToLPNId                     TRecordId,
          @vToLPN                       TLPN,

          @vPickingPalletId             TRecordId,
          @vPickingPallet               TPallet,

          @vBusinessUnit                TBusinessUnit,
          @vPickedBy                    TUserId,
          @vConfirmPartialPicksAsShort  TControlValue;

  declare @ttTaskDetailsInfo       TTaskDetailsInfoTable,
          @ttConfirmPicksInfo      TTaskDetailsInfoTable,
          @ttConfirmPicksAsShort   TTaskDetailsInfoTable;
begin /* pr_API_6River_Inbound_PickTaskPicked */
begin try
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vTranCount   = @@trancount;

  if (@vTranCount = 0) begin transaction;

  /* Prepare Hash table */
  select * into #PicksFromRawInput from @ttTaskDetailsInfo;
  select * into #PicksToConfirm from @ttTaskDetailsInfo;

  /* Get Transaction Info */
  select @vRawInput     = RawInput,
         @vBusinessUnit = BusinessUnit
  from APIInboundTransactions
  where (RecordId = @TransactionRecordId);

  /* Get Controls */
  select @vConfirmPartialPicksAsShort = dbo.fn_Controls_GetAsString('6RiverPicking', 'ConfirmPartialPicksAsShort', 'N' /* No */, @vBusinessUnit, null);

  /* Read input JSON data & extract necessary info */
  select @vToLPN         = json_value(@vRawInput, '$.container.containerID'),
         @vPickingPallet = json_value(@vRawInput, '$.induct.deviceID');

  /* Get the confirmed picks info into temp table from JSON data */
  /* If nothing is picked against a pick then we will not have captured identifiers */
  insert into #PicksFromRawInput (TaskDetailId, TDQuantity, QtyPicked, FromLocation, PickedBy, CoO)
    select TaskDetailId, UnitsToPick, coalesce(CapturedUnits, UnitsPicked), SourceLocation, PickedBy, CoO
    from openjson(@vRawInput, '$.picks')
    with (TaskDetailId          TVarchar     '$.pickID',
          UnitsToPick           TInteger     '$.eachQuantity',
          UnitsPicked           TInteger     '$.pickedQuantity',
          SourceLocation        TLocation    '$.sourceLocation',
          PickedBy              TUserId      '$.userID',
          capturedIdentifiers   nvarchar(max) as JSON)
    outer apply openjson(capturedIdentifiers)
    with (CoO             TVarchar     '$.COO',
          UPC             TUPC         '$.UPC',
          CapturedUnits   TInteger     '$.quantity')
    order by TaskDetailId;

  /* Prepare picks obtained from RawInput to process further */
  exec pr_API_6River_PreparePicksToConfirm @vBusinessUnit, @vPickedBy;

  /* Get the destination LPN info that inventory is picked into */
  if (@vToLPN is not null)
    select @vToLPNId = LPNId
    from LPNs
    where (LPN = @vToLPN) and (BusinessUnit = @vBusinessUnit);

  /* Get the Pallet info */
  if (@vPickingPallet is not null)
    select @vPickingPalletId = PalletId
    from Pallets
    where (Pallet = @vPickingPallet) and (BusinessUnit = @vBusinessUnit);

  /* Load all the picks from response into temp table and confirm picks */
  insert into @ttConfirmPicksInfo (PickBatchNo, TaskDetailId, OrderId, OrderDetailId, SKUId, PalletId, FromLPNId, FromLPNDetailId, CoO,
                                   FromLocationId, TempLabelId, TempLabelDtlId, QtyPicked, PickedBy, ToLPNId)
    select TD.PickBatchNo, TD.TaskDetailId, TD.OrderId, TD.OrderDetailId, TD.SKUId, @vPickingPalletId, TD.LPNId, TD.LPNDetailId, PTC.CoO,
           TD.LocationId, TD.TempLabelId, TD.TempLabelDetailId, PTC.QtyPicked, PTC.PickedBy, @vToLPNId
    from TaskDetails TD
      join #PicksToConfirm PTC on (TD.TaskDetailId = PTC.TaskDetailId) and (PTC.QtyPicked > 0)
    where (TD.Status = 'I' /* In-Progress */);  /* For 6River, we will be receiving response for each pick complete once and again for container pick complete, so consider only the picks that are to be picked */

  /* Call ConfirmPicks procedure to complete the pick */
  exec pr_Picking_ConfirmPicks @ttConfirmPicksInfo, 'Confirm6RiverPicks', @vBusinessUnit, null /* UserId */;

  /* If the partial picks needs to short picked then do so */
  if (@vConfirmPartialPicksAsShort = 'Y' /* Yes */)
    begin
      /* When there are short picks then there will be a difference in TDQuantity and PickedQty,
         so confirming the picks that are partially picked will split the source task detail and marks the
         task detail as picked and there will be a new task detail from the same from LPN detail for short picked quantity
         so we need to get that task detail and confirm the new task detail as short picked */
      insert into @ttConfirmPicksAsShort (TaskDetailId)
        select TD.TaskDetailId
        from TaskDetails TD
          join #PicksToConfirm PTC on (TD.TaskDetailId = PTC.TaskDetailId) and
                                      (PTC.QtyPicked = 0)   -- Picks without quantity picked
        where TD.Status not in ('C', 'X' /* Completed, Canceled */);

      /* Call ConfirmPicks procedure to complete the pick */
      exec pr_Picking_ConfirmPicksAsShort @ttConfirmPicksAsShort, 'Short6RiverPicks', @vBusinessUnit, @vPickedBy;
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  if (@vTranCount = 0) commit transaction;
end try
begin catch
  if (@vTranCount = 0) rollback transaction

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_6River_Inbound_PickTaskPicked */

Go
