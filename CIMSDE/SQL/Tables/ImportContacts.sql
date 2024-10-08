/*------------------------------------------------------------------------------
 Table: ImportContacts
------------------------------------------------------------------------------*/
declare @ttImportContacts TContactImportType;

select * into ImportContacts
from @ttImportContacts;

Go

alter table ImportContacts drop column RecordId;

alter table ImportContacts add RecordId        TRecordId identity (1,1),
                               ExchangeStatus  TStatus,
                               InsertedTime    TDateTime DEFAULT current_timestamp,
                               ProcessedTime   TDateTime,
                               Reference       TDescription,
                               Result          TVarchar;

create index ix_ImportContacts_ExchangeStatus    on ImportContacts (ExchangeStatus, BusinessUnit) Include (RecordId, ProcessedTime);
create index ix_ImportContacts_KeyField          on ImportContacts (ContactRefId, ContactType, ExchangeStatus) Include (RecordId, ProcessedTime);

Go

