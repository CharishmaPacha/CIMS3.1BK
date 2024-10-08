/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/08/25  AJM     pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Added CreatedDate field (portback from prod) (BK-904)
  2022/08/18  VS      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Added Comments field to Receive the comments from the cIMS (BK-885)
  2021/08/04  VS      pr_Exports_DE_GetExportDataFromCIMS: Made changes to improve the peformance of Exports (HA-3032)
  2021/06/12  VS      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Added Transdate (HA-2883)
  2021/03/02  PK      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Added ClientLoad (HA-2109)
  2021/02/20  PK      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Added DesiredShipDate (HA-2029)
  2021/02/01  SK      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Include new fields NumPallets, NumLPNs, NumCartons, InnerPacks, Quantity (HA-1896)
  2020/03/30  YJ      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Added Inventory Classses (HA-85)
  2020/03/24  VM      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Removed ReceiptLine, OrderLine (CIMS-2880)
  2019/11/28  RKC     pr_Exports_DE_GetExportDataFromCIMS:Added ShipToAddressLine1, ShipToAddressLine2, ShipToCity, ShipToState, ShipToCountry, ShipToZip,
  2018/03/21  SV      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData, pr_Exports_DE_GetOpenOrdersFromCIMS, pr_Exports_DE_GetOpenReceiptsFromCIMS:
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_DE_GetExportDataFromCIMS') is not null
  drop Procedure pr_Exports_DE_GetExportDataFromCIMS;
