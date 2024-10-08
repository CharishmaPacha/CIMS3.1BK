/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/12/17  OK      Added country code for CA (OB2-2252)
  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2016/05/15  AY      Added England, Great Britian
                      (other names for GB as default for GB says United Kingdom)
  2016/05/09  NY      Added NBD specific CoO.
  2016/04/28  AY      Initial Revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Country codes variations i.e. US, USA map to US

  In some cases the same country could be referred to with a diff. name. The
  standard code and names are setup in LookUps and additional ones are setup here
------------------------------------------------------------------------------*/
declare @Mapping       TMapping,
        @SourceSystem  TName      = 'CIMS',
        @TargetSystem  TName      = 'CIMS',
        @EntityType    TEntity    = 'Country',
        @Operation     TOperation = '';

delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem) and
                          (EntityType = @EntityType) and (Operation = @Operation);

insert into @Mapping
       (SourceValue,          TargetValue    )
values ('ENGLAND',           'GB'),
       ('GREAT BRITAIN',     'GB'),
       ('USA',               'US'),
       ('US',                'US'),  --Just to convert small case to upper case
       ('CANADA',            'CA'),
       ('CAN',               'CA'),
       ('CA',                'CA')   --Just to convert small case to upper case


exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
