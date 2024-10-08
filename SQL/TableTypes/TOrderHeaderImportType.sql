/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/04  LAC     TOrderHeaderImportType: Added ShipToContactPerson (BK-941)
  TOrderHeaderImportType:Added CartonGroup (S2GCA-929)
  TOrderHeaderImportType: Added ShipToAddressLine3
  2019/07/12  KBB     TOrderHeaderImportType: Added ShipCompletePercent field (CID-533)
  2018/03/28  TD      TOrderHeaderImportType:Changes to update HostNumLines (HPI-1831)
  2018/03/22  DK      TOrderHeaderImportType, TImportValidationType: Added SourceSystem (FB-1117)
  2018/03/22  DK      TOrderHeaderImportType, ROHImportType, SKUImportType: Added SourceSystem (FB-1117)
  2018/03/17  RT      TOrderHeaderImportType: Updated Status Field Type (HPI-1815)
  2018/03/16  AY      TOrderHeaderImportType: Added HostNumLines
  2017/09/06  DK      TOrderHeaderImportType: Added CarrierOptions (FB-1020)
  2017/08/23  SV      TOrderHeaderImportType: Included UDF11 to UDF30 (OB-548)
  2017/04/11  DK      TOrderHeaderImportType, TContactImportType: Added ShipToResidential, DeliveryRequirement (CIMS-1289)
  2016/04/07  AY      TOrderHeaderImportType: Removed not null constraints.
  2016/03/01  YJ      TOrderHeaderImportType: Added field ReceiptNumber, And TSKUImportType: SKUSortOrder (CIMS-780)
  2014/10/22  YJ      Added TOrderHeaderImportType
  Create Type TOrderHeaderImportType as Table (
  Grant References on Type:: TOrderHeaderImportType   to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
/* Type to use in Order Headers Import
   This table structure mimics the record structure of Order Headers import, with few additional fields
   to capture key fields, etc.,. */
Create Type TOrderHeaderImportType as Table (
    RecordId                 TRecordId      identity (1,1),
    RecordType               TRecordType,
    RecordAction             TAction,

    PickTicket               TPickTicket,
    SalesOrder               TSalesOrder,
    OrderType                TOrderType,
    HostNumLines             TCount,

    OrderDate                TDateTime,
    NB4Date                  TDateTime,
    DesiredShipDate          TDateTime,
    CancelDate               TDateTime,
    DeliveryStart            TDateTime,
    DeliveryEnd              TDateTime,

    Priority                 TPriority,
    CustPO                   TCustPO,
    Account                  TCustomerId,
    AccountName              TName,

    SoldToId                 TCustomerId,
    SoldToName               TName,
    SoldToAddressLine1       TAddressLine,
    SoldToAddressLine2       TAddressLine,
    SoldToCity               TCity,
    SoldToState              TState,
    SoldToCountry            TCountry,
    SoldToZip                TZip,
    SoldToPhoneNo            TPhoneNo,
    SoldToEmail              TEmailAddress,
    SoldToAddressReference1  TAddressLine,
    SoldToAddressReference2  TAddressLine,

    ShipToId                 TShipToId,
    ShipToName               TName,
    ShipToAddressLine1       TAddressLine,
    ShipToAddressLine2       TAddressLine,
    ShipToAddressLine3       TAddressLine,
    ShipToCity               TCity,
    ShipToState              TState,
    ShipToCountry            TCountry,
    ShipToZip                TZip,
    ShipToPhoneNo            TPhoneNo,
    ShipToEmail              TEmailAddress,
    ShipToAddressReference1  TAddressLine,
    ShipToAddressReference2  TAddressLine,
    ShipToResidential        TFlag          DEFAULT 'N',
    ShipToContactPerson      TName,

    ReturnAddrId             TReturnAddress,
    ReturnAddress            TReturnAddress,
    ReturnAddressName        TName,
    ReturnAddressLine1       TAddressLine,
    ReturnAddressLine2       TAddressLine,
    ReturnAddressCity        TCity,
    ReturnAddressState       TState,
    ReturnAddressCountry     TCountry,
    ReturnAddressZip         TZip,
    ReturnAddressPhoneNo     TPhoneNo,
    ReturnAddressEmail       TEmailAddress,
    ReturnAddressReference1  TAddressLine,
    ReturnAddressReference2  TAddressLine,

    MarkForAddress           TContactRefId,
    MarkForAddressName       TName,
    MarkForAddressLine1      TAddressLine,
    MarkForAddressLine2      TAddressLine,
    MarkForAddressCity       TCity,
    MarkForAddressState      TState,
    MarkForAddressCountry    TCountry,
    MarkForAddressZip        TZip,
    MarkForAddressPhoneNo    TPhoneNo,
    MarkForAddressEmail      TEmailAddress,
    MarkForAddressReference1 TAddressLine,
    MarkForAddressReference2 TAddressLine,

    BillToAddress            TContactRefId,
    BillToAddressName        TName,
    BillToAddressLine1       TAddressLine,
    BillToAddressLine2       TAddressLine,
    BillToAddressCity        TCity,
    BillToAddressState       TState,
    BillToAddressCountry     TCountry,
    BillToAddressZip         TZip,
    BillToAddressPhoneNo     TPhoneNo,
    BillToAddressEmail       TEmailAddress,
    BillToAddressReference1  TAddressLine,
    BillToAddressReference2  TAddressLine,

    ShipFrom                 TShipFrom,
    ShipToStore              TShipToStore,
    ShipVia                  TShipVia,
    FreightTerms             TDescription,
    BillToAccount            TBillToAccount,
    DeliveryRequirement      TDescription,
    CarrierOptions           TDescription,
    ShipCompletePercent      TPercent,

    OrderCategory1           TOrderCategory,
    OrderCategory2           TOrderCategory,
    OrderCategory3           TOrderCategory,
    OrderCategory4           TOrderCategory,
    OrderCategory5           TOrderCategory,

    Ownership                TOwnership,
    Warehouse                TWarehouse,

    ReceiptNumber            TReceiptNumber,
    Comments                 TVarchar,
    CartonGroup              TCategory,
    WaveGroup                TCategory,

    TotalTax                 TMoney,
    TotalShippingCost        TMoney,
    TotalDiscount            TMoney,
    TotalSalesAmount         TMoney,
    FreightCharges           TMoney,

    OH_UDF1                  TUDF,
    OH_UDF2                  TUDF,
    OH_UDF3                  TUDF,
    OH_UDF4                  TUDF,
    OH_UDF5                  TUDF,
    OH_UDF6                  TUDF,
    OH_UDF7                  TUDF,
    OH_UDF8                  TUDF,
    OH_UDF9                  TUDF,
    OH_UDF10                 TUDF,
    OH_UDF11                 TUDF,
    OH_UDF12                 TUDF,
    OH_UDF13                 TUDF,
    OH_UDF14                 TUDF,
    OH_UDF15                 TUDF,
    OH_UDF16                 TUDF,
    OH_UDF17                 TUDF,
    OH_UDF18                 TUDF,
    OH_UDF19                 TUDF,
    OH_UDF20                 TUDF,
    OH_UDF21                 TUDF,
    OH_UDF22                 TUDF,
    OH_UDF23                 TUDF,
    OH_UDF24                 TUDF,
    OH_UDF25                 TUDF,
    OH_UDF26                 TUDF,
    OH_UDF27                 TUDF,
    OH_UDF28                 TUDF,
    OH_UDF29                 TUDF,
    OH_UDF30                 TUDF,

    SourceSystem             TName          DEFAULT 'HOST',
    BusinessUnit             TBusinessUnit,
    CreatedDate              TDateTime      DEFAULT current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    /* Rest of the fields are for processing and not used for import */
    OrderId                  TRecordId,
    Status                   TStatus,

    InputXML                 TXML,
    ResultXML                TXML,

    HostRecId                TRecordId,

    PRIMARY KEY              (RecordId),
    Unique                   (OrderId, PickTicket, SalesOrder),
    Unique                   (RecordAction, RecordId)
);

Grant References on Type:: TOrderHeaderImportType   to public;

Go
