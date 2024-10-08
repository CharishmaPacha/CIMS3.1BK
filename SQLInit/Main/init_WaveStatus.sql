/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/08  SJ      Corrected Wave status (HA-672)
  2020/05/16  TK      Corrected Descriptions (HA-543)
  2020/04/29  AY      Entity changed from Pickbatch to Wave for V3
  2018/02/15  NB      Added subset GeneratePickBatch for status to use in Generate actions (CIMSV3-153)
  2014/04/05  AY      Added new status 'Planned'
  2012/05/29  AY      Added L - Ready to Pull, E - Being Pulled statuses
  2012/01/24  PK      Added 'D' - Completed.
  2011/10/26  AY      Added 'X' - Canceled
  2011/10/12  AY      Released -> Ready To Pick
  2011/09/11  TD      Added 'U' for Paused.
  2011/07/25  YA      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* Wave Status */
/*------------------------------------------------------------------------------*/
declare @WaveStatuses TStatusesTable, @Entity TEntity = 'PickBatch';

insert into @WaveStatuses
       (StatusCode,  StatusDescription,  Status)
values ('N',         'New',              'A'),
       ('B',         'Planned',          'A'),
       ('L',         'Ready To Pull',    'I'),
       ('E',         'Released',         'A'),
       ('R',         'Ready To Pick',    'A'),
       ('P',         'Picking',          'A'),
       ('U',         'Paused',           'A'),
       ('K',         'Picked',           'A'),
       ('A',         'Packing',          'A'),
       ('C',         'Packed',           'A'),
       ('G',         'Staged',           'A'),
       ('O',         'Loaded',           'A')

insert into @WaveStatuses
       (StatusCode,  StatusDescription,  Status,  SortSeq)
values ('S',         'Shipped',          'A',     90),
       ('D',         'Completed',        'A',     91),
       ('X',         'Canceled',         'A',     92)

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @WaveStatuses; -- for V2, to be deprecated
exec pr_Statuses_Setup 'Wave', @WaveStatuses; -- for V3

Go

/*------------------------------------------------------------------------------*/
/* Wave Status for Generate Waves from Open Orders */
/*------------------------------------------------------------------------------*/
declare @WaveStatuses TStatusesTable, @Entity TEntity = 'GeneratePickBatch';

insert into @WaveStatuses
       (StatusCode,  StatusDescription,  Status)
values ('N',         'New',              'A'),
       ('E',         'Released',         'A')

/* Create the above statuses for all BusinessUnits */
exec pr_Statuses_Setup @Entity, @WaveStatuses;  -- for V2, to be deprecated
exec pr_Statuses_Setup 'GenerateWave', @WaveStatuses; -- for V3

Go
