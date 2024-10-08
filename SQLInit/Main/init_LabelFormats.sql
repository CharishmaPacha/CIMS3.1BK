/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/03  BSP     Added LPN_3x2_SKUDetails (BK-934)
  2022/03/09  AY      Added Location/SKU labels for picklanes (BK-785)
  2021/08/26  AY      Added LPN_4x6_SKUPO (BK-LA GoLive)
  2021/08/09  KBB     Added Ship_4x6_Standard (BK-468)
  2021/07/30  KBB     Added Location_4x6_PickLane (BK-446)
  2021/07/13  PHK     Added Wave_4x6_FloorTagsBySKU (HA-2974)
  2021/02/26  RV      Added Packing_4x6_LPNLabel (HA-2412)
  2021/02/23  AY      Wave_4x6_ByStyleColor: New label (HA-2045)
  2021/01/05  RV      Wave_4x6_ByStyle: Update the ZPLLabelSQLStatement (HA-1855)
  2021/01/04  PHK     Added Wave_4x6_ByStyle (HA-1854)
  2020/12/24  AJM     Added Task_4x6_CycleCount (HA-1802)
  2020/10/15  KBB     Added Location_4x6_LargeFont, Location_4x6_MediumFont,Location_4x6_SmallFont (HA-1502)
  2020/10/01  KBB     Added Wave_4x6_CartonList (HA-1107)
  2020/09/25  VM      Pallet_4x6_DetailedCarton, Pallet_4x6_StdCarton: Removed as they are not valid labels (CIMSV3-1104)
  2020/08/13  KBB     Corrected  Recipts page Entity type  (HA-1295)
  2020/07/31  AY      Added LPN_4x6_ContractorLabel (HA-1273)
  2020/07/27  AY      Added Task_4x6_HeaderLabel_Xfer (HA-1224)
  2020/07/23  PHK     Added Pallet_4x6_ShippingPallet (HA-1153)
  2020/07/07  AY      Added Receiver_4x6_Detail label
  2020/06/01  SJ      Added Pallet_4x6_MasterPallet (HA-651)
  2020/06/01  AY      Added Wave Detail Labels
  2020/05/29  MS      Added Picking Labels (HA-660)
  2020/05/23  AJM     Added Task_4x6_HeaderLabel_RU (HA-634)
  2020/05/01  MS      Disabled Location_4x6, since we don't have ZPL done yet (HA-Support)
  2020/04/17  PHK     Added Printer_3x2_*Font labels (HA-98)
  2020/04/10  KBB     Changed the SKU_1x1_UPC Label Status Active (HA-122)
  2020/04/07  KBB     Added Receiver Labels (HA-51)
  2020/04/07  KBB     Added ReceiptOrder_4x6_SmallFont, ReceiptOrder_4x6_MediumFont Labels(HA-50)
  2020/04/06  MS      Changes to use proc, to insert LabelFormats (CIMSV3-804)
  2020/03/27  PHK     Added Receipt_4x6_LargeFont (HA-50)
  2020/03/20  KBB     LabelFormatName has changed (CIMSV3-744)
  2020/03/06  MS      Added LPN_4x3_SizeSpread (JL-123)
  2020/02/20  MS      Added Pallet_4x6_RecvSort (JL-39)
------------------------------------------------------------------------------*/

Go

/******************************************************************************
  All formates will be inserted into temptable and later procedure will handle
  updating other fields on LabelFormats Table.
 ******************************************************************************/

declare @ttLF TLabelFormats;

insert into @ttLF
              (LabelFormatName,                 LabelFormatDesc,                                    Status, LabelSize, EntityType)
/*-----------------------------------------------------------------------------*/
/* SKU_LabelSize_* - SKU Labels */
/*-----------------------------------------------------------------------------*/
      select  'SKU_1x1_UPC',                    '1x1 UPC only',                                     'A',    '1x1',     'SKU'
