/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/08/20  AY      Setup Reason codes for PT Status (S2GCA-200)
  2018/04/09  SV      Added RC_CancelPickTicket (HPI-1842)
  2017/11/17  DK      Added 'Refused delivery' reason code under Returns (S2G-9)
  2017/06/29 LRA/DK   Migrated the changes from onsite (CIMS-1437)
  2016/09/07  AY      Change reverse receipt reasons (HPI-587)
  2016/05/29  AY      Changed Explode-Prepack reason code to a number to am internal code.
                      Added 132 for Transfer Inventory when it is not done by a user.
  2016/04/01  DK      RC_TransferInv: Added new ReasonCodes for Transfer Inventory (FB-646).
  2016/02/16  NY      RC_LPNReverse: New reason codes
  2016/01/08  DK      RC_Returns: Added new ReasonCodes for Returns (FB-596).
  2015/10/27  AY      Added new reason code 121 for Short Pick of units
  2015/09/14  YJ      RC_Disposition_BackToInv, RC_Disposition_Scrap: WIP new reason codes for these categories
  2015/03/19  DK      RC_ExplodePrepack:  New reason codes.
  2014/12/24  VM      RC_LPNCreateInv: Added '999-Initial Inventory'
  2014/04/16  TK      Changes made to control data using procedure
  2013/11/22  PK      RC_CycleCount: new reason codes
  2013/10/08  AY      RC_LPNVoid: New reason codes
  2103/05/22  TD      RC_LPNCreateInv: Added Returned Inventory.
  2012/10/11  VM      RC_LPNCreateInv: Corrected reason codes to be unique
  2012/10/11  AY      RC_LPNCreateInv - New reasons for Create Inv LPNs
  2012/05/24  AY      Initial revision.
------------------------------------------------------------------------------*/

/*--------Need to add this LookUpCategory into Init_LookUps.sql file----------*/

/* ReasonCodes less than 200 are internal to the system */

Go

/*------------------------------------------------------------------------------
  ReasonCodes for Cycle Count
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory1 TCategory = 'RC_CycleCount',
                                    @LookUpCategory2 TCategory = 'RC_ShortPick';
delete from LookUps where LookUpCategory in (@LookUpCategory1, @LookUpCategory2);

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,            Status)
values ('100',       'Cycle Count Adjustment',     'A'),
       ('101',       'Cycle Count - Lost LPN',     'A'),
       ('102',       'Cycle Count - Move LPN',     'A'),

       ('120',       'Short Pick LPN/Pallet',      'A'),
       ('121',       'Short Pick Units',           'A')

exec pr_LookUps_Setup @LookUpCategory1, @ReasonCodes;
exec pr_LookUps_Setup @LookUpCategory2, @ReasonCodes;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for ExplodePrepack
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory TCategory = 'RC_ExplodePrepack';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,            Status)
values ('131',       'Explode Prepack',            'A')

exec pr_LookUps_Setup @LookUpCategory, @ReasonCodes;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for PT Status
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory TCategory = 'RC_PickTicketStatus';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,            Status)
values ('140',       'Wave Released',              'A'),
       ('141',       'Order Unwaved',              'A')

exec pr_LookUps_Setup @LookUpCategory, @ReasonCodes;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for LPN Adjustment - Generic for both increment/decrement
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory TCategory = 'RC_LPNAdjust';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,            Status)
values ('200',       'Product Damaged',            'A'),
       ('201',       'Packed Incorrectly',         'A'),
       ('202',       'Cannot find Units',          'A'),
       ('203',       'Found Inventory',            'A'),
       ('204',       'New Inventory in Picklane',  'A')

exec pr_LookUps_Setup @LookUpCategory, @ReasonCodes;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for LPN Adjustment - For increment
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory TCategory = 'RC_LPNAdjust+';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,            Status)
values ('220',       'Packed Incorrectly',         'A'),
       ('221',       'Found Inventory',            'A'),
       ('222',       'New Inventory',              'A'),
       ('223',       'New Inventory in Picklane',  'I')

exec pr_LookUps_Setup @LookUpCategory, @ReasonCodes;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for LPN Adjustment - For decrement
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory TCategory = 'RC_LPNAdjust-';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,            Status)
values ('240',       'Product Damaged',            'A'),
       ('241',       'Packed Incorrectly',         'A'),
       ('242',       'Cannot find Units',          'A')

exec pr_LookUps_Setup @LookUpCategory, @ReasonCodes;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for Location Adjustment - Generic for both increment/decrement
 -----------------------------------------------------------------------------*/
