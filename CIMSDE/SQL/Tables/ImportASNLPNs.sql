/*------------------------------------------------------------------------------
 Table: ImportASNLPNs
------------------------------------------------------------------------------*/
declare @ttImportASNLPNTypes TASNLPNImportType;

select * into ImportASNLPNs
from @ttImportASNLPNTypes;

Go

alter table ImportASNLPNs drop column RecordId;

alter table ImportASNLPNs add RecordId        TRecordId identity (1,1),
                              ExchangeStatus  TStatus   DEFAULT 'N',
                              InsertedTime    TDateTime DEFAULT current_timestamp,
                              ProcessedTime   TDateTime,
                              Reference       TDescription,
                              Result          TVarchar;

create index ix_ImportASNLPNs_ExchangeStatus     on ImportASNLPNs (ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);
create index ix_ImportASNLPNs_KeyField           on ImportASNLPNs (LPN, ExchangeStatus) Include (RecordId, ProcessedTime);

Go