union select  'SKU_2x1.5_UPC',                  '2x1.5 UPC',                                        'I',    '2x1.5',   'SKU'
union select  'SKU_3x1_HalfExample',            'Half 3x1 SKU',                                     'I',    '3x1',     'SKU'
union select  'SKU_3x1',                        '3x1 SKU',                                          'I',    '3x1',     'SKU'
union select  'SKU_3x1_UPC',                    '3x1 SKU UPC',                                      'I',    '3x1',     'SKU'
union select  'SKU_3x1_UPC2',                   '3x1 SKU UPC2',                                     'I',    '3x1',     'SKU'
union select  'SKU_3x2',                        '3x2 SKU',                                          'I',    '3x2',     'SKU'
union select  'SKU_4x1_UPCOnly',                'SKU UPC Only',                                     'I',    '4x1',     'SKU'
union select  'SKU_4x2_Details',                'SKU w/ Style, Color, Size',                        'I',    '4x2',     'SKU'
union select  'SKU_4x2_DetailsUPC',             'UPC w/ Style, Color, Size',                        'I',    '4x2',     'SKU'
union select  'SKU_4x2_DetailsUPC2',            'UPC w/ Style, Color, Size Details',                'I',    '4x2',     'SKU'
union select  'SKU_4x2_UPC',                    '4x2 SKU UPC',                                      'I',    '4x2',     'SKU'
union select  'SKU_4x3_TVLabel',                '4x3 SKU TV Label',                                 'I',    '4x3',     'SKU'
union select  'SKU_4x6',                        '4x6 SKU',                                          'D',    '4x6',     'SKU'
union select  'SKU_4x6_Picklane_SKU123',        '4x6 SKU for Picklane',                             'A',    '4x6',     'SKU'

/*------------------------------------------------------------------------------*/
/* LPN_LabelSize_* - LPN Labels */
/*------------------------------------------------------------------------------*/
union select  'LPN_4x2_Details',                '4x2 LPN Details Label',                            'I',    '4x2',     'LPN'
union select  'LPN_4x2_DetailsWithUPC',         '4x2 Details with UPC',                             'I',    '4x2',     'LPN'
union select  'LPN_4x2_Picklane',               '4x2 Picklane',                                     'I',    '4x2',     'LPN'
union select  'LPN_4x2_StyleColorSize',         '4x2 with Details',                                 'I',    '4x2',     'LPN'
union select  'LPN_4x2_WithSKU',                '4x2 with SKU',                                     'I',    '4x2',     'LPN'
union select  'LPN_4x3',                        '4x3 LPN Label',                                    'I',    '4x3',     'LPN'
union select  'LPN_4x3_BatchLabel',             '4x3 LPN Batch Label',                              'I',    '4x3',     'LPN'
union select  'LPN_4x6_SKUUPC',                 '4x6 SKU UPC',                                      'I',    '4x6',     'LPN'
union select  'LPN_4x6_StyleColorSize',         '4x6 Style Color Size',                             'I',    '4x6',     'LPN'
union select  'LPN_4x6_XSC',                    '4x6 LPN XSC',                                      'I',    '4x6',     'LPN' -- To review and rename

union select  'LPN_4x6_SKUPO',                  '4x6 LPN SKU/RO',                                   'A',    '4x6',     'LPN'
union select  'LPN_4x6_SKUPOQty_MF',            '4x6 LPN SKU/RO/Qty',                               'A',    '4x6',     'LPN'
union select  'LPN_4x6_ContractorLabel',        '4x6 LPN Contractor Label',                         'A',    '4x6',     'LPN'

union select  'LPN_4x6_SmallFont',              '4x6 LPN Small font',                               'A',    '4x6',     'LPN'
union select  'LPN_4x6_MediumFont',             '4x6 LPN Medium font',                              'A',    '4x6',     'LPN'
union select  'LPN_4x6_LargeFont',              '4x6 LPN Large font',                               'A',    '4x6',     'LPN'

union select  'LPN_4x3_SizeSpread',             '4x3 LPN SizeSpread Label',                         'A',    '4x3',     'LPN'
union select  'LPN_4x3_SmallFont',              '4x3 LPN Small font',                               'A',    '4x3',     'LPN'
union select  'LPN_4x3_MediumFont',             '4x3 LPN Medium font',                              'A',    '4x3',     'LPN'
union select  'LPN_4x3_LargeFont',              '4x3 LPN Large font',                               'A',    '4x3',     'LPN'

