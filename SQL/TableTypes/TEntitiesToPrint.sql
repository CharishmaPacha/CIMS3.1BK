/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this TableType exists. Taken here for additional fields.
  So, if there are any common fields to be added, MUST consider adding the same in Base version as well.
  *****************************************************************************

  2021/04/05  AY      TEntitiesToPrint: Added SKU, SKUSortOrder, Account, AccountName fields (HA-2538)
  2021/03/08  MS      TEntitiesToPrint: Added WaveSeqNo (BK-268)
  2020/08/08  RT      TEntitiesToPrint: Included ShipToStore (HA-1193)
  2020/07/13  RV      TEntitiesToPrint: Added ShipFrom (HA-1075)
  2020/07/09  RV      TEntitiesToPrint: Added IsValidTrackingNo (HA-1123)
  2020/06/17  MS      TEntitiesToPrint: Added new fields of PrinterNames (HA-853)
  2020/05/15  AY      TEntitiesToPrint: Added Document format for caller to be able to specific the format (HA-445)
  2020/04/04  NB      Added TEntitiesToPrint(CIMSV3-221)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Every print request may be exploded into a number of documents to be printed
   for various entities. This defines the structure to hold these requests
*/
if type_id('dbo.TEntitiesToPrint') is not null drop type TEntitiesToPrint;
Create Type TEntitiesToPrint as Table (
    RecordId                 TRecordId, -- not identity?
    -- Request info
    EntityType               TEntity,
    EntityId                 TRecordId,
    EntityKey                TEntityKey,
    Operation                TOperation,
    DocumentTypes            TVarchar,
    DocumentFormat           TName,
    LabelPrinterName         TName,
    LabelPrinterName2        TName,
    ReportPrinterName        TName,
    -- LPN
    LPNId                    TRecordId,
    LPN                      TLPN,
    LPNType                  TTypeCode,
    PackageSeqNo             TInteger,
    PalletId                 TRecordId,
    LoadId                   TRecordId,
    LPNStatus                TStatus,
    --SKU
    SKU                      TSKU,
    SKUSortOrder             TSortOrder,
    -- Wave
    WaveId                   TRecordId,
    WaveType                 TTypeCode,
    WaveNo                   TWaveNo,
    -- Order
    OrderId                  TRecordId,
    PickTicket               TPickTicket,
    OrderType                TTypeCode,
    OrderStatus              TStatus,
    CustPO                   TCustPO,
    ShipToId                 TShipToId,
    SoldToId                 TCustomerId,
    ShipToStore              TShipToStore,
    Account                  TCustomerId,
    AccountName              TName,
    OrderCategory1           TCategory,
    OrderCategory2           TCategory,
    OrderCategory3           TCategory,
    OrderCategory4           TCategory,
    OrderCategory5           TCategory,
    WaveSeqNo                TInteger,
    LPNsAssigned             TCount,

    Ownership                TOwnership,
    ShipFrom                 TShipFrom,
    Warehouse                TWarehouse,
    SourceSystem             TName,
    -- ShipVia
    IsSmallPackageCarrier    TFlag,
    IsValidTrackingNo        TFlag,
    ShipVia                  TShipVia,
    Carrier                  TCarrier,
    CarrierInterface         TCarrierInterface,
    -- Processing
    SortOrder                TSortOrder,
    -- Session Context
    BusinessUnit             TBusinessUnit,
    UserId                   TUserId,
    -- UDFs
    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF
);

Grant References on Type:: TEntitiesToPrint to public;

Go
