/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/08/25  AJM     pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Added CreatedDate field (portback from prod) (BK-904)
  2022/08/18  VS      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Added Comments field to Receive the comments from the cIMS (BK-885)
  2021/06/12  VS      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Added Transdate (HA-2883)
  2021/03/02  PK      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Added ClientLoad (HA-2109)
  2021/02/20  PK      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Added DesiredShipDate (HA-2029)
  2021/02/01  SK      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Include new fields NumPallets, NumLPNs, NumCartons, InnerPacks, Quantity (HA-1896)
  2020/03/30  YJ      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Added Inventory Classses (HA-85)
  2020/03/24  VM      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData: Removed ReceiptLine, OrderLine (CIMS-2880)
  2018/07/27  VS      pr_Exports_DE_ParseXMLData: Exports performance improvement (S2GCA-122)
  2018/05/01  PK      Migrated from onsite DB: pr_Exports_DE_GetShippedLoadsFromCIMS, pr_Exports_DE_ParseXMLData (S2G-785)
  2018/03/21  SV      pr_Exports_DE_GetExportDataFromCIMS, pr_Exports_DE_ParseXMLData, pr_Exports_DE_GetOpenOrdersFromCIMS, pr_Exports_DE_GetOpenReceiptsFromCIMS:
  2018/03/15  SV      pr_Exports_DE_ParseXMLData: Added the missing fields to send the complete exports to DE db (S2G-379)
  2018/01/31  OK      pr_Exports_DE_ParseXMLData: Changed the ExpiryDate datatype to TDate as caller sending TDate type data (S2G-187)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_DE_ParseXMLData') is not null
  drop Procedure pr_Exports_DE_ParseXMLData;