union select  'LPN_4x2_SmallFont',              '4x2 LPN Small font',                               'A',    '4x2',     'LPN'
union select  'LPN_4x2_MediumFont',             '4x2 LPN Medium font',                              'A',    '4x2',     'LPN'
union select  'LPN_4x2_LargeFont',              '4x2 LPN Large font',                               'A',    '4x2',     'LPN'

union select  'LPN_3x2_SmallFont',              '3x2 LPN Small font',                               'A',    '3x2',     'LPN'
union select  'LPN_3x2_MediumFont',             '3x2 LPN Medium font',                              'A',    '3x2',     'LPN'
union select  'LPN_3x2_LargeFont',              '3x2 LPN Large font',                               'A',    '3x2',     'LPN'

union select  'LPN_3x2_SKUDetails',             '3x2 LPN SKU Details',                              'A',    '3x2',     'LPN'

union select  'LPN_4x3_EngravingLabel',         '4x3 Engraving Label',                              'I',    '4x3',     'LPN'

/*------------------------------------------------------------------------------*/
/* Load_LabelSize_* - Load Label */
/*------------------------------------------------------------------------------*/
union select  'Load_4x6_Simple',                '4x6 Load Number',                                  'A',    '4x6',     'Load'
union select  'Load_4x6_Details',               '4x6 Load Details',                                 'I',    '4x6',     'Load'-- to be designed

/*------------------------------------------------------------------------------*/
/* Location_LabelSize_* - Location Labels */
/*------------------------------------------------------------------------------*/
union select  'Location_4x6_LargeFont',         '4x6 Location Large font',                          'A',    '4x6',     'Location'
union select  'Location_4x6_MediumFont',        '4x6 Location Medium font',                         'A',    '4x6',     'Location'
union select  'Location_4x6_SmallFont',         '4x6 Location Small font',                          'A',    '4x6',     'Location'

union select  'Location_4x6_PickLane',          '4x6 Location PickLane Label',                      'A',    '4x6',     'Location'
union select  'Location_4x6_PickLane_SKU123',   '4x6 PickLane Label with SKU',                      'A',    '4x6',     'Location'

union select  'Location_1.25x5.5_DownArrow',    '1.25x5.5 Label with Down Arrow',                   'I',    '1.25x5.5','Location'
union select  'Location_1.25x5.5_UpArrow',      '1.25x5.5 Label with Up Arrow',                     'I',    '1.25x5.5','Location'
union select  'Location_1x5_DownArrow',         '1x5 Label with Down Arrow',                        'I',    '1x5',     'Location'
union select  'Location_1x5_UpArrow',           '1x5 Label with Up Arrow',                          'I',    '1x5',     'Location'

union select  'Location_2.5x6_VerticalLeft',    '2.5x6 Label with Vertical Left',                   'I',    '2.5x6',   'Location'
union select  'Location_2.5x6_VerticalRight',   '2.5x6 Label with Vertical Right',                  'I',    '2.5x6',   'Location'
union select  'Location_2.5x7_DownArrow',       '2.5x7 Label with Down Arrow',                      'I',    '2.5x7',   'Location'
union select  'Location_2.5x7_UpArrow',         '2.5x7 Label with Up Arrow',                        'I',    '2.5x7',   'Location'

union select  'Location_3x2',                   '3x2 Label',                                        'I',    '3x2',     'Location'
union select  'Location_3x2_DownArrow',         '3x2 Label with Down Arrow',                        'I',    '3x2',     'Location'
union select  'Location_3x2_StdPicklane',       '3x2 Std. Picklane Label',                          'I',    '3x2',     'Location'
union select  'Location_3x2_UpArrow',           '3x2 Label with Up Arrow',                          'I',    '3x2',     'Location'
union select  'Location_3x8',                   '3x8 Label',                                        'I',    '3x8',     'Location'
union select  'Location_3x8_BarcodeBottom_DownArrow',
                                                '3x8 Label Barcode Bottom with Down Arrow',         'I',    '3x8',     'Location'
