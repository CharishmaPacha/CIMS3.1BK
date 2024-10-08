/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/08/07  AY      TDocumentListToPrint: Added Action, options to save documents (CID-901)
  2019/08/02  AY      TLabelListToPrint & TDocumentListToPrint: Added new fields for presentation (CID-884)
  2019/06/27  RV      TDocumentListToPrint: Renamed from TOutboundDocsToPrint and added new fields and cleaned up TStaticDocsToPrint (CID-630)
  Create Type TDocumentListToPrint as table (
  Grant References on Type:: TDocumentListToPrint to public;
------------------------------------------------------------------------------*/

Go

/*----------------------------------------------------------------------------*/
Create Type TDocumentListToPrint as table (
    Entity                   TEntity,
    EntityId                 TRecordId,
    EntityKey                TEntityKey,

    DocType                  TTypeCode,
    DocSubType               TTypeCode,
    DocName                  TName,
    DocPath                  TName,

    NumCopies                TInteger,
    SortSeqNo                TSortSeq,
    SortOrder                TSortOrder,
    InputRecordId            TRecordId,

    Status                   TStatus        Default 'N',
    Description              TDescription,

    Action                   TFlags,        -- P-Print, S-Save, D-Download
    FilePath                 TName,
    FileName                 TName,

    UDF1                     TUDF,
    UDF2                     TUDF,
    UDF3                     TUDF,
    UDF4                     TUDF,
    UDF5                     TUDF,

    RecordId                 TRecordId      Identity(1000, 1),
    Primary Key              (RecordId),
    Unique                   (EntityId, EntityKey, RecordId)
);

Grant References on Type:: TDocumentListToPrint to public;

Go