Go
/*------------------------------------------------------------------------------
  pr_Exports_DE_ParseXMLData: Parse the results returned by ImportRecords
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_DE_ParseXMLData
  (@xmlInput    TXML)
as
  declare @vReturnCode    TInteger,
          @vxmlInput      XML,
          @vXmlDocHandle  TInteger;
begin /* pr_Imports_DE_ParseResults */
  SET NOCOUNT ON;

  select @vxmlInput = convert(xml, @xmlInput);

  /* Prepare xml doc from xml input */
  exec sp_xml_preparedocument @vXmlDocHandle output, @vxmlInput;

  select *,
         'N'   as ExchangeStatus
  from OPENXML(@vXmlDocHandle, '//msg/msgBody/Record', 2)
  with (RecordType            TTypeCode         'RecordType/text()',    -- returns null when the xml doesn't contain any data
        ExportBatch           TBatch            'ExportBatch/text()',
        TransDate             TDate             'TransDate/text()',
        TransDateTime         TDateTime         'TransDateTime/text()',
        TransQty              TQuantity         'TransQty/text()',
        SKU                   TSKU              'SKU/text()',
        SKU1                  TSKU              'SKU1/text()',
        SKU2                  TSKU              'SKU2/text()',
        SKU3                  TSKU              'SKU3/text()',
        SKU4                  TSKU              'SKU4/text()',
        SKU5                  TSKU              'SKU5/text()',
        Description           TDescription      'Description/text()',
        UoM                   TUoM              'UoM/text()',
        UPC                   TUPC              'UPC/text()',
        Brand                 TDescription      'Brand/text()',
        LPN                   TLPN              'LPN/text()',
        LPNType               TTypeCode         'LPNType/text()',
        ShipmentId            TShipmentId       'ShipmentId/text()',
        LoadId                TLoadId           'LoadId/text()',
        ASNCase               TASNCase          'ASNCase/text()',
        UCCBarcode            TBarcode          'UCCBarcode/text()',
        TrackingNo            TTrackingNo       'TrackingNo/text()',
        CartonDimensions      TDescription      'CartonDimensions/text()',
        LPNLine               TDetailLine       'LPNLine/text()',
        UnitsPerPackage       TUnitsPerPack     'UnitsPerPackage/text()',
        SerialNo              TSerialNo         'SerialNo/text()',
        Pallet                TPallet           'Pallet/text()',
        Location              TLocation         'Location/text()',
        HostLocation          TLocation         'HostLocation/text()',
        ReceiverNumber        TReceiverNumber   'ReceiverNumber/text()',
        ReceiverDate          TDateTime         'ReceiverDate/text()',
        ReceiverBoL           TBoLNumber        'ReceiverBoL/text()',
        ReceiverRef1          TDescription      'ReceiverRef1/text()',
        ReceiverRef2          TDescription      'ReceiverRef2/text()',
        ReceiverRef3          TDescription      'ReceiverRef3/text()',
        ReceiverRef4          TDescription      'ReceiverRef4/text()',
        ReceiverRef5          TDescription      'ReceiverRef5/text()',
        ReceiptNumber         TReceiptNumber    'ReceiptNumber/text()',
        ReceiptType           TTypeCode         'ReceiptType/text()',
        ReceiptVessel         TVessel           'ReceiptVessel/text()',
        ReceiptContainerSize  TContainerSize    'ReceiptContainerSize/text()',
        ReceiptBillNo         TBolNumber        'ReceiptBillNo/text()',
        ReceiptSealNo         TSealNumber       'ReceiptSealNo/text()',
        ReceiptInvoiceNo      TInvoiceNo        'ReceiptInvoiceNo/text()',
        ReceiptContainerNo    TContainer        'ReceiptContainerNo/text()',
        VendorId              TVendorId         'VendorId/text()',
        CoO                   TCoO              'CoO/text()',
        UnitCost              TFloat            'UnitCost/text()',
        HostReceiptLine       THostReceiptLine  'HostReceiptLine/text()',
        ReasonCode            TReasonCode       'ReasonCode/text()',
        Warehouse             TWarehouse        'Warehouse/text()',
        Ownership             TOwnership        'Ownership/text()',
        SourceSystem          TName             'SourceSystem/text()',
        ExpiryDate            TDate             'ExpiryDate/text()',
        Lot                   TLot              'Lot/text()',
        InventoryClass1       TInventoryClass   'InventoryClass1/text()',
        InventoryClass2       TInventoryClass   'InventoryClass2/text()',
        InventoryClass3       TInventoryClass   'InventoryClass3/text()',
        NumPallets            TCount            'NumPallets/text()',
        NumLPNs               TCount            'NumLPNs/text()',
        NumCartons            TCount            'NumCartons/text()',
        InnerPacks            TInteger          'InnerPacks/text()',
        Quantity              TInteger          'Quantity/text()',
        Weight                TWeight           'Weight/text()',
        Volume                TVolume           'Volume/text()',
        Length                TLength           'Length/text()',
        Width                 TWidth            'Width/text()',
        Height                THeight           'Height/text()',
        InnerPacksPerLPN      TInteger          'InnerPacksPerLPN/text()',
        UnitsPerInnerPack     TInteger          'UnitsPerInnerPack/text()',
        Reference             TReference        'Reference/text()',
        MonetaryValue         TMonetaryValue    'MonetaryValue/text()',
        PickTicket            TPickTicket       'PickTicket/text()',
        SalesOrder            TSalesOrder       'SalesOrder/text()',
        OrderType             TTypeCode         'OrderType/text()',
        SoldToId              TCustomerId       'SoldToId/text()',
        SoldToName            TName             'SoldToName/text()',
        ShipToId              TShipToId         'ShipToId/text()',
        ShipToName            TName             'ShipToName/text()',
        ShipVia               TShipVia          'ShipVia/text()',
        ShipViaDescription    TDescription      'ShipViaDescription/text()',
        ShipViaSCAC           TTypeCode         'ShipViaSCAC/text()',
        ShipFrom              TShipFrom         'ShipFrom/text()',
        CustPO                TCustPO           'CustPO/text()',
        Account               TAccount          'Account/text()',
        AccountName           TName             'AccountName/text()',

        FreightCharges        TMoney            'FreightCharges/text()',
        FreightTerms          TDescription      'FreightTerms/text()',

        BillToAccount         TBillToAccount    'BillToAccount/text()',
        BillToName            TName             'BillToName/text()',
        BillToAddress         TContactRefId     'BillToAddress/text()',

        HostOrderLine         THostOrderLine    'HostOrderLine/text()',
        UnitsOrdered          TQuantity         'UnitsOrdered/text()',
        UnitsAuthorizedToShip TQuantity         'UnitsAuthorizedToShip/text()',
        UnitsAssigned         TQuantity         'UnitsAssigned/text()',
        CustSKU               TCustSKU          'CustSKU/text()',

        LoadNumber            TLoadNumber       'LoadNumber/text()',
        ClientLoad            TLoadNumber       'ClientLoad/text()',
        DesiredShipDate       TDateTime         'DesiredShipDate/text()',
        ShippedDate           TDateTime         'ShippedDate/text()',
        BoL                   TBoL              'BoL/text()',
        LoadShipVia           TShipVia          'LoadShipVia/text()',
        TrailerNumber         TTrailerNumber    'TrailerNumber/text()',
        ProNumber             TProNumber        'ProNumber/text()',
        SealNumber            TSealNumber       'SealNumber/text()',
        MasterBoL             TBoL              'MasterBoL/text()',

        FromWarehouse         TWarehouse        'FromWarehouse/text()',
        ToWarehouse           TWarehouse        'ToWarehouse/text()',
        FromLocation          TLocation         'FromLocation/text()',
        ToLocation            TLocation         'ToLocation/text()',
        FromSKU               TSKU              'FromSKU/text()',
        ToSKU                 TSKU              'ToSKU/text()',

        EDIShipmentNumber     TVarchar          'EDIShipmentNumber/text()',
        EDITransCode          TTypeCode         'EDITransCode/text()',
        EDIFunctionalCode     TTypeCode         'EDIFunctionalCode/text()',

        BusinessUnit          TBusinessUnit     'BusinessUnit/text()',

        /* ShipToAddress */
        ShipToAddressLine1    TAddressLine      'ShipToAddressLine1/text()',
        ShipToAddressLine2    TAddressLine      'ShipToAddressLine2/text()',
        ShipToCity            TCity             'ShipToCity/text()',
        ShipToState           TState            'ShipToState/text()',
        ShipToCountry         TCountry          'ShipToCountry/text()',
        ShipToZip             TZip              'ShipToZip/text()',
        ShipToPhoneNo         TPhoneNo          'ShipToPhoneNo/text()',
        ShipToEmail           TEmailAddress     'ShipToEmail/text()',
        ShipToReference1      TDescription      'ShipToReference1/text()',
        ShipToReference2      TDescription      'ShipToReference2/text()',
        Comments              TVarchar          'Comments/text()',

        SKU_UDF1              TUDF              'SKU_UDF1/text()',
        SKU_UDF2              TUDF              'SKU_UDF2/text()',
        SKU_UDF3              TUDF              'SKU_UDF3/text()',
        SKU_UDF4              TUDF              'SKU_UDF4/text()',
        SKU_UDF5              TUDF              'SKU_UDF5/text()',
        SKU_UDF6              TUDF              'SKU_UDF6/text()',
        SKU_UDF7              TUDF              'SKU_UDF7/text()',
        SKU_UDF8              TUDF              'SKU_UDF8/text()',
        SKU_UDF9              TUDF              'SKU_UDF9/text()',
        SKU_UDF10             TUDF              'SKU_UDF10/text()',

        LPN_UDF1              TUDF              'LPN_UDF1/text()',
        LPN_UDF2              TUDF              'LPN_UDF2/text()',
        LPN_UDF3              TUDF              'LPN_UDF3/text()',
        LPN_UDF4              TUDF              'LPN_UDF4/text()',
        LPN_UDF5              TUDF              'LPN_UDF5/text()',

        LPND_UDF1             TUDF              'LPND_UDF1/text()',
        LPND_UDF2             TUDF              'LPND_UDF2/text()',
        LPND_UDF3             TUDF              'LPND_UDF3/text()',
        LPND_UDF4             TUDF              'LPND_UDF4/text()',
        LPND_UDF5             TUDF              'LPND_UDF5/text()',

        RH_UDF1               TUDF              'RH_UDF1/text()',
        RH_UDF2               TUDF              'RH_UDF2/text()',
        RH_UDF3               TUDF              'RH_UDF3/text()',
        RH_UDF4               TUDF              'RH_UDF4/text()',
        RH_UDF5               TUDF              'RH_UDF5/text()',

        RD_UDF1               TUDF              'RD_UDF1/text()',
        RD_UDF2               TUDF              'RD_UDF2/text()',
        RD_UDF3               TUDF              'RD_UDF3/text()',
        RD_UDF4               TUDF              'RD_UDF4/text()',
        RD_UDF5               TUDF              'RD_UDF5/text()',

        OH_UDF1               TUDF              'OH_UDF1/text()',
        OH_UDF2               TUDF              'OH_UDF2/text()',
        OH_UDF3               TUDF              'OH_UDF3/text()',
        OH_UDF4               TUDF              'OH_UDF4/text()',
        OH_UDF5               TUDF              'OH_UDF5/text()',
        OH_UDF6               TUDF              'OH_UDF6/text()',
        OH_UDF7               TUDF              'OH_UDF7/text()',
        OH_UDF8               TUDF              'OH_UDF8/text()',
        OH_UDF9               TUDF              'OH_UDF9/text()',
        OH_UDF10              TUDF              'OH_UDF10/text()',
        OH_UDF11              TUDF              'OH_UDF11/text()',
        OH_UDF12              TUDF              'OH_UDF12/text()',
        OH_UDF13              TUDF              'OH_UDF13/text()',
        OH_UDF14              TUDF              'OH_UDF14/text()',
        OH_UDF15              TUDF              'OH_UDF15/text()',
        OH_UDF16              TUDF              'OH_UDF16/text()',
        OH_UDF17              TUDF              'OH_UDF17/text()',
        OH_UDF18              TUDF              'OH_UDF18/text()',
        OH_UDF19              TUDF              'OH_UDF19/text()',
        OH_UDF20              TUDF              'OH_UDF20/text()',
        OH_UDF21              TUDF              'OH_UDF21/text()',
        OH_UDF22              TUDF              'OH_UDF22/text()',
        OH_UDF23              TUDF              'OH_UDF23/text()',
        OH_UDF24              TUDF              'OH_UDF24/text()',
        OH_UDF25              TUDF              'OH_UDF25/text()',
        OH_UDF26              TUDF              'OH_UDF26/text()',
        OH_UDF27              TUDF              'OH_UDF27/text()',
        OH_UDF28              TUDF              'OH_UDF28/text()',
        OH_UDF29              TUDF              'OH_UDF29/text()',
        OH_UDF30              TUDF              'OH_UDF30/text()',

        OD_UDF1               TUDF              'OD_UDF1/text()',
        OD_UDF2               TUDF              'OD_UDF2/text()',
        OD_UDF3               TUDF              'OD_UDF3/text()',
        OD_UDF4               TUDF              'OD_UDF4/text()',
        OD_UDF5               TUDF              'OD_UDF5/text()',
        OD_UDF6               TUDF              'OD_UDF6/text()',
        OD_UDF7               TUDF              'OD_UDF7/text()',
        OD_UDF8               TUDF              'OD_UDF8/text()',
        OD_UDF9               TUDF              'OD_UDF9/text()',
        OD_UDF10              TUDF              'OD_UDF10/text()',
        OD_UDF11              TUDF              'OD_UDF11/text()',
        OD_UDF12              TUDF              'OD_UDF12/text()',
        OD_UDF13              TUDF              'OD_UDF13/text()',
        OD_UDF14              TUDF              'OD_UDF14/text()',
        OD_UDF15              TUDF              'OD_UDF15/text()',
        OD_UDF16              TUDF              'OD_UDF16/text()',
        OD_UDF17              TUDF              'OD_UDF17/text()',
        OD_UDF18              TUDF              'OD_UDF18/text()',
        OD_UDF19              TUDF              'OD_UDF19/text()',
        OD_UDF20              TUDF              'OD_UDF20/text()',

        LD_UDF1               TUDF              'LD_UDF1/text()',
        LD_UDF2               TUDF              'LD_UDF2/text()',
        LD_UDF3               TUDF              'LD_UDF3/text()',
        LD_UDF4               TUDF              'LD_UDF4/text()',
        LD_UDF5               TUDF              'LD_UDF5/text()',
        LD_UDF6               TUDF              'LD_UDF6/text()',
        LD_UDF7               TUDF              'LD_UDF7/text()',
        LD_UDF8               TUDF              'LD_UDF8/text()',
        LD_UDF9               TUDF              'LD_UDF9/text()',
        LD_UDF10              TUDF              'LD_UDF10/text()',

        UDF1                  TUDF              'UDF1/text()',
        UDF2                  TUDF              'UDF2/text()',
        UDF3                  TUDF              'UDF3/text()',
        UDF4                  TUDF              'UDF4/text()',
        UDF5                  TUDF              'UDF5/text()',
        UDF6                  TUDF              'UDF6/text()',
        UDF7                  TUDF              'UDF7/text()',
        UDF8                  TUDF              'UDF8/text()',
        UDF9                  TUDF              'UDF9/text()',
        UDF10                 TUDF              'UDF10/text()',
        UDF11                 TUDF              'UDF11/text()',
        UDF12                 TUDF              'UDF12/text()',
        UDF13                 TUDF              'UDF13/text()',
        UDF14                 TUDF              'UDF14/text()',
        UDF15                 TUDF              'UDF15/text()',
        UDF16                 TUDF              'UDF16/text()',
        UDF17                 TUDF              'UDF17/text()',
        UDF18                 TUDF              'UDF18/text()',
        UDF19                 TUDF              'UDF19/text()',
        UDF20                 TUDF              'UDF20/text()',
        UDF21                 TUDF              'UDF21/text()',
        UDF22                 TUDF              'UDF22/text()',
        UDF23                 TUDF              'UDF23/text()',
        UDF24                 TUDF              'UDF24/text()',
        UDF25                 TUDF              'UDF25/text()',
        UDF26                 TUDF              'UDF26/text()',
        UDF27                 TUDF              'UDF27/text()',
        UDF28                 TUDF              'UDF28/text()',
        UDF29                 TUDF              'UDF29/text()',
        UDF30                 TUDF              'UDF30/text()',

        CreatedDate           TUserId           'CreatedDate/text()',
        CreatedBy             TUserId           'CreatedBy/text()',
        ModifiedBy            TUserId           'ModifiedBy/text()',
        CIMSRecId             TRecordId);

  exec sp_xml_removedocument @vXmlDocHandle;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_DE_ParseXMLData */

Go
