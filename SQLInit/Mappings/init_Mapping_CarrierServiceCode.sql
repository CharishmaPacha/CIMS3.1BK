/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  This file defines the mapping between cims ShipVia Carrier Service Code and Shipping Interface Service Code
  This mapping will define the values expected by Shipping Interface implementation

  Revision History:

  Date        Person  Comments

  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2018/03/09  RT      Mapping set up for CarrierServiceCode (S2G-319)
  2017/07/18  LRA/DK  Migrated the changes from onsite (CIMS-1437)
  2017/06/20  PK      Service Code mapping for Rate shop groups of ADSI.
  2017/04/29  NB      Service Code mapping for USPS - changed to Endicia names per ADSI Support feedback (CIMS-1259)
  2017/04/20  NB      Service Code mapping for USPS (CIMS-1259)
  2017/04/18  NB      Service Code mapping for Rate shop groups of ADSI(CIMS-1259)
  2017/04/10  NB      Initial Revision(CIMS-1259)
------------------------------------------------------------------------------*/

declare @Mapping       TMapping,
        @SourceSystem  TName,
        @TargetSystem  TName,
        @EntityType    TName,
        @Operation     TOperation;

select  @SourceSystem = 'CIMS',
        @TargetSystem = 'ADSI',
        @EntityType   = 'CarrierServiceCode',
        @Operation    = null;

delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem)  and (EntityType = @EntityType );

/*------------------------------------------------------------------------------
 -----------------------------------------------------------------------------*/
insert into @Mapping
             (SourceValue,                                  TargetValue)
/* FEDEX */
      select  'FEDEX-SMART_POST',                           'FedEx SmartPost parcel select'
union select  'FEDEX-FEDEX_GROUND',                         'FedEx Ground'
union select  'FEDEX-GROUND_HOME_DELIVERY',                 'FedEx Home Delivery'
union select  'FEDEX-STANDARD_OVERNIGHT',                   'FedEx Standard Overnight'
union select  'FEDEX-FIRST_OVERNIGHT',                      'FedEx First Overnight'
union select  'FEDEX-PRIORITY_OVERNIGHT',                   'FedEx Priority Overnight'
union select  'FEDEX-FEDEX_2_DAY',                          'FedEx 2Day'
union select  'FEDEX-FEDEX_1_DAY_FREIGHT',                  'FedEx 1Day Freight'
union select  'FEDEX-FEDEX_2_DAY_FREIGHT',                  'FedEx 2Day Freight'
union select  'FEDEX-FEDEX_3_DAY_FREIGHT',                  'FedEx 3Day Freight'
union select  'FEDEX-FEDEX_EXPRESS_SAVER',                  'FedEx Express Saver'
union select  'FEDEX-INTERNATIONAL_FIRST_OVERNIGHT',        'FedEx International First'
union select  'FEDEX-INTERNATIONAL_PRIORITY_OVERNIGHT',     'FedEx International Priority'
union select  'FEDEX-INTERNATIONAL_ECONOMY',                'FedEx International Economy'
union select  'FEDEX-INTERNATIONAL_ECONOMY_FREIGHT',        'FedEx International Economy Freight'
union select  'FEDEX-INTERNATIONAL_PRIORITY_FREIGHT',       'FedEx International Priority Freight'
union select  'FEDEX-FEDEX_INTERNATIONAL_GROUND_TO_CANADA', 'FedEx International DirectDistribution Surface Solutions (U.S. to Canada)'
/* UPS */
union select  'UPS-UPS1',                                   'UPS Next Day Air (US)'
union select  'UPS-UPS2',                                   'UPS 2nd Day Air (US)'
union select  'UPS-UPS3',                                   'UPS 3 Day select (US)'
union select  'UPS-UPSG',                                   'UPS Ground (API)'
union select  'UPS-UPS_2ND_DAY_RESIDENTIAL',                'UPS 2nd Day Air (US)'
union select  'UPS-UPS_3RD_DAY_RESIDENTIAL',                'UPS 3 Day select (US)'
union select  'UPS-UPS_NEXT_DAY_RESIDENTIAL',               'UPS Next Day Air (US)'
union select  'UPS-UPSNAS',                                 'UPS Next Day Air Saver (US)'
union select  'UPS-UPSNEA',                                 'UPS Next Day Air Early A.M. (US)'
union select  'UPS-UPS2DAA',                                'UPS 2nd Day Air A.M. (US)'
/*
TODO Find the correct mapping
union select  'UPS-UPSS',                     ???
*/
union select  'UPS-UPS_WORLDWIDE_EXPRESS',                  'UPS Worldwide Express'
union select  'UPS-UPS_WORLDWIDE_EXPRESS_PLUS',             'UPS Worldwide Express Plus'
union select  'UPS-UPS_WORLDWIDE_SAVER',                    'UPS Worldwide Saver'
union select  'UPS-UPS_WORLDWIDE_EXPEDITED',                'UPS Worldwide Expedited'
union select  'UPS-UPS_STANDARD_TO_CANADA',                 'UPS Standard (Canada)'
/*
union select  'UPS-UPS_EXPRESS_CRITICAL',        ???
*/
union select  'UPS-UPSMIEC',                                'UPS Mail Innovations International Economy'
union select  'UPS-UPSMIEX',                                'UPS Mail Innovations Expedited (Parcel select Lightweight)'
union select  'UPS-UPSMIP',                                 'UPS Mail Innovations Domestic Priority Mail'
union select  'UPS-UPSS1G',                                 'UPS SurePost 1 lb or Greater (US)'
union select  'UPS-UPSSPBPM',                               'UPS SurePost Bound Printed Matter (US)'
union select  'UPS-UPSS1L',                                 'UPS SurePost Less than 1 lb (US)'
union select  'UPS-UPSSPM',                                 'UPS SurePost Media (US)'
/* USPS */
union select  'USPS-USPS_FirstClass',                       'Endicia First-Class Mail'
union select  'USPS-USPS_Priority',                         'Endicia Priority Mail'
union select  'USPS-USPS_Express',                          'Endicia Express Mail'
union select  'USPS-USPS_ParcelPost',                       'Endicia Parcel Post'
union select  'USPS-USPS_FirstClassMailIntl',               'Endicia International First-Class Mail'
union select  'USPS-USPS_PriorityMailIntl',                 'Endicia International Priority Mail'
union select  'USPS-USPS_ExpressMailIntl',                  'Endicia International Express Mail'
/*
union select  'USPS-USPSFC', 'USPS First Class Mail Canada',             'USPS First-Class Mail'
union select  'USPS-USPSPC', 'USPS Priority Mail Canada',                'USPS Priority Mail'
*/

/* Rate shop groups on ADSI */
union select  'Generic-BESTRATE',                           'Best Rate'
union select  'Generic-BESTUPS',                            'Best UPS'
union select  'Generic-BESTFEDX',                           'Best FedEx'
union select  'Generic-BESTUPSFDX',                         'Best UPSFedEx'
union select  'Generic-BESTGND',                            'Best Ground'
union select  'Generic-BEST1DAY',                           'Best 1Day'
union select  'Generic-BEST2DAY',                           'Best 2Day'
union select  'Generic-BEST3DAY',                           'Best 3Day'
union select  'Generic-BESTAIR',                            'Best Air'
union select  'Generic-BESTINT',                            'Best International'

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
