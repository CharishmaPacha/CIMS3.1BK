/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2020/01/11  RT      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
 /* Pallet Size */
/*------------------------------------------------------------------------------*/
declare @PalletSizeLookUps TLookUpsTable, @LookUpCategory TCategory = 'PalletSize';

insert into @PalletSizeLookUps
       (LookUpCode,  LookUpDescription,         Status)
values ('RS',        'Regular Size',            'A'),
       ('OS',        'Oversize' ,               'A')

exec pr_LookUps_Setup @LookUpCategory, @PalletSizeLookUps, @LookUpCategoryDesc = 'Pallet Size';

Go
