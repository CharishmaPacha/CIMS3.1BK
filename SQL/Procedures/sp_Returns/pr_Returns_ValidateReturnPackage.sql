/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/13  AY      pr_Returns_ValidateReturnPackage: Pull up order by CustPO (FB-1241)
  2017/06/02  TK      pr_Returns_ValidateReturnPackage: Bug fix to remove leading zeros (FB-932)
  2015/11/16  PK      pr_Returns_ValidateReturnPackage:
                        Bug-fix - Tracking number would be return tracking number (FB-522)
                        Allow to scan Sales Order number as well
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Returns_ValidateReturnPackage') is not null
  drop Procedure pr_Returns_ValidateReturnPackage;
Go
/*------------------------------------------------------------------------------
  Proc pr_Returns_ValidateReturnPackage: This procedure will validate the input
    which should be either a Tracking No of a shipped package or a Shipped PickTicket or a Receipt Authorisation
    The corresponding OrderId and ReceiptId is returned if the scanned input is valid.

Sample i/p XML:
<Root>
  <Entity>Returns</Entity>
  <Action>ValidateReturns</Action>
  <TrackingNoOrPickTicket></TrackingNoOrPickTicket>
</Root>

output XML:
<Root>
  <OrderId>...</OrderId>
  <ReceiptId>..</ReceiptId>
  <Message>...</Message>
</Root>
------------------------------------------------------------------------------*/
Create Procedure pr_Returns_ValidateReturnPackage
  (@XMLInput      xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @XMLResult     TXML output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,

          @vTrackingNoOrPickTicket  TTrackingNo,
          @vReceiptId               TRecordId,
          @vOrderId                 TRecordId,
          @vPickTicket              TPickTicket,
          @vAction                  TAction,
          @vLPNId                   TRecordId,
          @vLPN                     TLPN,
          @vLPNStatus               TStatus,
          @vOrderStatus             TStatus,
          @vOrderType               TOrderType,
          @vValidOrderTypes         TControlValue,
          @ResultXML                xml,
          @vBusinessUnit            TBusinessUnit,
          @vUserId                  TUserId;
begin /* pr_Returns_ValidateReturnPackage */
begin try
  begin transaction;
  SET NOCOUNT ON;

  /* Get the Input params */
  select @vTrackingNoOrPickTicket = Record.Col.value('TrackingNoOrPickTicket[1]', 'TTrackingNo'),
         @vAction                 = Record.Col.value('Action[1]',                 'TAction')
  from @xmlInput.nodes('/Root') as Record(Col);

  /* First we check for Receipt Authorization to return the inventory */
  select @vReceiptId  = ReceiptId,
         @vPickTicket = PickTicket
  from ReceiptHeaders
  where (ReceiptNumber = @vTrackingNoOrPickTicket);

  /* If they scanned otherthan Receipt Number, then we need to check for Order */
  if (coalesce(@vPickTicket, '') = '')
    select @vOrderId = OrderId
    from OrderHeaders
    where (PickTicket = @vPickTicket);
    --where (PickTicket = coalesce(@vPickTicket, @vTrackingNoOrPickTicket));

  /* Trim the leading zeros from the scanned info */
  select @vTrackingNoOrPickTicket = replace(ltrim(replace(@vTrackingNoOrPickTicket, '0', ' ')), ' ', '0');

  /* Get the return package info */
  select @vLPN = EntityKey
  from ShipLabels
  where (TrackingNo = @vTrackingNoOrPickTicket) and
        (LabelType = 'RL' /* Return label */);

  /* Check if it is */
  select @vOrderId   = OrderId,
         @vLPNId     = LPNId,
         @vLPN       = LPN,
         @vLPNStatus = Status
  from LPNs
  where ((LPN = @vLPN) or
         (TrackingNo  = @vTrackingNoOrPickTicket)) and
        (BusinessUnit = @BusinessUnit);

  /* If it isn't an LPN, then check if user passed PickTicket */
  if (@vLPNId is null)
    select @vOrderId = OrderId
    from OrderHeaders
    where (SalesOrder  = @vTrackingNoOrPickTicket) and
          (BusinessUnit = @BusinessUnit);

  /* If nothing else, check if it is CustPO */
  if (@vOrderId is null)
    select @vOrderId = OrderId
    from OrderHeaders
    where (CustPO  = @vTrackingNoOrPickTicket) and
          (BusinessUnit = @BusinessUnit);

  select @vOrderStatus = Status,
         @vOrderType   = OrderType
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Get the valid OrderTypes to allow returns */
  select @vValidOrderTypes = dbo.fn_Controls_GetAsString('Receipts_Return', 'ValidOrderTypes', '', @BusinessUnit, @vUserId);

  /* Validations */
  if (@vTrackingNoOrPickTicket is null)
    set @vMessageName = 'InvalidTrackingNoOrPickTicket';
  else
  if (@vOrderId is null) and (@vReceiptId is null)
    set @vMessageName = 'NotanLPNorReceiptorPickTicket';
  else
  /* Allow client specified order types for returns */
  if (charindex(@vOrderType, @vValidOrderTypes) = 0)
    set @vMessageName = 'CreateReturns_NotAValidOrderType';
  else
  if (@vOrderStatus <> 'S' /* Shipped */)
    set @vMessageName = 'OrderNotShipped';
  else
  if (@vLPNStatus <> 'S' /* Shipped */)
    set @vMessageName = 'LPNNotShipped';

  if (@vMessageName is not null) goto ErrorHandler;

  /* Build the output xml and return */
  select @ResultXML = (select coalesce(@vOrderId,'')      OrderId,
                              coalesce(@vReceiptId,'')    ReceiptId,
                              coalesce(@vMessageName,'')  Message
                       for xml raw('Root'), elements);

  select @XMLResult = convert(varchar(max), @ResultXML);
  --select @XMLResult;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, null;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;
  exec @vReturnCode = pr_ReRaiseError;
end catch;
end /* pr_Returns_ValidateReturnPackage */

Go
