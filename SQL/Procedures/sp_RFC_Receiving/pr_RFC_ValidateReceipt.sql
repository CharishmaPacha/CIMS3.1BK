/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/26  NB      pr_RFC_ValidateReceipt: Receiver and Receipt Warehouse match, when Receiver is given(CIMSV3-987)
  2020/05/06  MS      pr_RFC_ValidateReceipt: Changes to validate the Location (HA-227)
  2020/04/15  VM      pr_RFC_ValidateReceipt: Bugfix in validating the given location to raise error (HA-174)
  2020/04/13  VM      pr_RFC_ValidateReceipt: Process custom receiving validations (HA-174)
  2018/06/23  MJ      pr_RFC_ValidateReceipt: Validated to not receive inventory of the closed receiver (S2G-933)
  2018/04/11  YJ      pr_RFC_ReceiveToLocation, pr_RFC_ValidateReceipt: Added RF Log (S2G-514)
  2018/03/06  AY/SV   pr_RFC_ValidateReceipt: Changes for Auto Create Receivers (S2G-337) & cleanup.
  2018/02/23  SV      pr_RFC_ValidateReceipt: Added validation for Receiver# if at all provided from RF (S2G-225)
  2018/01/17  TK      pr_RFC_ReceiveToLPN: Changes to receive an external LPN (S2G-20)
                      pr_RFC_ValidateReceipt: Changes to return UPC and CaseUPC & re-factored code (S2G-41)
  2014/03/27  NY      pr_RFC_ValidateReceipt: Added transfer type.
  2014/03/18  PKS     pr_RFC_ValidateReceipt: PackingSlip changed to ReceiverNumber, return XML was modified,
                      All receiptDetails records comes in detail XML.And added Qty and LPN related new fields in output XML for future use.
                      pr_RFC_ReceiveToLPN: parameters of pr_RFC_ValidateReceipt converted into XML.
  2014/03/17  PKS     pr_RFC_ValidateReceipt: Signature of the procedure changed, Both input and output parameters are XMLs.
  2013/08/27  TD      pr_RFC_ValidateReceipt:Getting Default Lcoation if the user does not enter the Location.
  2013/08/08  PK      pr_RFC_ValidateReceipt: Minor fix to return data set if the CustPO is null.
  2013/07/27  DK      pr_RFC_ValidateReceipt:Added condition to validate Receive into location which matches the Warehouse of the Receipt
  2013/07/12  YA      pr_RFC_ValidateReceipt: Made Receiving related control category specific to ReceiptOrder Types.
  2013/04/16  TD      pr_RFC_ReceiveToLPN, pr_RFC_ValidateReceipt, pr_RFC_ReceiveToLocation : Added
                          CustPO as inputparam and made custpo as controloption based.
  2013/03/05  YA/PK   pr_RFC_ValidateReceipt, pr_RFC_ReceiveToLPN: Modified to receive inventory
                        in to a dock location.
  2011/02/09  PK      pr_RFC_ValidateReceipt: Validating other types((M)anufacturing, (R)eturn).
  2011/02/07  PK      pr_RFC_ValidateReceipt : Changed PurchaseOder PO to P.
  2011/01/21  VM      pr_RFC_ReceiveToLPN: Return Receipt details dataset to use in RF to show updated.
                      pr_RFC_ValidateReceipt: Corrected a validation and added required where condition
                        in return query.
  2011/01/03  VM      pr_RFC_ValidateReceipt:Bug-fix - Get the details of ReceiptId or ReceiptNumber.
  2010/11/02  VK      pr_RFC_ValidateReceipt: Replaced 'var' with 'v' as prefix
                        to local variables
  2010/11/29  PK      pr_RFC_ValidateReceipt: Functionality implemented
  2010/11/25  PK      Completed pr_RFC_ValidateReceipt.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ValidateReceipt') is not null
  drop Procedure pr_RFC_ValidateReceipt;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ValidateReceipt:
  Validate Option: 'V' - Validate Only, 'D' - return Data as well.

  Note:
  IsCustPORequired: Possible values are
    -O, it is optional
    -A, Allowed, but not required. It is however be considered as required if user gives a CustPO
          and there are multiple CustPOs in the shipment with the same SKU
    -R, then it is required all the time.

  ConsiderExtraQty: If Yes, then we will show the lines to be received even though
    the line is completely received as ExtraQty can be received. If No, then we do
    not show lines completely received.

  XML Input(@xmlInput):
  <ValidateReceiptInput>
    <ReceiverNumber>R001</ReceiverNumber>
    <ReceiptId>1</ReceiptId>
    <ReceiptNumber>RH001</ReceiptNumber>
    <CustPO>123</CustPO>
    <ReceiveToLocation>R01-01-001</ReceiveToLocation>
    <ReceiveToPallet>P0001</ReceiveToPallet>
    <Warehouse>CO1</Warehouse>
    <ValidateOption>D</ValidateOption>
    <BusinessUnit>SCT</BusinessUnit>
    <UserId>rfcadmin</UserId>
  </ValidateReceiptInput>

  output XML: Initially below XML information was returned in form of data set by pr_ReceiptHeaders_GetToReceiveDetails.

  XML output(@xmlResult):
  <ValidateReceiptResult>
    <ReceiptHeader>
      <ReceiverNumber></ReceiverNumber>
      <ReceiptId></ReceiptId>
      <ReceiptNumber></ReceiptNumber>
      <CustPO></CustPO>
      <EnableQty></EnableQty>
      <DefaultQty></DefaultQty>
      <ReceivingPallet></ReceivingPallet>
      <ReceivingLocation></ReceivingLocation>
    </ReceiptHeader>
    <ReceiptDetails>
      <ReceiptDetail>
        <ReceiptDetailId></ReceiptDetailId>
        <SKU></SKU>
        <Description></Description>
        <QtyOrdered></QtyOrdered>
        <QtyIntransit></QtyIntransit>
        <QtyReceived></QtyReceived>
        <QtyToReceive></QtyToReceive>
        <DisplayQtyToReceive></DisplayQtyToReceive>
        <LPNsOrdered></LPNsOrdered>
        <LPNsIntransit></LPNsIntransit>
        <LPNsReceived></LPNsReceived>
        <LPNsToReceive></LPNsToReceive>
        <DisplaySKU></DisplaySKU>
        <UnitsPerInnerPack></UnitsPerInnerPack>
        <WarningMsg></WarningMsg>
        <UDF1></UDF1>
        <UDF2></UDF2>
      </ReceiptDetail>
    </ReceiptDetails>
  </ValidateReceiptResult>
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ValidateReceipt
  (@xmlInput   xml,
   @xmlResult  xml output)
