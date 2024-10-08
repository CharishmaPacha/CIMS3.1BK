/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/22  NB      Initial revision(CIMSV3-963)
------------------------------------------------------------------------------*/

Go

declare @EntityType             TName,
        @ttShippingDocEntities  TEntityValuesTable;

select @EntityType = 'ShippingDocs_EntityInfo_';

/* List all possible Shipping Doc entities */
insert into @ttShippingDocEntities(EntityType, RecordId)
      select 'LPN',    1
union select 'Pallet', 2
union select 'Order',  3
union select 'Wave',   4
union select 'Load',   5
union select 'Task',   6


delete from UIEntityInfo where (EntityType like @EntityType + '%');

insert into UIEntityInfo
            (EntityType,                  RelationType,  DisplayCaption,     ContextName,                     ContentType,  DbSourceType,  DbSource,                      FormName,                       BusinessUnit)
      select @EntityType + tt.EntityType, 'D',           null,               @EntityType + tt.EntityType,     'Html',       'P',           'pr_Entities_GetSummaryInfo',  @EntityType + tt.EntityType,    BU.BusinessUnit from @ttShippingDocEntities tt, vwBusinessUnits BU

Go
