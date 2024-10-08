/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/08/25  AJM     pr_Exports_GetData, pr_Exports_CaptureData: Added CreatedDate field (portback from prod) (BK-904)
  2022/08/18  VS      pr_Exports_CaptureData, pr_Exports_GetData: Added comments field to send error message to the Host (BK-885)
  2021/08/04  VS      pr_Exports_CaptureData, pr_Exports_CIMSDE_ExportData, pr_Exports_GetData: Improve the Performance of Export data to CIMSDE DB (HA-3032)
  2021/08/02  VS      pr_Exports_CaptureData, pr_Exports_CIMSDE_ExportData: Improve the Performance of Export data to CIMSDE DB (HA-3032)
                      pr_Exports_CaptureData: Clearing the temp table (HA-2882)
  2021/06/01  RKC     pr_Exports_CaptureData, pr_Exports_CIMSDE_ExportData: Used the #table instead of temp table (HA-2850)
  2021/03/02  PK      pr_Exports_CaptureData, pr_Exports_GetData: Added ClientLoad (HA-2109)
  2021/01/20  PK      pr_Exports_InsertRecords, pr_Exports_GetData. pr_Exports_CaptureData: Added DesiredShipDate in the dataset (HA-2029)
  2020/11/16  SV      pr_Exports_CaptureData: Resolved the issue with updating wrong counts in interface log (HA-1309)
  2020/03/24  VM      pr_Exports_CaptureData: Removed ReceiptLine, OrderLine as they are not required for exports (CIMS-2880)
  2019/12/08  RKC     pr_Exports_GetData,pr_Exports_CaptureData:Added ShipToAddress fields
  2018/12/02  AY      pr_Exports_CaptureData: Change to reflect new ActivityLog_AddMessage (FB-1226)
  2018/08/09  VS      pr_Exports_CaptureData: Enhance pr_Exports_CaptureData to handle OPENXML (S2GCA-141)
  2018/05/20  TK      pr_Exports_CaptureData: Changes to return interface log id in the result xml
  2018/03/21  SV      pr_Exports_CaptureData, pr_Exports_GetData: Added the missing fields to send the complete exports to DE db (S2G-379)
  2018/03/14  DK      pr_Exports_CaptureData, pr_Exports_GetData: Enhanced to process exports file based on SourceSystem (FB-1111)
  2018/03/13  DK      pr_Exports_CaptureData, pr_Exports_GetNextBatchCriteria, pr_Exports_GetData, pr_Exports_GenerateBatches, pr_Exports_CreateBatchesForOrders
  2017/12/01  DK      pr_Exports_CaptureData: Made changes to return appropriate return value in order to process all creted batch in one DE run (FB-1051)
  2017/07/28  RV      pr_Exports_CaptureData: BusinessUnit and UserId passed to activity log procedure
  2017/07/07  RV      pr_Exports_CaptureData: Procedure id is passed to logging procedure to
  2017/07/03  NB      Code optimization on pr_Exports_CaptureData: Moved updates on InterfaceLog to pr_InterfaceLog_AddUpdate (CIMSDE-6)
  2017/06/12  NB      pr_Exports_CaptureData: Minor fix to update earlier records for Export in InterfaceLog (CIMSDE-6)
  2017/06/08  NB      pr_Exports_CaptureData: Minor fix to update RecordsProcessed in InterfaceLog (CIMSDE-6)
  2017/02/15  NB      pr_Exports_CaptureData: Enhanced to create InterfaceLog entry for export batch(CIMSDI-6)
  2016/08/24  AY      pr_Exports_CaptureData: Debug info, transaction control added
  2016/05/10  NB      pr_Exports_CaptureData: Changes to support repeated calls (NBD-446).
  2016/05/09  OK      pr_Exports_CaptureData: Modified to accept Parameters or xmlinput and added its wrapper procedure pr_Exports_CaptureData_HPI (HPI-95)
  2016/04/27  AY      pr_Exports_CaptureData: Changes to support repeated calls (NBD-396).
  2016/04/21  NB      pr_Exports_CaptureData: Changes to return EDITransCode in the Header (NBD-422)
  2016/02/17  NB      pr_Exports_CaptureData: Minor change to statements reading SenderId and ReceiverId for Header(NBD-102)
                      pr_Exports_CaptureData: added validation to verify TransType/Ownership from GetNextBatchCriteria call (NBD-133)
  2016/02/05  TK      pr_Exports_CaptureData & pr_Exports_GetData: changes made to return
  2016/01/28  NB      pr_Exports_CaptureData: Minor syntax correction
  2016/01/27  TK      pr_Exports_CaptureData: Message Header should contain SenderId and ReceiverId (NBD-105)
  2015/06/12  YJ      Changes to pr_Exports_CaptureData for exports fields order.
  2015/04/22  PK      pr_Exports_CaptureData: Corrected the position of the Reference field.
  2015/02/27  SV      pr_Exports_CaptureData: Had made the changes to show the "msgHeader" data
  2015/01/20  VM      pr_Exports_CaptureData, pr_Exports_GetData: Added MasterBoL to export as well
  2014/05/26  TD      pr_Exports_CaptureData: Changed UnitsPerLPN => UnitsPerInnerPack.
  2014/03/13  PK      pr_Exports_CaptureData: Corrected the order of the fields and fieldNames as per the
  2014/02/14  NY      pr_Exports_CaptureData, pr_Exports_GetData: Added additinal UDF's.
  2014/02/11  NY      pr_Exports_CaptureData: Chnaged order of fields to insert into Exports table.
  2014/02/04  TD      pr_Exports_CaptureData: changes to export FromLocation, ToLocation data.
  2014/01/30  TD      pr_Exports_CaptureData, pr_Exports_GetData: Added UDFs while exporting data.
  2013/10/10  NY      pr_Exports_CaptureData:Added FromWarehouse,ToWarehouse
  2013/09/06  PK      pr_Exports_CaptureData: Building exports result based on the control variable to add exportmsgheader node.
  2013/08/09  PK      pr_Exports_CaptureData: Changed the DateTime format as requested by client.
                      pr_Exports_CaptureData: converting  into decimal while building xml.
  2012/12/08  VM      pr_Exports_CaptureData: Added new field 'Archived' in temp table to recieve from return dataset
  2012/10/26  VM      pr_Exports_CaptureData: Return ShippedDate (from Loads) as well
  2012/09/11  SP      pr_Exports_CaptureData: Added   LoadNumber, BoL, LoadShipVia, UCCBarcode,
  2012/09/11  AY      pr_Exports_CaptureData: Added RecordType
  2012/08/16  YA      pr_Exports_CaptureData: Included Warehouse in temp table - Fix for interface sevice issue.
  2012/05/10  AY      pr_Exports_CaptureData: Added UnitsAuthorizedToShip to XML
  2012/05/07  VM      pr_Exports_CaptureData: Added SerialNo based on view change
  2011/07/26  PK      pr_Exports_CaptureData : Exporting records based on given inputs,
  2011/07/06  PK      pr_Exports_CaptureData : Added newly added fields from vwExports because
  2011/02/16  PK      pr_Exports_CaptureData : Modified the procedure to get the xml resultset.
  2011/01/26  VM      pr_Exports_CaptureData: Corrected the inconsistency of
                         StatusDescription fields to pr_Exports_CaptureData.
  2010/12/30  PK      Created pr_Exports_CaptureData.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_CaptureData') is not null
  drop Procedure pr_Exports_CaptureData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_CaptureData:
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_CaptureData
  (@ExportBatch         TBatch        = null,
   @IntegrationType     TAction       = null,
   @TransferToDBMethod  TControlValue = null,
   @TransType           TTypeCode     = null,
   @Ownership           TOwnership    = null,
   @SourceSystem        TName         = null,
   @BusinessUnit        TBusinessUnit = null,
   @UserId              TUserId       = null,
   @XmlData             xml           = null,
   @XmlResult           xml   output)
