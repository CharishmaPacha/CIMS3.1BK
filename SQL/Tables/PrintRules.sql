/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/07/22  AY      PrintRules: Initial version
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: PrintRules

  Used to define rules for printing different documents for different operations
  in the system based upon several criteria. It can be better understood with examples.

   Operation   : Various operations in the system where it has to be decided what type
                 of labels or reports are to be printed. i.e. more like events or actions
                 Packing.CloseLPN, Packing.PauseLPN, Packing.CloseOrder,
                 ShipLabels.Print, Load.Ship, PrintUCCLabel, PrintUPSLabel,
                 LPNs.PrintPackingList, Orders.PrintPackingList

   SubOperation: A suboperation is also a defined operation. This is used when there needs
                 to be a recursive definition of an operation. Some examples are -
                 Packing.CloseLPN - PrintUCC128Label, PrintLPNPL (for OB)
                 Packing.CloseLPN - PrintLPNContentsLabel (for Fechheimer)

   Document
   Category    : Label (Bartender Label), Report (SSRS), Message (like sending label to Panda)

   DocumentName: Name of the Label, Report or type of Mesage to be sent.

   Document
   Options     : An XML that can be used to send additional info for the Document. For example
                 when the same Packing list is used for LPN and ORD we need to know what type
                 of PL to print.

   Criteria    : Various input fields that decide what rules apply. The individual fields
                 could be used or more criteria could be specified in the OtherCriteria XML

   Copies      : Number of copies to print. It is not necessarily a number. It could be LPNQuantity
                 for example - if we need to price stickers for each of the units in the LPN,
                 then copies will return LPNQuantity and can be substituted with the
                 desired value.

------------------------------------------------------------------------------*/
Create Table PrintRules (
    RecordId                 TRecordId      identity (1,1) not null,

    Operation                TName,
    SubOperation             TName,
    Action                   TAction,

    DocumentCategory         TCategory,     /* Label, Report, Message */
    DocumentName             TName,
    DocumentOptions          TXML,

    /* Criteria */
    SoldToId                 TCustomerId,
    ShipToId                 TShipToId,
    Carrier                  TCarrier,
    ShipVia                  TShipVia,
    Account                  TAccount,
    OrderCategory1           TCategory,
    OrderCategory2           TCategory,
    OrderCategory3           TCategory,
    OrderCategory4           TCategory,
    OrderCategory5           TCategory,

    BatchType                TTypeCode,
    OrderType                TOrderType,
    LPNType                  TTypeCode,
    PalletType               TTypeCode,
    ReceiptType              TReceiptType,

    UoM                      TUoM,
    Warehouse                TWarehouse,

    OtherCriteria            TXML,

    Copies                   TVarchar,      /* 1, 2,.. LPNQUANTITY etc. */

    Iteration                TFlags,        /* S - Stop processing rules, R - Recursively process this rule */
    Status                   TStatus        not null default 'A' /* Active*/,
    ExecuteSortSeq           TSortSeq                default 0,  /* The sequence in which the rules will be applied */
    SortSeq                  TSortSeq                default 0,  /* The sequence in which the rules will be processed */

    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pkPrintRules_RecordId PRIMARY KEY (RecordId)
);

Go
