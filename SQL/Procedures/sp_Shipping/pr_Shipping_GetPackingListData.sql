/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/22  RV      pr_Shipping_GetPackingListData_New: Made changes to return logo node even logo is not exists (BK-610)
  2021/08/11  RV      pr_Shipping_GetPackingListData_New: Made changes control value get from Packing list category (BK-484)
  2021/07/28  RV      pr_Shipping_GetPackingListData_New: Made changes to show the component lines based upon the rules and control (OB2-1960)
  2020/07/10  MS      pr_Shipping_GetPackingListData_New, pr_Shipping_PLGetShipLabelsXML: Changes to generate labels based on EntityType (S2GCA-1178)
  2020/06/13  MS      pr_Shipping_GetPackingListData_New, pr_Shipping_GetPackingListDetails,
                      pr_Shipping_GetPackingListDetails_ComputePages: Changes to print Append file (HA-857)
  2020/06/02  MS      pr_Shipping_GetPackingListData_New: Setup Default Options to generate info (HA-597)
  2020/05/23  MS      pr_Shipping_GetPackingListData; Param mismatch fixes
  2019/08/09  MS      pr_Shipping_GetPackingListDetails: Changes to not to print UnitsOrdered & BackOrdQty on LPNWithORD PL Types
                      pr_Shipping_GetPackingListData: Changes to callers (HPI-2691)
  2018/05/07  RV      pr_Shipping_GetPackingListData: Made changes to send flag whether already label generated or not (S2G-827)
  2018/05/01  RV/RT   pr_Shipping_GetPackingListData: Refactor the code to get the ship label xml and comments xml by
                        adding procedures pr_Shipping_PLGetCommentsXML and pr_Shipping_PLGetShipLabelsXML (HPI-1498)
  2018/05/01  RV/RT   pr_Shipping_GetPackingListData, pr_Shipping_GetPackingListDetails: Made changes to print
                        fixed records on first page and remaining records on second page if required (HPI-1498)
  2017/07/12  CK      pr_Shipping_GetPackingListData: Added validation to not print voided ship labels (HPI-1582)
  2016/07/26  RV      pr_Shipping_GetPackingListData: Added AdditionalPLInfo1 to the order packing list data set (HPI-363)
  2016/07/08  RV      pr_Shipping_GetPackingListData: Line details count get with respect to the LPN for LPN packing list (HPI-246)
  2016/06/17  RV      pr_Shipping_GetPackingListData: Added new parameter to pass the Options to print the packing
                        list with respect to those options (HPI-167)
  2016/05/12  RV      pr_Shipping_GetPackingListData, fn_Shipping_GetPackingListDummyRecordsCount: Generalize the logic
                        to get the number dummy rows to print on the report with respect to the Report Name (CIMS-888)
  2016/05/09  RV      pr_Shipping_GetPackingListData: Get the Packing list type from pr_Shipping_GetPackingListsToPrint and
                        use for printing the packing list (NBD-493)
  2016/04/11  RV      pr_Shipping_GetPackingListData: if TotalShippingCost is null then return zero (NBD-371)
  2016/03/24  RV      pr_Shipping_GetPackingListData: Get the Dummy Records counts for Gift Packing list (NBD-121)
  2016/02/23  RV      pr_Shipping_GetPackingListData: Add the PackingList format Ownership category to controls and get that control varialble to add the dummy records (NBD-94)
  2016/02/12  RV      pr_Shipping_GetPackingListData: Get the PackingList format category from control varialble to add the dummy records (FB-624)
  2016/01/06  DK      pr_Shipping_GetPackingListData: Included RETURNSHIPLABEL node which is used for printing return labels (FB-590).
  2016/01/06  KN      pr_Shipping_GetPackingListData:added return label xml node (FB-509)
  2015/12/04  TK      pr_Shipping_GetPackingListData: Print details in the order of HostOrderLine (ACME-423)
  2015/10/14  RV      pr_Shipping_GetPackingListData: Return the Dummy details with dummy rows to print ship label at the bottom of the page (FB-437)
  2015/09/01  RV      pr_Shipping_GetPackingListData: Include return Ship Label for order packing list (FB-392)
  2015/09/30  AY      pr_Shipping_GetPackingListData: Bug fix related to computations of Order Tax and Subtotals.
  2015/09/15  TK      pr_Shipping_GetPackingListData: Changes made to display Dept and PO on the Packing List(ACME-323)
  2015/03/11  DK      pr_Shipping_GetPackingListData, pr_Shipping_GetPackingListsToPrint : :Made changes to print ReturnPackingSlip.
  2015/01/16  PKS     pr_Shipping_GetPackingListData: Total Weight added to OrderPackingList and PackingListType added for both LPN and Order packing lists.
  2014/12/29  PKS     pr_Shipping_GetPackingListData used vwPackingListDetails as data source for PackingListDetailXML
  2014/06/10  SV      pr_Shipping_GetPackingListData: Implemented rules in it.
  2014/02/12  NY      pr_Shipping_GetPackingListData: Showing packinglist details by grouping with SKU
  2012/10/08  PKS     pr_Shipping_GetPackingListData: Minor fixes done related to Comments field.
  2012/08/16  PKS     pr_Shipping_GetPackingListData: function 'fn_Shipping_GetPackingListMatrix' is used
                      instead of vwPackingListDetails.
  2012/08/06  AY      pr_Shipping_GetPackingListData: Fixes to support multiple modes.
  2012/07/23  AA      pr_Shipping_GetPackingListData: Moved call to CanPrintPackingList function
                        from Entries table to PackingListsToPrint table
  2012/07/10  AY      pr_Shipping_GetPackingListData: Do not print packing lists
                        for Bulk/Replenish Orders when printing for a batch or LPN.
  2011/11/10  AY      pr_Shipping_GetPackingListData: Changed computation of order subtotal
                        as they now give total discount on the line and not per unit.
                        UnitTaxAmount is actually the line tax amount!
  2011/11/06  AY      pr_Shipping_GetPackingListData: Return PackageTaxAmount and PackageTotal
  2011/10/21  NB      pr_Shipping_GetPackingListData - Fix to read ShipVia from OrderHeaders
                      pr_Shipping_SaveLPNData: Minor fix - call to pr_LPNs_Ship corrected
