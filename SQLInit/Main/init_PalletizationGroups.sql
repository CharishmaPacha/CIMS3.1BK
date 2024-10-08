/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/15  AY      Palletize by Style & Color (HA GoLive)
  2020/11/15  MS      Corrections as per New Format (CIMSV3-1210)
  2020/07/10  TK      Initial Revison (HA-1031)
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
 Palletization Groups
 -----------------------------------------------------------------------------*/
declare @ttPalletizationGroups TLookUpsTable, @LookUpCategory TCategory = 'PalletizationGroups';

insert into @ttPalletizationGroups
       (LookUpCode,                    LookUpDescription,      Status)
values ('L.SKU',                       'By SKU',               'A'),
       ('L.SKU1',                      'By Style',             'A'),
       ('L.SKU1 + L.SKU2',             'By Style & Color',     'A'),
       ('L.Pallet',                    'By Pallet',            'A'),
       ('OH.PickTicket',               'By PickTicket',        'A'),
       ('OH.ShipToId',                 'By Ship To',           'A'),
       ('OH.ShipVia',                  'By Ship Via',          'A'),
       ('OH.CustPO',                   'By CustPO',            'A'),
       ('OH.CustPO + OH.ShipToStore',  'By CustPO and DC',     'A'),
       ('L.Reference',                 'By Reference',         'A'),
       ('0',                           'None',                 'A')

exec pr_LookUps_Setup @LookUpCategory, @ttPalletizationGroups, @LookUpCategoryDesc = 'Palletization Groups';

Go
