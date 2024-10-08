 /*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/09  SK      Initial Revision (HA-2972)
------------------------------------------------------------------------------*/

Go

declare @OperationTypes TLookUpsTable, @LookUpCategory TCategory = 'Operation';

insert into @OperationTypes
       (LookUpCode,  LookUpDescription,   Status)
values ('REC',       'Receiving',         'A'),
       ('PUT',       'Putaway',           'A'),
       ('PICK',      'Picking',           'A'),
       ('RESV',      'Reservation',       'A'),
       ('REPL',      'Replenishments',    'A'),
       ('PACK',      'Packing',           'A'),
       ('SHIP',      'Shipping',          'A'),
       ('CC',        'Cycle Count',       'A'),
       ('N',         'None',              'A')

exec pr_LookUps_Setup @LookUpCategory, @OperationTypes, @LookUpCategoryDesc = 'Warehouse Operations';

Go
