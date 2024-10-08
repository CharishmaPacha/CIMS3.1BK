/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/14  AY      pr_AMF_Shipping_CancelShipCartons_Confirm: Code optimization (HA-2734)
  2021/04/27  TK      pr_AMF_Shipping_CancelShipCartons_Confirm: Add BulkPickTicket to temp table (HA-GoLive)
  2021/02/26  RIA     Added pr_AMF_Shipping_CancelShipCartons_Confirm, pr_AMF_Shipping_CancelShipCartons_Validate (HA-2087)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Shipping_CancelShipCartons_Confirm') is not null
  drop Procedure pr_AMF_Shipping_CancelShipCartons_Confirm;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Shipping_CancelShipCartons_Confirm: We will fetch all the necessary
    LPN information and call the cancel proc

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Shipping_CancelShipCartons_Confirm
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vMessage                  TMessage,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vScannedLPN               TLPN,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNType                  TTypeCode,
          @vStatus                   TStatus,
          @vValidLPNStatuses         TControlValue,
          @vOrderId                  TRecordId,
          @vWaveId                   TRecordId,
          @vWaveNo                   TWaveNo,
          @vWaveType                 TTypeCode,
          @vBulkOrderId              TRecordId,

          @vLoggedInWarehouse        TWarehouse,
          @vLPNDestWarehouse         TWarehouse,

          @ttLPNDetails              TLPNDetails;
begin /* pr_AMF_Shipping_CancelShipCartons_Confirm */

  select * into #LPNDetails from @ttLPNDetails;
  alter table #LPNDetails add KeyValue as cast(SKUId as varchar) + '-' + Warehouse + '-' + Ownership + '-' +
                                          InventoryClass1 + '-' + InventoryClass2 + '-' + InventoryClass3;
  alter table #LPNDetails add BulkOrderId int, BulkPickTicket varchar(30);

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId     = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vScannedLPN   = Record.Col.value('(Data/LPN)[1]',                        'TLPN'         ),
         @vOperation    = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get the LPN info */
  select @vLPNId            = LPNId,
         @vLPN              = LPN,
         @vLPNType          = LPNType,
         @vStatus           = Status,
         @vOrderId          = OrderId,
         @vLPNDestWarehouse = DestWarehouse,
         @vWaveId           = PickBatchId,
         @vWaveNo           = PickBatchNo
  from LPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN (@vScannedLPN, @vBusinessUnit, 'LTU'));

  /* Get Wave Info */
  select @vWaveId   = WaveId,
         @vWaveType = WaveType
  from Waves
  where (WaveNo = @vWaveNo) and (BusinessUnit = @vBusinessUnit);

  /* Find the bulk order associated with the wave */
  select @vBulkOrderId = OrderId
  from OrderHeaders
  where (PickBatchId = @vWaveId) and (OrderType = 'B' /* Bulk Order */);

  /* Fetch all the LPN related information */
  insert into #LPNDetails (LPNId, LPNType, LPNStatus, LPNDetailId, LPNLines, SKUId,
                           InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                           ReceiptId, ReceiptDetailId, OrderId, OrderDetailId,
                           Ownership, Warehouse, Lot, CoO, BusinessUnit,
                           PalletId, WaveId, WaveNo, LoadId, ShipmentId,
                           InventoryClass1, InventoryClass2, InventoryClass3, SortOrder)
    select L.LPNId, L.LPNType, L.Status, LD.LPNDetailId, L.NumLines, LD.SKUId,
           LD.InnerPacks, LD.UnitsPerPackage, LD.Quantity, LD.ReservedQty,
           LD.ReceiptId, LD.ReceiptDetailId, LD.OrderId, LD.OrderDetailId,
           L.Ownership, L.DestWarehouse, LD.Lot, LD.CoO, L.BusinessUnit,
           L.PalletId, L.PickBatchId, L.PickBatchNo, L.LoadId, L.ShipmentId,
           L.InventoryClass1, L.InventoryClass2, L.InventoryClass3, null /* sort order */
    from LPNs L join LPNDetails LD on L.LPNId = LD.LPNId
    where (L.LPNId = @vLPNId);

  /* Get user logged in Warehouse */
  select @vLoggedInWarehouse = dbo.fn_Users_LoggedInWarehouse(@vDeviceId, @vUserId, @vBusinessUnit);

  /* Populate XML input for activating LPNs procedure: Driven by ToLPNs */
  select @vrfcProcInputxml = dbo.fn_XMLNode('CancelActivatedLPNs',
                               dbo.fn_XMLNode('BusinessUnit',  @vBusinessUnit) +
                               dbo.fn_XMLNode('UserId',        @vUserId) +
                               dbo.fn_XMLNode('DeviceId',      @vDeviceId) +
                               dbo.fn_XMLNode('LPN',           @vLPN) +
                               dbo.fn_XMLNode('LPNType',       @vLPNType) +
                               dbo.fn_XMLNode('Warehouse',     @vLoggedInWarehouse));

  select @vxmlRFCProcInput = convert(xml, @vrfcProcInputxml);

  /* Cancel pre-generated Ship Carton LPN */
  exec pr_Reservation_CancelActivatedLPNs @vxmlRFCProcInput, @vxmlrfcProcOutput output;

  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is error raised simply return */
  if (@vTransactionFailed > 0) return;

  /* Build the success message */
  select @vMessage  = coalesce(@vMessage, dbo.fn_Messages_Build('AMF_ShipLabelCancel_Successful', @vScannedLPN, null, null, null, null));
  select @InfoXML   = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  select @DataXML = (select 'Done' as Resolution
                     for Xml Raw(''), elements, Root('Data'));

end /* pr_AMF_Shipping_CancelShipCartons_Confirm */

Go