as
  declare @vReturnCode          TInteger,
          @MessageName          TMessageName,
          @vMessage             TDescription,
          @SenderId             TUserId,
          @ReceiverId           TUserId,
          @xmlExportsMsgHeader  TVarchar,
          @vAddExportsMsgHeader TFlag,
          @vEDITransCode        TTypeCode,
          @vExportRecordCount   TCount,
          @vInterfaceLogId      TRecordId,
          @vRecordTypes         TRecordTypes,
          @vDebug               TControlValue,
          @vDataXML             TXML,
          @vXmlDocHandle        Int;

  declare @ExportInfo           TExportsType;

  declare @ttMarkers            TMarkers,
          @vActivityLogId       TRecordId;

begin
  SET NOCOUNT ON;

begin try
  begin tran

  select @vReturnCode = 1;

  /* Create #ExportInfo if it doesn't exist */
  if (object_id('tempdb..#ExportInfo') is null)
    begin
      select * into #ExportInfo from @ExportInfo

      /* CIMSDE table has RecordId and we don't need this again */
      if (@TransferToDBMethod = 'SQLDATA')
        alter table #ExportInfo drop column RecordId;
    end

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @BusinessUnit, @vDebug output;

    /*  1. Create a view vwExports and join all the required tables(LPNs, SKUs, RH, RD, OH, OD etc) fields to the view.

       2. Fetch the records which has the status type as Unprocessed Flag.
          and insert into temp table
          insert into @ExportInfo

       3. select * from @ExportInfo where
            TransType = case
                          when (@TransType is not null) then @TransType else TypeCode
                        end  and
            ExportBatch = case
                            when (@BatchType is not null) then @ExportBatch else ExportBatch
                          end
            and (BusinessUnit = @BusinessUnit);
   */

  /* Fetch the parameter values from the xmlData */
  if (@XmlData is not null)
    begin
      exec sp_xml_preparedocument @vXmlDocHandle output, @xmlData;

      select @ExportBatch     = ExportBatch,
             @IntegrationType = IntegrationType,
             @TransType       = TransType,
             @Ownership       = Ownership,
             @BusinessUnit    = BusinessUnit,
             @UserId          = UserId
      from OPENXML(@vXmlDocHandle, '//msg/msgHeader', 2)
      with (ExportBatch         TBatch,
            IntegrationType     TAction,
            TransType           TTypeCode,
            Ownership           TOwnership,
            BusinessUnit        TBusinessUnit,
            UserId              TUserId);
    end

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  /* insert into activitylog details */
  if (charindex('L' /* Log */, @vDebug) > 0)
    exec pr_ActivityLog_AddMessage 'Exports_CaptureData', null /* EntityId */, @ExportBatch, 'Exports',
                                   @TransType, @@ProcId, @xmlData,
                                   @ActivityLogId = @vActivityLogId output;

  /* Make null if empty strings are passed */
  select @ExportBatch     = nullif(@ExportBatch,     ''),
         @IntegrationType = nullif(@IntegrationType, ''),
         @TransType       = nullif(@TransType,       ''),
         @Ownership       = nullif(@Ownership,       ''),
         @SourceSystem    = nullif(coalesce(@SourceSystem, 'HOST'), ''),
         @BusinessUnit    = nullif(@BusinessUnit,    ''),
         @UserId          = nullif(@UserId,          '');

  /* Validations */
  select @vMessage = dbo.fn_IsValidLookUp('SourceSystem', @SourceSystem, @BusinessUnit, @UserId);

  if (@vMessage is not null)
    begin
      set @vReturnCode = 0; /* Means there are no records to process */
      goto ErrorHandler; /* We go there so that we can commit and end the call */
    end

   /* insert into activitylog details */
   if (charindex('L' /* Logging */, @vDebug) > 0)
     begin
       if (@xmlData is null)
         select @xmlData = (select @ExportBatch     ExportBatch,
                                   @IntegrationType IntegrationType,
                                   @TransType       TransType,
                                   @Ownership       Ownership,
                                   @BusinessUnit    BusinessUnit
                            for Xml RAW('INPUT'), TYPE, ELEMENTS XSINIL);

       select @vDataxml = convert(varchar(max), @xmldata);

       exec pr_ActivityLog_AddMessage 'Export_CaptureData', @ExportBatch, @TransType, 'Exports',
                                      'Start' /* Message */, @@ProcId, @vDataxml, @BusinessUnit, @UserId;
     end

  /* Get the control value whether to add ExportMsgHeader node in result or not */
  select @vAddExportsMsgHeader = dbo.fn_Controls_GetAsBoolean('ExportBatch', 'AddMsgHeaderNode', 'N' /* No */, @BusinessUnit, @UserId);

  /* If Exportbatch is null
     1)Then only call pr_Exports_GetNextBatchCriteria proc to get the TransType, Ownership & Export Batch No to process
     2)Else no need to call this proc
     Because in this proc finally just taking the same ExportBatch value so its a time taken process */
  if (coalesce(@ExportBatch , '') = '')
    exec pr_Exports_GetNextBatchCriteria @IntegrationType output,
                                         @TransType       output,
                                         @Ownership       output,
                                         @SourceSystem    output,
                                         @ExportBatch     output,
                                         @BusinessUnit;

  /* Verify whether or not the batch criteria is present
     If there are no batch criteria identified, it means that there are no exports to process currently
     If this condition is not verified, then Exports_GetData procedure returns the first available set of export records
     CaptureData must always pass in the TransType/Ownership information to Exports_GetData procedure */
  /* We introduced a new job proc pr_Exports_GenerateBatches to generate batches before the hand
     and reduce burden for DE. So, if there is a batch to export, then do so else exit */
  if ((@TransType is null) and (@Ownership is null))
    begin
      set @vReturnCode = 0; /* Means there are no records to process */
      goto ErrorHandler; /* There is no error, but we go there so that we can commit and end the call */
    end

  /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'Before Get Data';

  if (charindex('L' /* Logging */, @vDebug) > 0)
    begin
      select @xmlData  = convert(xml, dbo.fn_XMLStuffValue (convert(varchar(max), @xmlData), 'Ownership', @Ownership));
      select @vDataXML = convert(varchar(max), @xmlData);

      exec pr_ActivityLog_AddMessage 'Export_CaptureData', @ExportBatch, @TransType, 'Exports',
                                     'Before Get Data' /* Message */, @@ProcId, @vDataXML, @BusinessUnit, @UserId;
    end

  /* Clear the temp table for each run */
  if (object_id('tempdb..#ExportInfo') is not null)
    delete from #ExportInfo;

  /* In TExportsType, we have moved the identity column (RecordId) to the end of the domain definition.
     Hence, we can directly(by not specifying column names explicitly) insert into @ExportInfo */
  exec pr_Exports_GetData @TransType, @Ownership, @SourceSystem, @ExportBatch output, @BusinessUnit, @UserId;

  /* Get the count of records being exported to log in InterfaceLog */
  select @vExportRecordCount = @@rowcount;

  if (charindex('L' /* Logging */, @vDebug) > 0)
    begin
      exec pr_ActivityLog_AddMessage 'Export_CaptureData', @ExportBatch, @TransType, 'Exports',
                                     'After Get Data' /* Message */, @@ProcId, @BusinessUnit = @BusinessUnit, @UserId = @UserId;
    end

  /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After Get Data';

  /* Assumption - Each batch is for one Transaction code only */
  select top 1
         @vEDITransCode = EDITransCode,
         @ExportBatch   = ExportBatch,
         @vRecordTypes  = RecordType
  from #ExportInfo;

  /* If CIMSDE Server is in same server then fetch the export batch data from #Exportinfo temp table */
  if (@TransferToDBMethod = 'SQLDATA')
    select * into ##ExportTransactions from #ExportInfo where (ExportBatch = @ExportBatch);
  else
    /* If CIMSDE Server is not same server then fetch the export batch data from XML/JSON */
    set @XmlResult = (select RecordId,
                             RecordType,
                             ExportBatch,
                             TransDate,
                             TransDateTime,
                             TransQty,

                             /* SKU */
                             SKU,
                             SKU1,
                             SKU2,
                             SKU3,
                             SKU4,
                             SKU5,
                             Description,
                             UoM,
                             UPC,
                             Brand,

                             /* LPN */
                             LPN,
                             LPNType,
                             ASNCase,
                             UCCBarcode,
                             TrackingNo,
                             CartonDimensions,

                             /* Counts */
                             NumPallets,
                             NumLPNs,
                             NumCartons,

                             /* LPN Detail */
                             LPNLine,
                             Innerpacks,
                             Quantity,
                             UnitsPerPackage,
                             SerialNo,

                             /* Pallet */
                             Pallet,
                             Location,
                             HostLocation,

                             /* Receiver Details */
                             ReceiverNumber,
                             ReceiverDate,
                             ReceiverBoL,
                             ReceiverRef1,
                             ReceiverRef2,
                             ReceiverRef3,
                             ReceiverRef4,
                             ReceiverRef5,

                             /* ROH, ROD */
                             ReceiptNumber,
                             ReceiptType,
                             VendorId,
                             ReceiptVessel,
                             ReceiptContainerNo,
                             ReceiptContainerSize,
                             ReceiptBillNo,
                             ReceiptSealNo,
                             ReceiptInvoiceNo,
                             HostReceiptLine,
                             CoO,
                             UnitCost,

                             /* Common */
                             ReasonCode,
                             Warehouse,
                             Ownership,
                             ExpiryDate,
                             Lot,
                             InventoryClass1,
                             InventoryClass2,
                             InventoryClass3,

                             cast(Weight as Decimal(18,4)) as Weight,
                             cast(Volume as Decimal(18,4)) as Volume,
                             cast(Length as Decimal(18,4)) as Length,
                             cast(Width as Decimal(18,4))  as Width,
                             cast(Height as Decimal(18,4)) as Height,
                             InnerPacks as InnerPacksPerLPN,
                             UnitsPerInnerPack,
                             Reference,
                             MonetaryValue,

                             /* Order Header */
                             PickTicket,
                             SalesOrder,
                             OrderType,
                             SoldToId,
                             SoldToName,
                             ShipToId,
                             ShipToName,
                             ShipVia,
                             ShipViaDescription,
                             ShipViaSCAC,
                             ShipFrom,
                             CustPO,
                             Account,
                             AccountName,
                             FreightCharges,
                             FreightTerms,
                             BillToAccount,
                             BillToName,
                             BillToAddress,

                             /* Order Details */
                             HostOrderLine,
                             UnitsOrdered,
                             UnitsAuthorizedToShip,
                             UnitsAssigned,
                             CustSKU,

                             /* Loads */
                             LoadNumber,
                             ClientLoad,
                             DesiredShipDate,
                             ShippedDate,
                             BoL,
                             LoadShipVia,
                             TrailerNumber,
                             ProNumber,
                             SealNumber,
                             MasterBoL,

                             /* Transfers */
                             FromWarehouse,
                             ToWarehouse,
                             FromLocation,
                             ToLocation,
                             FromSKU,
                             ToSKU,

                             /* EDI */
                             EDIShipmentNumber,
                             EDITransCode,
                             EDIFunctionalCode,

                             /* ShipToAddress */
                             ShipToAddressLine1,
                             ShipToAddressLine2,
                             ShipToCity,
                             ShipToState,
                             ShipToCountry,
                             ShipToZip,
                             ShipToPhoneNo,
                             ShipToEmail,
                             ShipToReference1,
                             ShipToReference2,

                             Comments,

                             /* UDFs */
                             SKU_UDF1,
                             SKU_UDF2,
                             SKU_UDF3,
                             SKU_UDF4,
                             SKU_UDF5,
                             SKU_UDF6,
                             SKU_UDF7,
                             SKU_UDF8,
                             SKU_UDF9,
                             SKU_UDF10,

                             LPN_UDF1,
                             LPN_UDF2,
                             LPN_UDF3,
                             LPN_UDF4,
                             LPN_UDF5,

                             LPND_UDF1,
                             LPND_UDF2,
                             LPND_UDF3,
                             LPND_UDF4,
                             LPND_UDF5,

                             RH_UDF1,
                             RH_UDF2,
                             RH_UDF3,
                             RH_UDF4,
                             RH_UDF5,

                             RD_UDF1,
                             RD_UDF2,
                             RD_UDF3,
                             RD_UDF4,
                             RD_UDF5,

                             OH_UDF1,
                             OH_UDF2,
                             OH_UDF3,
                             OH_UDF4,
                             OH_UDF5,
                             OH_UDF6,
                             OH_UDF7,
                             OH_UDF8,
                             OH_UDF9,
                             OH_UDF10,
                             OH_UDF11,
                             OH_UDF12,
                             OH_UDF13,
                             OH_UDF14,
                             OH_UDF15,
                             OH_UDF16,
                             OH_UDF17,
                             OH_UDF18,
                             OH_UDF19,
                             OH_UDF20,
                             OH_UDF21,
                             OH_UDF22,
                             OH_UDF23,
                             OH_UDF24,
                             OH_UDF25,
                             OH_UDF26,
                             OH_UDF27,
                             OH_UDF28,
                             OH_UDF29,
                             OH_UDF30,

                             OD_UDF1,
                             OD_UDF2,
                             OD_UDF3,
                             OD_UDF4,
                             OD_UDF5,
                             OD_UDF6,
                             OD_UDF7,
                             OD_UDF8,
                             OD_UDF9,
                             OD_UDF10,
                             OD_UDF11,
                             OD_UDF12,
                             OD_UDF13,
                             OD_UDF14,
                             OD_UDF15,
                             OD_UDF16,
                             OD_UDF17,
                             OD_UDF18,
                             OD_UDF19,
                             OD_UDF20,

                             LD_UDF1,
                             LD_UDF2,
                             LD_UDF3,
                             LD_UDF4,
                             LD_UDF5,
                             LD_UDF6,
                             LD_UDF7,
                             LD_UDF8,
                             LD_UDF9,
                             LD_UDF10,

                             EXP_UDF1,
                             EXP_UDF2,
                             EXP_UDF3,
                             EXP_UDF4,
                             EXP_UDF5,
                             EXP_UDF6,
                             EXP_UDF7,
                             EXP_UDF8,
                             EXP_UDF9,
                             EXP_UDF10,
                             EXP_UDF11,
                             EXP_UDF12,
                             EXP_UDF13,
                             EXP_UDF14,
                             EXP_UDF15,
                             EXP_UDF16,
                             EXP_UDF17,
                             EXP_UDF18,
                             EXP_UDF19,
                             EXP_UDF20,
                             EXP_UDF21,
                             EXP_UDF22,
                             EXP_UDF23,
                             EXP_UDF24,
                             EXP_UDF25,
                             EXP_UDF26,
                             EXP_UDF27,
                             EXP_UDF28,
                             EXP_UDF29,
                             EXP_UDF30,

                             ShipmentId,
                             LoadId,

                             SourceSystem,
                             BusinessUnit,

                             CreatedDate,
                             CreatedBy,
                             ModifiedBy,
                             CIMSRecId
                      from #ExportInfo
                      where (ExportBatch = @ExportBatch)
                      order by RecordId
                      for XML RAW('Record'), TYPE, ELEMENTS XSINIL, ROOT('msgBody'));

  /* Marker */ if (charindex('M', @vDebug) > 0) insert into @ttMarkers (Marker) select 'After Build Result XML';

  if (charindex('L' /* Logging */, @vDebug) > 0)
    exec pr_ActivityLog_AddMessage 'Export_CaptureData', @ExportBatch, @TransType, 'Exports',
                                   'After Build Result XML' /* Message */, @@ProcId, @BusinessUnit = @BusinessUnit, @UserId = @UserId;

  /* Retrieve SenderId and Receiver Id */
  select @SenderId   = dbo.fn_GetMappedValue('CIMS', @Ownership, 'HOST', '3rdPartySenderId',   'ExportData', @BusinessUnit),
         @ReceiverId = dbo.fn_GetMappedValue('CIMS', @Ownership, 'HOST', '3rdPartyReceiverId', 'ExportData', @BusinessUnit);

  /* Build MsgHeader node for exports */
  select @xmlExportsMsgHeader = dbo.fn_XMLNode('msgHeader', dbo.fn_XMLNode('SchemaName', 'CIMS_ExportDetails') +
                                                            dbo.fn_XMLNode('SchemaVersion', '1.0') +
                                                            dbo.fn_XMLNode('msgSubject', 'ExportDetails') +
                                                            dbo.fn_XMLNode('msgAttribute', 'Export') +
                                                            dbo.fn_XMLNode('msgType', 'Export') +
                                                            dbo.fn_XMLNode('msgFrom', 'CIMS') +
                                                            dbo.fn_XMLNode('CompanyId', @BusinessUnit) +
                                                            dbo.fn_XMLNode('msgGuid', @BusinessUnit + 'Export') +
                                                            dbo.fn_XMLNode('InterfaceLogId', @vInterfaceLogId) +
                                                            dbo.fn_XMLNode('SenderId', @SenderId) +
                                                            dbo.fn_XMLNode('ReceiverId', @ReceiverId) +
                                                            dbo.fn_XMLNode('Ownership', @Ownership) +
                                                            dbo.fn_XMLNode('EDIVersion', '') +
                                                            dbo.fn_XMLNode('EDISequenceNumber', '') +
                                                            dbo.fn_XMLNode('DataUsage', 'T') +
                                                            dbo.fn_XMLNode('EDIFunctionalCode', '') +
                                                            dbo.fn_XMLNode('EDITransCode', @vEDITransCode) +
                                                            dbo.fn_XMLNode('TransType', @TransType) +
                                                            dbo.fn_XMLNode('TimeStamp', (select convert(varchar, (select current_timestamp), 126))) +
                                                            dbo.fn_XMLNode('ExportBatch', convert(varchar(10),(select top 1 ExportBatch from @ExportInfo)))
                                                );
  /* Build the exports result set based on control of client choice */
  if (@vAddExportsMsgHeader = 'Y')
    begin
      /* Build MsgHeader node for exports */
      select @XmlResult = '<msg>' + convert(varchar(max), @xmlExportsMsgHeader) + convert(varchar(max), @xmlResult) + '</msg>';
    end
  else
    begin
      select @XmlResult = '<msg>' + convert(varchar(max), @XmlResult)  + '</msg>';
    end

  /* Create interface log */
  exec pr_InterfaceLog_AddUpdate @SourceSystem     = 'CIMS',
                                 @TargetSystem     = 'HOST',
                                 @SourceReference  = @ExportBatch,
                                 @TransferType     = 'Export',
                                 @BusinessUnit     = @BusinessUnit,
                                 @xmlData          = @xmlExportsMsgHeader,
                                 @xmlDocHandle     = null,
                                 @RecordsProcessed = @vExportRecordCount,
                                 @LogId            = @vInterfaceLogId output,
                                 @RecordTypes      = @vRecordTypes output;

