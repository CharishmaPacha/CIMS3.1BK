/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/14  MS      Moved PalletTypes from Base to WMS (CIMSV3-1209)
  2020/10/22  AY      Activate all used Pallet Types (HA-346)
  2020/03/22  MS      Corrections to Entity (JL-111)
  2015/08/18  YJ      Added new list of Pallet Types To Generate (ACME-139)
  2014/08/01  TK      set some of the Pallet types Status to 'View'.
  2014/07/29  TK      Made all the Pallet types Inactive except Inventory Pallet.
  2014/04/16  TK      Changes made to control data using procedure
  2013/06/04  TD      Added Putaway type Pallet.
  2012/03/27  AY      Disabled Pallet Types as appropriate for TD.
  2012/03/08  PKS     SO (Single Order), MO (Multiple Order) Pallet types added.
  2012/02/22  PKS     Added Receiving and Shipping Carts.
  2011/12/09  YA      Modified TypeDescription's for Picking and return Carts.
  2011/10/12  AY      New Pallet Types for Hanging/Flat carts.
  2010/07/28  AK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------*/
/* PALLET Type */
/*------------------------------------------------------------------------------*/
declare @PalletTypes TEntityTypesTable, @Entity TEntity = 'Pallet';

insert into @PalletTypes
       (TypeCode,  TypeDescription,         Status)
values ('I',       'Inventory',             'A'),
       ('C',       'Picking Cart',          'A'),
       ('T',       'Trolley',               'I'),
       ('H',       'Hanging Returns Cart',  'I'),
       ('F',       'Flat Returns Cart',     'I'),
       ('R',       'Receiving Pallet',      'A'),
       ('P',       'Picking Pallet',        'A'),
       ('S',       'Shipping Pallet',       'A'),
       ('SO',      'SingleOrder',           'I'),
       ('MO',      'MultipleOrders',        'I'),
       ('U',       'Putaway Pallet',        'A')

exec pr_EntityTypes_Setup @Entity, @PalletTypes;

Go

/*------------------------------------------------------------------------------*/
/* Pallet Types to Generate */
/*------------------------------------------------------------------------------*/
declare @PalletTypes TEntityTypesTable, @Entity TEntity = 'PalletTypeGen';

insert into @PalletTypes
       (TypeCode,  TypeDescription,         Status)
values ('I',       'Inventory',             'A')

exec pr_EntityTypes_Setup @Entity, @PalletTypes;

Go

/*------------------------------------------------------------------------------*/
/* Cart Types to Generate */
/*------------------------------------------------------------------------------*/
declare @PalletTypes TEntityTypesTable, @Entity TEntity = 'CartTypeGen';

insert into @PalletTypes
       (TypeCode,  TypeDescription,         Status)
values ('C',       'Picking Cart',          'A')

exec pr_EntityTypes_Setup @Entity, @PalletTypes;

Go
