/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  This file defines the mapping between cims ShipVia Carrier Service Code and Shipping Interface Service Code
  This mapping will define the values expected by Shipping Interface implementation

  Revision History:

  Date        Person  Comments

  2021/07/24  RV      TrackingURL: Added new mapping for UPS, FEDEX and USPS (BK-277)
------------------------------------------------------------------------------*/

declare @Mapping       TMapping,
        @SourceSystem  TName,
        @TargetSystem  TName,
        @EntityType    TName,
        @Operation     TOperation,
        @BusinessUnit  TBusinessUnit;

/******************************************************************************/
/***************************** Carrier Tracking URLs ****************************/
/******************************************************************************/

/*----------------------------------------------------------------------------*/
/* Packing List based upon Ship From */
/*----------------------------------------------------------------------------*/
select @SourceSystem  = 'CIMS',
       @TargetSystem  = 'CIMS',
       @EntityType    = 'TrackingURL',
       @Operation     = 'Tracking';

delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem)  and (EntityType = @EntityType );

delete from @Mapping;
insert into @Mapping
            (SourceValue,        TargetValue,                                                            Status)
      select 'FEDEX',            'https://www.fedex.com/apps/fedextrack/?action=track&trackingnumbers=', 'A'
union select 'UPS',              'https://www.ups.com/track?tracknum=',                                  'A'
union select 'USPS',             'https://tools.usps.com/go/TrackConfirmAction?tLabels=',                'A'

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation, @BusinessUnit;

Go
