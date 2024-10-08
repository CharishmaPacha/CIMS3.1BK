/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/09  MS      Bug fix not to remove all mappings of Warheouse Entity (BK-584)
  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2018/03/17  RT      Mapping set up for Warehouse (S2G-319)
  2015/08/24  OK      Initial Revision (FB-310).
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
Warehouse -> DropLocation
 -----------------------------------------------------------------------------*/
declare @Mapping       TMapping,
        @SourceSystem  TName      = 'CIMS',
        @TargetSystem  TName      = 'CIMS',
        @EntityType    TEntity    = 'Warehouse',
        @Operation     TOperation = 'DropLocation';

delete from @Mapping where EntityType = @EntityType;


insert into @Mapping
       (SourceValue, TargetSystem)
values ('B1',        'B1'),
       ('03',        '03'),
       ('03',        '06'),
       ('03',        'SE'),
       ('06',        '03'),
       ('06',        '06'),
       ('06',        'SE'),
       ('SE',        '03'),
       ('SE',        '06'),
       ('SE',        'SE');

--exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
