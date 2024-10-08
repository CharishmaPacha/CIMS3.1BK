/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

/* Definitions

   EDIMap    : EDI Map is a set of process rules on how a particular EDI transaction set should be processed by CIMS.
   EDIProfile: EDI Profile is a set of EDI Maps i.e. One EDI profile can have one or more EDI Maps defined.
               For example, an EDI Profile like 'NorthBay_Generic' can have Maps defined for multiple transactions i.e. 832, 850, 940 etc.
               An EDI profile can be be a map of one EDI transaction only.
*/

/*------------------------------------------------------------------------------
 Table: EDIProfileMaps: The table defines the set of process rules to be applied to a
   particular EDI transaction set block. Each Map is part of a profile i.e. One profile
   can have definitions for one or more EDI transactions
------------------------------------------------------------------------------*/
Create Table EDIProfileMaps (
    RecordId                 TRecordId      identity (1,1) not null,

    EDIProfileName           TName          not null,
    EDITransaction           TName          not null,

    ProcessAction            TAction,
    EDISegmentId             TName,
    EDIElementId             TName,

    ProcessConditions        TQuery,

    CIMSXMLPath              TName,
    CIMSXMLField             TName,
    CIMSFieldName            TName,
    defaultValue             TDescription,

    EDIElementDesc           TDescription,  -- future use

    Status                   TStatus        not null default 'A' /* Active*/,
    SortSeq                  TSortSeq               default 0,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pk_EDIProfileMaps_RecordId PRIMARY KEY (RecordId)
);

create index ix_EDIProfileMaps_MapName           on EDIProfileMaps (EDIProfileName, EDITransaction) Include (Status, SortSeq);

Go