------------------------------------------------------------------------------*/

--Go

--if object_id('dbo.pr_Shipping_GetPackingListData') is not null
  --   drop Procedure pr_Shipping_GetPackingListData;
-- Go
-- /*------------------------------------------------------------------------------
--   Proc pr_Shipping_GetPackingListData: Returns all the info associated with the
--     LPN and it's order to print a shipping label integrated with the packing list.
--
--   Sample xml:
--
--   <Rules>
--     <CarriersIntegration>Y</CarriersIntegration>
--     <PackingListType>LPN</PackingListType>
--     <LPN>C001</LPN>
--   </Rules>
-- ------------------------------------------------------------------------------*/
-- Create Procedure pr_Shipping_GetPackingListData
--   (@LPNsXML         XML = null /* Carton */,
--    @PickTicketsXML  XML = null,
--    @BatchNosXML     XML = null,
--    @ShipmentId      TShipmentId  = null,
--    @LoadId          TLoadId      = null,
--    @PackingListType TTypeCode,
--    @Options         XML          = null,
--    @BusinessUnit    TBusinessUnit,
--    @UserId          TUserId,
--    @PLResultXML     TXML         = null output)
-- as
--   declare @ReturnCode         TInteger,
--           @MessageName        TMessageName,
--           @Message            TDescription,
--           @vRecordId          TInteger,
--
--           @PLHeaderxml        TXML,
--           @PLDetailsxml1      TXML,
--           @PLDetailsxml2      TXML,
--
--           @ShipLabelxml       TXML,
--           @ReturnShipLabelxml TXML,
--           @CommInvoicexml     TXML,
--           @DummyDetailsxml    TXML,
--           @xmlData            TXML,
--           @Report             TName,
--           @vRemainingPageNumRows
--                               TInteger,
--           @vTotalPages        TInteger,
--           @Reportsxml1        TXML,
--           @Reportsxml2        TXML,
--           @OptionsXML         TXML,
--           @Resultxml          TXML,
--           @Commentsxml        TXML,
--           @TrackingNo         TTrackingNo,
--           @vOrderId           TRecordId,
--           @vPickTicket        TPickTicket,
--           @vWaveType          TTypeCode,
--           @vLPNId             TRecordId,
--           @vLPN               TLPN,
--
--           @vSource            TName,
--
--           @vComments          TVarchar,
--           @vOwnership         TTypecode,
--           @vWarehouse         TWarehouse,
--
--
--           @OrderTaxAmount       TMoney,
--           @OrderSubTotal        TMoney,
--           @vOrderTotal          TMoney,
--           @vTotalWeight         TWeight,
--           @vUnitsPerCarton      TInteger,
--           @vUCCount             TCount,
--           @vDummyRecordsCount   TCount,
--           @CanPrintPackingList  TFlag,
--           @vAccount             TAccount,
--           @vAdditionalPLInfo1   varchar(max),
--           @vNumPackedDetails    TInteger,
--           @vCarriersIntegration TFlag,
--           @vShipVia             TShipVia,
--           @vCarrier             TCarrier,
--           @vCarrierInterface    TDescription,
--
--           @vLoadId              TRecordId;
--
--   declare @PackingListsToPrint  table
--           (RecordId        TRecordId identity(1,1),
--            OrderId         TRecordId,
--            LPNId           TRecordId,
--            LPN             TLPN,
--            LoadId          TLoadId,
--            PackingListType TTypeCode,
--            PrintPL         TBoolean default 1);
--
--   declare @LPN         TLPN         = null /* Carton */,
--           @PickTicket  TPickTicket  = null,
--           @BatchNo     TPickBatchNo = null,
--           @vEntity     varchar(max);
--
-- begin /* pr_Shipping_GetPackingListData */
--   select @ReturnCode   = 0,
--          @Messagename  = null,
--          @vComments    = '',
--          @vRecordId    = 0;
--
--   /* Return if Packing List have to be printed for the LPN */
--   /*Call  fn_Packing_CanPrintPackingList(@LPN);
--   If True then call
--      Call fn_Shipping_GetPackedOrders (@LPN)
--              LPN..Details
--               ..Find out distinct Customer and ShipTo from the LPN Detail OrderIds
--               ..And, Check if the Order Pick Batch -> Pallet has some more items to be Packed
--               ..And, if there are no Items to be Packed for the Pick Batch on the Pallet, for the Customer and ShipTo.. then Find distinct
--               Order Ids for the Customer ShipTo Combination
--   */
--
--   /* Exit if all inputs are null */
--   if (@LPNsXML is null and @PickTicketsXML is null and @BatchNosXML is null and @LoadId is null)
--     goto ExitHandler;
--
--   exec pr_ActivityLog_AddMessage 'PackingList', null, null, 'Start_Packing',
--                                  null /* Message */, @@ProcId, @LPNsXML, @BusinessUnit, @UserId;
--
--   /* Get the Source from the Options input xml */
--   select @vSource     = nullif(Record.Col.value('Source[1]',     'TName'),'')
--   from @Options.nodes('/Options') as Record(Col);
--
--   insert into @PackingListsToPrint
--     exec pr_Shipping_GetPackingListsToPrint @LPNsXML, @PickTicketsXML, @BatchNosXML, @ShipmentId, @LoadId,
--                                             @PackingListType, @Options, @BusinessUnit, @UserId;
--
--   /* Determine if any of these entities need or do not need a Packing List */
--   if (@PackingListType <> 'Load')
--     update @PackingListsToPrint
--     set PrintPL = dbo.fn_Packing_CanPrintPackingList(LPNId, OrderId, PackingListType);
--
--   delete from @PackingListsToPrint where coalesce(PrintPL, 0) <> 1;
--
--   while (exists(select * from @PackingListsToPrint where RecordId > @vRecordId))
--     begin
--
--       /* select top 1 here */
--       select top 1 @vOrderId        = OrderId,
--                    @vLPNId          = LPNId,
--                    @vLPN            = LPN,
--                    @vLoadId         = LoadId,
--                    @PackingListType = PackingListType,
--                    @vRecordId       = RecordId
--       from @PackingListsToPrint
--       where (RecordId > @vRecordId)
--       order by RecordId;
--
--       /* get carrier integration status */
--       select @vCarriersIntegration = dbo.fn_Controls_GetAsString('ShipLPNOnPack', 'CarriersIntegration','N' /* No */, @BusinessUnit, 'CIMSAgent');
--
--       select @vAccount   = OH.Account,
--              @vWaveType  = PB.BatchType,
--              @vOwnership = OH.Ownership,
--              @vShipVia   = OH.ShipVia
--       from OrderHeaders OH
--         left outer join PickBatches PB on (OH.PickBatchId = PB.RecordId)
--       where (OrderId = @vOrderId);
--
--       select @vCarrier = Carrier
--       from ShipVias
--       where (ShipVia = @vShipVia);
--
--       /* There are multiple formats of packing lists to be printed, primarily based
--          upon the Carrier. We would use it as rule driven
--          To do so - we need to generate an xml and get the packing list by passing xml to the procedure */
--       select @xmlData = '<RootNode>' +
--                           dbo.fn_XMLNode('PackingListType',      @PackingListType) +
--                           dbo.fn_XMLNode('CarriersIntegration',  @vCarriersIntegration) +
--                           dbo.fn_XMLNode('LPN',                  @vLPN) +
--                           dbo.fn_XMLNode('LPNId',                @vLPNId) +
--                           dbo.fn_XMLNode('PickTicket',           @vPickTicket) +
--                           dbo.fn_XMLNode('OrderId',              @vOrderId) +
--                           dbo.fn_XMLNode('Carrier',              @vCarrier) +
--                           dbo.fn_XMLNode('WaveType',             @vWaveType) +
--                           dbo.fn_XMLNode('Account',              @vAccount) +
--                           dbo.fn_XMLNode('Source',               @vSource) + /* Consider the source of request to determine which
--                                                                                 packing list to print using the rules */
--                           dbo.fn_XMLNode('BusinessUnit',         @BusinessUnit) +
--                           dbo.fn_XMLNode('Ownership',            @vOwnership) +
--                         '</RootNode>'
--
--       /* Get Carrier Interface */
--       exec pr_RuleSets_Evaluate 'CarrierInterface', @xmlData, @vCarrierInterface output;
--
--       /* Get the packing list */
--       exec pr_RuleSets_Evaluate 'PackingList', @xmlData, @Report output;
--
--       /* Get additional Packing List info */
--       exec pr_RuleSets_Evaluate 'PackingList_Info1', @xmlData, @vAdditionalPLInfo1 output;
--
--       /* Compute the Total Tax Amount for this package */
--       select @OrderTaxAmount = sum(coalesce(UnitTaxAmount, 0) * coalesce(UnitsAssigned, 0)),
--              @OrderSubTotal  = sum(coalesce(UnitSalePrice, 0) * coalesce(UnitsAssigned, 0))
--       from OrderDetails
--       where (OrderId = @vOrderId);
--
--       select @vTotalWeight = sum(ActualWeight)
--       from vwLPNPackingListHeaders
--       where (OrderId = @vOrderId);
--
--       if (@PackingListType = 'ORD')
--         begin
--           /* Packing List Header for the Order */
--           set @PLHeaderxml = (select *
--                                      ,@OrderTaxAmount as OrderTaxAmount
--                                      ,(@OrderTaxAmount +
--                                       coalesce(TotalShippingCost,0) +
--                                       @OrderSubTotal) as OrderTotal
--                                      ,@vTotalWeight as ActualWeight
--                                      ,'ORD' as PackingListType
--                                      ,@vAdditionalPLInfo1 as AdditionalPLInfo1
--                               from vwPackingListHeaders
--                               where OrderId = @vOrderId
--                               for xml raw('PACKINGLISTHEADER'), elements )
--
--           exec pr_Shipping_GetPackingListDetails null, @vOrderId, @vLPNId, @Report, @PackingListType, @xmlData,
--                                                  @PLDetailsxml1 output, @PLDetailsxml2 output, @vTotalPages output, @vNumPackedDetails output;
--
--           /* Get any one of the LPN of the order
--              Assumption is any return label will not have any package details and
--              FedEx/UPS only charge for what customer returns */
--           select top 1
--                  @vLPN = LPN
--           from LPNs
--           where (OrderId = @vOrderId) and
--                 (LPNType in ('C', 'S' /* Carton, ShipCarton */)) and
--                 (Status  in ('D', 'L', 'S' /* Packed, Loaded, Shipped */))
--
--           /* Returns the top 1 LPN into order packing list header information to print LPN on the order packinglist */
--           select @PLHeaderxml = dbo.fn_XMLStuffValue (@PLHeaderxml, 'LPN', @vLPN);
--
--           exec pr_Shipping_PLGetShipLabelsXML @vOrderId, null /* LPN */, @BusinessUnit, @ShipLabelxml output, @ReturnShipLabelXML output;
--
--           /* Include Commercial Invoice i.e. label type of 'CI%' */
--           set @CommInvoicexml = (select RecordId, EntityType, EntityKey, LabelType, TrackingNo, Label, ShipVia,
--                                         Status, BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, Notifications
--                                  from ShipLabels
--                                  where EntityKey = @vLPN and LabelType like 'CI%' /* CI Label */
--                                  for xml raw('CISHIPLABEL'), elements, binary base64)
--
--           /* Capture comments from Order Header */
--           select @vComments  = coalesce(Comments,''),
--                  @vWarehouse = Warehouse
--           from OrderHeaders
--           where (OrderId = @vOrderId);
--         end
--       else
--       if (@PackingListType in ('LPN', 'ReturnLPN', 'LPNWithLDs', 'LPNWithODs' /* for return Packing list */))
--         begin
--           /* Carton / Packing List Header */
--           set @PLHeaderxml =  (select *
--                                       ,@OrderTaxAmount as OrderTaxAmount
--                                       ,(@OrderTaxAmount +
--                                         coalesce(TotalShippingCost, 0) +
--                                         @OrderSubTotal) as OrderTotal
--                                       ,'LPN' as PackingListType
--                                       ,@vAdditionalPLInfo1 as AdditionalPLInfo1
--                                from vwLPNPackingListHeaders
--                                where LPNId = @vLPNId
--                                for xml raw('PACKINGLISTHEADER'), elements )
--
--           exec pr_Shipping_GetPackingListDetails null, @vOrderId, @vLPNId, @Report, @PackingListType,
--                                                  @PLDetailsxml1 output, @PLDetailsxml2 output, @vTotalPages output, @vNumPackedDetails output;
--
--           exec pr_Shipping_PLGetShipLabelsXML null /* OrderId */, @vLPN /* LPNId */, @BusinessUnit, @ShipLabelxml output, @ReturnShipLabelXML output;
--
--           /* Include label type of 'CI%' */
--           set @CommInvoicexml = (select RecordId, EntityType, EntityKey, LabelType, TrackingNo, Label, ShipVia,
--                                             Status, BusinessUnit, CreatedDate, ModifiedDate, CreatedBy, ModifiedBy, Notifications
--                                  from ShipLabels
--                                  where EntityKey = @vLPN and LabelType like 'CI%' /* CI Label */
--                                  for xml raw('CISHIPLABEL'), elements, binary base64)
--         end
--       else
--       if (@PackingListType = 'Load')
--         begin
--           /* Carton / Packing List Header */
--           set @PLHeaderxml =  (select *
--                                       ,@OrderTaxAmount as OrderTaxAmount
--                                       ,(@OrderTaxAmount +
--                                         TotalShippingCost +
--                                         @OrderSubTotal) as OrderTotal
--                                from vwLPNPackingListHeaders
--                                where LoadId = @vLoadId
--                                for xml raw('PACKINGLISTHEADER'), elements )
--
--           /* Carton / Packing List Details for all LPNs on the load */
--           set @PLDetailsxml1 = (select distinct SKU, UDF1, min(SKUDescription) SKUDescription, min(SKU_UDF8) SKU_UDF8,
--                                                 sum(Quantity) Quantity, sum(UnitsPerPackage) UnitsPerPackage
--                                 from vwLPNPackingListDetails
--                                 where LoadId = @vLoadId
--                                 group by SKU, UDF1
--                                 for xml raw('PACKINGLISTDETAILS'), elements )
--
--           /* Get the Packed details count to pad the dummy records to fit the required
--              object at the bottom of packing list */
--           select @vNumPackedDetails = count(*)
--           from vwLPNPackingListDetails
--           where OrderId = @vOrderId;
--
--           exec pr_Shipping_PLGetShipLabelsXML null /* OrderId */, @vLPN /* LPNId */, @BusinessUnit, @ShipLabelxml output, @ReturnShipLabelXML output;
--         end
--
--       exec pr_Shipping_PLGetCommentsXML @xmlData, @Commentsxml output
--
--       /* Get the Dummy rows count to print on report */
--       select @vDummyRecordsCount = dbo.fn_Shipping_GetPackingListDummyRecordsCount (@vNumPackedDetails, @Report , 'Y' /* Yes */, @BusinessUnit),
--              @DummyDetailsxml = '';
--
--       /* Build the Dummy details with rows through loop */
--       while (@vDummyRecordsCount > 0)
--         begin
--            select @DummyDetailsxml    = coalesce(@DummyDetailsxml, '') +
--                                         dbo.fn_XMLNode('DummyDetails',
--                                         dbo.fn_XMLNode('DummyColumn1', '')),
--                   @vDummyRecordsCount = @vDummyRecordsCount -1;
--         end
--
--       /* Default report will always print, if there are additional records, then print the addendum page */
--       set @Reportsxml1 = dbo.fn_XMLNode('REPORTS',
--                             dbo.fn_XMLNode('Report',             @Report) +
--                             dbo.fn_XMLNode('TotalPages',         @vTotalPages) +
--                             dbo.fn_XMLNode('StartingPageNumber', 1)); /* This is the first page print */
--
--       if (@PLDetailsxml2 is not null)
--         begin
--           select @Reportsxml2 = dbo.fn_XMLNode('REPORTS',
--                                    dbo.fn_XMLNode('Report', @Report + '_AP') +
--                                    dbo.fn_XMLNode('TotalPages',         @vTotalPages) +
--                                    dbo.fn_XMLNode('StartingPageNumber', 2));  /* From the second page we are print remaining records */
--         end
--
--       select @OptionsXML =  dbo.fn_XMLNode('OPTIONS',
--                               dbo.fn_XMLNode('CarrierInterface', @vCarrierInterface));
--
--       select @Resultxml = coalesce(@Resultxml,'') +
--              '<PACKINGLIST>' +
--                coalesce(@PLHeaderxml,        '') +
--                coalesce(@PLDetailsxml1,      '') +
--                coalesce(@Commentsxml,        '') +
--                coalesce(@ShipLabelxml,       '') +
--                coalesce(@ReturnShipLabelxml, '') +
--                coalesce(@CommInvoicexml,     '') +
--                coalesce(@DummyDetailsxml,    '') +
--                coalesce(@Reportsxml1,        '') +
--                coalesce(@OptionsXML,         '') +
--              '</PACKINGLIST>'
--
--       /* Remaining records print on second report */
--       if (@PLDetailsxml2 is not null)
--         select @Resultxml = coalesce(@Resultxml, '') +
--                '<PACKINGLIST>' +
--                  coalesce(@PLHeaderxml,        '') +
--                  coalesce(@PLDetailsxml2,      '') +
--                  coalesce(@Commentsxml,        '') +
--                  coalesce(@ShipLabelxml,       '') +
--                  coalesce(@ReturnShipLabelxml, '') +
--                  coalesce(@DummyDetailsxml,    '') +
--                  coalesce(@Reportsxml2,        '') +
--                  coalesce(@OptionsXML,         '') +
--                '</PACKINGLIST>'
--     end
--
--   select '<PACKINGLISTS>' +
--            @Resultxml        +
--          '</PACKINGLISTS>' as result
--
-- ErrorHandler:
--   if (@MessageName is not null)
--     exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;
--
-- ExitHandler:
--   return(coalesce(@ReturnCode, 0));
-- end /* pr_Shipping_GetPackingListData */
--
-- Go
