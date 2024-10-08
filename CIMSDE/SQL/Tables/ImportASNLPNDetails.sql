/*------------------------------------------------------------------------------
 Table: ImportASNLPNDetails
------------------------------------------------------------------------------*/
declare @ttImportASNLPNDetailTypes TASNLPNDetailImportType;

select * into ImportASNLPNDetails
from @ttImportASNLPNDetailTypes;

Go

alter table ImportASNLPNDetails drop column RecordId;

alter table ImportASNLPNDetails add RecordId        TRecordId identity (1,1),
                                    ExchangeStatus  TStatus,
                                    InsertedTime    TDateTime DEFAULT current_timestamp,
                                    ProcessedTime   TDateTime,
                                    Reference       TDescription,
                                    Result          TVarchar;

create index ix_ImportASNLPNDetails_ExchangeStatus    on ImportASNLPNDetails (ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);
create index ix_ImportASNLPNDetails_KeyField          on ImportASNLPNDetails (LPN, ExchangeStatus) Include (RecordId, ProcessedTime);

Go

