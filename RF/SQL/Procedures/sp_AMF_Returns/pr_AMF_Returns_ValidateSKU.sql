/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/13  SV      pr_AMF_Returns_ValidateSKU: Added Validations (OB2-1794)
  2021/02/25  RIA     Added pr_AMF_Returns_ValidateSKU and made changes to pr_AMF_Returns_ValidateLPNs (OB2-1357)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Returns_ValidateSKU') is not null
  drop Procedure pr_AMF_Returns_ValidateSKU;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Returns_ValidateSKU: When user scans a SKU/UPC to return the
    inventory and it is not in shipped details, we will make a db call and validate
    it. If valid then we will prompt the user to enter Qty same SKU else will raise
    an error and ask user to scan another SKU.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Returns_ValidateSKU
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

          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vScannedSKU               TSKU;

          /* Functional variables */
  declare @vDeviceName               TName,
          @vSKUId                    TRecordId,
          @vSKU                      TSKU,
          @vScannedEntityType        TEntity,
          @vScannedEntityId          TRecordId,
          @vScannedQuantity          TQuantity,
          @vQtyToReceive             TQuantity,
          @vRDExists                 TFlag,
          @vReceiptNumber            TReceiptNumber,
          @vValue1                   TDescription,
          @vValue2                   TDescription,
          @vxmlData                  xml;
begin /* pr_AMF_Returns_ValidateSKU */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit      = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId            = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId          = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vScannedSKU        = Record.Col.value('(Data/SKU)[1]',                        'TSKU'         ),
         @vScannedEntityType = Record.Col.value('(Data/m_ScannedEntityType)[1]',        'TEntity'      ),
         @vScannedEntityId   = Record.Col.value('(Data/m_EntityId)[1]',                 'TRecordId'    ),
         @vScannedQuantity   = Record.Col.value('(Data/m_Quantity)[1]',                 'TQuantity'    )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Device Name is used to update dataxml in devices */
  select @vDeviceName = @vDeviceId + '@' + @vUserId;

  /* Delete the RFFormAction and SKU scanned */
  select @vxmlData = convert(xml, @DataXML);
  set @vxmlData.modify('delete /Data/RFFormAction');
  set @vxmlData.modify('delete /Data/SKU');
  select @DataXML = convert(varchar(max), @vxmlData);

  /* Get the SKU related Info */
  select @vSKUId = SKUId,
         @vSKU   = SKU
  from dbo.fn_SKUs_GetScannedSKUs(@vScannedSKU, @vBusinessUnit);

  if (@vScannedEntityType = 'RMA')
    select @vRDExists     = 'Y',
           @vQtyToReceive = QtyToReceive
    from ReceiptDetails
    where (ReceiptId = @vScannedEntityId) and (SKUId = @vSKUId);

  if (@vScannedEntityType = 'RMA')
    select @vReceiptNumber = ReceiptNumber
    from ReceiptHeaders
    where (ReceiptId = @vScannedEntityId);

  /* Validations */
  if (@vSKUId is null)
    set @vMessageName = 'SKUDoesNotExist';
  else
  if (coalesce(@vRDExists, '') <> 'Y')
    select @vMessageName = 'Returns_ScannedSKUIsNotAssociatedWithReceipt',
           @vValue1      = @vSKU,
           @vValue2      = @vReceiptNumber;
  else
  if (@vScannedQuantity > coalesce(@vQtyToReceive, 0))
    select @vMessageName = 'Returns_ExcessQtyNotAllowed',
           @vValue1      = @vQtyToReceive;

  if (@vMessageName is not null)
    begin
      /* Update the devices */
      update Devices
      set DataXML = @DataXML
      where (DeviceId = @vDeviceName);

      exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vValue1, @vValue2;
    end

  /* Build DataXML */
  select @DataXML = dbo.fn_XMLAddNode(@DataXML, 'Data', dbo.fn_XMLNode('ValidatedSKU', @vSKU));
end /* pr_AMF_Returns_ValidateSKU */

Go

