/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/09  RV      Added BulkOrderPacking (FBV3-421)
  2021/04/30  NB      Initial revision(CIMSV3-156)
------------------------------------------------------------------------------*/

Go

declare @EntityType             TName,
        @ttPackingTypeEntities  TEntityValuesTable;

select @EntityType = 'Packing_EntityInfo_';

/* List all possible Packing  entities */
insert into @ttPackingTypeEntities(EntityType, RecordId)
      select 'StandardOrderPacking',  1
union select 'BulkOrderPacking',      2

delete from UIEntityInfo where (EntityType like @EntityType + '%');

insert into UIEntityInfo
            (EntityType,                  RelationType,  DisplayCaption,     ContextName,                     ContentType,  DbSourceType,  DbSource,                      FormName,                       BusinessUnit)
      select @EntityType + tt.EntityType, 'D',           null,               @EntityType + tt.EntityType,     'Html',       'P',           'pr_Packing_GetEntityDetail',  @EntityType + tt.EntityType,    BU.BusinessUnit from @ttPackingTypeEntities tt, vwBusinessUnits BU

Go
