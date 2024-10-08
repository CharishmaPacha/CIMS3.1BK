/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/02  AY      Initial revision (HA-2849)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* BoL FreightTerms */
/*------------------------------------------------------------------------------*/

declare @FreightTerms TLookUpsTable, @LookUpCategory TCategory = 'BoLFreightTerms';

insert into @FreightTerms
       (LookUpCode,  LookUpDescription,       Status)
values ('PREPAID',   'Pre-Paid',              'A'),
       ('SENDER',    'Sender',                'A'),
       ('COLLECT',   'Collect',               'A');

exec pr_LookUps_Setup @LookUpCategory, @FreightTerms, @LookUpCategoryDesc = 'BoL Freight Terms';

Go
