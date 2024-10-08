/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  This file defines the mapping between cims ShipVia or Carton Packaging Type Code and Shipping Interface Packaging Code
  This mapping will define the values expected by Shipping Interface implementation

  Revision History:

  Date        Person  Comments

  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2018/03/09  RT      Mapping set up for Carrier Packaging Type (S2G-319)
  2017/04/11  NB      Initial Revision
------------------------------------------------------------------------------*/

declare @Mapping       TMapping,
        @SourceSystem  TName,
        @TargetSystem  TName,
        @EntityType    TName,
        @Operation     TOperation;

select  @SourceSystem = 'CIMS',
        @TargetSystem = 'ADSI',
        @EntityType   = 'CarrierPackagingType',
        @Operation    = null;

delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem)  and (EntityType = @EntityType );

/*------------------------------------------------------------------------------
 -----------------------------------------------------------------------------*/
insert into @Mapping
             (SourceValue,               TargetValue)
      select  'YOUR_PACKAGING',          'pkgCUSTOM'
union select  'UPS Express Envelope',    'pkgUPS_LETTER'
union select  'UPS Tube',                'pkgUPS_TUBE'
/*
union select  'UPS Pak',                 'pkgUPS_EXPRESS_PAK'
union select  'UPS Express Box',
*/
union select  'UPS 25kg Box',            'pkgUPS_25KG_BOX'
union select  'UPS 10kg Box',            'pkgUPS_10KG_BOX'
/*
union select  'Pallet',
*/
union select  'UPS Small Express Box',   'pkgUPS_US_EXPRESS_BOX_SMALL'
union select  'UPS Medium Express Box',  'pkgUPS_US_EXPRESS_BOX_MEDIUM'
union select  'UPS Large Express Box',   'pkgUPS_US_EXPRESS_BOX_LARGE'
/*
union select  'UPS Parcel Post',

union select  'MIP',
union select  'MIE',
union select  'CP',
*/
union select  'FEDEX_ENVELOPE',          'pkgFedEx_ENVELOPE'
union select  'FEDEX_PAK',               'pkgFedEx_PAK'
union select  'FEDEX_TUBE',              'pkgFedEx_TUBE'
union select  'FEDEX_SMALL_BOX',         'pkgFedEx_SMALL_BOX'
union select  'FEDEX_MEDIUM_BOX',        'pkgFedEx_MEDIUM_BOX'
union select  'FEDEX_LARGE_BOX',         'pkgFedEx_LARGE_BOX'
union select  'FEDEX_10KG_BOX',          'pkgFedEx_10KG_BOX'
union select  'FEDEX_25KG_BOX',          'pkgFedEx_25KG_BOX'
/*
union select  'USPS_SMALL_BOX',
union select  'USPS_MEDIUM_BOX',
union select  'USPS_LARGE_BOX',
*/

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
