/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/02  MS      pr_Receivers_AutoCreateReceiver: Changes to send ContainerNo in Rules (JL-287)
  2020/06/25  NB      pr_Receivers_Create, pr_Receivers_Modify, pr_Receivers_AutoCreateReceiver
                      pr_Receivers_AutoCreateReceiver: Pass on BoL# & Container values when auto create receiver is called to update Receiver (HA-392)
  2018/08/29  AY/PK   pr_Receivers_AutoCreateReceiver: Migrated from onsite Prod (S2G-727)
  2018/03/06  AY/SV   pr_Receivers_AutoCreateReceiver: New procedure to create receivers on the fly
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_AutoCreateReceiver') is not null
  drop Procedure pr_Receivers_AutoCreateReceiver;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_AutoCreateReceiver:
------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_AutoCreateReceiver
  (@ReceiptId          TRecordId,
   @CustPO             TCustPO,
   @LocationId         TRecordId,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @ReceiverId         TRecordId       output,
   @ReceiverNumber     TReceiverNumber output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vRecordId            TRecordId,

          @xmlReceiverContents  xml,
          @xmlRulesData         TXML,
          @vContainer           TContainer,
          @vBoLNumber           TBoLNumber,
          @vWarehouse           TWarehouse;

begin
  SET NOCOUNT ON;

  select @vReturnCode = 0;

  /* Get Receipt Info */
  select  @vBoLNumber = BillNo,
          @vContainer = ContainerNo,
          @vWarehouse = Warehouse
  from ReceiptHeaders
  where (ReceiptId = @ReceiptId);

  /* Prepare XML for rules */
  set @xmlRulesData = dbo.fn_XMLNode('RootNode',
                        dbo.fn_XMLNode('ReceiptId',     @ReceiptId) +
                        dbo.fn_XMLNode('CustPO',        @CustPO) +
                        dbo.fn_XMLNode('LocationId',    @LocationId) +
                        dbo.fn_XMLNode('ContainerNo',   @vContainer) +
                        dbo.fn_XMLNode('BusinessUnit',  @BusinessUnit) +
                        dbo.fn_XMLNode('UserId',        @UserId));

  /* Check if there is an existing receiver to use for this ReceiptId */
  exec pr_RuleSets_Evaluate 'Receiver_Find', @xmlRulesData, @ReceiverId output;

  /* If there is an open Receiver for the PO that can be used, then return it */
  if (@ReceiverId is not null)
    begin
      select @ReceiverNumber = ReceiverNumber
      from Receivers
      where (ReceiverId = @ReceiverId);

      return;
    end;

  set @xmlReceiverContents = (select 'AutoCreate' as Action,
                                     @vBoLNumber  as BoLNo,
                                     @vContainer  as ContainerNo,
                                     @vWarehouse  as Warehouse
                              for XML RAW('Data'), TYPE, ELEMENTS XSINIL, ROOT('Root'));

  /* If there is no Open Receiver then create a new one */
  exec pr_Receivers_Create @xmlReceiverContents, @BusinessUnit, @UserId, default /* Message */,
                           @ReceiverId output, @ReceiverNumber output;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receivers_AutoCreateReceiver */

Go
