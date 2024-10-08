/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this Table exists. Taken here for additional fields.
  So, if there are any common fields to be added, MUST consider adding the same in Base version as well.
  *****************************************************************************

  2022/07/17  VM      Moved several tables from WMS to Base (CIMSV3-2951)
  2022/02/19  AY      Added DocumentPathFileName (CIMSV3-2530)
  2022/12/12  VKN     Printers: Added SortOrder (OBV3-1525)
  2022/11/25  SK/AY   ix_PrintJobs_Status: Extended including BusinessUnit and LabelPrinterName (HA-3670)
  2022/11/06  AY      DocumentLibrary: Moved from WMS to Base (OBV3-1356)
  2022/02/02  MS      PrintJobs, PrintJobDetails: Renamed Count fields (BK-752)
  2022/01/02  MS      PrintJobDetails: Added Archived, Count4, Count5 Field (BK-156)
                      PrintJobs: Added Count4, Count5
  2021/07/18  AY      Revised ix_PrintJobs_Status (BK-263)
  2021/03/03  AY      Printers: Add Printer Make/Model/SerialNo (HA Mock GoLive)
  2021/01/22  MS      PrintJobDetails: Added new table (BK-67)
  2020/09/05  PK      PrintJobs. PrintRequests: Added Warehouse (HA-1233)
  2020/08/28  SAK     PrintJobs: Added NumLabels, NumReports, Label & Report Stock sizes,
                      PrintJobs: Added Count1 and Count2 fields (HA-887)
  2020/08/26  RV      Printers: Added ProcessGroup and PrinterStatus (HA-1324)
  2020/06/19  TK      PrintJobs: Removed not null on Status column (HA-Support)
  2020/06/04  AY      Printers: Added PrinterZPLCommands & LabelZPLCommands
  2020/05/28  VS      PrintJobs: Added ixPrintJobs_EntityId (HA-668)
  2020/05/21  AY      PrintJobs: Added Reference & UDFs
  2020/05/20  AY      PrintJobs: Added specific PrinterNames
  2020/05/18  AY      Revised PrinterType and added PrintProtocol
  2020/04/20  NB      Added Printers table(CIMSV3-221)
  2020/04/30  RV      PrintJobs: default value set to NR (HA-136)
  2020/03/23  NB      Initial revision(CIMSV3-221)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.PrintJobs') is not null
/*------------------------------------------------------------------------------
  WMS fields
------------------------------------------------------------------------------*/
alter table PrintJobs add
  Warehouse                     TWarehouse;

Go

