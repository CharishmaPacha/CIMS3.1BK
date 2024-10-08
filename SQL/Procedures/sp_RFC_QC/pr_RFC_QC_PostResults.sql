/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/14  HB      pr_RFC_QC_PostResults: Initial Revision (HPI-2283)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_QC_PostResults') is not null
  drop Procedure pr_RFC_QC_PostResults;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_QC_PostResults: This procedure will take xml as input and post the details into QCHeaders and QCDetails.

  Input:
<QCInfo>
    <CartonInfo>
        <LPNId></LPNId>
        <LPN></LPN>
        <OrderId></OrderId>
        <PickTicket></PickTicket>
        <SalesOrder></SalesOrder>
        <Quantity></Quantity>
        <InnerPacks></InnerPacks>
        <ReservedQuantity> </ReservedQuantity>
        <Location></Location>
        <PickedUser></PickedUser>
        <PackedUser></PackedUser>
        <BusinessUnit></BusinessUnit>
        <UserId></UserId>
    </CartonInfo>
    <CartonDetailsInfo>
        <LPNDetailId></LPNDetailId>
        <SKUId></SKUId>
        <SKU></SKU>
        <Quantity></Quantity>
        <InnerPacks></InnerPacks>
        <OnhandStatus></OnhandStatus>
    </CartonDetailsInfo>
    <NotScannableItems>
        <LPNDetailId></LPNDetailId>
        <SKUId></SKUId>
        <SKU></SKU>
        <Quantity></Quantity>
        <InnerPacks></InnerPacks>
        <OnhandStatus></OnhandStatus>
    </NotScannableItems>
    <Options>
        <QCMode>SE/SQ</QCMode>                           -- SE - Scan Each, SQ - Scan Qty
    </Options>
    <AdditionalChecks>
        <ChecksRequired>LBA,PSI,ACT,PC</ChecksRequired>  -- LBA - Label Attached Properly, PSI - Packing Slip Included, ACT - Appropriate Carton Type, PC - Packed Correctly
        <ChecksConfirmed>
          <Check></Check>
          <Status></Status>
        </ChecksConfirmed>
    </AdditionalChecks>
    <QCDetails>
        <SKU></SKU>
        <Quantity></Quantity>
        <InnerPacks></InnerPacks>
    </QCDetails>
</QCInfo>

  output:
<QCResult>
    <LPNId></LPNId>
    <LPN></LPN>
    <OrderId></OrderId>
    <PickTicket></PickTicket>
    <SalesOrder></SalesOrder>
    <Quantity></Quantity>
    <InnerPacks></InnerPacks>
    <QCResults></QCResults>

    <QCResults>
        <SKUId></SKUId>
        <SKU></SKU>
        <ExpQuantity></ExpQuantity>
        <ExpInnerPacks></ExpInnerPacks>
        <ScannedQty></ScannedQty>
        <ScannedInnerPacks> </ScannedInnerPacks>
        <Result></Result>
    </QCResults>
</QCResult>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_QC_PostResults
  (@xmlInput   xml,
   @xmlResult  xml output)
