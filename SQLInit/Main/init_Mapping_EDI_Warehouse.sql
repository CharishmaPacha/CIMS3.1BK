/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2018/03/09  RT      Mapping set up for Warehouse (S2G-319)
  2016/04/06  NB      Added mapping for KUU, CHROME, VASYLI sender ids(NBD-353)
  2016/03/02  KL      Changed target Warehouse values..
  2016/01/04  NB      Minor changes to Vasyli specific code(NBD-59)
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
        @EntityType   = 'Warehouse',
        @Operation    = null;

/* VM_20200415: Commented below as it is deleting the 'Warehouse' entity mappings establised in int_Mapping_Warehouses.sql */ 
--delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem)  and (EntityType = @EntityType );

/*------------------------------------------------------------------------------
  EDI Owners
  The Source values are arrived at, by concatenating the SenderId + Warehouse code, and truncating for 10 chars
  Warehouse column is 10 chars
 -----------------------------------------------------------------------------*/
insert into @Mapping
            (SourceValue,   TargetValue)
      select 'CHROMENB',    '2050'
union select 'CHROME',      '2050'
union select 'VASYLINB3P',  '2030'
union select 'VASYLI',      '2030'
union select 'KUI',         '2029'
union select 'KUU',         '2029'

--exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
