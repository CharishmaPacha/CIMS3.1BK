/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2018/03/17  RT      Mapping set up for Ownership (S2G-319)
  2016/03/22  NB      Script corrections
  2016/03/17  NB      Modified Source value to match the actual values from Host
  2016/01/05  NB      Owner mapping for KUIU
  2016/01/01  NB      Changed SourceSystem from 'EDI' -> 'HOST'
  2015/12/23  NB      Initial Revision
------------------------------------------------------------------------------*/

declare @Mapping       TMapping,
        @SourceSystem  TName      = 'HOST',
        @TargetSystem  TName      = 'CIMS',
        @EntityType    TEntity    = 'Ownership',
        @Operation     TOperation = 'Import';

delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem) and
                          (EntityType = @EntityType) and (Operation = @Operation);

/*------------------------------------------------------------------------------
EDI Owners
For Ownership, the SenderId from EDI file is used.
-----------------------------------------------------------------------------*/
/*
insert into @Mapping
            (SourceValue, TargetValue)
      select 'CHROME',    'CHR'
union select 'VASYLI',    'VSL'
union select 'KUI',       'KUU'

--exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;
*/

Go
