/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2018/03/09  RT      Mapping set up for entity 3rdPartySenderId (S2G-319)
  2016/02/16  NB      Initial Revision
------------------------------------------------------------------------------*/

declare @Mapping       TMapping,
        @SourceSystem  TName,
        @TargetSystem  TName,
        @EntityType    TName,
        @Operation     TOperation;

select  @SourceSystem = 'CIMS',
        @TargetSystem = 'HOST',
        @EntityType   = '3rdPartySenderId',
        @Operation    = null;

delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem) and (EntityType = @EntityType) ;

/*------------------------------------------------------------------------------
 -----------------------------------------------------------------------------*/
insert into @Mapping
            (SourceValue, TargetValue)
      select 'CHR',       '7074529984'
union select 'VSL',       '7074529984'
union select 'KUU',       '7074529984'

--exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
