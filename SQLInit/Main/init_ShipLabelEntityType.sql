/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/10  AJM     Corrections as per New Standards (CIMSV3-1273)
  2014/04/16  TK      Changes made to control data using procedure
  2011/08/31  NB      Initial Revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* ShipLabel Types */
/*------------------------------------------------------------------------------*/
declare @ShipLabelEntityTypes TEntityTypesTable, @Entity TEntity = 'ShipLabelEntity';

insert into @ShipLabelEntityTypes
       (TypeCode,  TypeDescription,  Status)
values ('L',       'LPN',            'A'),
       ('P',       'Pallet',         'I')

exec pr_EntityTypes_Setup @Entity, @ShipLabelEntityTypes;

Go