Go
/*------------------------------------------------------------------------------
  pr_Exports_DE_GetExportDataFromCIMS: This procedure will import data into exports table
    (which is in CIMSDE database) from the given XML. CIMS' jobs will prepare the
    xml for each export batch in CIMS and then invoke this procedures to insert
    the data into the CIMSDE CIMSExport table.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_DE_GetExportDataFromCIMS
  (@BatchNo             TBatch        = null,
   @xmlExportData       TXML          = null,
   @TransferToDBMethod  TControlValue = null,
   @UserId              TUserId       = null,
   @BusinessUnit        TBusinessUnit = null)
as
  declare @vReturnCode  TInteger;
begin /* pr_Exports_DE_GetExportDataFromCIMS */
  SET NOCOUNT ON;

  /* insert into host export table here from the given/resul xml.
     Even if ExportTransactions is defined of type TExportsType, we need to specify the column names explicitly as there are
     few more fields like ExchangeStatus, InsertedTime, ProcessedTime, ... added to the end of ExportTransactions def_DE_Interface */
  if (@TransferToDBMethod = 'SQLDATA')  /* If CIMSDE is in same server then will insert the data from ##ExportTransactions table */
    insert into ExportTransactions
       (RecordType, ExportBatch, TransDate, TransDateTime, TransQty, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, Description, UoM, UPC, Brand,
        LPN, LPNType, ASNCase, UCCBarcode, TrackingNo, CartonDimensions,
        NumPallets, NumLPNs, NumCartons, LPNLine, InnerPacks, Quantity, UnitsPerPackage, SerialNo,
        Pallet, Location, HostLocation,
        ReceiverNumber, ReceiverDate, ReceiverBoL, ReceiverRef1, ReceiverRef2, ReceiverRef3, ReceiverRef4, ReceiverRef5,
        ReceiptNumber, ReceiptType, VendorId,
        ReceiptVessel, ReceiptContainerNo, ReceiptContainerSize, ReceiptBillNo, ReceiptSealNo, ReceiptInvoiceNo,
        HostReceiptLine, CoO, UnitCost,
        ReasonCode, Warehouse, Ownership, ExpiryDate, Lot, InventoryClass1, InventoryClass2, InventoryClass3,
        Weight, Volume, Length, Width, Height, InnerPacksPerLPN, UnitsPerInnerPack, Reference, MonetaryValue,
        PickTicket, SalesOrder, OrderType, SoldToId, SoldToName, ShipVia, ShipViaDescription, ShipViaSCAC, ShipFrom, CustPO, Account, AccountName,
        FreightCharges, FreightTerms, BillToAccount, BillToName, BillToAddress,
        HostOrderLine, UnitsOrdered, UnitsAuthorizedToShip, UnitsAssigned, CustSKU,
        LoadNumber, ClientLoad, DesiredShipDate, ShippedDate, BoL, LoadShipVia, TrailerNumber, ProNumber, SealNumber, MasterBoL,
        FromWarehouse, ToWarehouse, FromLocation, ToLocation, FromSKU, ToSKU,
        EDIShipmentNumber, EDITransCode, EDIFunctionalCode,
        /* ShipToAddress */
        ShipToId, ShipToName, ShipToAddressLine1, ShipToAddressLine2, ShipToCity, ShipToState, ShipToCountry, ShipToZip, ShipToPhoneNo, ShipToEmail, ShipToReference1, ShipToReference2,
        Comments,
        /* UDFs */
        SKU_UDF1, SKU_UDF2, SKU_UDF3, SKU_UDF4, SKU_UDF5, SKU_UDF6, SKU_UDF7, SKU_UDF8, SKU_UDF9, SKU_UDF10,
        LPN_UDF1, LPN_UDF2, LPN_UDF3, LPN_UDF4, LPN_UDF5,
        LPND_UDF1, LPND_UDF2, LPND_UDF3, LPND_UDF4, LPND_UDF5,
        RH_UDF1, RH_UDF2, RH_UDF3, RH_UDF4, RH_UDF5,
        RD_UDF1, RD_UDF2, RD_UDF3, RD_UDF4, RD_UDF5,
        OH_UDF1, OH_UDF2, OH_UDF3, OH_UDF4, OH_UDF5, OH_UDF6, OH_UDF7, OH_UDF8, OH_UDF9, OH_UDF10,
        OH_UDF11, OH_UDF12, OH_UDF13, OH_UDF14, OH_UDF15, OH_UDF16, OH_UDF17, OH_UDF18, OH_UDF19, OH_UDF20,
        OH_UDF21, OH_UDF22, OH_UDF23, OH_UDF24, OH_UDF25, OH_UDF26, OH_UDF27, OH_UDF28, OH_UDF29, OH_UDF30,
        OD_UDF1, OD_UDF2, OD_UDF3, OD_UDF4, OD_UDF5, OD_UDF6, OD_UDF7, OD_UDF8, OD_UDF9, OD_UDF10,
        OD_UDF11, OD_UDF12, OD_UDF13, OD_UDF14, OD_UDF15, OD_UDF16, OD_UDF17, OD_UDF18, OD_UDF19, OD_UDF20,
        LD_UDF1, LD_UDF2, LD_UDF3, LD_UDF4, LD_UDF5, LD_UDF6, LD_UDF7, LD_UDF8, LD_UDF9, LD_UDF10,
        EXP_UDF1, EXP_UDF2, EXP_UDF3, EXP_UDF4, EXP_UDF5, EXP_UDF6, EXP_UDF7, EXP_UDF8, EXP_UDF9, EXP_UDF10,
        EXP_UDF11, EXP_UDF12, EXP_UDF13, EXP_UDF14, EXP_UDF15, EXP_UDF16, EXP_UDF17, EXP_UDF18, EXP_UDF19, EXP_UDF20,
        EXP_UDF21, EXP_UDF22, EXP_UDF23, EXP_UDF24, EXP_UDF25, EXP_UDF26, EXP_UDF27, EXP_UDF28, EXP_UDF29, EXP_UDF30,
        ShipmentId, LoadId, SourceSystem, BusinessUnit, CreatedDate, CreatedBy, ModifiedBy, CIMSRecId, ExchangeStatus)
      /* Get the Data from CIMS Exports table */
      select *, 'N' from ##ExportTransactions where (ExportBatch = @BatchNo);
  else
  if (@xmlExportData is not null)
    insert into ExportTransactions
       (RecordType, ExportBatch, TransDate, TransDateTime, TransQty, SKU, SKU1, SKU2, SKU3, SKU4, SKU5, Description, UoM, UPC, Brand,
        LPN, LPNType, ShipmentId, LoadId, ASNCase, UCCBarcode, TrackingNo, CartonDimensions,
        LPNLine, UnitsPerPackage, SerialNo,
        Pallet, Location, HostLocation,
        ReceiverNumber, ReceiverDate, ReceiverBoL, ReceiverRef1, ReceiverRef2, ReceiverRef3, ReceiverRef4, ReceiverRef5,
        ReceiptNumber, ReceiptType, ReceiptVessel, ReceiptContainerSize, ReceiptBillNo, ReceiptSealNo, ReceiptInvoiceNo, ReceiptContainerNo, VendorId,
        CoO, UnitCost, HostReceiptLine,
        ReasonCode, Warehouse, Ownership, SourceSystem, ExpiryDate, Lot, InventoryClass1, InventoryClass2, InventoryClass3,
        NumPallets, NumLPNs, NumCartons, InnerPacks, Quantity,
        Weight, Volume, Length, Width, Height, InnerPacksPerLPN, UnitsPerInnerPack, Reference, MonetaryValue,
        PickTicket, SalesOrder, OrderType, SoldToId, SoldToName, ShipToId, ShipToName, ShipVia, ShipViaDescription, ShipViaSCAC, ShipFrom, CustPO, Account, AccountName,
        FreightCharges, FreightTerms, BillToAccount, BillToName, BillToAddress,
        HostOrderLine, UnitsOrdered, UnitsAuthorizedToShip, UnitsAssigned, CustSKU,
        LoadNumber, ClientLoad, DesiredShipDate, ShippedDate, BoL, LoadShipVia, TrailerNumber, ProNumber, SealNumber, MasterBoL,
        FromWarehouse, ToWarehouse, FromLocation, ToLocation, FromSKU, ToSKU,
        EDIShipmentNumber, EDITransCode, EDIFunctionalCode, BusinessUnit,
        /* ShipToAddress */
        ShipToAddressLine1, ShipToAddressLine2, ShipToCity, ShipToState, ShipToCountry, ShipToZip, ShipToPhoneNo, ShipToEmail, ShipToReference1, ShipToReference2,
        /* Comments */
        Comments,
        /* UDFs */
        SKU_UDF1, SKU_UDF2, SKU_UDF3, SKU_UDF4, SKU_UDF5, SKU_UDF6, SKU_UDF7, SKU_UDF8, SKU_UDF9, SKU_UDF10,
        LPN_UDF1, LPN_UDF2, LPN_UDF3, LPN_UDF4, LPN_UDF5,
        LPND_UDF1, LPND_UDF2, LPND_UDF3, LPND_UDF4, LPND_UDF5,
        RH_UDF1, RH_UDF2, RH_UDF3, RH_UDF4, RH_UDF5,
        RD_UDF1, RD_UDF2, RD_UDF3, RD_UDF4, RD_UDF5,
        OH_UDF1, OH_UDF2, OH_UDF3, OH_UDF4, OH_UDF5, OH_UDF6, OH_UDF7, OH_UDF8, OH_UDF9, OH_UDF10,
        OH_UDF11, OH_UDF12, OH_UDF13, OH_UDF14, OH_UDF15, OH_UDF16, OH_UDF17, OH_UDF18, OH_UDF19, OH_UDF20,
        OH_UDF21, OH_UDF22, OH_UDF23, OH_UDF24, OH_UDF25, OH_UDF26, OH_UDF27, OH_UDF28, OH_UDF29, OH_UDF30,
        OD_UDF1, OD_UDF2, OD_UDF3, OD_UDF4, OD_UDF5, OD_UDF6, OD_UDF7, OD_UDF8, OD_UDF9, OD_UDF10,
        OD_UDF11, OD_UDF12, OD_UDF13, OD_UDF14, OD_UDF15, OD_UDF16, OD_UDF17, OD_UDF18, OD_UDF19, OD_UDF20,
        LD_UDF1, LD_UDF2, LD_UDF3, LD_UDF4, LD_UDF5, LD_UDF6, LD_UDF7, LD_UDF8, LD_UDF9, LD_UDF10,
        EXP_UDF1, EXP_UDF2, EXP_UDF3, EXP_UDF4, EXP_UDF5, EXP_UDF6, EXP_UDF7, EXP_UDF8, EXP_UDF9, EXP_UDF10,
        EXP_UDF11, EXP_UDF12, EXP_UDF13, EXP_UDF14, EXP_UDF15, EXP_UDF16, EXP_UDF17, EXP_UDF18, EXP_UDF19, EXP_UDF20,
        EXP_UDF21, EXP_UDF22, EXP_UDF23, EXP_UDF24, EXP_UDF25, EXP_UDF26, EXP_UDF27, EXP_UDF28, EXP_UDF29, EXP_UDF30,
        CreatedDate, CreatedBy, ModifiedBy, CIMSRecId, ExchangeStatus)
       exec pr_Exports_DE_ParseXMLData @xmlExportData;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_DE_GetExportDataFromCIMS */

Go
