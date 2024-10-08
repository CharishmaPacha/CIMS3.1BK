/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/20  TK      pr_RFC_Picking_ConfirmTaskPicks: pr_Picking_ConfirmTaskPicks renamed to pr_Picking_ConfirmPicks (S2GCA-469)
  2017/01/04  YJ      pr_RFC_Picking_ConfirmTaskPicks: Added audit trail for ConfirmTaskPicks (HPI-1158)
  2016/11/09  OK      pr_RFC_Picking_ValidateTaskPicks, pr_RFC_Picking_ConfirmTaskPicks: Added (HPI-1008)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_Picking_ConfirmTaskPicks') is not null
  drop Procedure pr_RFC_Picking_ConfirmTaskPicks;

Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_Picking_ConfirmTaskPicks: Wrapper procedure to  pr_Picking_ConfirmPicks
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_Picking_ConfirmTaskPicks
  (@xmlInput             xml,
   @xmlResult            xml  output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,
          @vRecordId          TRecordId,

          @ToLPN              TLPN,
          @vToLPNId           TRecordId,
          @vToLPNQuantity     TQuantity,
          @TaskId             TRecordId,
          @PickTicket         TPickTicket,
          @DropLocation       TLocation,
          @Operation          TOperation,
          @PickType           TTypeCode,
          @DeviceId           TDeviceId,
          @UserId             TUserId,
          @BusinessUnit       TBusinessUnit,
          @Debug              TFlags;

  declare @ttTaskPicksInfo    TTaskDetailsInfoTable;
begin
begin try
  SET NOCOUNT ON;

  begin transaction;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vMessage     = null,
         @vRecordId    = 0,
         @Debug        = 'N' /* No */;

   if (@xmlInput is not null)
    begin
      select @ToLPN                = Record.Col.value('ToLPN[1]',           'TLPN'),
             @TaskId               = Record.Col.value('TaskId[1]',          'TRecordId'),
             @PickTicket           = Record.Col.value('PickTicket[1]',      'TPickTicket'),
           --@DropLocation         = Record.Col.value('DropLocation[1]',    'TLocation'),
             @Operation            = Record.Col.value('Operation[1]',       'TOperation'),
             @PickType             = Record.Col.value('PickType[1]',        'TTypeCode'),
             @DeviceId             = Record.Col.value('DeviceId[1]',        'TDeviceId'),
             @UserId               = Record.Col.value('UserId[1]',          'TUserId'),
             @BusinessUnit         = Record.Col.value('BusinessUnit[1]',    'TBusinessUnit')
      from @xmlInput.nodes('ConfirmTaskPickInfo/TaskPickHeaderInfoDto/TaskPickHeaderInfo') as Record(Col);

      select @vToLPNId        = LPNId,
             @vToLPNQuantity  = Quantity
      from LPNs
      where LPN = @ToLPN;

      insert into @ttTaskPicksInfo (TaskDetailId, ToLPNId, SKU, QtyPicked)
        select Record.Col.value('TaskDetailId[1]', 'TRecordId'),
               @vToLPNId,
               Record.Col.value('SKU[1]',          'TSKU'),
               Record.Col.value('Quantity[1]',     'TQuantity')
        from @xmlInput.nodes('ConfirmTaskPickInfo/TaskPickDetailsInfoDto/TaskPickDetailInfo') as Record(Col);
    end
  else
    select @vMessageName = 'InvalidInput';

  /*--------------------------------------------------------------------------*/
  /* Validations */
  /*--------------------------------------------------------------------------*/

  if (@vMessageName is not null) goto ErrorHandler;

  /* Validate the Input Data again */
  exec pr_RFC_Picking_ValidateTaskPicks @xmlInput, @xmlResult output;

  /* If Validation procedure returns any Error message then raise that error and stop processing further */
  if (@xmlResult.exist('/ERRORDETAILS') = 1)
    goto ErrorHandler;

  /* Call core procedure */
  exec @vReturnCode = pr_Picking_ConfirmPicks @ttTaskPicksInfo, 'ConfirmTaskPick', @BusinessUnit, @UserId, @Debug;

  /* Build the Description */
  select  @vMessage = dbo.fn_Messages_BuildDescription('TaskPickCompleted', 'LPN', @ToLPN /* LPN */ , 'Quantity', @vToLPNQuantity , 'PickTicket', @PickTicket , null, null, null, null, null, null);

  exec pr_BuildRFSuccessXML @vMessage, @xmlResult output;

  /* Insert Audit Trail */
  exec pr_AuditTrail_Insert 'PickTasksConfirm', @UserId, null /* ActivityTimestamp */,
                            @LPNId        = @vToLPNId,
                            @BusinessUnit = @BusinessUnit

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;
end catch;
end /* pr_RFC_Picking_ConfirmTaskPicks */

Go