ErrorHandler:
  if (@MessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* insert into activitylog details */
  if (charindex('L' /* Logging */, @vDebug) > 0)
    exec pr_ActivityLog_AddMessage 'Export_CaptureData', @ExportBatch, @TransType, 'Exports',
                                   'Completed' /* Message */, @@ProcId, @BusinessUnit = @BusinessUnit, @UserId = @UserId, @Value1 = @IntegrationType,
                                   @ActivityLogId = @vActivityLogId output;

  if (charindex('L' /* Log */, @vDebug) > 0) and (charindex('M' /* Markers */, @vDebug) > 0)
    exec pr_Markers_Log @ttMarkers, 'ExportBatch', null /* EntityId */, @ExportBatch,
                                    'Exports_CaptureData', @@ProcId;

  commit;
end try
begin catch
  if (@@trancount > 0) rollback;

  /* insert into activitylog details */
  select @vMessage = Error_Message();
  exec pr_ActivityLog_AddMessage 'Export_CaptureData', @ExportBatch, @TransType, 'Exports',
                                 @vMessage /* Message */, @@ProcId, @BusinessUnit = @BusinessUnit, @UserId = @UserId, @Value1 = @IntegrationType;

  exec pr_ReRaiseError;
end catch

ExitHandler:
  return(@vReturnCode);
end /* pr_Exports_CaptureData */

Go
