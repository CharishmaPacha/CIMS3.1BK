/*------------------------------------------------------------------------------
 Table: ExportCarrierTrackingInfo

 CIMSRecId and other fields are already in domain, so no need to add again here
------------------------------------------------------------------------------*/
declare @ttExportCarrierTrackingInfo TExportCarrierTrackingInfo;

select * into ExportCarrierTrackingInfo
from @ttExportCarrierTrackingInfo;

Go

alter table ExportCarrierTrackingInfo drop column RecordId;

alter table ExportCarrierTrackingInfo add RecordId        TRecordId identity (1,1),
                                          ExchangeStatus  TStatus   DEFAULT 'N',
                                          InsertedTime    TDateTime DEFAULT current_timestamp,
                                          ProcessedTime   TDateTime,
                                          Result          TVarchar;

/* Client side would be using to mark the record as processed for each record id */
create index ix_ExportCarrierTrackingInfo_RecordId        on ExportCarrierTrackingInfo (RecordId);
create index ix_ExportCarrierTrackingInfo_ExchangeStatus  on ExportCarrierTrackingInfo (ExchangeStatus, SourceSystem, BusinessUnit) Include (RecordId, TrackingNo, Carrier, PickTicket, LPN);

Go

