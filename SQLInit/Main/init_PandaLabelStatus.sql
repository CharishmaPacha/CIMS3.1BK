/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/10/23  VM      Panda Label Induction Status:
                       Description changed to be appropriate for 'I' from 'Ignored' to 'Inducted'
  2012/04/23  AA      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* PandaLabelExport Status */
/*------------------------------------------------------------------------------*/
declare @LabelExportStatuses TStatusesTable, @Entity TEntity = 'PandaLabelExport';

insert into @LabelExportStatuses
       (StatusCode,  StatusDescription,  SortSeq,  Status)
values ('N',         'New',              1,        'A'),
       ('L',         'Label Generated',  2,        'A'),
       ('E',         'Exported',         3,        'A'),
       ('P',         'Processed',        4,        'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @LabelExportStatuses;

Go

/*------------------------------------------------------------------------------*/
/* PandaLabelConfirm Status */
/*------------------------------------------------------------------------------*/
declare @LabelConfirmStatuses TStatusesTable, @Entity TEntity = 'PandaLabelConfirm';

insert into @LabelConfirmStatuses
               (StatusCode,  StatusDescription,                   SortSeq,  Status)
--      select  'I',         'Invalid print data stream',         1,        'A'
--union select  'L',         'Invalid Label',                     2,        'A'
--union select  'T',         'Passed through with out printing',  3,        'A'
--union select  'P',         'Printed',                           4,        'A'
  values       ('V',         'Verified',                          1,        'A'),
               ('X',         'Not verified',                      2,        'A'),
               ('P',         'Processed',                         3,        'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @LabelConfirmStatuses;

Go

/*------------------------------------------------------------------------------*/
/* PandaLabelInduction Status */
/*------------------------------------------------------------------------------*/
declare @LabelInductionStatuses TStatusesTable, @Entity TEntity = 'PandaLabelInduction';

insert into @LabelInductionStatuses
       (StatusCode,  StatusDescription,   SortSeq,  Status)
values ('A',         'Arrived at PandA',  1,        'A'),
       ('P',         'Processed',         2,        'A'),
       ('I',         'Inducted',          3,        'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @LabelInductionStatuses;

Go
