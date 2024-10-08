/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/05  RBV     Added PickMethod Field (CID-1488)
  2020/07/10  RKC     Added LoadingMethod (HA-1106)
  2020/07/02  TK      Added PalletizationGroups (HA-1031)
  2020/04/03  TK      Added PropagatePermissions (HA-69)
  2020/03/30  MS      Added InventoryClasses (HA-77)
  2020/03/30  TK      Added Boolean (HA-69)
  2020/03/20  RT      Changed the LPNTypeForModify, LPNTypeForGenerate and LPNTypeForCart as per standard by capitalising the Prefix (CIMSV3-697)
  2020/01/11  RT      Added PalletSize (JL-59)
  2019/01/03  MS      Added CarrierOptions (cIMSV3-424)
  2019/03/05  MJ      Added RC_QCHold and RC_QCRelease (CID-166)
  2018/10/11  RIA     Added a new WavePickSequence to display the required fields (OB2-796)
  2018/10/11  RIA     Added a new LookUp PalletLPNFormat to display the required fields (OB2-651)
  2018/09/25  KSK     Added CartonGroups (HPI-2044)
  2018/06/05  YJ      Added RC_WHXFer (S2G-727)
  2018/04/09  SV      Added RC_CancelPickTicket (HPI-1842)
  2018/03/14  DK      Added SourceSystem (FB-1111)
  2018/02/07  CK      Added ABCClasses, ReplenishClasses (S2G-18)
  2018/01/16  TD      Added LocAllowedOperations (CIMS-1717)
  2017/12/03  TD      Added LocationClasses (CIMS-1749).
  2017/02/10  OK      Added Location Operations (GNC-1426)
  2016/09/07  AY      Added RC_RecvAdjust (HPI-587)
  2016/04/01  DK      Added RC_TransferInv (FB-646).
  2016/03/28  KL      Split the pallet formats into two categories (CIMS-810).
  2016/01/08  DK      Added RC_Returns (FB-596)
  2016/01/05  NB      Added OwnerDefaultWarehouse (NBD-59)
  2015/09/30  TK      Added ReceivingUoM (ACME-317)
  2015/09/24  DK      Added RC_Disposition_BackToInv and RC_Disposition_Scrap.
  2015/09/16  SV      Added RePrintLabelType (SRI-387)
  2015/08/21  YJ      Added LPNTypeforCart (ACME-139)
  2015/07/09  YJ      Added LPNTypeforGenerate (cIMS-522)
  2015/03/19  DK      Added RC_ExplodePrepack.
  2014/07/01  PKS     Added RC_LocAdjust, RC_ShortPick, RC_CycleCount
  2014/05/26  YJ      Using Temp table.
  2013/10/09  VM      Added RC_LPNVoid.
  2013/08/27  TD      Added generate Pallet options.
  2012/12/05  NY      Lookup Countries of Origin -> Country of Origin
  2012/11/10  AA      Added LookupCategory: LabelType, LabelPrintSortOrder for shipping label intergace
  2012/10/11  YA      Added LookUpCode 'RC_LPNCreateInv'.
  2012/06/20  PK      Added Owner.
  2012/06/18  TD      Added LookupCategory: FreightTerms.
  2012/06/17  VM      YesNo: Status reverted back to 'Active' as if it is Inactive
                        will not be loaded in drop down list (example in Putaway Rules page new/edit)
  2012/05/01  AY      Added LookupCategory: CoO - Countries of Origin
  2012/04/09  AY      Added LookupCategory: 'Owners'
  2012/12/20  YA      Added LookUpCode: Variance.
  2011/12/05  VM      Activated "ProcessedFlag" as it is used by UI (Data Exports)
  2011/11/17  SHR     Added LPNTypeforModify.
  2011/10/31  SHR     Change 'YesNo' Status to 'A' - Active
  2011/08/28  TD      Changed the order of Lookups.
  2011/07/26  YA      Added LookUpCode name is ShipVia.
  2011/07/21  TD      Added 'YesNo' LookUpCode to the file.
  2011/02/24  VK      Added the LPNFormat LookUpCode to the file.
  2011/02/19  VK      Added the 'PickZones' and 'PutawayZones' LookUpCode to the
                      file.
  2011/02/08  VK      Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  These are all the lookup Categories.
  If they are active, users would be able to see and edit them, If inactive,
  users cannot see them in UI nor edit them.

  The list is organized in logical groups
------------------------------------------------------------------------------*/
declare @LookUps TLookUpsTable, @LookUpCategory TCategory = 'CategoryDesc';

insert into @LookUps
       (LookUpCode,                        LookUpDescription,                      Status)
