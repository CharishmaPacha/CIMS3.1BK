/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2016/03/28  KL      Split the pallet formats into two categories (CIMS-810).
  2014/04/16  TK      Changes made to control data using procedure
  2012/05/06  TD      Initial revision for TD.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Pallet Formats
------------------------------------------------------------------------------*/
declare @PalletFormats TLookUpsTable, @LookUpCategory TCategory = 'PalletFormat_I';

insert into @PalletFormats
       (LookUpCode,  LookUpDescription,  Status)
values ('PFI1',       'P<SeqNo>',         'A'),
       ('PFI2',       'PA<SeqNo>',        'A'),
       ('PFI3',       '<SeqNo>',          'A')

exec pr_LookUps_Setup @LookUpCategory, @PalletFormats, @LookUpCategoryDesc =  'Pallet Format for Inventory';

Go

/*------------------------------------------------------------------------------
  Cart Formats
 -----------------------------------------------------------------------------*/
declare @PalletFormats TLookUpsTable, @LookUpCategory TCategory = 'PalletFormat_C';

insert into @PalletFormats
       (LookUpCode,  LookUpDescription,  Status)
values ('PFC1',      'C<SeqNo>',         'A'),
       ('PFC2',      'T<SeqNo>',         'A')

exec pr_LookUps_Setup @LookUpCategory, @PalletFormats, @LookUpCategoryDesc = 'Pallet Format for Cart';

Go
