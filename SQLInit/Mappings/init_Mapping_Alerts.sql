/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/09  MS      Initial Revision (BK-546)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  These mappings would be used in alerts to identify the email
------------------------------------------------------------------------------*/

declare @Mapping       TMapping,
        @SourceSystem  TName,
        @TargetSystem  TName,
        @EntityType    TEntity,
        @Operation     TOperation,
        @BusinessUnit  TBusinessUnit;

/******************************************************************************/
/**************************** Emails ****************************/
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Alert Inventory change Email based on SKU Category */
/*----------------------------------------------------------------------------*/
select @SourceSystem  = 'CIMS',
       @TargetSystem  = 'CIMS',
       @EntityType    = 'AlertInvChanges',
       @Operation     = null;

delete from @Mapping;
insert into @Mapping
            (SourceValue,        TargetValue,                        Status)
      select '',                 'cims.dev@cloudimsystems.com',      'A'

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation, @BusinessUnit;

Go