union select  'Location_3x8_BarcodeBottom_UpArrow',
                                                '3x8 Label Barcode Bottom with Up Arrow',           'I',    '3x8',     'Location'
union select  'Location_3x8_DownArrow',         '3x8 Label with Down Arrow',                        'I',    '3x8',     'Location'
union select  'Location_3x8_DownArrow_2',       '3x8 Label with Down Arrow #2',                     'I',    '3x8',     'Location'
union select  'Location_3x8_DownArrow_3',       '3x8 Label with Down Arrow #3',                     'I',    '3x8',     'Location'
union select  'Location_3x8_DownArrow_4',       '3x8 Label with Down Arrow #4',                     'I',    '3x8',     'Location'
union select  'Location_3x8_Level1',            '3x8 Label for Level 1',                            'I',    '3x8',     'Location'
union select  'Location_3x8_Level1_BarcodeBottom',
                                                '3x8 Label for Level 1 BarcodeBottom',              'I',    '3x8',     'Location'
union select  'Location_3x8_Level2',            '3x8 Label for Level 2',                            'I',    '3x8',     'Location'
union select  'Location_3x8_Level2_BarcodeBottom',
                                                '3x8 Label for Level 2 BarcodeBottom',              'I',    '3x8',     'Location'
union select  'Location_3x8_Level3',            '3x8 Label for Level 3',                            'I',    '3x8',     'Location'
union select  'Location_3x8_Level3_BarcodeBottom',
                                                '3x8 Label for Level 3 BarcodeBottom',              'I',    '3x8',     'Location'
union select  'Location_3x8_Level4',            '3x8 Label for Level 4',                            'I',    '3x8',     'Location'
union select  'Location_3x8_Level4_BarcodeBottom',
                                                '3x8 Label for Level 4 BarcodeBottom',              'I',    '3x8',     'Location'
union select  'Location_3x8_UpArrow',           '3x8 Label with Up Arrow',                          'I',    '3x8',     'Location'
union select  'Location_3x8_UpArrow_2',         '3x8 Up Arrow #2',                                  'I',    '3x8',     'Location'
union select  'Location_3x8_UpArrow_3',         '3x8 Up Arrow #3',                                  'I',    '3x8',     'Location'
union select  'Location_3x8_UpArrow_4',         '3x8 Up Arrow #4',                                  'I',    '3x8',     'Location'
union select  'Location_4x2',                   '4x2 Label',                                        'I',    '4x2',     'Location'
union select  'Location_4x2_2',                 '4x2 Location #2',                                  'I',    '4x2',     'Location'
union select  'Location_4x2_DownArrow',         '4x2 Label with Down Arrow',                        'I',    '4x2',     'Location'
union select  'Location_4x2_DownArrow_2',       '4x2 Label with Down Arrow #2',                     'I',    '4x2',     'Location'
union select  'Location_4x2_StdPicklane',       '4x2 Std. Picklane Label',                          'I',    '4x2',     'Location'
union select  'Location_4x2_UpArrow',           '4x2 Label with Up Arrow',                          'I',    '4x2',     'Location'
union select  'Location_4x2_UpArrow_2',         '4x2 Label with Up Arrow #2',                       'I',    '4x2',     'Location'
union select  'Location_4x6_2',                 '4x6 Label #2',                                     'I',    '4x6',     'Location'
union select  'Location_4x6_DownArrow',         '4x6 Label with Down Arrow',                        'I',    '4x6',     'Location'
union select  'Location_4x6_PickZone',          '4x6 PickZone',                                     'I',    '4x6',     'Location'
union select  'Location_4x6_UpArrow',           '4x6 Label with Up Arrow',                          'I',    '4x6',     'Location'

union select  'Location_4x2_MediumFont',        '4x2 Location Medium font',                         'A',    '4x2',     'Location'

