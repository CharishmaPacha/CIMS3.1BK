/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2014/04/16  TK      Changes made to control data using procedure
  2013/08/27  TD      Initial revision for TD.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  LPN Format
 -----------------------------------------------------------------------------*/
declare @GeneratePalletOptions TLookUpsTable, @LookUpCategory TCategory = 'GeneratePalletOptions';

insert into @GeneratePalletOptions
       (LookUpCode,  LookUpDescription,       Status)
values ('I',         'Ignore',                'A'),
       ('N',         'Scan or Enter Pallet',  'A'),
       ('Y',         'Generate New Pallet',   'A')

exec pr_LookUps_Setup @LookUpCategory, @GeneratePalletOptions, @LookUpCategoryDesc = 'Generate Pallet Options';

Go
