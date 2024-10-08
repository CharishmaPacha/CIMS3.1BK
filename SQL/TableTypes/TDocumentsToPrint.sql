/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this TableType exists. Taken here for additional fields.
  So, if there are any common fields to be added, MUST consider adding the same in Base version as well.
  *****************************************************************************

  2018/09/18  NB      TDocumentsToPrint added Weight, CartonType, ReturnTrackingNo + additional columns (CIMSV3-221)
  2018/09/07  NB      TDocumentsToPrint added with ParentRecordId, PrinterDataStream (CIMSV3-221)
  2018/08/27  NB      Added TDocumentsToPrint(CIMSV3-221)
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
if type_id('dbo.TDocumentsToPrint') is not null drop type TDocumentsToPrint;
Create Type TDocumentsToPrint as Table (
    RecordId                 TRecordId,
    ParentRecordId           TRecordId,
    WaveNo                   TWaveNo,
    PickTicket               TPickTicket,
    Pallet                   TPallet,
    LPNId                    TRecordId,
    LPN                      TLPN,
    OrderId                  TRecordId,
    CustPO                   TCustPO,
    SoldToId                 TCustomerId,
    ShipToId                 TShipToId,
    Carrier                  TCarrier,
    ShipVia                  TShipvia,
    ShipToStore              TShipToStore,
    TaskId                   TRecordId,
    WaveType                 TTypeCode, -- future use
    TaskType                 TTypeCode, -- future use
    TaskSubType              TTypeCode, -- future use
    IsPrintable              TFlags,
    CreateShipment           TFlags,
    LPNPrintFlags            TPrintFlags,
    PalletPrintFlags         TPrintFlags, -- future use
    EntityKey                TEntityKey,
    EntityType               TTypeCode,   -- LPN, PickTicket, Wave
    DocumentType             TLookUpCode, -- PL (Packing List), SL - Shipping Label, SPL - Small Package Label, CL - ContentLabel
    DocumentName             TName,       -- Generated Physical File Name pdf, image etc.,.
    DocumentFormatName       TName,    -- Bartender Template, Report Template etc.,.
    DocumentFormat           TName,    -- BT (Bartender) ZPL PDF IMAGE etc.,.
    PrinterDataStream        TVarchar,
    BusinessUnit             TBusinessUnit,
    Ownership                TOwnership,
    Description              TDescription,
    CartonType               TCartonType,
    CartonTypeRequired       TBoolean,
    Weight                   TWeight,
    WeightRequired           TBoolean,
    ReturnTrackingNo         TTrackingNo,
    ReturnTrackingNoRequired TBoolean,
    /* UDFs to use if im     mediate need arises for more fields */
    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF
);

Grant References on Type:: TDocumentsToPrint   to public;

Go
