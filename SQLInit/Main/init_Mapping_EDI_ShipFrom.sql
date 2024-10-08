/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2018/03/09  RT      Mapping set up for entity ShipFrom (S2G-319)
  2016/01/05  NB      SenderId -> Owner Mapping for Chrome and Vionics
  2016/01/04  NB      Initial Revision
------------------------------------------------------------------------------*/

declare @Mapping       TMapping,
        @SourceSystem  TName,
        @TargetSystem  TName,
        @EntityType    TName,
        @Operation     TOperation;

select  @SourceSystem = 'HOST',
        @TargetSystem = 'CIMS',
        @EntityType   = 'ShipFrom',
        @Operation    = null;

delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem) and (EntityType = @EntityType) ;

/*------------------------------------------------------------------------------
EDI ShipFrom
ShipFrom information from EDI file in of freetext type. This freetext is converted to the ShipFrom Address reference while importing
using the below mepping reference
If there is no ShipFrom information in EDI, then SenderId is passed in the XML. The SenderId should be mapped to respective Owner code here
 -----------------------------------------------------------------------------*/
insert into @Mapping
            (SourceValue,            TargetValue)
      select 'NORTH BAY',            'CHR'
union select 'CHROME',               'CHR'
union select 'VIONIC GROUP LLC',     'VSL'
union select 'VASYLI',               'VSL'
union select 'KUI',                  'KUU'

--exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
