/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/22  TK      pr_AMF_Picking_LPNReservation_ValidateLPN: Changes to reserve a partially allocate LPN (HA-1821)
  pr_AMF_Picking_LPNReservation_ValidateLPN: Changes to retrieve filter value (HA-1263)
  2020/06/29  RIA     pr_AMF_Picking_LPNReservation_ValidateLPN: Changes to use table instead of view (HA-789)
  pr_AMF_Picking_LPNReservation_Validate, pr_AMF_Picking_LPNReservation_ValidateLPN: Code Refactoring (HA-789)
  2020/06/21  TK      pr_AMF_Picking_LPNReservation_Validate, pr_AMF_Picking_LPNReservation_ValidateLPN &
  pr_AMF_Picking_LPNReservation_ValidateLPN: Validate Pallet and return it to screen (HA-789)
  2020/05/27  RIA     Changes to pr_AMF_Picking_LPNReservation_Confirm, pr_AMF_Picking_LPNReservation_ValidateLPN (HA-521)
  2020/05/25  RIA     Added: pr_AMF_Picking_LPNReservation_ValidateLPN (HA-521)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_LPNReservation_ValidateLPN') is not null
  drop Procedure pr_AMF_Picking_LPNReservation_ValidateLPN;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_LPNReservation_ValidateLPN: Validates the LPN scanned
    and returns the details of LPN if valid
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_LPNReservation_ValidateLPN
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
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit              TBusinessUnit,
          @vUserId                    TUserId,
          @vDeviceId                  TDeviceId,
          @vEntityToReserve           TEntity,
          @vWaveId                    TRecordId,
          @vWaveNo                    TWaveNo,
          @vOrderId                   TRecordId,
          @vPickTicket                TPickTicket,
          @vScannedLPN                TLPN,
          @vPallet                    TPallet,
          @vFilterValue               TEntity,
          @vOperation                 TOperation,
          @vAllocateOption            TFlags;
          /* Functional variables */
  declare @vxmlSKUDetails             xml,
          @vxmlInput1                 xml,
          @vSKUInfoXML                TXML,
          @vPrevDataXML               TXML,
          @vLPNId                     TRecordId,
          @vLPN                       TLPN,
          @vSKUId                     TRecordId,
          @vSKU                       TSKU,
          @vAllocableQty              TQuantity,
          @vTotalQty                  TQuantity,
          @vReservationFor            TTypeCode;

  declare @ttLPNDetails               TLPNDetails,
          @ttOrderDetails             TOrderDetails;