/*------------------------------------------------------------------------------*/
/* Receipt_LabelSize_*  - Receipt Label */
/*------------------------------------------------------------------------------*/
union select  'Receipt_4x6',                    '4x6 Receipt Label',                                'A',    '4x6',     'Receipt'
union select  'Receipt_4x6_LargeFont',          '4x6 Receipt Large font',                           'A',    '4x6',     'Receipt'
union select  'Receipt_4x6_SmallFont',          '4x6 Receipt Small font',                           'A',    '4x6',     'Receipt'
union select  'Receipt_4x6_MediumFont',         '4x6 Receipt Medium font',                          'A',    '4x6',     'Receipt'

/*------------------------------------------------------------------------------*/
/* User_LabelSize_* - User Label */
/*------------------------------------------------------------------------------*/
union select  'User_4x2',                       '4x2 User Label',                                   'A',    '4x2',     'User'

/*------------------------------------------------------------------------------*/
/* Pallet_LabelSize_*  - Pallet/Cart Labels */
/*------------------------------------------------------------------------------*/
union select  'Pallet_4x6_LargeFont',           '4x6 Pallet Label',                                 'A',    '4x6',     'Pallet'
union select  'Pallet_4x6_MediumFont',          '4x6 Pallet Medium font',                           'A',    '4x6',     'Pallet'
union select  'Pallet_4x6_SmallFont',           '4x6 Pallet Small font',                            'A',    '4x6',     'Pallet'

union select  'Pallet_4x2',                     '4x2 Pallet Label',                                 'I',    '4x2',     'Pallet'
union select  'Pallet_4x3',                     '4x3 Pallet Label',                                 'I',    '4x3',     'Pallet'
union select  'Pallet_4x3_2',                   '4x3 Pallet Label #2',                              'I',    '4x3',     'Pallet'
union select  'Pallet_4x6_RecvSort',            '4x6 Pallet Receiving Label',                       'I',    '4x6',     'Pallet'
union select  'Pallet_4x6_MasterPallet',        '4x6 Master Pallet',                                'A',    '4x6',     'Pallet'
union select  'Pallet_4x6_ShippingPallet',      '4x6 Shipping Pallet',                              'A',    '4x6',     'Pallet'

/*------------------------------------------------------------------------------*/
/* Printer Labels - Enable one or the other. Medium font should be fine for most clients with names upto 20 chars
   if the names are longer, then enable the Smallfont version for the client */
/*------------------------------------------------------------------------------*/
union select  'Printer_3x2_MediumFont',         '3x2 Printer Medium font',                          'A',    '3x2',     'Printer'
union select  'Printer_3x2_SmallFont',          '3x2 Printer Small font',                           'A',    '3x2',     'Printer'

/*------------------------------------------------------------------------------*/
/* Ship_LabelSize_* - Ship Labels */
/*------------------------------------------------------------------------------*/
union select  'Ship_4x6_Pallet',                '4x6 Ship Pallet',                                  'A',    '4x6',     'Ship'
union select  'Ship_4x6_Generic',               '4x6 Ship Generic',                                 'A',    '4x6',     'Ship'
union select  'Ship_4x6_PalletGeneric',         '4x6 Pallet Ship Label',                            'A',    '4x6',     'Ship'

union select  'Ship_4x6_Standard',              '4x6 Standard Ship Label',                          'A',    '4x6',     'Ship'

union select  'Ship_4x8_Generic',               '4x8 Ship Generic',                                 'A',    '4x8',     'Ship'
union select  'Ship_4x8_PTS',                   '4x8 PTS Ship label',                               'A',    '4x8',     'Ship'