declare @Reasons TLookUpsTable, @LookUpCategory TCategory = 'RC_LocAdjust';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @Reasons
       (LookUpCode,    LookUpDescription,                          Status)
values ('250',         'Product Damaged',                          'A'),
       ('251',         'Picking Error/ Inner Pack Mispick',        'A'),
       ('252',         'Theft',                                    'A'),
       ('253',         'In Office Use',                            'A'),
       ('254',         'Physical Count',                           'A')

exec pr_LookUps_Setup @LookUpCategory, @Reasons;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for Create Inv LPNs
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory TCategory = 'RC_LPNCreateInv';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,            Status)
values ('260',       'Received Product',           'A'),
       ('261',       'Returned Inventory',         'A'),
       ('262',       'Found Inventory',            'A'),
       ('263',       'Relabel: Packed Incorrectly','A'),
       ('999',       'Initial Inventory',          'A')

exec pr_LookUps_Setup @LookUpCategory, @ReasonCodes;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for Void LPNs
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory TCategory = 'RC_LPNVoid';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,            Status)
values ('280',       'Void Inventory',             'A')

exec pr_LookUps_Setup @LookUpCategory, @ReasonCodes;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for Cancel Pick Tickets
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory TCategory = 'RC_CancelPickTicket';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,            Status)
values ('900',       'System Cancelled',           'I'),
       ('901',       'Cancel',                     'A'),
       ('902',       'Inv Short',                  'A')

exec pr_LookUps_Setup @LookUpCategory, @ReasonCodes;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for Transfer Inventory
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory TCategory = 'RC_TransferInv';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,                    Status)
values ('132',       'Default Tranfer Inv ReasonCode',     'A'),
       ('360',       'Internal Warehouse transfer',        'A')


exec pr_LookUps_Setup @LookUpCategory, @ReasonCodes;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for Back To Inventory
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory TCategory = 'RC_Disposition_BackToInv';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,            Status)
values ('300',       'Looks New',                   'A'),
       ('301',       'Not Worn',                    'A')

exec pr_LookUps_Setup @LookUpCategory, @ReasonCodes;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for Scrap Inventory
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory TCategory = 'RC_Disposition_Scrap';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,            Status)
values ('320',       'Stained',                    'A'),
       ('321',       'Damaged',                    'A')

exec pr_LookUps_Setup @LookUpCategory, @ReasonCodes;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for Returns
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory TCategory = 'RC_Returns';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,            Status)
values ('340',       'Stained',                     'A'),
       ('341',       'Damaged',                     'A'),
       ('342',       'Refused delivery',            'A'),
       ('343',       'Unauthorized Returns',        'A'),
       ('344',       'Unspecified reason by customer',
                                                    'A')

exec pr_LookUps_Setup @LookUpCategory, @ReasonCodes;

Go

/*------------------------------------------------------------------------------
  ReasonCodes for Reverse LPNs
 -----------------------------------------------------------------------------*/
declare @ReasonCodes TLookUpsTable, @LookUpCategory TCategory = 'RC_RecvAdjust';
delete from LookUps where LookUpCategory = @LookUpCategory;

insert into @ReasonCodes
       (LookUpCode,  LookUpDescription,            Status)
values ('290',       'Return to Vendor',           'A'),
       ('291',       'Wrong product',              'A'),
       ('292',       'Received wrong WO/PO',       'A'),
       ('293',       'Other',                      'A')

exec pr_LookUps_Setup @LookUpCategory, @ReasonCodes;

Go
