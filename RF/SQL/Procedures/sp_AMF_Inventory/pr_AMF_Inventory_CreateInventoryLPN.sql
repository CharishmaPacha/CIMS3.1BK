/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/06  RIA     Added pr_AMF_Inventory_CreateInventoryLPN
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_CreateInventoryLPN') is not null
  drop Procedure pr_AMF_Inventory_CreateInventoryLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_CreateInventoryLPN: In this procedure we will be doing
    some basic validations followed by creating an LPN if not passed by user and
    updating inventory on that LPN. We can further enhance the procedure to Palletize
    the LPNs created.

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_CreateInventoryLPN
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TDescription,
          @vMessage                  TMessage,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vDeviceId                 TDeviceId,
          @vUserId                   TUserId,
          @LPN                       TLPN,
          @vSKU                      TSKU,
          @vInnerPacks               TInnerPacks,
          @vUnitsPerIP               TQuantity,
          @vUnits                    TQuantity,
          @vUnits1                   TQuantity,
          @vInventoryClass1          TInventoryClass,
          @vInventoryClass2          TInventoryClass,
          @vInventoryClass3          TInventoryClass,
          @vReasonCode               TReasonCode,
          @vOwnership                TOwnership,
          @vWarehouse                TWarehouse,
          @vReference                TReference,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML,
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNStatus                TStatus,
          @vLPNType                  TTypeCode,
          @vLPNQty                   TQuantity,
          @vLPNDetailId              TRecordId,
          @vSKUId                    TRecordId,
          @vQuantity                 TQuantity,
          @vCreatedDate              TDateTime,
          @vFormAction               TAction;
begin /* pr_AMF_Inventory_CreateInventoryLPN */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read the values from input */
  select @vBusinessUnit    = Record.Col.value('(SessionInfo/BusinessUnit)[1]',     'TBusinessUnit'  ),
         @vDeviceId        = Record.Col.value('(SessionInfo/DeviceId)[1]',         'TDeviceId'      ),
         @vUserId          = Record.Col.value('(SessionInfo/UserName)[1]',         'TUserId'        ),
         @vSKUId           = Record.Col.value('(Data/m_SKUInfo_SKUId)[1]',         'TRecordId'      ),
         @vSKU             = Record.Col.value('(Data/m_SKUInfo_SKU)[1]',           'TSKU'           ),
         @LPN              = nullif(Record.Col.value('(Data/LPN)[1]',              'TLPN'     ), '' ),
         @vUnits           = nullif(Record.Col.value('(Data/NewUnits)[1]',         'TQuantity'), '' ),
         @vUnits1          = nullif(Record.Col.value('(Data/NewUnits1)[1]',        'TQuantity'), '' ),
         @vInventoryClass1 = Record.Col.value('(Data/InventoryClass1)[1]',         'TInventoryClass'),
         @vReasonCode      = Record.Col.value('(Data/ReasonCode)[1]',              'TReasonCode'    ),
         @vOwnership       = Record.Col.value('(Data/Owner)[1]',                   'TOwnership'     ),
         @vWarehouse       = Record.Col.value('(Data/Warehouse)[1]',               'TWarehouse'     ),
         @vReference       = Record.Col.value('(Data/Reference)[1]',               'TReference'     ),
         @vOperation       = Record.Col.value('(Data/Operation)[1]',               'TOperation'     )
  from @vxmlInput.nodes('/Root') as Record(Col);

  /* select the quantity */
  select @vQuantity = coalesce(@vUnits, @vUnits1);

  /* Get LPN related info */
  if (@LPN is not null)
    select @vLPNId     = LPNId,
           @vLPN       = LPN,
           @vLPNStatus = Status,
           @vLPNType   = LPNType,
           @vLPNQty    = Quantity
    from LPNs
    where (LPNId = dbo.fn_LPNs_GetScannedLPN (@LPN, @vBusinessUnit, 'LTU'));

  /* Validations */
  if (@vSKUId is null)
    set @vMessageName = 'SKUIsRequired';
  else
  if (@vQuantity < 1)
    set @vMessageName = 'InvalidQuantity';
  else
  if (@LPN is not null) and (@vLPNStatus not in ('N' /* New */))
    set @vMessageName = 'InvalidLPNStatus';
  else
  if (@LPN is not null) and (@vLPNType not in ('C' /* Carton */))
    set @vMessageName = 'InvalidLPNType';
  else
  if (@vLPNQty > 0)
    set @vMessageName = 'AMF_ScanLPNWithoutQty'

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec pr_Messages_ErrorHandler @vMessageName;

  /* Create an LPN if not scanned by user */
  if (@vLPN is null)
    exec pr_LPNs_Generate 'C' /* Carton */, 1 /* NumLPNsToCreate */, null /* LPNFormat - Use default format based upon LPNType */,
                          @vWarehouse, @vBusinessUnit, @vUserId, @vLPNId output, @vLPN output;


  update LPNs
  set @vLPN            = LPN,
      Ownership       = @vOwnership,
      DestWarehouse   = @vWarehouse,
      ReasonCode      = @vReasonCode,
      InventoryClass1 = coalesce(@vInventoryClass1, ''),
      InventoryClass2 = coalesce(@vInventoryClass2, ''),
      InventoryClass3 = coalesce(@vInventoryClass3, ''),
      Reference       = @vReference,
      CreatedDate     = @vCreatedDate,
      ModifiedDate    = current_timestamp,
      ModifiedBy      = @vUserId
  where (LPNId = @vLPNId);

  /* Create LPNDetail for the above created LPN */
  exec pr_LPNDetails_AddOrUpdate @vLPNId             /* LPNId */,
                                 null                /* LPNLine */,
                                 null                /* CoO */,
                                 @vSKUId             /* SKUId */,
                                 null                /* SKU */,
                                 @vInnerPacks        /* InnerPacks */,
                                 @vQuantity          /* Quantity */,
                                 0                   /* ReceivedUnits */,
                                 null                /* ReceiptId */,
                                 null                /* ReceiptDetailsId */,
                                 null                /* OrderId */,
                                 null                /* OrderDetailId */,
                                 null                /* OnhandStatus */,
                                 null                /* Operation */,
                                 null                /* Weight */,
                                 null                /* Volume */,
                                 null                /* Lot */,
                                 @vBusinessUnit      /* BusinessUnit */,
                                 @vLPNDetailId  output;

  /* Pre-process the newly created LPN to establish Putaway and Picking Class */
  exec pr_LPNs_PreProcess @vLPNId, null, @vBusinessUnit;

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'CreateInvLPN', @vUserId, null /* ActivityTimestamp */,
                            @LPNId      = @vLPNId,
                            @Quantity   = @vQuantity,
                            @ReasonCode = @vReasonCode;

  /* Build success message */
  select @vMessage = dbo.fn_Messages_Build('AMF_CreateInvLPN_Successful', @vLPN, @vSKU, @vQuantity, null, null);
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  /* Build the DataXML */
  select @DataXML = (select 'Done' Resolution
                     for Xml Raw(''), elements, Root('Data'));

end /* pr_AMF_Inventory_CreateInventoryLPN */

Go