union select  'Ship_4x6_Label_FEDEX',           'ShipLabel_FEDEX',                                  'A',    '4x6',     'Ship'
union select  'Ship_4x6_Label_UPS',             'ShipLabel_UPS',                                    'A',    '4x6',     'Ship'
union select  'Ship_4x6_Label_USPS',            'ShipLabel_USPS',                                   'A',    '4x6',     'Ship'
union select  'Ship_4x6_Label_USPS_Address',    'ShipLabel_USPS_Address',                           'A',    '4x6',     'Ship'
union select  'Ship_4x6_Label_ADSI_0',          'Ship Label For ADSI without rotation',             'A',    '4x6',     'Ship'
union select  'Ship_4x6_Label_ADSI_90',         'Ship Label For ADSI with 90 degrees rotation',     'A',    '4x6',     'Ship'
union select  'Ship_4x6_Label_ADSI_180',        'Ship Label For ADSI with 180 degrees rotation',    'A',    '4x6',     'Ship'
union select  'Ship_4x6_Label_ADSI_270',        'Ship Label For ADSI with 270 degrees rotation',    'A',    '4x6',     'Ship'
union select  'Ship_4x7_3096',                  '4x7 Ship 3096',                                    'A',    '4x7',     'Ship'
union select  'Ship_4x6_Label_DHL',             'ShipLabel_DHL',                                    'A',    '4x6',     'Ship'
union select  'Ship_4x6_Label_GenericCarrier',  '4x6 Ship Label for Generic Carrier',               'A',    '4x6',     'Ship'
union select  'Ship_4x6_Label_error',           '4x6 Alternate Ship Label',                         'A',    '4x6',     'Ship'
union select  'Ship_4x6_PalletGeneric',         '4x6 Pallet Ship Label',                            'A',    '4x6',     'Ship'

/*------------------------------------------------------------------------------*/
/* Task_LabelSize_* - Task Labels */
/*------------------------------------------------------------------------------*/
union select  'Task_4x3_HeaderLabel',           '4x3 Task Label',                                   'I',    '4x3',     'Task'
union select  'Task_4x6_HeaderLabel',           '4x6 Task Label',                                   'A',    '4x6',     'Task'
union select  'Task_4x7_HeaderLabel_BCP',       '4x6 Task Label Case Pick',                         'I',    '4x6',     'Task'
union select  'Task_4x7_HeaderLabel_BPP',       '4x6 Task Label Pick & Pack',                       'I',    '4x6',     'Task'
union select  'Task_4x6_HeaderLabel_PTC',       '4x6 Task Label for PTC',                           'I',    '4x6',     'Task'
union select  'Task_4x6_HeaderLabel_PTS',       '4x6 Task Label PTS Wave',                          'A',    '4x6',     'Task'
union select  'Task_4x6_HeaderLabel_RU',        '4x6 Task Label for Replenish',                     'A',    '4x6',     'Task'
union select  'Task_4x6_HeaderLabel_SLB',       '4x6 Task Label for Single Line',                   'I',    '4x6',     'Task'
union select  'Task_4x6_HeaderLabel_Xfer',      '4x6 Task Label for Transfer',                      'A',    '4x6',     'Task'

/*------------------------------------------------------------------------------*/
/* Task_LabelSize_* - Task Pick Labels */
/*------------------------------------------------------------------------------*/
union select  'Task_4x6_SKUs',                  '4x6 TaskSKUs',                                     'I',    '4x6',     'Task'
union select  'Task_4x6_SKUSa',                 '4x6 TaskSKUsa',                                    'I',    '4x6',     'Task'
union select  'Task_4x6_PickLabel',             '4x6 Task PickLabel',                               'I',    '4x6',     'Task'

/*------------------------------------------------------------------------------*/
/* Task_LabelSize_* - Task Cycle Count Labels */
/*------------------------------------------------------------------------------*/
union select  'Task_4x6_CycleCount',            '4x6 CC Task Label',                                'A',    '4x6',     'CycleCountTasks'

/*------------------------------------------------------------------------------*/
/* Task_LabelSize_* - Task Employee Labels */
/*------------------------------------------------------------------------------*/
union select  'Task_4x3_EmployeeLabel',         '4x3 Employee Label',                               'I',    '4x3',     'Task'

/*------------------------------------------------------------------------------*/
/* Content Labels */
/*------------------------------------------------------------------------------*/
union select  'ContentLabel_4x6_Standard',      '4x6 Standard Case Contents',                       'I',    '4x6',     'Ship'

