/*------------------------------------------------------------------------------
 Table: ExportOnhandInventory
------------------------------------------------------------------------------*/
declare @ttExportOnhandInventory TOnhandInventoryExportType;

select * into ExportOnhandInventory
from @ttExportOnhandInventory;

Go

alter table ExportOnhandInventory drop column RecordId;

alter table ExportOnhandInventory add RecordId        TRecordId identity (1,1),
                                      ExchangeStatus  TStatus   DEFAULT 'N',
                                      InsertedTime    TDateTime DEFAULT current_timestamp,
                                      ProcessedTime   TDateTime,
                                      Reference       TDescription,
                                      Result          TVarchar,
                                      CIMSRecId       TRecordId;

create index ix_ExportOnhandInventory_ExchangeStatus  on ExportOnhandInventory (ExchangeStatus, BusinessUnit) Include (RecordId);
create index ix_ExportOnhandInventory_RecordType      on ExportOnhandInventory (RecordType, RecordId) Include (Lot, LPNType);

Go

