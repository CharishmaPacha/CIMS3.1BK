/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/09/14  AY      TLabelsToPrint: Added Account
  2019/05/23  RT      TLabelsToPrint: PackageSeqNo,LPNsAssigned,OrderStatus (CID-365)
  2019/03/20  VS      Added ShipFrom Column in TLabelsToPrint (CID-188)
  2019/01/21  RT      Added LoadNumber, AddressRegion, Operation, DocSubType, CustPOsOnPallet in TLabelsToPrint (S2GMI-39)
  2019/01/21  RT      Added LoadNumber in TLabelsToPrint (S2GMI-76)
  2015/11/09  SV      TLabelsToPrint: Added Carrier field (LL-248)
  2015/08/14  AY      TLabelsToPrint: Added LPNPrintFlags, PalletPrintFlags and UDF1..5
  2015/07/23  AY      TLabelsToPrint: Added EntityType, DocumentType, BusinessUnit & Ownership
  2015/07/12  AY      TLabelsToPrint: Added LPNId, OrderId, TaskId and other fields for future use to be used in rules
  2014/06/13  SV      Added TLabelsToPrint.
  Create Type TLabelsToPrint as Table (
  Grant References on Type:: TLabelsToPrint to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TLabelsToPrint as Table (
    RecordId                 TRecordId      Identity(1,1),
    LoadNumber               TLoadNumber,
    BatchNo                  TPickBatchNo,
    PickTicket               TPickTicket,
    Pallet                   TPallet,
    LPNId                    TRecordId,
    LPN                      TLPN,
    PackageSeqNo             TInteger,
    OrderId                  TRecordId,
    CustPO                   TCustPO,
    LPNsAssigned             TCount,
    OrderStatus              TStatus,
    Account                  TCustomerId,
    SoldToId                 TCustomerId,
    ShipToId                 TShipToId,

    Carrier                  TCarrier,
    ShipFrom                 TShipFrom,
    ShipVia                  TShipvia,
    ShipToStore              TShipToStore,
    TaskId                   TRecordId,
    WaveType                 TTypeCode,     -- future use
    TaskType                 TTypeCode,     -- future use
    TaskSubType              TTypeCode,     -- future use
    LabelType                TLookUpCode,
    IsPrintable              TFlags,
    LPNPrintFlags            TPrintFlags,
    PalletPrintFlags         TPrintFlags,   -- future use
    EntityType               TTypeCode,     -- LPN, PickTicket, Wave
    AddressRegion            TAddressRegion,
    Operation                TOperation,     -- Operation to name from which the report gets printed
    DocSubType               TTypeCode,     -- PackingListType
    DocumentType             TLookUpCode,   -- PL (Packing List), SL - Shipping Label, SPL - Small Package Label, CL - ContentLabel
    DocumentName             TName,
    LabelFormatName          TName,
    BusinessUnit             TBusinessUnit,
    Ownership                TOwnership,
    /* UDFs to use if immediate need arises for more fields */
    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF
);

Grant References on Type:: TLabelsToPrint to public;

Go