as
  declare @vQCRecordId           TRecordId,
          @vLPNId                TRecordId,
          @vLPN                  TLPN,
          @vTrackingNo           TTrackingNo,
          @vLPNOrderId           TRecordId,
          @vLPNReceiptId         TRecordId,
          @vOrderId              TRecordId,
          @vPickTicket           TPickTicket,

          @vWaveId               TRecordId,
          @vWaveNo               TWaveNo,
          @vWaveType             TTypeCode,

          @vReceiptId            TRecordId,
          @vReceiptNumber        TReceiptNumber,
          @vReceiverNumber       TReceiverNumber,
          @vROType               TTypeCode,

          @vQCMode               TTypeCode,
          @vQCCategory           TCategory,

          @vPickedBy             TUserId,
          @vPackedBy             TUserId,
          @vQCStatus             TStatus,
          @vNumErrors            TCount,

          @vLocation             TLocation,
          @vReservedQuantity     TQuantity,
          @vInnerPacks           TQuantity,
          @vQuantity             TQuantity,
          @vSalesOrder           TDescription,

          @vArchived             TFlag = 'N',
          @vBusinessUnit         TBusinessUnit,
          @vUserId               TUserId,

          @vQCHeaderXML          XML,
          @vQCDetailsXML         XML,

          @vActivityLogId        TRecordId,
          @vReturnCode           TInteger,
          @vMessageName          TMessageName,
          @vMessage              TDescription;

  declare @ttQCDetails table (RecordId             TRecordId identity (1,1),
                              QCRecordId           TRecordId,
                              LPNId                TRecordId,
                              LPNDetailId          TRecordId,
                              SKUId                TRecordId,
                              SKU                  TSKU,
                              OrderId              TRecordId,
                              OrderDetailId        TRecordId,
                              ExpectedInnerPacks   TQuantity default 0,
                              ConfirmedInnerPacks  TQuantity,
                              ExpectedQty          TQuantity default 0,
                              ConfirmedQty         TQuantity,
                              OnhandStatus         TStatus,
                              ConfirmedQCCheck     TDescription,
                              ConfirmedQCStatus    TStatus,
                              QCComment            TNote,
                              QCInfoType           TDescription,

                              Primary key          (RecordId));