as
  declare @ReceiverNumber            TReceiverNumber  = null,
          @ReceiptId                 TRecordId,
          @ReceiptNumber             TReceiptNumber,
          @CustPO                    TCustPO,

          @ReceiveToLocation         TLocation,
          @ReceiveToPallet           TPallet       = null,
          @Warehouse                 TWarehouse    = null,
          @Operation                 TOperation,
          @ValidateOption            TFlags        = 'VD',
          @vReceiptId                TRecordId,
          @vReceiptNumber            TReceiptNumber,
          @vReceiptType              TReceiptType,
          @vReceiptStatus            TStatus,
          @vReceiptDetailId          TRecordId,
          @vReceiverId               TRecordId,
          @vReceiverNumber           TReceiverNumber,
          @vReceiverStatus           TStatus,
          @vReceiverWarehouse        TWarehouse,
          @vCustPO                   TCustPO,
          @SKU                       TSKU,
          @QtyToReceive              TQuantity,
          @Description               TDescription,
          @ReceiptLine               TReceiptLine,
          @vLocationId               TRecordId,
          @vLocationType             TLocationType,
          @vReceiveToLocation        TLocation,
          @vPalletId                 TRecordId,
          @vPalletStatus             TStatus,
          @vPalletLocationId         TRecordId,
          @vReceiptWarehouse         TWarehouse,
          @vLocWarehouse             TWarehouse,
          @vIsLocationRequired       TControlValue,
          @vIsReceiverRequired       TControlValue,
          @vIsCustPORequired         TControlValue,
          @vMaxQtyToReceive          TQuantity,
          @vControlCategory          TCategory,
          @BusinessUnit              TBusinessUnit,
          @UserId                    TUserId,
          @vDeviceId                 TDeviceId,
          @vActivityLogId            TRecordId,

          @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vMessage                  TDescription,
          @vReceiveToDiffWarehouse   TControlValue,
          @vReceiptHeaderXML         TXML,
          @vReceiptDetailXML         xml,
          @xmlRulesData              TXML;

  declare @ttReceiptDetails table (ReceiptId           TRecordId,
                                   ReceiptNumber       TReceiptNumber,
                                   ReceiptDetailId     TRecordId,
                                   SKU                 TSKU,
                                   UoM                 TUoM,
                                   UPC                 TUPC,
                                   CaseUPC             TUPC,
                                   Description         TDescription,
                                   QtyToReceive        TQuantity,    -- we will get QtyToLabel to it as it is accurate qty to receive
                                   DisplayQtyToReceive varchar(Max), -- we will get DisplayQtyToLabel to it as it is accurate qty to receive
                                   DisplaySKU          TSKU,
                                   CustPO              TCustPO,
                                   ReceiverNumber      TReceiverNumber,
                                   UnitsPerInnerPack   TInteger,
                                   WarningMsg          TMessage,
                                   UDF1                TUDF,
                                   UDF2                TUDF,
                                   EnableQty           TFlag,
                                   DefaultQty          TQuantity,
                                   ReceivingPallet     TPallet,
                                   ReceivingLocation   TLocation);
