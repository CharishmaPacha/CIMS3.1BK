/*------------------------------------------------------------------------------
 Table: ImportSKUPrePacks
------------------------------------------------------------------------------*/
declare @ttImportSKUPrePacks TSKUPrepacksImportType;

select * into ImportSKUPrePacks
from @ttImportSKUPrePacks;

Go

alter table ImportSKUPrePacks drop column RecordId;

alter table ImportSKUPrePacks add RecordId        TRecordId identity (1,1),
                                  ExchangeStatus  TStatus   DEFAULT 'N',
                                  InsertedTime    TDateTime DEFAULT current_timestamp,
                                  ProcessedTime   TDateTime,
                                  Reference       TDescription,
                                  Result          TVarchar;

create index ix_ImportSKUPrePacks_ExchangeStatus on ImportSKUPrePacks (ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);
create index ix_ImportSKUPrePacks_KeyField       on ImportSKUPrePacks (MasterSKUId, ExchangeStatus) Include (RecordId, ProcessedTime);

Go

