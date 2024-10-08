/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/06  MS      Initial Revision (BK-393)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  These mappings would be used in order preprocess to identify the packing list
    format, UCC128Label Format or Contents label formats for the specific order.
    The target value would be used to build OH.PackingListFormat, OH.UCC128LabelFormat
    and OH.ContentsLabelFormats. The criteria varies by client i.e. for some customers
    the format is specified by the host and given in the interface, but for some others
    we setup the mapping which may be based upon ShipFrom, Account, SoldTo or ShipTo
    and used in preprocess.
------------------------------------------------------------------------------*/

declare @Mapping       TMapping,
        @SourceSystem  TName,
        @TargetSystem  TName,
        @EntityType    TEntity,
        @Operation     TOperation,
        @BusinessUnit  TBusinessUnit;

/******************************************************************************/
/******************************* UCC 128 Format *******************************/
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* UCC128 Format based upon SoldTo */
/*----------------------------------------------------------------------------*/
select @SourceSystem  = 'CIMS',
       @TargetSystem  = 'CIMS',
       @EntityType    = 'SoldTo',
       @Operation     = 'UCC128LabelFormat';

insert into @Mapping
            (SourceValue,        TargetValue,        Status)
      select 'ABC',              '123',              'I'

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation, @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* UCC128 Format based upon Account */
/*----------------------------------------------------------------------------*/
select @SourceSystem  = 'CIMS',
       @TargetSystem  = 'CIMS',
       @EntityType    = 'Account',
       @Operation     = 'UCC128LabelFormat';

insert into @Mapping
            (SourceValue,        TargetValue,        Status)
      select 'ABC',              '123',              'I'

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation, @BusinessUnit;

/******************************************************************************/
/*************************** Contents Label Format ****************************/
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Contents Label Format based upon SoldTo */
/*----------------------------------------------------------------------------*/
select @SourceSystem  = 'CIMS',
       @TargetSystem  = 'CIMS',
       @EntityType    = 'SoldTo',
       @Operation     = 'ContentsLabelFormat';

insert into @Mapping
            (SourceValue,        TargetValue,        Status)
      select 'ABC',              'CustSpecific',     'I'

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation, @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Contents Label Format based upon Account */
/*----------------------------------------------------------------------------*/
select @SourceSystem  = 'CIMS',
       @TargetSystem  = 'CIMS',
       @EntityType    = 'Account',
       @Operation     = 'ContentsLabelFormat';

insert into @Mapping
            (SourceValue,        TargetValue,        Status)
      select 'ABC',              'CustSpecific',     'I'

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation, @BusinessUnit;

/******************************************************************************/
/***************************** Packing List Format ****************************/
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Packing List based upon Ship From */
/*----------------------------------------------------------------------------*/
select @SourceSystem  = 'CIMS',
       @TargetSystem  = 'CIMS',
       @EntityType    = 'ShipFrom',
       @Operation     = 'PackingListFormat';

delete from @Mapping;
insert into @Mapping
            (SourceValue,        TargetValue,        Status)
      select 'ABC',              '123',              'I'

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation, @BusinessUnit;

/*----------------------------------------------------------------------------*/
/* Packing List based upon Account */
/*----------------------------------------------------------------------------*/
select @SourceSystem  = 'CIMS',
       @TargetSystem  = 'CIMS',
       @EntityType    = 'Account',
       @Operation     = 'PackingListFormat';

delete from @Mapping;
insert into @Mapping
            (SourceValue,        TargetValue,        Status)
      select 'ABC',              'AccountSpecific',  'I'

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation, @BusinessUnit;

Go
