/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2018/03/17  RT      Mapping set up for Warehouse (S2G-319)
  2013/08/30  TD      Initial Revision
------------------------------------------------------------------------------*/
/*--------Need to add this LookUpCategory into Init_LookUps.sql file----------*/

Go

/*------------------------------------------------------------------------------
Warehouses
 -----------------------------------------------------------------------------*/
declare @Mapping TStatusesTable, @Entity TEntity = 'Warehouse';
delete from Statuses where Entity = @Entity;

/*
declare @Mapping       TMapping,
        @SourceSystem  TName,
        @TargetSystem  TName,
        @EntityType    TName,
        @Operation     TOperation;

select  @SourceSystem = 'CIMS',
        @TargetSystem = 'CIMS',
        @EntityType   = 'Warehouse',
        @Operation    = null;

delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem)  and (EntityType = @EntityType );

insert into @Mapping (SourceValue, TargetValue)
              select  '300',       '300'
        union select  '302',       '300'
        union select  '302',       '302'
        union select  '400',       '400'
        union select  '402',       '400'
        union select  '402',       '402'

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

*/

Go
