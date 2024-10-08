/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/03/02  AA      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* DevicePrinterMapping */
/*------------------------------------------------------------------------------*/
declare @DevicePrinterMapping TStatusesTable, @Entity TEntity = 'DevicePrinterMapping';
delete from Statuses where Entity = @Entity;

insert into DevicePrinterMapping (PrintRequestSource, MappedPrinterId, PrintType, SortSeq, BusinessUnit)
                          select 'POCKET_PC',         'Intermec1',     'Label',   1,       BusinessUnit from vwBusinessUnits
                union all select 'POCKET_PC',         'Zebra1',        'Label',   1,       BusinessUnit from vwBusinessUnits
                union all select 'POCKET_PC',         'PDF',           'Label',   1,       BusinessUnit from vwBusinessUnits

Go
