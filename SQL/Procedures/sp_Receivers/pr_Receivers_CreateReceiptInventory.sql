/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/15  TK      pr_Receivers_CreateReceiptInventory: Changes to update InventoryClasses (FBV3-810)
  2021/12/02  SV      pr_Receivers_CreateReceiptInventory, pr_Receivers_CreateReceiptInventory_Validate: Intial version to validate the I/P data
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_CreateReceiptInventory') is not null
  drop Procedure pr_Receivers_CreateReceiptInventory;
Go
/*---------------------------------------------------------------------------------------------
  Proc pr_Receivers_CreateReceiptInventory: This is the main proc called from Create Receipt
    Inventory menu item from V3 Receiving Menu. This is used to create the LPNs against the
    selected Receipt. Receiver may also be selected by user or a new receiver created based
    upon control var.
 -----------------------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_CreateReceiptInventory
  (@InputXML     TXML,
   @XmlResult    TXML output)
as
  declare @vReturnCode            TInteger,
          @xmlData                xml,
          @vReceiverId            TRecordId,
          @vReceiverNumber        TReceiverNumber,
          @vReceiptId             TRecordId,
          @vReceiptType           TReceiptType,
          @vReceiptDetailId       TRecordId,
          @vSKUId                 TRecordId,
          @vCustPO                TCustPO,
          @vInventoryClass1       TInventoryClass,
          @vInventoryClass2       TInventoryClass,
          @vInventoryClass3       TInventoryClass,
          @vLot                   TLot,
          @vControlCategory       TCategory,
          @vIsReceiverRequired    TControlValue,
          @vMessageName           TMessageName,
          @vBusinessUnit          TBusinessUnit,
          @vUserId                TUserId,
          @ttResultMessages       TResultMessagesTable;

begin
  SET NOCOUNT ON;

  select @vReturnCode = 0;

  /* Extracting data elements from XML. */
  set @xmlData = convert(xml, @InputXML);

  /* Create hash table if one does not exist */
  if (object_id('tempdb..#ResultMessages') is null) select * into #ResultMessages from @ttResultMessages;

  /* Validate Input data */
  exec pr_Receivers_CreateReceiptInventory_Validate @xmlData;

  /* Go to Exit handler to throw the error message rather than creating the Receiver and throw the error message */
  if (exists (select * from #ResultMessages where MessageType = 'E'))
    goto Exithandler;

  select @vReceiverId      = Record.Col.value('ReceiverId[1]',      'TRecordId'),
         @vReceiptId       = Record.Col.value('ReceiptId[1]',       'TRecordId'),
         @vReceiptDetailId = Record.Col.value('ReceiptDetailId[1]', 'TRecordId'),
         @vSKUId           = Record.Col.value('SKUId[1]',           'TRecordId')
  from @xmlData.nodes('/Root/Data') as Record(Col);

  select @vUserId       = Record.Col.value('UserId[1]',       'TUserId'),
         @vBusinessUnit = Record.Col.value('BusinessUnit[1]', 'TBusinessUnit')
  from @xmlData.nodes('/Root/SessionInfo') as Record(Col);

  /* Get ROH info */
  select @vReceiptType = ROH.ReceiptType
  from ReceiptHeaders ROH
  where (ROH.ReceiptId = @vReceiptId);

  /* Get ROD info */
  select @vCustPO          = ROD.CustPO,
         @vInventoryClass1 = InventoryClass1,
         @vInventoryClass2 = InventoryClass2,
         @vInventoryClass3 = InventoryClass3,
         @vLot             = Lot
  from ReceiptDetails ROD
  where (ROD.ReceiptDetailId = @vReceiptDetailId);

  /* Determine if receiver is to be created */
  select @vControlCategory = 'Receiving_' + @vReceiptType;
  select @vIsReceiverRequired = dbo.fn_Controls_GetAsString(@vControlCategory, 'IsReceiverRequired', 'AUTO', @vBusinessUnit, @vUserId);

  /* If user has not given Receiver, find out the Receiver# already assigned for the Receipt.
     If it does not exist, then AUTO create a new Receiver# */
  if (@vReceiverId is null) and (@vIsReceiverRequired = 'AUTO')
    exec pr_Receivers_AutoCreateReceiver @vReceiptId, @vCustPO, null /* LocationId */, @vBusinessUnit, @vUserId,
                                         @vReceiverId output, @vReceiverNumber output;

  if (@vIsReceiverRequired <> 'AUTO') and (@vReceiverId is null)
    select @vMessageName = 'CreateReceiptInventory_ReceiverIsRequired';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Plug in ReceiverId into @InputXML */
  select @InputXML = dbo.fn_XMLAddNameValue(@InputXML, 'Data', 'ReceiverId',      @vReceiverId);
  select @InputXML = dbo.fn_XMLAddNameValue(@InputXML, 'Data', 'InventoryClass1', @vInventoryClass1);
  select @InputXML = dbo.fn_XMLAddNameValue(@InputXML, 'Data', 'InventoryClass2', @vInventoryClass2);
  select @InputXML = dbo.fn_XMLAddNameValue(@InputXML, 'Data', 'InventoryClass3', @vInventoryClass3);
  select @InputXML = dbo.fn_XMLAddNameValue(@InputXML, 'Data', 'Lot',             @vLot);

  /* Call pr_LPNs_CreateLPNs to create LPNs for the selected Receipt and selected/created Receiver */
  exec pr_LPNs_CreateLPNs @InputXML, @XmlResult out;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receivers_CreateReceiptInventory */

Go