begin /* pr_AMF_Picking_LPNReservation_ValidateLPN */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Fetch the input values */
  select @vBusinessUnit    = Record.Col.value('(SessionInfo/BusinessUnit)[1]',                    'TBusinessUnit'   ),
         @vUserId          = Record.Col.value('(SessionInfo/UserName)[1]',                        'TUserId'         ),
         @vDeviceId        = Record.Col.value('(SessionInfo/DeviceId)[1]',                        'TDeviceId'       ),
         @vEntityToReserve = Record.Col.value('(Data/m_LPNReservationInfo_EntityToReserve)[1]',   'TEntity'         ),
         @vWaveId          = Record.Col.value('(Data/m_WaveInfo_WaveId)[1]',                      'TRecordId'       ),
         @vWaveNo          = nullif(Record.Col.value('(Data/m_WaveInfo_WaveNo)[1]',               'TWaveNo'),     ''),
         @vOrderId         = Record.Col.value('(Data/m_OrderInfo_OrderId)[1]',                    'TRecordId'       ),
         @vPickTicket      = nullif(Record.Col.value('(Data/m_OrderInfo_PickTicket)[1]',          'TPickTicket'), ''),
         @vPallet          = nullif(Record.Col.value('(Data/Pallet)[1]',                          'TPallet'),     ''),
         @vFilterValue     = Record.Col.value('(Data/FilterValue)[1]',                            'TEntity'         ),
         @vScannedLPN      = Record.Col.value('(Data/LPN)[1]',                                    'TLPN'            ),
         @vOperation       = Record.Col.value('(Data/Operation)[1]',                              'TOperation'      ),
         @vAllocateOption  = Record.Col.value('(Data/AllocateOption)[1]',                         'TFlags'          )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @vxmlInput = null ) );

  /* If pallet is scanned or entered then validate the pallet */
  if (@vPallet is not null)
    begin
      exec pr_RFC_Inv_ValidatePallet @vPallet, @vOperation, @vBusinessUnit, @vUserId,
                                     @vDeviceId, @vxmlRFCProcOutput output;

      exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                     @ErrorXML output;
    end

  /* If not a valid pallet exit */
  if ((@vPallet is not null) and (@vTransactionFailed > 0)) return;

  /* Fetch the LPN Information */
  select @vLPNId        = LPNId,
         @vLPN          = LPN,
         @vSKUId        = SKUId,
         @vSKU          = SKU,
         @vAllocableQty = AllocableQty,
         @vTotalQty     = Quantity
  from vwLPNs
  where (LPNId = dbo.fn_LPNs_GetScannedLPN(@vScannedLPN, @vBusinessUnit, default));

  /* create the return table from vwOrderToPackDetails structure */
  if object_id('tempdb..#LPNDetails') is null
    select * into #LPNDetails from @ttLPNDetails;

  if object_id('tempdb..#OrderDetails') is null
    select * into #OrderDetails from @ttOrderDetails;

  /* Additional fields needed for pre-validation */
  alter table   #LPNDetails add InventoryKey as cast(SKUId as varchar) + '-' +
                                                coalesce(Warehouse, '') + '-' +
                                                coalesce(Ownership, '') + '-' +
                                                coalesce(BusinessUnit, '') + '-' +
                                                rtrim(coalesce(InventoryClass1, '')) + '-' +
                                                rtrim(coalesce(InventoryClass2, '')) + '-' +
                                                rtrim(coalesce(InventoryClass3, ''));

  alter table   #OrderDetails add BusinessUnit varchar(10);
  alter table   #OrderDetails add InventoryKey as cast(SKUId as varchar) + '-' +
                                                  coalesce(Warehouse, '') + '-' +
                                                  coalesce(Ownership, '') + '-' +
                                                  coalesce(BusinessUnit, '') + '-' +
                                                  rtrim(coalesce(InventoryClass1, '')) + '-' +
                                                  rtrim(coalesce(InventoryClass2, '')) + '-' +
                                                  rtrim(coalesce(InventoryClass3, ''));

  /* Get From LPN Details */
  /* There are instances when user will try to allocate an LPN that is partially reserved, so in this scenario LPN will have
     both available and reserved lines so when reserving the LPN try to process the available lines only */
  if (@vAllocateOption = 'A' /* Allocate */)
    insert into #LPNDetails (LPNId, LPNDetailId, SKUId, InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                             ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Lot, CoO,
                             Warehouse, Ownership, BusinessUnit, InventoryClass1, InventoryClass2, InventoryClass3)
      select LD.LPNId, LD.LPNDetailId, LD.SKUId, LD.InnerPacks, LD.UnitsPerPackage, LD.Quantity, 0 /* ReservedQty */,
             LD.ReceiptId, LD.ReceiptDetailId, LD.OrderId, LD.OrderDetailId, LD.Lot, LD.CoO,
             L.DestWarehouse, L.Ownership, L.BusinessUnit, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3
      from LPNDetails LD
        join LPNs L on (LD.LPNId = L.LPNId) and (LD.OrderId is null)
      where LD.LPNId = @vLPNId;
  else
    insert into #LPNDetails (LPNId, LPNDetailId, SKUId, InnerPacks, UnitsPerPackage, Quantity, ReservedQty,
                             ReceiptId, ReceiptDetailId, OrderId, OrderDetailId, Lot, CoO,
                             Warehouse, Ownership, BusinessUnit, InventoryClass1, InventoryClass2, InventoryClass3)
      select LD.LPNId, LD.LPNDetailId, LD.SKUId, LD.InnerPacks, LD.UnitsPerPackage, LD.Quantity, 0 /* ReservedQty */,
             LD.ReceiptId, LD.ReceiptDetailId, LD.OrderId, LD.OrderDetailId, LD.Lot, LD.CoO,
             L.DestWarehouse, L.Ownership, L.BusinessUnit, L.InventoryClass1, L.InventoryClass2, L.InventoryClass3
      from LPNDetails LD
        join LPNs L on (LD.LPNId = L.LPNId)
      where LD.LPNId = @vLPNId;

  /* Get all the order details to be reserved for the given wave or pick ticket
     executing following procedure will insert required order details into #OrderDetails & #SKUQuantities table */
  exec pr_Reservation_GetOrderDetailsToReserve @vEntityToReserve, @vWaveId, @vOrderId;

  /* Build V2 Input Xml */
  select @vxmlRFCProcInput = (select Record.Col.value('(SessionInfo/BusinessUnit)[1]',   'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(SessionInfo/UserName)[1]',       'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/DeviceId)[1]',       'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(Data/WaveNo)[1]',                'TWaveNo'      ) as PickBatchNo,
                                     Record.Col.value('(Data/PickTicket)[1]',            'TPickTicket'  ) as PickTicket,
                                     Record.Col.value('(Data/Operation)[1]',             'TOperation'   ) as Operation,
                                     Record.Col.value('(Data/LPN)[1]',                   'TLPN'         ) as LPN,
                                     Record.Col.value('(Data/AllocateOption)[1]',        'TFlag'        ) as 'Option', -- SelectedOption would be better
                                     @vReservationFor as OperationVia
                              from @vxmlInput.nodes('/Root') as Record(Col)
                              for xml raw('ConfirmLPNReservations'), elements);

  /* Validate Wave or PickTicket or both when given */
  exec pr_Reservation_ValidateLPN @vxmlRFCProcInput;

  select @vxmlInput1 = (select @vEntityToReserve  as EntityToReserve,
                               @vWaveId           as WaveId,
                               @vWaveNo           as WaveNo,
                               @vOrderId          as OrderId,
                               @vPickTicket       as PickTicket
                        for XML RAW('LPNReservationInfo'), ELEMENTS);

  /* Build response in the required format to show in the screen */
  exec pr_AMF_Info_GetLPNReservationInfoXML @vxmlInput1, @vSKUId /* SKUId */, @DataXML output;

  select @DataXml = dbo.fn_XmlAddNode(@DataXML, 'Data', dbo.fn_XMLNode('LPNReservationInfo_LPNId', @vLPNId) +
                                                        dbo.fn_XMLNode('LPNReservationInfo_LPN', @vLPN) +
                                                        dbo.fn_XMLNode('LPNReservationInfo_AllocableQty', @vAllocableQty) +
                                                        dbo.fn_XMLNode('LPNReservationInfo_Pallet', @vPallet) +
                                                        dbo.fn_XMLNode('LPNReservationInfo_FilterValue', @vFilterValue));

end /* pr_AMF_Picking_LPNReservation_ValidateLPN */

Go

