/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2018/03/09  RT      Mapping set up for Locations (S2G-319)
  2014/07/09  NY      Initial Revision
------------------------------------------------------------------------------*/
/*--------Need to add this LookUpCategory into Init_LookUps.sql file----------*/

declare @Mapping       TMapping,
        @SourceSystem  TName,
        @TargetSystem  TName,
        @EntityType    TName,
        @Operation     TOperation;

select  @SourceSystem = 'CIMS',
        @TargetSystem = 'NS',
        @EntityType   = 'Location',
        @Operation    = null;

delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem)  and (EntityType = @EntityType );

/*------------------------------------------------------------------------------
Locations
 -----------------------------------------------------------------------------*/
insert into @Mapping (SourceValue,  TargetValue)
              select  '100',        '100'
        union select  '50Hilton',   '50Hilton'
        union select  'FLOOR',      'FLOOR'
        union select  'FLOO',       'FLOO'
        union select  'Amazon',     'Amazon'
        union select  'Capacity',   'Capacity'
        union select  'UnitStorage','UnitStorage'


--exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
