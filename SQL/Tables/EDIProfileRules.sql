/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: EDIProfileRules: This table defines the criteria on which ProfileMaps would
    be used to process the EDI document. It could depend upon the file name or other
    attributes from the ISA, GS or ST segments of the document. For North Bay, we would
    determine it by the SenderId.

  Examples
    SenderId      Transaction ProfileName

    KUIU          null         NBDGeneric    -- all transactions use generic profile

    NYT           null         NYT           -- all transactions use a custom profile

    Chrome        940          NBDGeneric    -- 940 uses generic
    Chrome        null         Chrome        -- all but 940 use a custom profile

    Vionics       832          Vionics832    -- 832 uses specific profile, all others use generic profile
    Vionics       null         NBDGeneric

  What the above means is:
  For Chrome we would use the NBDGeneric profile for 940 but for all other transactions, we would use their specific maps
  For NYT for all transactions we would use NYT profile only
  For Vionics we would use their specific profile for 832, but for all others we would use Generic

  Note: The above is only an example and may not be true rules.

  The profile rules may be later expanded based upon the name of the file or the folder the files were dropped in, but
   the initial goal is only to user the Sender and Transactions from ISA and ST segments to determine the profile to use
------------------------------------------------------------------------------*/
Create Table EDIProfileRules (
    RecordId                 TRecordId      identity (1,1) not null,

    EDISenderId              TName,
    EDITransaction           TName,         /* could be null and defined at the ProcessMap level */
    EDIDirection             TName,         /* Import, Export */
    EDIProfileName           TName,

    FileName                 TName,         /* future use */
    FolderName               TName,         /* future use */
    VersionId                TRecordId,     /* future use */

    Status                   TStatus        not null default 'A' /* Active*/,
    SortSeq                  TSortSeq               default 0,

    Archived                 TFlag          default 'N',
    BusinessUnit             TBusinessUnit  not null,
    CreatedDate              TDateTime      default current_timestamp,
    ModifiedDate             TDateTime,
    CreatedBy                TUserId,
    ModifiedBy               TUserId,

    constraint pk_EDIProfileRules          PRIMARY KEY (RecordId),
    constraint uk_EDIProfileRules_SenderTS UNIQUE (EDISenderId, EDITransaction, BusinessUnit)
);

Go
