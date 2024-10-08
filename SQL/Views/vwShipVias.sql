/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/09/22  MS      Added CutOffTime (MBW-473)
  2023/06/13  VMG     Added TransitDays (FBV3-1582)
  2021/04/23  SJ      Made changes to get SCAC for LTL Carrier (HA-2618)
  2020/12/04  AY      Use new fields for Service Level (HA-1670)
  2020/11/16  KBB     Added RecordId (HA-1670)
  2019/08/22  VS      Added SCAC (CID-216)
  2019/07/30  AY      Added NoLock hint
  2019/05/08  AY      Added ServiceClass/ServiceClassDesc to distinguish between Air & Ground services (S2GCA-749)
  2018/09/10  AY      Added Carrier PackagingType and ServiceLevel (S2GCA-131)
  2018/08/29  RV      Added IsSmallPackageCarrier (S2GCA-131)
  2016/08/27  VM      Bug-fix: Duplicate of USPS used. Corrected to UPS (HPI-529)
  2016/08/25  AY      Added CarrierType for easier evaluation of Small Package (HPI-529)
  2012/09/12  SP      Made correction for appending ShipVia and Description fields.
  2010/09/12  SP      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwShipVias') is not null
  drop View dbo.vwShipVias;
Go

Create View dbo.vwShipVias (
   RecordId,
   ShipVia,
   ShipViaDescription,
   Carrier,
   Description,        -- deprecated, do not use
   DisplayDescription, -- deprecated, do not use

   SCAC,
   CarrierServiceCode,
   StandardAttributes,
   SpecialServices,

   TransitDays,
   IsSmallPackageCarrier,
   CarrierType, /* SPG or LTL */
   PackagingType,
   ServiceLevel,
   ServiceClass, /* AIR - GND (for Air or Ground) */
   ServiceClassDesc, /* Air or Ground */
   CutOffTime,

   Status,
   SortSeq,
   BusinessUnit,

   CreatedDate,
   ModifiedDate,
   CreatedBy,
   ModifiedBy

) as
select
   S.RecordId,
   S.ShipVia,
   S.Description,
   S.Carrier,
   S.Description,                  -- deprecated, do not use
   S.ShipVia + '-'+ S.Description, -- deprecated, do not use

   S.SCAC,
   S.CarrierServiceCode,
   S.StandardAttributes,
   S.SpecialServices,

   S.TransitDays,
   S.IsSmallPackageCarrier,
   case when S.IsSmallPackageCarrier = 'Y' /* Yes */
     then 'SPG' /* Small Package */
     else S.Carrier
   end /* Carrier Type */,
   nullif(cast(StandardAttributes as xml).value('(/PACKAGINGTYPE/node())[1]', 'TVarchar'), ''),
   nullif(cast(StandardAttributes as xml).value('(/SERVICELEVEL/node())[1]',  'TVarchar'), ''),
   coalesce(S.ServiceClass,     nullif(cast(StandardAttributes as xml).value('(/SERVICECLASS/node())[1]',      'TVarchar'), '')),
   coalesce(S.ServiceClassDesc, nullif(cast(StandardAttributes as xml).value('(/SERVICECLASSDESC/node())[1]',  'TVarchar'), '')),
   S.CutOffTime,

   S.Status,
   S.SortSeq,
   S.BusinessUnit,

   S.CreatedDate,
   S.ModifiedDate,
   S.CreatedBy,
   S.ModifiedBy

from ShipVias S with (NoLock)

Go
