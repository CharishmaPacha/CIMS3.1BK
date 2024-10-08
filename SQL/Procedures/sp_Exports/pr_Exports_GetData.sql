/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/08/25  AJM     pr_Exports_GetData, pr_Exports_CaptureData: Added CreatedDate field (portback from prod) (BK-904)
  2022/08/18  VS      pr_Exports_CaptureData, pr_Exports_GetData: Added comments field to send error message to the Host (BK-885)
  2021/08/04  VS      pr_Exports_CaptureData, pr_Exports_CIMSDE_ExportData, pr_Exports_GetData: Improve the Performance of Export data to CIMSDE DB (HA-3032)
  2020/11/21  VS      pr_Exports_GetData, pr_Exports_GetNextBatchCriteria: Made changes to export the Batch to host after Batch creation only (FB-2194)
  2021/03/02  PK      pr_Exports_CaptureData, pr_Exports_GetData: Added ClientLoad (HA-2109)
  2021/01/20  PK      pr_Exports_InsertRecords, pr_Exports_GetData. pr_Exports_CaptureData: Added DesiredShipDate in the dataset (HA-2029)
  2021/02/01  SK      pr_Exports_InsertRecords, pr_Exports_CIMSDE_ExportData, pr_Exports_GetData
  2020/04/20  VS      pr_Exports_GetData: Export Client WH Codes to the CIMSDE DB (HA-180)
  2020/03/30  YJ      pr_Exports_AddOrUpdate, pr_Exports_GetData, pr_Exports_LPNData: To get E.InventoryClassses (HA-85)
  2019/12/08  RKC     pr_Exports_GetData,pr_Exports_CaptureData:Added ShipToAddress fields
  2018/03/21  SV      pr_Exports_CaptureData, pr_Exports_GetData: Added the missing fields to send the complete exports to DE db (S2G-379)
  2018/03/14  DK      pr_Exports_CaptureData, pr_Exports_GetData: Enhanced to process exports file based on SourceSystem (FB-1111)
  2018/03/13  DK      pr_Exports_CaptureData, pr_Exports_GetNextBatchCriteria, pr_Exports_GetData, pr_Exports_GenerateBatches, pr_Exports_CreateBatchesForOrders
                      pr_Exports_GetData: Because of above new job to generate batches as separate, stop creating batches from here (FB-1048)
  2016/02/05  TK      pr_Exports_CaptureData & pr_Exports_GetData: changes made to return
  2016/01/21  TK      pr_Exports_GetData & pr_Exports_CreateBatch: The Export Batch creation should create batches
                      pr_Exports_GetData: Modified to send TransEntity.
  2015/05/09  VM      pr_Exports_GetData: Get specific trans type of transactions when requested for specific batch and Trans type
  2015/01/20  VM      pr_Exports_CaptureData, pr_Exports_GetData: Added MasterBoL to export as well
                      pr_Exports_GetData:Changes to export to Host based on the control variable.
  2014/02/14  NY      pr_Exports_CaptureData, pr_Exports_GetData: Added additinal UDF's.
  2014/01/30  TD      pr_Exports_CaptureData, pr_Exports_GetData: Added UDFs while exporting data.
  2013/10/29  TD      pr_Exports_GetData:Getting transactiontypes from controls.
                      pr_Exports_GetData: Only export records with Status N even when re-exporting a batch
  2013/08/05  TD      pr_Exports_GetData: Changes to export MMS Location instead of CIMS Location.
  2012/12/11  SP      pr_Exports_GetData: Replaced the select statement with fields in vwexports.
  2012/08/18  AY      pr_Exports_GetData: Enhance to export a previous batch if it
  2011/08/17  YA      pr_Exports_CreateBatch, pr_Exports_GetData: New procs
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_GetData') is not null
  drop Procedure pr_Exports_GetData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_GetData: This procedure is used to return the export data
    for a given batch. If no batch is given, it would create a new batch and
    return the results of the newly created batch.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_GetData
  (@TransType     TTypeCode  = null,
   @Ownership     TOwnership = null,
   @SourceSystem  TName,
   @BatchNo       TBatch     = null output,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vTransType_CC          TControlCode,
          @vTransType_PC          TControlCode,
          @vIntegrationType       TControlValue,
          @vGenerateBatchesFromDE TControlValue;

begin /* pr_Exports_GetData */
  /* Get Transaction type here from controls */
  select @vIntegrationType       = dbo.fn_Controls_GetAsString ('Exports', 'IntegrationType',  'DE', @BusinessUnit, @UserId),
         @vGenerateBatchesFromDE = dbo.fn_Controls_GetAsBoolean('Exports', 'GenerateBatchesFromDE', 'Y' /* Yes */, @BusinessUnit, @UserId);

  /* Check if there is an existing batch to export, if so export that first */
  if (coalesce(@BatchNo, 0) = 0)
    select top 1 @BatchNo = ExportBatch
    from Exports
    where (TransType = coalesce(@TransType, TransType)) and
          (Ownership = coalesce(@Ownership, Ownership)) and
          (SourceSystem = coalesce(@SourceSystem, SourceSystem)) and
          (Status = 'N') and (ExportBatch > 0)
    group by ExportBatch
    having (datediff(second, max(CreatedDate), getdate()) > 60) /* Export the batch to host after 1 min because Batch generation is in in-progress */
    order by ExportBatch;

  /* We introduced a new job proc pr_Exports_GenerateBatches to generate batches before the hand
     and reduce burden for DE. So, if there is a batch to export, then do so else exit */
  if (coalesce(@BatchNo, 0) = 0) and (@vGenerateBatchesFromDE <> 'Y' /* Yes */)
    return;

  /*  If BatchNo in param is null/0, that means there are no available batches to export, so create a new one */
  if (coalesce(@BatchNo, 0) = 0)
    exec pr_Exports_CreateBatch @TransType, @Ownership, @SourceSystem, @BusinessUnit, @UserId,
                                @BatchNo output;

   /* Get Shipto and SoldTo info and then update to exports table*/
   exec pr_Exports_PrepareData @BatchNo, @TransType;

  /* Return the records for the particular Batch */
  /******************************************************************************/
  /*  This should match the number of fields and order of fields in TExportType */
  /******************************************************************************/
  insert into #ExportInfo
    select  E.RecordType,
            E.ExportBatch,
            E.TransDate,
            E.TransDateTime,
            E.TransQty,

            /* SKU */
            E.SKU,
            E.SKU1,
            E.SKU2,
            E.SKU3,
            E.SKU4,
            E.SKU5,
            E.Description,
            E.UoM,
            E.UPC,
            E.Brand,

            /* LPN */
            E.LPN,
            E.LPNType,
            E.ASNCase,
            E.UCCBarcode,
            E.TrackingNo,
            E.CartonDimensions,

            /* Counts */
            E.NumPallets,
            E.NumLPNs,
            E.NumCartons,

            /* LPN Details */
            E.LPNLine,
            E.Innerpacks,
            E.Quantity,
            E.UnitsPerPackage,
            E.SerialNo,

            /* Pallet & Location */
            E.Pallet,
            coalesce(E.HostLocation, E.Location) as Location,
            E.HostLocation,

            /* Receiver Details */
            E.ReceiverNumber,
            E.ReceiverDate,
            E.ReceiverBoL,
            E.ReceiverRef1,
            E.ReceiverRef2,
            E.ReceiverRef3,
            E.ReceiverRef4,
            E.ReceiverRef5,

            /* RO Hdr */
            E.ReceiptNumber,
            E.ReceiptType,
            E.VendorId,
            E.Vessel        as ReceiptVessel,
            E.ContainerNo   as ReceiptContainerNo,
            E.ContainerSize as ReceiptContainerSize,
            E.BillNo        as ReceiptBillNo,
            E.SealNo        as ReceiptSealNo,
            E.InvoiceNo     as ReceiptInvoiceNo,

            /* RO Details */
            E.HostReceiptLine,
            E.CoO,
            E.UnitCost,

            /* General */
            E.ReasonCode,
            dbo.fn_GetMappedValue('CIMS', E.Warehouse, 'HOST', 'Warehouse', 'Export', @BusinessUnit),
            E.Ownership,
            E.ExpiryDate,
            E.Lot,
            E.InventoryClass1,
            E.InventoryClass2,
            E.InventoryClass3,

            E.Weight,
            E.Volume,
            E.Length,
            E.Width,
            E.Height,
            E.InnerPacksPerLPN,
            E.UnitsPerPackage as UnitsPerInnerPack,
            E.Reference,
            E.MonetaryValue,

            /* Sales Order Header */
            E.PickTicket,
            E.SalesOrder,
            E.OrderType,
            E.SoldToId,
            E.SoldToName,
            E.ShipVia,
            E.ShipViaDescription,
            E.ShipViaSCAC,
            E.ShipFrom,
            E.CustPO,
            E.Account,
            E.AccountName,

            E.FreightCharges,
            E.FreightTerms,

            E.BillToAccount,
            E.BillToName,
            E.BillToAddress,

            /* Sales Order Detail */
            E.HostOrderLine,
            E.UnitsOrdered,
            E.UnitsAuthorizedToShip,
            E.UnitsAssigned,
            E.CustSKU,

            /* Loads */
            E.LoadNumber,
            E.ClientLoad,
            E.DesiredShipDate,
            E.ShippedDate,
            E.BoL,
            E.LoadShipVia,
            E.TrailerNumber,
            E.ProNumber,
            E.SealNumber,
            E.MasterBoL,

            /* Future Use */
            dbo.fn_GetMappedValue('CIMS', E.FromWarehouse, 'HOST', 'Warehouse', 'Export', @BusinessUnit),
            dbo.fn_GetMappedValue('CIMS', E.ToWarehouse, 'HOST', 'Warehouse', 'Export', @BusinessUnit),
            E.FromLocation,
            E.ToLocation,
            E.PrevSKU as FromSKU,
            E.SKU     as ToSKU,

            /* EDI */
            E.EDIShipmentNumber,
            E.EDITransCode,
            E.EDIFunctionalCode,

            /* ShipToAddress */
            E.ShipToId,
            E.ShipToName,
            E.ShipToAddressLine1,
            E.ShipToAddressLine2,
            E.ShipToCity,
            E.ShipToState,
            E.ShipToCountry,
            E.ShipToZip,
            E.ShipToPhoneNo,
            E.ShipToEmail,
            E.ShipToReference1,
            E.ShipToReference2,

            E.Comments,

            E.SKU_UDF1,
            E.SKU_UDF2,
            E.SKU_UDF3,
            E.SKU_UDF4,
            E.SKU_UDF5,
            E.SKU_UDF6,
            E.SKU_UDF7,
            E.SKU_UDF8,
            E.SKU_UDF9,
            E.SKU_UDF10,

            E.LPN_UDF1,
            E.LPN_UDF2,
            E.LPN_UDF3,
            E.LPN_UDF4,
            E.LPN_UDF5,

            E.LPND_UDF1,
            E.LPND_UDF2,
            E.LPND_UDF3,
            E.LPND_UDF4,
            E.LPND_UDF5,

            E.RH_UDF1,
            E.RH_UDF2,
            E.RH_UDF3,
            E.RH_UDF4,
            E.RH_UDF5,

            E.RD_UDF1,
            E.RD_UDF2,
            E.RD_UDF3,
            E.RD_UDF4,
            E.RD_UDF5,

            E.OH_UDF1,
            E.OH_UDF2,
            E.OH_UDF3,
            E.OH_UDF4,
            E.OH_UDF5,
            E.OH_UDF6,
            E.OH_UDF7,
            E.OH_UDF8,
            E.OH_UDF9,
            E.OH_UDF10,
            E.OH_UDF11,
            E.OH_UDF12,
            E.OH_UDF13,
            E.OH_UDF14,
            E.OH_UDF15,
            E.OH_UDF16,
            E.OH_UDF17,
            E.OH_UDF18,
            E.OH_UDF19,
            E.OH_UDF20,
            E.OH_UDF21,
            E.OH_UDF22,
            E.OH_UDF23,
            E.OH_UDF24,
            E.OH_UDF25,
            E.OH_UDF26,
            E.OH_UDF27,
            E.OH_UDF28,
            E.OH_UDF29,
            E.OH_UDF30,

            E.OD_UDF1,
            E.OD_UDF2,
            E.OD_UDF3,
            E.OD_UDF4,
            E.OD_UDF5,
            E.OD_UDF6,
            E.OD_UDF7,
            E.OD_UDF8,
            E.OD_UDF9,
            E.OD_UDF10,
            E.OD_UDF11,
            E.OD_UDF12,
            E.OD_UDF13,
            E.OD_UDF14,
            E.OD_UDF15,
            E.OD_UDF16,
            E.OD_UDF17,
            E.OD_UDF18,
            E.OD_UDF19,
            E.OD_UDF20,

            E.LD_UDF1,
            E.LD_UDF2,
            E.LD_UDF3,
            E.LD_UDF4,
            E.LD_UDF5,
            E.LD_UDF6,
            E.LD_UDF7,
            E.LD_UDF8,
            E.LD_UDF9,
            E.LD_UDF10,

            E.UDF1,
            E.UDF2,
            E.UDF3,
            E.UDF4,
            E.UDF5,
            E.UDF6,
            E.UDF7,
            E.UDF8,
            E.UDF9,
            E.UDF10,
            E.UDF11,
            E.UDF12,
            E.UDF13,
            E.UDF14,
            E.UDF15,
            E.UDF16,
            E.UDF17,
            E.UDF18,
            E.UDF19,
            E.UDF20,
            E.UDF21,
            E.UDF22,
            E.UDF23,
            E.UDF24,
            E.UDF25,
            E.UDF26,
            E.UDF27,
            E.UDF28,
            E.UDF29,
            E.UDF30,

            E.ShipmentId,
            E.LoadId,

            E.SourceSystem,
            E.BusinessUnit,

            E.CreatedDate,
            E.CreatedBy,
            E.ModifiedBy,
            E.RecordId as CIMSRecId
    from vwExports E
    where (ExportBatch = @BatchNo) and (Status = 'N')
    order by RecordId;

  /* Mark the Batch as processed */
  update Exports
  set status            = 'Y' /* Processed */,
      ProcessedDateTime = current_timestamp
  where (ExportBatch = @BatchNo) and (Status = 'N');
end /* pr_Exports_GetData */

Go
