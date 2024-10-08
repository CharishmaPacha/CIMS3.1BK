/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/13  SV      pr_AMF_Returns_ConfirmReceiveRMA, pr_AMF_Returns_ValidateEntity:
  2021/05/12  SV      pr_AMF_Returns_ValidateEntity: Changes to send the Qty Info in data table on scanning the RMA (OB2-1794)
  2021/02/12  RIA     Added pr_AMF_Returns_ValidateLPN and made changes to pr_AMF_Returns_ValidateEntity (OB2-1357)
  2021/02/05  SV      pr_AMF_Returns_ValidateEntity: Changes to return the ShippedUnits and ReturnedUnits (OB2-1356)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Returns_ValidateEntity') is not null
  drop Procedure pr_AMF_Returns_ValidateEntity;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Returns_ValidateEntity: Returns process is started by scanning
    an entity which could be the LPN, TrackingNo, UCCBarcode or ReturnTrackingNo
    of the package being returned and gives the related information from the
    RMA or the Shipped Order
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Returns_ValidateEntity
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vxmlInput                 xml,
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vScannedEntity            TEntity,
          @vRFFormAction             TMessageName,
          @vOperation                TOperation;

  /* Functional variables */
  declare @vEntityId                 TRecordId,
          @vEntityKey                TEntity,
          @vReceiptId                TRecordId,
          @vReceiptNumber            TReceiptNumber,
          @vReceiptType              TTypeCode,
          @vReceiptStatus            TStatus,
          @vTotalUnitsShipped        TQuantity,
          @vUnitsReturned            TQuantity,
          @vQtyToBeReturned          TQuantity,
          @vOrderId                  TRecordId,
          @vSalesOrder               TSalesOrder,
          @vPickTicket               TPickTicket,
          @vLPNOrderId               TRecordId,
          @vReturnOrderId            TRecordId,
          @vReturnPT                 TPickTicket,
          @vTrackingNo               TTrackingNo,
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNStatus                TStatus,
          @vLPNPT                    TPickTicket,
          @vOrderStatus              TStatus,
          @vHasRMA                   TFlags,
          @vScanningLPNOptional      TControlValue,
          @vScannedEntityType        TControlValue,
          @vAllowedInvClasses        TControlValue,
          @vValue1                   TDescription,
          @vValue2                   TDescription,

          @vxmlReturnDetails         xml,
          @vReturnDetailsxml         TXML,
          @vInvClass1XML             TXML,
          @vReasonCodesXML           TXML,
          @vDispositionXML           TXML,
          @vActivityLogId            TRecordId,
          @vSuccessMessage           TMessage;
