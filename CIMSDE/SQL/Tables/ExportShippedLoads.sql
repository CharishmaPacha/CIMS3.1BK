/*------------------------------------------------------------------------------
 Table: ExportShippedLoads
------------------------------------------------------------------------------*/
declare @ttCIMSExportShippedLoads TShippedLoadsExportType;

select * into ExportShippedLoads
from @ttCIMSExportShippedLoads;

Go

alter table ExportShippedLoads drop column RecordId;

alter table ExportShippedLoads add RecordId        TRecordId identity (1,1),
                                   ExchangeStatus  TStatus   DEFAULT 'N',
                                   InsertedTime    TDateTime DEFAULT current_timestamp,
                                   ProcessedTime   TDateTime,
                                   Reference       TDescription,
                                   Result          TVarchar,
                                   CIMSRecId       TRecordId;

create index ix_ExportShippedLoads_ExchangeStatus     on ExportShippedLoads (ExchangeStatus, BusinessUnit) Include (RecordId);
create index ix_ExportShippedLoads_LoadPickTicket     on ExportShippedLoads (LoadNumber, PickTicket, RecordId) Include (LPN);

Go