begin
begin try
  -- Transactions are commented and need to fix this in another way.
  --begin transaction;
  SET NOCOUNT ON;

  select @ReceiverNumber    = nullif(Record.Col.value('ReceiverNumber[1]',    'TReceiverNumber'), ''),
         @ReceiptId         = nullif(Record.Col.value('ReceiptId[1]',         'TRecordId'),       ''),
         @ReceiptNumber     = nullif(Record.Col.value('ReceiptNumber[1]',     'TReceiptNumber'),  ''),
         @CustPO            = nullif(Record.Col.value('CustPO[1]',            'TCustPO'),         ''),
         @Warehouse         = nullif(Record.Col.value('Warehouse[1]',         'TWarehouse'),      ''),
         @ReceiveToLocation = nullif(Record.Col.value('ReceiveToLocation[1]', 'TLocation'),       ''),
         @ReceiveToPallet   = nullif(Record.Col.value('ReceiveToPallet[1]',   'TPallet'),         ''),
         @Operation         = nullif(Record.Col.value('Operation[1]',         'TOperation'),      ''),
         @ValidateOption    = nullif(Record.Col.value('ValidateOption[1]',    'TFlag'),           ''),
         @BusinessUnit      = nullif(Record.Col.value('BusinessUnit[1]',      'TBusinessUnit'),   ''),
         @UserId            = nullif(Record.Col.value('UserId[1]',            'TUserId'),         ''),
         @vDeviceId         = nullif(Record.Col.value('DeviceId[1]',          'TDeviceId'),       '')
  from @xmlInput.nodes('/ValidateReceiptInput') as Record(Col);

  /* Add to RF Log */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, @vDeviceId,
                      @ReceiptId, @ReceiptNumber, 'Receipt', @Value1 = @ReceiverNumber,
                      @ActivityLogId = @vActivityLogId output;

  /* Update the variables to null if the value is empty */
  select @ReceiverNumber     = nullif(@ReceiverNumber,    ''),
         @ReceiveToLocation  = nullif(@ReceiveToLocation, ''),
         @ReceiveToPallet    = nullif(@ReceiveToPallet,   ''),
         @CustPO             = nullif(@CustPO ,           ''),
         @Operation          = coalesce(@Operation,       'ReceiveToLPN');
  select @vReceiveToLocation = @ReceiveToLocation;

  select @vReceiptId        = ReceiptId,
         @vReceiptNumber    = ReceiptNumber,
         @vReceiptType      = ReceiptType,
         @vReceiptStatus    = Status,
         @vReceiptWarehouse = Warehouse
  from ReceiptHeaders
  where ((ReceiptId     = @ReceiptId) or
         (ReceiptNumber = @ReceiptNumber)) and
        (ReceiptType in ('PO'/* Purchase Order */, 'A'/* ASN */, 'R'/* Return */, 'M'/* Manufacturing */, 'T' /* Transfer */)) and
        (BusinessUnit  = @BusinessUnit);

  /* set the control category based on the control type */
  select @vControlCategory = 'Receiving_' + @vReceiptType;

  select @vIsLocationRequired     = dbo.fn_Controls_GetAsString(@vControlCategory, 'IsLocationRequired',     'N',    @BusinessUnit, @UserId),
         @vIsReceiverRequired     = dbo.fn_Controls_GetAsString(@vControlCategory, 'IsReceiverRequired',     'AUTO', @BusinessUnit, @UserId),
         @vIsCustPORequired       = dbo.fn_Controls_GetAsString(@vControlCategory, 'IsCustPORequired',       'O',    @BusinessUnit, @UserId),
         @vReceiveToDiffWarehouse = dbo.fn_Controls_GetAsString(@vControlCategory, 'ReceiveToDiffWarehouse', 'Y' /* Yes */,@BusinessUnit, @UserId);

  /* If CustPO is given, then get the details of CustPO to validate */
  if (@CustPO is not null)
    select @vReceiptDetailId = Min(ReceiptDetailId),
           @vCustPO          = Min(CustPO),
           @vMaxQtyToReceive = sum(MaxQtyAllowedToReceive)
    from vwReceiptDetails
    where ((ReceiptId = @vReceiptId) and
           (CustPO    = @CustPO));

  /* If user did not enter the Location, then get the default
     receiving location which would be any location in the RecvStaging area */
  if (@vReceiveToLocation is null)
    select top 1 @vReceiveToLocation = Location
    from Locations
    where (Warehouse    = @vReceiptWarehouse) and
          (PutawayZone  = 'RecvStaging') and
          (LocationType = 'S' /* Staging */)
    order by PutawayPath, NumLPNs;

  /* If user does not enter the Location and we could not identify a default location
     in the Warehouse, then use the location from controls */
  if (@vReceiveToLocation is null)
    select @vReceiveToLocation = dbo.fn_Controls_GetAsString('Receipts', 'LPNLocation_'+@vReceiptWarehouse, 'RIP', @BusinessUnit, @UserId);

  /* Get the location details if we have identified the receivng location */
  if (@vReceiveToLocation is not null)
    select @vLocationId        = LocationId,
           @vReceiveToLocation = Location,
           @vLocationType      = LocationType,
           @vLocWarehouse      = Warehouse
    from Locations
    where (LocationId = dbo.fn_Locations_GetScannedLocation (null, @vReceiveToLocation, @vDeviceId, @UserId, @BusinessUnit));

  if (@ReceiverNumber is not null)
    select @vReceiverId        = ReceiverId,
           @vReceiverNumber    = ReceiverNumber,
           @vReceiverStatus    = Status,
           @vReceiverWarehouse = Warehouse
    from Receivers
    where (ReceiverNumber = @ReceiverNumber) and (BusinessUnit = @BusinessUnit);

  if (@ReceiveToPallet is not null)
    select @vPalletId         = PalletId,
           @vPalletStatus     = Status,
           @vPalletLocationId = LocationId
    from Pallets
    where (Pallet = @ReceiveToPallet);

  /* Build the XML for custom validations */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                         dbo.fn_XMLNode('Operation',    @Operation) +
                         dbo.fn_XMLNode('ReceiptId',    @vReceiptId) +
                         dbo.fn_XMLNode('ROWarehouse',  @vReceiptWarehouse) +
                         dbo.fn_XMLNode('LocWarehouse', @vLocWarehouse));

  if (@vReceiptId is null)
    set @vMessageName = 'ReceiptDoesNotExist';
  else
  if (@vReceiptNumber is null)
    set @vMessageName = 'ReceiptIsInvalid';
  else
  if (@vReceiptStatus = 'C' /* Closed */)
    set @vMessageName = 'CannotReceiveClosedRO';
  else
  /* Get info about if there are multiple CustPOs in the shipment with the same SKU*/
  if ((@CustPO is null) and (@vIsCustPORequired = 'R'/* Always Required */))
    set @vMessageName = 'CustPOIsRequired';
  else
  if ((@CustPO is not null) and (@vReceiptDetailId is null))
    set @vMessageName = 'RODoesNothaveCustPO';
  else
  if (@CustPO is not null) and (@vMaxQtyToReceive < 1)
    set @vMessageName = 'CustPOCompletelyReceived';
  else
  if ((@CustPO is null) and (@vIsCustPORequired = 'A' /* What does A stand for? */) and
      (exists(select SKU, count(distinct CustPO)
              from vwReceiptdetails
              where ReceiptId = @vReceiptId
              group by SKU having count(distinct CustPO) > 1)))
    set @vMessageName = 'ReceiptHasMultipleCustPOsWithSameSKU';
  else
  if (@vIsReceiverRequired = 'Y'/* Yes, Required */) and (@ReceiverNumber is null)
    set @vMessageName = 'ReceiverNumberIsRequired';
  else
  if (@ReceiverNumber is not null) and (@vReceiverId is null)
    set @vMessageName = 'ReceiverNumberIsInvalid';
  else
  if (@ReceiverNumber is not null) and
     (coalesce(@vReceiverWarehouse, '') <> coalesce(@vReceiptWarehouse, ''))
    set @vMessageName = 'ReceiverReceiptWHMismatch';
  else
  if (@vReceiverStatus = 'C' /* Closed */)
    set @vMessageName = 'ReceiverIsClosed';
  else
  if (@vIsLocationRequired = 'Y'/* Yes */) and (@ReceiveToLocation is null)
    set @vMessageName = 'Recv_LocationIsRequired';
  else
  if ((@vReceiptType = 'A' /* ASN */) and (@vLocationId is not null) and (@vLocationType not in ('D', 'S'  /* Dock, Staging */)))
    set @vMessageName = 'NotAnASNReceivingLocation';
  else
  if (@vReceiveToLocation is not null) and (@vLocationId is null)
    set @vMessageName = 'InvalidLocation';
  else
  if (@vLocationId is not null) and (@Warehouse is not null) and
     (@vLocWarehouse <> @Warehouse)
    set @vMessageName = 'LocationNotInGivenWarehouse';
  else
  if (@vLocationId is not null) and (@vLocationType not in ('D', 'S', 'K' /* Dock, Staging, Picklane */))
    set @vMessageName = 'NotAReceivingLocation';
  else
  if (@ReceiveToPallet is not null) and (@vPalletId is null)
    set @vMessageName = 'InvalidPallet';
  else
  if (@vPalletId is not null) and
     (@vPalletStatus <> 'E' /* Empty */) and
     (@vLocationId is not null) and
     (@vLocationId <> coalesce(@vPalletLocationId, 0))
    set @vMessageName = 'LocationDoesNotHoldThisPallet';
  else
  /* Cannot receive into any location which does not match the Warehouse of the Receipt */
  if (@vReceiveToDiffWarehouse = 'N') and
     (coalesce(@vReceiptWarehouse, '') <> coalesce(@vLocWarehouse, ''))
    set @vMessageName = 'Recv_WarehouseMismatch';
  else
  /* If Loc WH is diff than RH WH, then check if it is a valid mapping, else raise error */
  if (@vReceiveToDiffWarehouse = 'Y') and
     (coalesce(@vReceiptWarehouse, '') <> coalesce(@vLocWarehouse, '')) and
     (@vLocWarehouse not in (select TargetValue
                             from dbo.fn_GetMappedValues('CIMS', @vReceiptWarehouse, 'CIMS', 'Warehouse', 'Receiving', @BusinessUnit)))
    set @vMessageName = 'Recv_WarehouseMismatch';
  else
  if (not exists(select *
                 from vwReceiptDetails
                 where (ReceiptId    = @vReceiptId) and
                       (MaxQtyAllowedToReceive > 0)))
    set @vMessageName = 'NoUnitsToReceive';
  else
    /* Custom validations */
    exec pr_RuleSets_Evaluate 'Receiving_Validations', @xmlRulesData, @vMessageName output;

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* The return dataset if requested is used for RF to show Receipt details */
  if (@ValidateOption like '%D%')
    begin
      insert into @ttReceiptDetails (ReceiptId, ReceiptNumber, ReceiptDetailId, SKU, Description, DisplaySKU,
                                     UoM, UPC, CaseUPC, UnitsPerInnerPack, QtyToReceive, DisplayQtyToReceive, CustPO,
                                     ReceivingPallet, ReceivingLocation, ReceiverNumber,
                                     WarningMsg, EnableQty, DefaultQty, UDF1, UDF2)
        exec pr_ReceiptHeaders_GetToReceiveDetails @vReceiptId, @CustPO, @vReceiverNumber, @ReceiveToPallet, @vReceiveToLocation,
                                                   @Operation, null /* Options */, @BusinessUnit, @UserId;

      set @vReceiptHeaderXML = (select top 1 ReceiverNumber,
                                             ReceiptId,
                                             ReceiptNumber,
                                             CustPO,
                                             EnableQty,
                                             DefaultQty,
                                             ReceivingPallet,
                                             ReceivingLocation
                                from @ttReceiptDetails
                                for XML raw('ReceiptHeader'), elements);

      set @vReceiptDetailXML = (select ReceiptDetailId,
                                       SKU,
                                       UoM,
                                       coalesce(Description,SKU) Description,
                                       UPC,
                                       CaseUPC,
                                       0 as QtyOrdered,
                                       0 as QtyIntransit,
                                       0 as QtyReceived,
                                       QtyToReceive,
                                       DisplayQtyToReceive,
                                       0 as LPNsOrdered,
                                       0 as LPNsIntransit,
                                       0 as LPNsReceived,
                                       0 as LPNsToReceive,
                                       DisplaySKU,
                                       UnitsPerInnerPack,
                                       WarningMsg,
                                       /* As client requires any new values to show, we will use the below UDFs */
                                       coalesce(UDF1, '') UDF1,
                                       coalesce(UDF2, '') UDF2
                                from @ttReceiptDetails
                                for XML raw('ReceiptDetail'), type, elements, root('ReceiptDetails'));

      set @xmlResult = (select dbo.fn_XMLNode('ValidateReceiptResult',
                                 coalesce(@vReceiptHeaderXML, '') +
                                 coalesce(convert(varchar(max), @vReceiptDetailXML), '')));
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  --commit transaction;
end try
begin catch
  --rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* To log RF log if any exception exist */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;
end catch;
  return(coalesce(@vReturnCode, 0));
end /* pr_RFC_ValidateReceipt */

Go
