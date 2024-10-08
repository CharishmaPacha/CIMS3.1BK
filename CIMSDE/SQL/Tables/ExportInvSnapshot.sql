/*------------------------------------------------------------------------------
 Table: ExportInvSnapshot

 CIMSRecId and other fields are already in domain, so no need to add again here
------------------------------------------------------------------------------*/
declare @ttExportInvSnapshot TExportInvSnapshot;

select * into ExportInvSnapshot
from @ttExportInvSnapshot;

Go

alter table ExportInvSnapshot drop column RecordId;

alter table ExportInvSnapshot add RecordId        TRecordId identity (1,1),
                                  ExchangeStatus  TStatus   default 'N',
                                  InsertedTime    TDateTime default getdate(),
                                  ProcessedTime   TDateTime,
                                  Result          TVarchar;

/* Client side would be using to mark the record as processed for each record id */
create index ix_ExportInvSnapshot_RecordId            on ExportInvSnapshot (RecordId);
create index ix_ExportInvSnapshot_ExchangeStatus      on ExportInvSnapshot (ExchangeStatus, SKU, SourceSystem, BusinessUnit);

Go
