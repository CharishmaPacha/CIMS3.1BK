/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/02/19  TD      Added ImportResults (CIMS-1685)
------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
 Table: ImportResults
------------------------------------------------------------------------------*/
 Create Table ImportResults (
    RecordId                      TRecordId identity (1,1) not null,
    Entity                        TEntity,
    Result                        varchar(max),

    BusinessUnit                  TBusinessUnit,
    CreatedDate                   TDateTime     DEFAULT current_timestamp,
    ModifiedDate                  TDateTime,
    CreatedBy                     TUserId,
    ModifiedBy                    TUserId,

    constraint pkImportResults_RecordId PRIMARY KEY (RecordId)
);

create index ix_ImportResults_RecordId           on ImportResults (RecordId) Include (Entity);

Go
