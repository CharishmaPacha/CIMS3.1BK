/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2018/10/10  RIA     Added a new Pallet LPN format (OB2-651)
  2012/05/06  AY      Initial revision for TD.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  LPN Format
 -----------------------------------------------------------------------------*/
declare @LPNFormats TLookUpsTable, @LookUpCategory TCategory = 'LPNFormat';

insert into @LPNFormats
       (LookUpCode,  LookUpDescription,                  Status)
values ('LPNF1',     '<LPNType><BusinessUnit><SeqNo>',   'I'),
       ('LPNF2',     '<LPNType><SeqNo>',                 'A'),
       ('LPNF3',     '<Owner><SeqNo>',                   'I'),
       ('LPNF4',     'T<SeqNo>',                         'A')

exec pr_LookUps_Setup @LookUpCategory, @LPNFormats, @LookUpCategoryDesc = 'LPN Format';

Go

/*------------------------------------------------------------------------------
  Pallet LPN Format
 -----------------------------------------------------------------------------*/
declare @LPNFormats TLookUpsTable, @LookUpCategory TCategory = 'PalletLPNFormat';

insert into @LPNFormats
       (LookUpCode,  LookUpDescription,                  Status)
values ('PLPNF1',    '<PalletNo>-<CharSeq>',             'A'),
       ('PLPNF2',    '<PalletNo>-<SeqNo>',               'A')

exec pr_LookUps_Setup @LookUpCategory, @LPNFormats, @LookUpCategoryDesc = 'Pallet LPN Format';

Go
