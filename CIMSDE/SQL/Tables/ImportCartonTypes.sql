/*------------------------------------------------------------------------------
 Table: ImportCartonTypes
------------------------------------------------------------------------------*/
declare @ttImportCartonTypes TCartonTypesImportType;

select * into ImportCartonTypes
from @ttImportCartonTypes;

Go

alter table ImportCartonTypes drop column RecordId;

alter table ImportCartonTypes add RecordId        TRecordId identity (1,1),
                                  ExchangeStatus  TStatus,
                                  InsertedTime    TDateTime DEFAULT current_timestamp,
                                  ProcessedTime   TDateTime,
                                  Reference       TDescription,
                                  Result          TVarchar;

create index ix_ImportCartonTypes_ExchangeStatus on ImportCartonTypes (ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);
create index ix_ImportCartonTypes_KeyField       on ImportCartonTypes (CartonType, ExchangeStatus) Include (RecordId, ProcessedTime);

Go