begin /* pr_AMF_Returns_ValidateEntity */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read the inputs */
  select @vBusinessUnit       = Record.Col.value('(SessionInfo/BusinessUnit)[1]',              'TBusinessUnit'),
         @vUserId             = Record.Col.value('(SessionInfo/UserName)[1]',                  'TUserId'      ),
         @vDeviceId           = Record.Col.value('(SessionInfo/DeviceId)[1]',                  'TDeviceId'    ),
         @vScannedEntity      = Record.Col.value('(Data/Entity)[1]',                           'TEntity'      ),
         @vOperation          = Record.Col.value('(Data/Operation)[1]',                        'TOperation'   )
  from @vxmlInput.nodes('/Root')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Check if user scanned LPN/UCC/TrackingNo */
  select @vLPNId              = LPNId,
         @vLPN                = LPN,
         @vEntityId           = LPNId,
         @vEntityKey          = LPN,
         @vLPNStatus          = Status,
         @vLPNOrderId         = OrderId,
         @vScannedEntityType  = 'LPN'
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@vScannedEntity, @vBusinessUnit, 'LTU'));

  /* if it not an LPN, check if user scanned RMA */
  if (@vEntityKey is null)
    select @vReceiptId          = ReceiptId,
           @vReceiptNumber      = ReceiptNumber,
           @vEntityId           = ReceiptId,
           @vEntityKey          = ReceiptNumber,
           @vReceiptType        = ReceiptType,
           @vReceiptStatus      = Status,
           @vReturnPT           = PickTicket,
           @vScannedEntityType  = 'RMA'
    from ReceiptHeaders
    where (ReceiptNumber = @vScannedEntity) and
          (BusinessUnit  = @vBusinessUnit );

  /* If isn't an LPN or RMA, check if it is a PickTicket */
  if (@vEntityKey is null)
    select @vOrderId            = OrderId,
           @vPickTicket         = PickTicket,
           @vEntityId           = OrderId,
           @vEntityKey          = PickTicket,
           @vOrderStatus        = Status,
           @vScannedEntityType  = 'PickTicket'
    from OrderHeaders
    where (PickTicket = @vScannedEntity) and
          (BusinessUnit = @vBusinessUnit);

  /* Get controls for scanning an LPN optional or not */
  select @vScanningLPNOptional = dbo.fn_Controls_GetAsString('Receipts_Return', 'ScanningLPNOptional', 'Y' /* Yes */, @vBusinessUnit, @vUserId);

  /* Validations */
  if (@vScannedEntityType is null)
    set @vMessageName = 'AMF_Returns_InvalidInput';
  else
  if (@vOrderStatus <> 'S' /* Shipped */)
    set @vMessageName = 'OrderNotShipped';
  else
  if (@vLPNStatus <> 'S' /* Shipped */)
    set @vMessageName = 'LPNNotShipped';
  else
  if (@vReceiptType <> 'R')
    set @vMessageName = 'AMF_Returns_NotRMA';
  else
  if (@vReceiptStatus in ('T', 'E', 'C', 'X'  /* InTransit, Received, Closed, Canceled */))
    select @vMessageName = 'Returns_InvalidReceiptStatus',
           @vValue1      = @vReceiptNumber,
           @vValue2      = dbo.fn_Status_GetDescription('Receipt', @vReceiptStatus, @vBusinessUnit);

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vValue1, @vValue2;

  /* If there is RMA associated then return details of the RMA */
  if (@vReceiptNumber is not null)
    begin
      select @vTotalUnitsShipped = NumUnits,
             @vUnitsReturned     = UnitsReceived
      from ReceiptHeaders
      where (ReceiptId = @vReceiptId);

      insert into #DataTableSKUDetails (SKUId, Quantity, Quantity1, Quantity2)
        select SKUId, QtyOrdered, QtyReceived, (QtyOrdered - QtyReceived)
        from ReceiptDetails
        where (ReceiptId = @vReceiptId) and (QtyToReceive > 0);
    end

  /* If it is a valid LPN that was shipped, show the details of the LPN */
  if (@vLPNId is not null)
    begin
      select @vUnitsReturned = RH.UnitsReceived,
             @vLPNPT         = RH.PickTicket,
             @vReceiptId     = RH.ReceiptId
      from ReceiptHeaders RH
        join OrderHeaders OH on (OH.PickTicket = RH.PickTicket)
      where (OH.OrderId = @vLPNOrderId);

      select @vTotalUnitsShipped = Quantity
      from LPNs
      where (LPNId = @vLPNId);

      /* We will get UnitsReturned if we already received at least 1 unit against the LPN, so
         we are computing the Units Returned to show the information to user */
      if (@vUnitsReturned is not null)
        insert into #DataTableSKUDetails (SKUId, Quantity, Quantity1, Quantity2)
          select S.SKUId, LD.Quantity, coalesce(RD.QtyReceived, 0), coalesce((LD.Quantity - RD.QtyReceived), LD.Quantity)
          from LPNDetails LD
            join SKUs S on (LD.SKUId = S.SKUId)
            join LPNs L on (L.LPNId = LD.LPNId)
            join OrderHeaders OH on (L.OrderId = OH.OrderId)
            join ReceiptHeaders RH on (RH.PickTicket = OH. PickTicket) and (OH.BusinessUnit = RH.BusinessUnit)
            left join ReceiptDetails RD on (RD.SKUId = S.SKUId) and (RD.ReceiptId = RH.ReceiptId)
          where (LD.LPNId = @vLPNId) and (RH.ReceiptId = @vReceiptId);
      else
      /* When no units were receieved against the LPN, defaulting the Units retruned to 0 */
      if (@vUnitsReturned is null)
        insert into #DataTableSKUDetails (SKUId, Quantity, Quantity1, Quantity2)
          select S.SKUId, LD.Quantity, 0, LD.Quantity
          from LPNDetails LD
            left outer join SKUs S on (LD.SKUId = S.SKUId)
          where (LD.LPNId = @vLPNId);
    end
  else
  if (@vPickTicket is not null)
    begin
      select @vUnitsReturned = RH.UnitsReceived
      from ReceiptHeaders RH
      join OrderHeaders OH on (OH.PickTicket = RH.PickTicket)
      where (OH.OrderId = @vOrderId);

      select @vTotalUnitsShipped = UnitsShipped
      from OrderHeaders
      where (OrderId = @vOrderId);

      /* We will get UnitsReturned if we already received at least 1 unit against the Order, so
         we are computing the Units Returned to show the information to user */
      if (@vUnitsReturned is not null)
        insert into #DataTableSKUDetails (SKUId, Quantity, Quantity1, Quantity2)
          select S.SKUId, OD.UnitsShipped, coalesce(RD.QtyReceived, 0), coalesce((OD.UnitsShipped - RD.QtyReceived), OD.UnitsShipped)
          from OrderDetails OD
            join SKUs S on (OD.SKUId = S.SKUId)
            join OrderHeaders OH on (OH.OrderId = OD.OrderId)
            join ReceiptHeaders RH on (RH.PickTicket = OH. PickTicket) and (OH.BusinessUnit = RH.BusinessUnit)
            left join ReceiptDetails RD on (RD.SKUId = S.SKUId) and (RD.ReceiptId = RH.ReceiptId)
          where (OD.OrderId = @vOrderId) and (RH.ReceiptId = @vReceiptId);
      else
      /* When no units were receieved against the Order, defaulting the Units retruned to 0 */
      if (@vUnitsReturned is null)
        insert into #DataTableSKUDetails (SKUId, Quantity, Quantity1, Quantity2)
          select S.SKUId, OD.UnitsShipped, 0, OD.UnitsShipped
          from OrderDetails OD
            left outer join SKUs S on (OD.SKUId = S.SKUId)
          where (OD.OrderId = @vOrderId)
    end

  /* Fill in the SKU related info in the data table */
  exec pr_AMF_DataTableSKUDetails_UpdateSKUInfo;

  /* Build the xml from the values in datatable */
  select @vxmlReturnDetails = (select * from #DataTableSKUDetails
                               for Xml Raw('RMA'), elements XSINIL, Root('RMADETAILS'));

  select @vReturnDetailsxml = convert(varchar(max), @vxmlReturnDetails);

  /* If ReceiptNumber is null */
  if (@vReceiptNumber is null)
    set @vHasRMA = 'N'
  else
    set @vHasRMA = 'Y';

  /* Get the controlvalue for InvClasses */
  select @vAllowedInvClasses = dbo.fn_Controls_GetAsString(@vOperation, 'AllowedInventoryClasses', '' /* default */, @vBusinessUnit, @vUserId);

  /* Fetch the InventoryClass1/LabelCode */
  if (@vAllowedInvClasses like '%1%')
    exec pr_AMF_BuildLookUpList 'InventoryClass1' /* Look up Category */, 'InventoryClass1',
                                'select Label Code', @vBusinessunit, @vInvClass1XML output;

  /* Fetch the disposition codes */
  exec pr_AMF_BuildLookUpList 'Return_Disposition', 'Dispositions', 'select a Disposition',
                              @vBusinessunit, @vDispositionXML output;

  /* Fetch the reason codes for Returns */
  exec pr_AMF_BuildLookUpList 'RC_Returns', 'ReasonCodes', 'select a reason',
                              @vBusinessunit, @vReasonCodesXML output;

  /* Build qty to be returned */
  select @vQtyToBeReturned = @vTotalUnitsShipped - coalesce(@vUnitsReturned, 0);

  /* Build the Location Info */
  select @DataXml = dbo.fn_XmlNode('Data', coalesce(@vReturnDetailsxml, '') +
                                           dbo.fn_XMLNode('EntityId', @vEntityId) +
                                           dbo.fn_XMLNode('Entity',   @vEntityKey) +
                                           dbo.fn_XMLNode('HasRMA',   @vHasRMA) +
                                           dbo.fn_XMLNode('InventoryClass', @vAllowedInvClasses) +
                                           coalesce(@vInvClass1XML, '') +
                                           coalesce(@vDispositionXML, '') +
                                           coalesce(@vReasonCodesXML, '') +
                                           dbo.fn_XMLNode('ScanningLPNOptional', @vScanningLPNOptional) +
                                           dbo.fn_XMLNode('ScannedEntityType',   @vScannedEntityType) +
                                           dbo.fn_XMLNode('QtyToBeReturned',     @vQtyToBeReturned) +
                                           dbo.fn_XMLNode('UnitsReturned',       @vUnitsReturned) +
                                           dbo.fn_XMLNode('UnitsShipped',        @vTotalUnitsShipped));

end /* pr_AMF_Returns_ValidateEntity */

Go