begin
begin try
  SET NOCOUNT ON;

  begin transaction;

  if (@xmlInput is null)
    begin
      select @vMessageName = 'InvalidInput';
      goto ErrorHandler;
    end

  /* Get the input xml data to local variables */
  select @vLPNId            = Record.Col.value('LPNId[1]',            'TRecordId'),
         @vLPN              = Record.Col.value('LPN[1]',              'TLPN'),
         @vOrderId          = Record.Col.value('OrderId[1]',          'TRecordId'),
         @vQuantity         = Record.Col.value('Quantity[1]',         'TQuantity'),
         @vInnerPacks       = Record.Col.value('InnerPacks[1]',       'TQuantity'),
         @vReservedQuantity = Record.Col.value('ReservedQuantity[1]', 'TQuantity'),
         @vLocation         = Record.Col.value('Location[1]',         'TLocation'),
         @vBusinessUnit     = Record.Col.value('BusinessUnit[1]',     'TBusinessUnit'),
         @vUserId           = Record.Col.value('UserId[1]',           'TUserId')
  from @xmlInput.nodes('/QCInfo/LPNInfo') as Record(Col);

  select @vQCMode = Record.Col.value('QCMode[1]', 'TTypeCode')
  from @xmlInput.nodes('/QCInfo/Options') as Record(Col);

  /* Get CartonDetailsInfo, NotScannableItems and AdditionalChecksConfirmed into temp table */
  insert into @ttQCDetails
        (LPNDetailId,
         SKUId,
         SKU,
         ConfirmedQty,
         ConfirmedInnerPacks,
         OnhandStatus,
         ConfirmedQCCheck,
         ConfirmedQCStatus,
         QCInfoType)
  select Record.Col.value('LPNDetailId[1]',      'TRecordId'),
         Record.Col.value('SKUId[1]',            'TRecordId'),
         Record.Col.value('SKU[1]',              'TSKU'),
         Record.Col.value('Quantity[1]',         'TQuantity'),
         Record.Col.value('InnerPacks[1]',       'TQuantity'),
         Record.Col.value('OnhandStatus[1]',     'TStatus'),
         'Item Count', /* ConfirmedQCCheck */
         null, /* ConfirmedQCStatus */
         'LPNDetailsInfo'  /* We will get all scannableand non scannable items in LPNDetails node only */
  from @xmlInput.nodes('/QCInfo/LPNDetailInfo/LPNDetail') as Record(Col)
  union
  select null, /* LPNDetailId */
         null, /* SKUId */
         null, /* SKU */
         null, /* ConfirmedQty */
         null, /* ConfirmedInnerPacks */
         null, /* OnhandStatus */
         Record.Col.value('Check[1]',            'TDescription'),
         Record.Col.value('Status[1]',           'TStatus'),
         'AdditionalChecks'
  from @xmlInput.nodes('/QCInfo/AdditionalChecks/ChecksConfirmed') as Record(Col);

  /* Get the Tracking No, Receiver No */
  select @vTrackingNo     = TrackingNo,
         @vReceiverNumber = ReceiverNumber,
         @vLPNOrderId     = OrderId,
         @vLPNReceiptId   = ReceiptId,
         @vWaveId         = PickBatchId,
         @vWaveNo         = PickBatchNo
  from vwLPNs
  where (LPNId = @vLPNId);

  /* PickedBy/PackedBy are from LPN Details of the LPN */
  select top 1 @vPickedBy = PickedBy,
               @vPackedBy = PackedBy
  from LPNDetails
  where (LPNId = @vLPNId);

  /* Get the Wave Info */
  select @vWaveType = W.BatchType
  from PickBatches W
  where (RecordId = @vWaveId);

  /* Get Order info */
  if (@vLPNOrderId is not null)
    select @vOrderId    = OrderId,
           @vPickTicket = PickTicket,
           @vSalesOrder = SalesOrder
    from OrderHeaders
    where (OrderId = @vLPNOrderId);

  /* Get the Receipt Info */
  if (@vLPNReceiptId is not null)
    select @vReceiptId     = RH.ReceiptId,
           @vROType        = RH.ReceiptType
    from ReceiptHeaders RH
    where (RH.ReceiptId = @vLPNReceiptId);

  /* Validations */
  if (@vLPNId is null)
    set @vMessageName = 'LPNDoesNotExist';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    goto ErrorHandler;

    /* Add the LPN and associated info to QCHeaders table */
  insert into QCHeaders (LPNId, LPN, TrackingNo, OrderId, PickTicket, WaveId, WaveNo, WaveType,
                         ReceiptId, ReceiptNumber, ReceiverNumber, ROType,
                         QCMode, QCCategory, PickedBy, PackedBy, QCDate, QCStatus, NumErrors,
                         BusinessUnit, CreatedBy)
    select @vLPNId, @vLPN, @vTrackingNo, @vOrderId, @vPickTicket, @vWaveId, @vWaveNo, @vWaveType,
           @vReceiptId, @vReceiptNumber, @vReceiverNumber, @vROType,
           @vQCMode, @vQCCategory, @vPickedBy, @vPackedBy, current_timestamp, null /* QC Status */, null /* NumErrors */,
           @vBusinessUnit, @vUserId;

  select @vQCRecordId = Scope_Identity();

  /* Update the SKUId */
  update ttQCD
  set ttQCD.SKUId = S.SKUId
  from @ttQCDetails ttQCD
    join SKUs S on (S.SKU = ttQCD.SKU) and (BusinessUnit = @vBusinessUnit);

  /* Updating QCComments for Additional checks */
  update @ttQCDetails
  set QCComment = case when ConfirmedQCStatus = 'S' /* Success */ then 'Verified' else 'Incorrect' end
  where QCInfoType = 'AdditionalChecks';

  /* Getting the LPN Info and updating the status */
  -- We have to group by SKUId as there could be multiple LPNDetails with same SKUId
  update QCD
  set QCD.LPNId              = LD.LPNId,
      QCD.ExpectedInnerPacks = coalesce(LD.InnerPacks, 0),
      QCD.ExpectedQty        = coalesce(LD.Quantity, 0),
      QCD.OrderId            = LD.OrderId
  from @ttQCDetails QCD
    left outer join LPNDetails LD on (LD.LPNId = @vLPNId) and (QCD.SKUId = LD.SKUId)

  /* Get the corresponding Order Detail of each SKU */
  update QCD
  set QCD.OrderDetailid = OD.OrderDetailId
  from @ttQCDetails QCD join OrderDetails OD on (OD.OrderId = @vOrderId) and (QCD.SKUId = OD.SKUId);

  /* Verifying Expected Qty with the Scanned Qty and updating comments accordingly */
  update QCD
  set QCD.QCComment         = case when QCD.SKU = 'Unknown Item' then 'Unknown Item'
                                   when QCD.ExpectedQty = QCD.ConfirmedQty then 'Verified' /* when both expected and scanned Qty are equal */
                                   when QCD.ExpectedQty = 0 and QCD.ConfirmedQty > 0 and QCD.OrderDetailId is null then 'Not on Order'
                                   when QCD.ExpectedQty = 0 and QCD.ConfirmedQty > 0 then 'Wrong Item' /* when expected Qty exists and scanned Qty not exists */
                                   /* when expected Qty exists and scanned Qty not exists and SKU not in same order */
                                   when QCD.ExpectedQty < QCD.ConfirmedQty then 'Extra Item' /* when scanned Qty is greater than expected */
                                   when QCD.ExpectedQty > QCD.ConfirmedQty then 'Missing Item' /* when scanned Qty is lesser than expected */
                                   else ''
                              end,
      QCD.ConfirmedQCStatus = case when QCD.ExpectedQty = QCD.ConfirmedQty then 'S' /* Success */ else 'E' /* Error */ end
  from @ttQCDetails QCD

  /* will insert all the scannable, non-scannable items and additional checks into QCDetails */
  if (@vQCRecordId is not null)
    insert into QCDetails
          (QCRecordId, LPNId, SKUId, ExpectedQty, ConfirmedQty,
           QCCheck, QCStatus, QCComment, BusinessUnit, CreatedBy)
      select @vQCRecordId, LPNId, SKUId, ExpectedQty, ConfirmedQty, ConfirmedQCCheck,
             ConfirmedQCStatus, QCComment, @vBusinessUnit, @vUserId
      from @ttQCDetails;

  /* updating error count on QCHeaders */
  if (@@rowcount > 0)
    begin
      select @vNumErrors = count(*)
      from @ttQCDetails
      where (ConfirmedQCStatus = 'E' /* Error */);

      update QCHeaders
      set NumErrors = coalesce(@vNumErrors, NumErrors),
          QCStatus  = case when @vNumErrors > 0 then 'E' else 'S' end
      where (QCRecordId = @vQCRecordId);
    end

  /* Build the xml for result */
  set @vQCDetailsXML = (select coalesce(SKUId,0) as SKUId,
                               coalesce(SKU,'') as SKU,
                               coalesce(ExpectedQty,0) as ExpQuantity,
                               coalesce(ExpectedInnerPacks,0) as ExpInnerPacks,
                               coalesce(ConfirmedQty,0) as ScannedQty,
                               coalesce(ConfirmedInnerPacks,0) as ScannedInnerPacks,
                               coalesce(QCComment,' ') as Result
                        from @ttQCDetails
                        for XML raw('QCDetail'), type, elements, root('QCDetails'));

  set @vQCHeaderXML = (select coalesce(@vLPNId,0)       as LPNId,
                              coalesce(@vLPN,'')        as LPN,
                              coalesce(@vOrderId,0)     as OrderId,
                              coalesce(@vPickTicket,'') as PickTicket,
                              coalesce(@vSalesOrder,'') as SalesOrder,
                              coalesce(@vQuantity,0)    as Quantity,
                              coalesce(@vInnerPacks,0)  as InnerPacks
                       for XML raw(''), type, elements, root('QCInfo'));

  select @vMessage = case when coalesce(@vNumErrors, 0) > 0 then 'LPNQCCompleted_Failure' else 'LPNQCCompleted_Success' end;

  /* Build XML, The return dataset is used for RF to show Pallet info, Pallet Details in seperate nodes */
  --set @xmlResult = dbo.fn_XMLNode('QCResult',
  --                                  coalesce(convert(varchar(max), @vQCHeaderXML),  '') +
  --                                  coalesce(convert(varchar(max), @vQCDetailsXML), ''));

  /* Build the Description */
  select @vMessage = dbo.fn_Messages_BuildDescription(@vMessage, 'LPN', @vLPN /* LPN */ , null, null, null, null, null, null, null, null, null, null);

  exec pr_BuildRFSuccessXML @vMessage, @xmlResult output;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @vMessageName, @EntityId = @vLPNId, @ActivityLogId = @vActivityLogId output;
end catch;
  return(coalesce(@vReturnCode, 0));
end  /* pr_RFC_QC_PostResults */

Go
