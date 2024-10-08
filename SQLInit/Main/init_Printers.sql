/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/24  LAG     ZebraFFI: Corrected the printer config IP (CIMSV3-2707)
  2021/01/21  MS      Setup IP for Zebra Printer & Cleanup HA Printers (BK-123)
                      Add DefaultWarehouse on printers (BK-121)
  2020/09/23  VM      Added ProcessGroup, CreatedBy (HA-1425)
  2020/06/03  AY      Setup onsite printers for testing
  2020/05/28  RV      Corrected the PDF printer config name
  2020/05/20  YJ      Initial revision.
------------------------------------------------------------------------------*/

delete from Printers;

Go

/*------------------------------------------------------------------------------*/
/* Printers */
/*------------------------------------------------------------------------------*/

insert into Printers
                (PrinterName,         PrinterDescription,       PrinterType, PrinterConfigName,              PrinterConfigIP,    PrinterPort, PrintProtocol, StockSizes, ProcessGroup,                    Status, SortSeq, Warehouse, CreatedBy, BusinessUnit )
          select 'SAMSUNG',           'Samsung Printer @ FFI',  'Report',    'FFIAllInOne01',                null,               null,        'WIN',         '4x6',      'DocumentProcessor_Instance1',   'A',    1,       null,      'cimsdba', BusinessUnit from vwBusinessUnits
union all select 'PDF',               'Print to PDF',           'Report',    'CutePDF Writer',               null,               null,        'WIN',         '4x6',      'DocumentProcessor_Instance1',   'A',    2,       null,      'cimsdba', BusinessUnit from vwBusinessUnits
union all select 'ZebraFFI',          'Zebra @FFI',             'Label',     'ZDesigner GC420t',             '183.82.99.1',      '9100',      'IP',          '4x6',      'DocumentProcessor_Instance1',   'A',    3,       null,      'cimsdba', BusinessUnit from vwBusinessUnits
union all select 'ZebraAY',           'Zebra @ AY',             'Label',     null,                           '75.136.102.194',   '9100',      'IP',          '4x6',      'DocumentProcessor_Instance1',   'A',    8,       null,      'cimsdba', BusinessUnit from vwBusinessUnits
union all select 'EpsonAY',           'Epson @ AY',             'Report',    'EPSON WF-3270 Series',         '75.136.102.194',   '9101',      'WIN',         '4x6',      'DocumentProcessor_Instance1',   'A',    9,       null,      'cimsdba', BusinessUnit from vwBusinessUnits
union all select 'SaveLabelToFile',   'Save Label to File',     'Label',     'SaveLabelToFile',              'SaveLabelToFile',  '9100',      'IP',          '4x6',      null,                            'A',    10,      null,      'cimsdba', BusinessUnit from vwBusinessUnits
union all select 'SaveReportToFile',  'Save Report to File',    'Report',    'SaveReportToFile',             'SaveReportToFile', null,        'WIN',         '8.5x11',   null,                            'A',    21,      null,      'cimsdba', BusinessUnit from vwBusinessUnits

/* Temp change: Make sure Printer should have atleast have a Warehouse,
   since we are validating WH to update PrinterNames on PrintJobs to autorelease the printjobs.
   Parmanent fix will be handled in BK-121 */
declare @vDefaultWarehouse TWarehouse;

select top 1 @vDefaultWarehouse = LookupCode
from Lookups
where (LookupCategory ='Warehouse')
order by SortSeq;

update Printers set Warehouse = @vDefaultWarehouse where Warehouse is null;

Go