/*------------------------------------------------------------------------------*/
/* Packing_LabelSize_* - Packing Labels */
/*------------------------------------------------------------------------------*/
union select  'Packing_4x6_LPNLabel',           '4x6 Packing Label',                                'A',    '4x6',     'Ship'
union select  'Packing_4x6_Default',            '4x6 Packing Default Label',                        'I',    '4x6',     'Ship'
union select  'Packing_4x2_barcodeLabel',       '4x2 Packing barcode Label',                        'I',    '4x2',     'Ship'
union select  'Packing_LPNLabel',               '4x6 Packing Label',                                'A',    '4x6',     'Ship'

/*------------------------------------------------------------------------------*/
/* Picking Labels */
/*------------------------------------------------------------------------------*/
union select  'PickingLabel_4x2',               '4x2 Picking Label',                                'I',    '4x2',     'Pick'
union select  'PickingLabel_4x8',               '4x8 Picking Label',                                'I',    '4x8',     'Pick'

/*------------------------------------------------------------------------------*/
/* Pricestickers_LabelSize_* -  Pricestickers Labels */
/*------------------------------------------------------------------------------*/
union select  'PriceStickers_1x1_Generic',      'PriceStickers Generic',                            'I',    '1x1',     'PS'

/*------------------------------------------------------------------------------*/
/* Receiver Labels: ReceiverNumber is fixed size, so multiple fonts not required */
/*------------------------------------------------------------------------------*/
union select  'Receiver_4x6_Simple',            '4x6 Receiver Number',                              'A',    '4x6',     'Receiver'
union select  'Receiver_4x6_Detail',            '4x6 Receiver Details',                             'A',    '4x6',     'Receiver'

/*------------------------------------------------------------------------------*/
/* Wave Labels: WaveNo is fixed size, so multiple fonts not required */
/*------------------------------------------------------------------------------*/
union select  'Wave_4x6_Simple',                '4x6 Wave No',                                      'A',    '4x6',     'Wave'
union select  'Wave_4x6_Detail_BCP',            '4x6 Case Pick Wave Label',                         'A',    '4x6',     'Wave'
union select  'Wave_4x6_Detail_PTS',            '4x6 Pick To Ship Wave Label',                      'A',    '4x6',     'Wave'
union select  'Wave_4x6_Detail_BPP',            '4x6 Pick & Pack Wave Label',                       'A',    '4x6',     'Wave'
union select  'Wave_4x6_Detail_RW',             '4x6 Rework Wave Label',                            'A',    '4x6',     'Wave'
union select  'Wave_4x6_Detail_XFER',           '4x6 Transfer Wave Label',                          'A',    '4x6',     'Wave'
union select  'Wave_4x6_Detail_SLB',            '4x6 Single Line Wave Label',                       'A',    '4x6',     'Wave'
union select  'Wave_4x6_CartonList',            '4x6 Carton List for Wave',                         'A',    '4x6',     'Wave'
union select  'Wave_4x6_ByStyle',               '4x6 Wave by Style',                                'A',    '4x6',     'Wave'
union select  'Wave_4x6_ByStyleColor',          '4x6 Wave by Style/Color',                          'A',    '4x6',     'Wave'
union select  'Wave_4x6_FloorTagsBySKU',        '4x6 Floor Tags by SKU',                            'A',    '4x6',     'Wave'

/*------------------------------------------------------------------------------*/
/* Picklane label with SKU has to print for all LPNs in the Location so, use DBObject LocationLPNLabel */
update @ttLF
set DBObjectName = 'LocationLPNLabel'
where LabelFormatName = 'Location_4x6_PickLane';

/*******************************************************************************/
exec pr_Setup_LabelFormats @ttLF, 'AU' /* Add/Update */, null, null;

Go

/********************************************************************************
   Procedure will do all generic updates for the labels, if we have any custom
   updates to be made for specific labels, we have to add statements below
********************************************************************************/