values ('CategoryDesc',                    'Categories',                           'A'),
       /* Location */
       ('LocationClasses',                 'Location Classes',                     'A'),
       ('LocationFormat',                  'Location Format',                      'A'),
       ('LocAllowedOperations',            'Location Operations',                  'I'),
       ('PickZones',                       'Pick Zones',                           'A'),
       ('PutawayZones',                    'Putaway Zones',                        'A'),
       /* LPN */
       ('GeneratePalletOptions',           'Generate Pallet Options',              'A'),
       ('PalletizationGroups',             'Palletization Groups',                 'A'),
       ('InventoryClass1',                 'Inventory Class1',                     'A'),
       ('InventoryClass2',                 'Inventory Class2',                     'I'), -- Not used by default
       ('InventoryClass3',                 'Inventory Class3',                     'I'), -- Not used by default
       ('LPNFormat',                       'LPN Format',                           'A'),
       ('LPNPutawayClasses',               'LPN Putaway Classes',                  'A'),
       ('LPNTypeForModify',                'LPN Type for Modify',                  'A'),
       ('LPNTypeForGenerate',              'LPN Type for Generate',                'A'),
       ('LPNTypeForCart',                  'LPN Type for Cart',                    'A'),
       /* Pallet */
       ('PalletFormat_I',                  'Pallet Format for Inventory',          'A'),
       ('PalletFormat_C',                  'Pallet Format for Cart',               'A'),
       ('PalletLPNFormat',                 'Pallet LPN Format',                    'A'),
       ('PalletSize',                      'Pallet Size',                          'A'),
       /* Reason codes */
       ('RC_LPNCreateInv',                 'Create Inventory Reasons',             'A'),
       ('RC_LPNAdjust',                    'LPN Adjustment Reasons',               'A'),
       ('RC_LPNVoid',                      'Reasons for LPN Void',                 'A'),
       ('RC_CancelPickTicket',             'Reasons for PT Cancel',                'A'),
       ('RC_LocAdjust',                    'Reasons for Location Adjust',          'A'),
       ('RC_ShortPick',                    'Reasons for Short Pick',               'A'),
       ('RC_CycleCount',                   'Reasons for Cycle Count',              'A'),
       ('RC_ExplodePrepack',               'Reasons for Explode Prepack',          'A'),
       ('RC_Disposition_BackToInv',        'Reasons for BackToInv Disposition',    'A'),
       ('RC_Disposition_Scrap',            'Reasons for Scrap Disposition',        'A'),
       ('RC_QCHold',                       'Reasons for QC Hold',                  'A'),
       ('RC_QCRelease',                    'Reasons for QC Release',               'A'),
       ('RC_Returns',                      'Reasons for Returns',                  'A'),
       ('RC_RecvAdjust',                   'Reasons for Reverse Receipt',          'A'),
       ('RC_TransferInv',                  'Reasons for Transfer Inventory',       'A'),
       ('RC_WHXFer',                       'Warehouse Transfers',                  'A'),
       /* SKU */
       ('ABCClasses',                      'ABC Classes',                          'A'),
       ('ProductCategory',                 'Product Category',                     'A'),
       ('ProductSubCategory',              'Product Sub Category',                 'A'),
       ('PutawayClasses',                  'Putaway Classes',                      'A'),
       ('ReplenishClasses',                'Replenish Classes',                    'A'),
       /* Shipping */
       ('CarrierOptions',                  'Carrier Options',                      'A'),
       ('FreightTerms',                    'Freight Terms',                        'A'),
       ('ShipVia',                         'Ship Methods',                         'A'),
       /* Generic/Misc */
       ('State',                           'State',                                'A'),
       ('Country',                         'Country',                              'A'),
       ('Variance',                        'Variance',                             'A'),
       ('LabelType',                       'Label Type',                           'A'),
       ('RePrintLabelType',                'Reprint Label Type',                   'A'),
       ('LabelPrintSortOrder',             'Label Print Sort Sequence',            'A'),
       ('UoM',                             'Unit Of Measure',                      'A'),
       ('ReplenishUoM',                    'Replenish UoM',                        'A'),
       ('ReceivingUoM',                    'Receiving UoM',                        'A'),
       ('WavePickSequence',                'Pick Sequence',                        'A'),
       ('CartonGroups',                    'Carton Groups',                        'A'),
       ('PickMethod',                      'PickMethod',                           'A'),
       /* System config */
       ('CoO',                             'Country of Origin',                    'A'),
       ('Owner',                           'Owners',                               'A'),
       ('OwnerDefaultWarehouse',           'Owner Warehouse Mapping',              'A'),
       ('Warehouse',                       'Warehouses',                           'A'),
       /* System internal */
       ('Boolean',                         'True / False',                         'I'),
       ('BusinessUnit',                    'Business Unit',                        'I'),
       ('PropagatePermissions',            'Propagate Permisisons options',        'I'),
       ('ProcessedFlag',                   'Export Processed Flag',                'I'),
       ('SourceSystem',                    'SourceSystems',                        'I'),
       ('YesNo',                           'Yes / No',                             'I');

/* Create the above Look ups for all BusinessUnits */
exec pr_LookUps_Setup @LookUpCategory, @LookUps;

Go
