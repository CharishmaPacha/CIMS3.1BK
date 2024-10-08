/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/12  RKC     Changed the Names for some of the fields (HA-451)
  2017/12/18  TD      Added LocationClass(CIMS-1750)
  2015/10/23  AY      Added PalletPutawayClass
  2014/03/24  AY      Changed PAClass to SKUPutawayClass and added LPNPutawayClass
  2013/08/30  TD      Added Warehouse.
  2013/03/31  AY      Added PAType and PATypeDescription
  2012/04/10  PK      Added PalletType, PalletTypeDescription.
  2011/07/27  TD      Added Putawayclass,PutawayZone Display Descriptions.
  2011/07/19  TD      Added Descriptions for table Fields.
  2011/07/09  AY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwPutawayRules') is not null
  drop View dbo.vwPutawayRules;
Go

Create View dbo.vwPutawayRules (
  RecordId,

  SequenceNo,

  PAType,
  PATypeDescription,
  SKUPutawayClass,
  SKUPutawayClassDescription,
  SKUPutawayClassDisplayDescription,

  LPNPutawayClass,
  PalletPutawayClass,

  LPNType,
  LPNTypeDescription,
  PalletType,
  PalletTypeDescription,

  Warehouse,
  LocationClass,
  LocationType,
  LocationTypeDesc,

  StorageType,
  StorageTypeDesc,

  LocationStatus,
  LocationStatusDesc,

  PutawayZone,
  PutawayZoneDesc,
  PutawayZoneDisplayDesc,

  Location,
  SKUExists,

  Status,
  StatusDescription,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  PR.RecordId,

  PR.SequenceNo,

  PR.PAType,
  PAT.TypeDescription,
  PR.SKUPutawayClass,
  SPC.LookUpDescription,
  SPC.LookUpDisplayDescription,

  PR.LPNPutawayClass,
  PR.PalletPutawayClass,

  PR.LPNType,
  ET.TypeDescription,
  PR.PalletType,
  PT.TypeDescription,

  PR.Warehouse,
  PR.LocationClass,
  PR.LocationType,
  LT.TypeDescription,

  PR.StorageType,
  ST.TypeDescription,

  PR.LocationStatus,
  LS.StatusDescription,

  PR.PutawayZone,
  PZ.LookUpDescription,
  PZ.LookupDisplayDescription,

  PR.Location,
  PR.SKUExists,

  PR.Status,
  SS.StatusDescription,

  PR.BusinessUnit,
  PR.CreatedDate,
  PR.ModifiedDate,
  PR.CreatedBy,
  PR.ModifiedBy
from
  PutawayRules PR
  left outer join EntityTypes  ET   on (PR.LPNType         = ET.TypeCode      ) and
                                       (ET.Entity          = 'LPN'            ) and
                                       (ET.BusinessUnit    = PR.BusinessUnit  )
  left outer join EntityTypes  LT   on (PR.LocationType    = LT.TypeCode      ) and
                                       (LT.Entity          = 'Location'       ) and
                                       (LT.BusinessUnit    = PR.BusinessUnit  )
  left outer join EntityTypes  ST   on (PR.StorageType     = ST.TypeCode      ) and
                                       (ST.Entity          = 'LocationStorage') and
                                       (ST.BusinessUnit    = PR.BusinessUnit  )
  left outer join EntityTypes  PT   on (PR.PalletType      = PT.TypeCode      ) and
                                       (PT.Entity          = 'Pallet'         ) and
                                       (PT.BusinessUnit    = PR.BusinessUnit  )
  left outer join Statuses     LS   on (PR.LocationStatus  = LS.StatusCode    ) and
                                       (LS.Entity          = 'Location'       ) and
                                       (LS.BusinessUnit    = PR.BusinessUnit  )
  left outer join Statuses     SS   on (PR.Status          = SS.StatusCode    ) and
                                       (SS.Entity          = 'Status'         ) and
                                       (SS.BusinessUnit    = PR.BusinessUnit  )
  left outer join Lookups      PZ   on (PR.PutawayZone     = PZ.LookUpCode    ) and
                                       (PZ.LookUpCategory  = 'PutawayZones'   ) and
                                       (PZ.BusinessUnit    = PR.BusinessUnit  )
  left outer join Lookups      SPC  on (PR.SKUPutawayClass = SPC.LookUpCode   ) and
                                       (SPC.LookUpCategory = 'PutawayClasses' ) and
                                       (SPC.BusinessUnit   = PR.BusinessUnit  )
  left outer join EntityTypes  PAT  on (PR.PAType          = PAT.TypeCode     ) and
                                       (PAT.Entity         = 'Putaway'        ) and
                                       (PAT.BusinessUnit   = PR.BusinessUnit  )
;

Go