/* Updating PrintDataStream on UPS & FedEx labels to stuff some additional data on the ZPL labels */
update LabelFormats
set PrintDataStream = '^FT10,1230^A0N,21,25^FVCONTAINER ID: <%LPN%>^FS^FT10,1260^A0N,21,25^FVLABEL: <%ShippedDate%> PO#: <%CustPO%> STORE NO: <%ShipToStore%>^FS^FT10,1290^A0N,21,25^FV<%DATETIME%> VENDOR: <%AccountName%>^FS^FT10,1320^A0N,21,25^FVPT: <%PickTicket%> SKU: <%SKU%> DPCI: <%CustomerSKU%> DEPT: <%SoldToEmail%>^FS^FT40,1530^BY5^BCN,170,Y,N,N,A^FV<%UCCBARCODE%>^FS'
where LabelFormatName in ('Ship_4x6_Label_UPS', 'Ship_4x6_Label_FEDEX');

update LabelFormats
set PrintOptions = '<printoptions>' +
                     '<printsize>' + LabelSize + '</printsize>' +
                     '<ContentsInfo>Y</ContentsInfo>' +
                     '<ContentLinesPerLabel>5</ContentLinesPerLabel>' +
                   '</printoptions>'
where LabelFormatName = 'LPN_4x3_EngravingLabel'

update LabelFormats
set PrintOptions = '<printoptions>' +
                     '<printsize>' + LabelSize + '</printsize>' +
                     '<ContentsInfo>Y</ContentsInfo>' +
                     '<ContentLinesPerLabel>4</ContentLinesPerLabel>' +
                   '</printoptions>'
where LabelFormatName = 'Task_4x3_EmployeeLabel'

update LabelFormats
set LabelSQLStatement    = 'exec pr_ShipLabel_GetLPNData null, ~EntityId~',
    ZPLLabelSQLStatement = 'exec pr_ShipLabel_GetLPNData null, ~EntityId~',
    PrintOptions         = '<printoptions>
                              <ContentsInfo>Y</ContentsInfo>
                              <ContentsLinesPerLabel>9</ContentsLinesPerLabel>
                              <MaxLabelsToPrint>1</MaxLabelsToPrint>
                            </printoptions>'
where LabelFormatName like 'Packing_%'

update LabelFormats
set LabelSQLStatement    ='exec pr_Tasks_GetHeaderLabelData ~EntityId~',
    ZPLLabelSQLStatement ='exec pr_Tasks_GetHeaderLabelData ~EntityId~'
where LabelFormatName like 'Task_%_HeaderLabel%'

update LabelFormats
set LabelSQLStatement ='exec pr_Tasks_GetHeaderLabelData ~EntityId~',
    ZPLLabelSQLStatement ='exec pr_Tasks_GetHeaderLabelData ~EntityId~'
where LabelFormatName = 'Task_4x6_CycleCount'


update LabelFormats
set LabelSQLStatement    ='exec pr_ShipLabel_GetLPNData null, ~EntityId~',
    ZPLLabelSQLStatement ='exec pr_ShipLabel_GetLPNData null, ~EntityId~'
where (LabelFormatName like 'Ship%') or (LabelFormatName like 'PickingLabel%');

/* Setup PTS labels to have additonal picking label at bottom */
update LabelFormats
set AdditionalContent = 'PickingLabel_4x8'
where LabelFormatName in ('Ship_4x8_PTS', 'Ship_4x8_Generic');

update LabelFormats
set LabelSQLStatement    ='exec pr_Waves_GetLabelDataByStyle ~EntityId~',
    ZPLLabelSQLStatement ='exec pr_Waves_GetLabelDataByStyle ~EntityId~'
where (LabelFormatName = 'Wave_4x6_ByStyle');

update LabelFormats
set LabelSQLStatement    ='exec pr_Waves_GetLabelDataByStyle ~EntityId~, ''ByStyleColor''',
    ZPLLabelSQLStatement ='exec pr_Waves_GetLabelDataByStyle ~EntityId~, ''ByStyleColor'''
where (LabelFormatName = 'Wave_4x6_ByStyleColor');

update LabelFormats
set LabelSQLStatement    ='exec pr_Waves_GetLabelDataByStyle ~EntityId~, ''ByStyleColorSize''',
    ZPLLabelSQLStatement ='exec pr_Waves_GetLabelDataByStyle ~EntityId~, ''ByStyleColorSize'''
where (LabelFormatName = 'Wave_4x6_FloorTagsBySKU');

Go
