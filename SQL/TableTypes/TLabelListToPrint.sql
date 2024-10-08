/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/11  AY      TLabelListToPrint: Added AdditionalContent (CID-909)
  2019/08/02  AY      TLabelListToPrint & TDocumentListToPrint: Added new fields for presentation (CID-884)
  2019/07/31  AY      TLabelListToPrint: Added (CID-884)
  Create Type TLabelListToPrint as table (
  Grant References on Type:: TLabelListToPrint to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TLabelListToPrint as table (
    Entity                   TEntity,
    EntityId                 TRecordId,
    EntityKey                TEntityKey,

    LabelType                TTypeCode,     /* SPL, CL, SL */
    ImageType                TTypeCode,     /* ZPL, BTW, PNG */

    LabelFormat              TName,
    ZPLData                  TVarchar,
    AdditionalContent        TName          Default '',

    PrinterName              TName,
    PrinterPort              TName,
    PrintBatch               TInteger,      /* Group records that need to be printed together */

    NumCopies                TInteger,
    SortSeqNo                TSortSeq,
    SortOrder                TSortOrder,
    InputRecordId            TRecordId,

    Status                   TStatus        Default 'N',
    Description              TDescription,
    CreateShipment           TFlags,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    ParentRecordId           TRecordId,
    RecordId                 TRecordId      Identity(2000, 1),
    Primary Key              (RecordId),
    Unique                   (EntityId, EntityKey, RecordId)
);

Grant References on Type:: TLabelListToPrint to public;

Go
