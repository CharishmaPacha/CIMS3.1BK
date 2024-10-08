/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2018/03/09  RT      Mapping set up for OrderType (S2G-319)
  2016/01/01  NB      Changed SourceSystem from 'EDI' -> 'HOST'
  2015/12/23  NB      Initial Revision
------------------------------------------------------------------------------*/

declare @Mapping       TMapping,
        @SourceSystem  TName,
        @TargetSystem  TName,
        @EntityType    TName,
        @Operation     TOperation;

select  @SourceSystem = 'HOST',
        @TargetSystem = 'CIMS',
        @EntityType   = 'OrderType',
        @Operation    = null;

delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem) and (EntityType = @EntityType) ;

/*------------------------------------------------------------------------------
EDI Order Type
Order Type is passed in from EDI files as SenderId+EDIOrderType
 -----------------------------------------------------------------------------*/
insert into @Mapping
            (SourceValue, TargetValue)
      select 'CHROMEEC',  'W'
union select 'VASYLIE',   'W'

--exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
