/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/05  NB      Added PlaceHolder Fields ReportFileName and DownloadReportFile (CIMSV3-1412)
  2021/02/18  MS      Added NumDetails, NumOrders, NumCartons (BK-156)
  2020/09/07  PK      Added Count1, Count2, LabelStockSizes, ReportStockSizes (HA-1017)
  2020/09/05  PK      Added Warehouse (HA-1233)
  2020/07/07  NB      Renamed Notifications to PrintJobNotications(CIMSV3-886)
  2020/06/25  MRK     Print Jobs: Show descriptions of the printer rather than names (HA-991)
  2020/06/17  SAK     Added Fields NumOrders, LPNsAssigned, NumLabels, NumReports and WaveType for Reference2 (HA-887)
  2020/05/22  MS      Initial revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPrintJobs') is not null
  drop View dbo.vwPrintJobs;
Go

Create View dbo.vwPrintJobs (
  PrintJobId,

  PrintRequestId,
  PrintJobType,
  PrintJobOperation,
  PrintJobStatus,
  PrintJobStatusDesc,

  EntityType,
  EntityId,
  EntityKey,

  NumDetails,

  PrintJobReference1,
  PrintJobReference2,
  PrintJobReference3,

  WaveType,
  WaveTypeDesc,
  WaveNo,
  NumOrders,
  NumCartons,

  LabelPrinterName,
  LabelPrinterDesc,
  LabelPrinterName2,
  LabelPrinter2Desc,
  ReportPrinterName,
  ReportPrinterDesc,
  PrintJobInfo,
  PrintJobNotifications,
  PrintBatchNo,
  PrintOrder,
  ProcessInstance,

  NumLabels,
  NumReports,
  Count1,
  Count2,
  LabelStockSizes,
  ReportStockSizes,
  TotalDocuments,
  StartDateTime,
  EndDateTime,
  EstimatedCompletionTime,
  ActualCompletionTime,

  Warehouse,

  PJ_UDF1,
  PJ_UDF2,
  PJ_UDF3,
  PJ_UDF4,
  PJ_UDF5,

  DownloadLabelFile,
  ReportFileName,
  DownloadReportFile,

  JobDate,
  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  PJ.PrintJobId,

  PJ.PrintRequestId,
  PJ.PrintJobType,
  PJ.PrintJobOperation,
  PJ.PrintJobStatus,
  ST.StatusDescription,

  PJ.EntityType,
  PJ.EntityId,
  PJ.EntityKey,

  PJ.NumDetails,

  PJ.Reference1,
  PJ.Reference2,
  PJ.Reference3,

  W.WaveType,
  WT.TypeDescription,
  W.WaveNo,
  PJ.NumOrders, /* Num Orders */
  PJ.NumCartons, /* Num Cartons */

  PJ.LabelPrinterName,
  LP1.PrinterDescription,
  PJ.LabelPrinterName2,
  LP2.PrinterDescription,
  PJ.ReportPrinterName,
  RP.PrinterDescription,

  PJ.PrintJobInfo,
  PJ.Notifications,
  PJ.PrintBatchNo,
  PJ.PrintOrder,
  PJ.ProcessInstance,

  PJ.NumLabels,
  PJ.NumReports,
  PJ.Count1,
  PJ.Count2,
  PJ.LabelStockSizes,
  PJ.ReportStockSizes,
  PJ.TotalDocuments,
  PJ.StartDateTime,
  PJ.EndDateTime,
  PJ.EstimatedCompletionTime,
  PJ.ActualCompletionTime,

  PJ.Warehouse,

  PJ.PJ_UDF1,
  PJ.PJ_UDF2,
  PJ.PJ_UDF3,
  PJ.PJ_UDF4,
  PJ.PJ_UDF5,

  case when (PJ.PJ_UDF1 is not null) then
    reverse(left(reverse(PJ.PJ_UDF1), charindex('\', reverse(PJ.PJ_UDF1)) -1))
  else PJ.PJ_UDF1 
  end, -- DownloadLabelFile    
  case when (PJ.PJ_UDF2 is not null) then
    reverse(left(reverse(PJ.PJ_UDF2), charindex('\', reverse(PJ.PJ_UDF2)) -1))
    else PJ.PJ_UDF2 
  end,  -- ReportFileName
  case when (PJ.PJ_UDF2 is not null) then
    reverse(left(reverse(PJ.PJ_UDF2), charindex('\', reverse(PJ.PJ_UDF2)) -1))
    else PJ.PJ_UDF2 
  end,  -- DownloadReportFile
  
  PJ.JobDate,
  PJ.Archived,
  PJ.BusinessUnit,
  PJ.CreatedDate,
  PJ.ModifiedDate,
  PJ.CreatedBy,
  PJ.ModifiedBy
from
  PrintJobs PJ
    left outer join Printers      LP1 on (LP1.Printername  = PJ.LabelPrinterName)
    left outer join Printers      LP2 on (LP2.Printername  = PJ.LabelPrinterName2)
    left outer join Printers      RP  on (RP.Printername   = PJ.ReportPrinterName)
    left outer join Statuses      ST  on (ST.StatusCode    = PJ.PrintJobStatus) and
                                         (ST.Entity        = 'PrintJob'       ) and
                                         (ST.BusinessUnit  = PJ.BusinessUnit  )
    left outer join Waves         W   on (PJ.EntityId      = W.WaveId) and (PJ.EntityType = 'Wave')
    left outer join Tasks         T   on (PJ.EntityId      = T.TaskId) and (PJ.EntityType = 'Task')
    left outer join EntityTypes   WT  on (W.BatchType      = WT.TypeCode    ) and
                                         (WT.Entity        = 'Wave'         ) and
                                         (WT.BusinessUnit  = W.BusinessUnit )

Go
