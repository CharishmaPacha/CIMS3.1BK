/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/26  VM      Initial Revision (S2G-496).
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwRoutingRuleZones') is not null
  drop View dbo.vwRoutingRuleZones;
Go

Create View dbo.vwRoutingRuleZones (
  RR_RecordId,
  RR_SortSeq,

  RZ_RecordId,
  RZ_SortSeq,

  SoldToId,
  SoldToName,
  ShipToId,
  ShipToName,
  Account,

  ShipToZone,
  ShipToState,
  ShipToZipStart,
  ShipToZipEnd,
  ShipToCountry,
  ShipToAddressRegion,

  InputCarrier,
  InputShipVia,
  InputShipViaDesc,
  InputFreightTerms,
  InputFreightTermsDesc,

  MinWeight,
  MaxWeight,

  TransitDays,
  DeliveryRequirement,

  ShipFrom,
  Ownership,
  Warehouse,

  Criteria1,
  Criteria2,
  Criteria3,
  Criteria4,
  Criteria5,

  ShipVia,
  ShipViaDesc,
  FreightTerms,
  FreightTermsDesc,
  BillToAccount,
  BillToAccountName,

  RR_UDF1,
  RR_UDF2,
  RR_UDF3,
  RR_UDF4,
  RR_UDF5,

  RZ_UDF1,
  RZ_UDF2,
  RZ_UDF3,
  RZ_UDF4,
  RZ_UDF5,

  RR_Status,
  RZ_Status,

  /* vwUDFs */
  vwRRZ_UDF1,
  vwRRZ_UDF2,
  vwRRZ_UDF3,
  vwRRZ_UDF4,
  vwRRZ_UDF5,

  RR_BusinessUnit,
  RR_CreatedDate,
  RR_ModifiedDate,
  RR_CreatedBy,
  RR_ModifiedBy,

  RZ_BusinessUnit,
  RZ_CreatedDate,
  RZ_ModifiedDate,
  RZ_CreatedBy,
  RZ_ModifiedBy
) As
select
  RR.RecordId,
  RR.SortSeq,

  RZ.RecordId,
  RZ.SortSeq,

  coalesce(RR.SoldToId, RZ.SoldToId),
  C.Name,
  coalesce(RR.ShipToId, RZ.ShipToId),
  CS.Name,
  RR.Account,

  RR.ShipToZone,
  coalesce(RR.ShipToState,    RZ.ShipToState),
  coalesce(RR.ShipToZipStart, RR.ShipToZipEnd,   RZ.ShipToZipStart, RZ.ShipToZipEnd),   -- If only end is specified, use that that for Start as well
  coalesce(RR.ShipToZipEnd,   RR.ShipToZipStart, RZ.ShipToZipEnd,   RZ.ShipToZipStart), -- if only Start is specified, use that for end as well
  coalesce(RR.ShipToCountry,  RZ.ShipToCountry),
  RR.ShipToAddressRegion,

  RR.InputCarrier,
  RR.InputShipVia,
  ISV.Description,
  RR.InputFreightTerms,
  IFT.LookUpDescription,

  RR.MinWeight,
  RR.MaxWeight,

  RZ.TransitDays,
  coalesce(RR.DeliveryRequirement, RZ.DeliveryRequirement),

  RR.ShipFrom,
  RR.Ownership,
  RR.Warehouse,

  RR.Criteria1,
  RR.Criteria2,
  RR.Criteria3,
  RR.Criteria4,
  RR.Criteria5,

  RR.ShipVia,
  SV.Description,
  RR.FreightTerms,
  FT.LookUpDescription,
  RR.BillToAccount,
  BT.Name,

  RR.UDF1,
  RR.UDF2,
  RR.UDF3,
  RR.UDF4,
  RR.UDF5,

  RZ.UDF1,
  RZ.UDF2,
  RZ.UDF3,
  RZ.UDF4,
  RZ.UDF5,

  RR.Status,
  RZ.Status,

  cast(' ' as varchar(50)), /* vwUDF1 */
  cast(' ' as varchar(50)), /* vwUDF2 */
  cast(' ' as varchar(50)), /* vwUDF3 */
  cast(' ' as varchar(50)), /* vwUDF4 */
  cast(' ' as varchar(50)), /* vwUDF5 */

  RR.BusinessUnit,
  RR.CreatedDate,
  RR.ModifiedDate,
  RR.CreatedBy,
  RR.ModifiedBy,

  RZ.BusinessUnit,
  RZ.CreatedDate,
  RZ.ModifiedDate,
  RZ.CreatedBy,
  RZ.ModifiedBy
from
  RoutingRules RR
  left outer join RoutingZones RZ  on (RZ.ZoneName        = RR.ShipToZone                     ) and
                                      (RZ.BusinessUnit    = RR.BusinessUnit                   )
  left outer join Contacts     C   on (C.ContactRefId     = coalesce(RR.SoldToId, RZ.SoldToId)) and
                                      (C.ContactType      = 'C' /* Cust */                    ) and
                                      (C.BusinessUnit     = RR.BusinessUnit                   )
  left outer join Contacts     CS  on (CS.ContactRefId    = coalesce(RR.ShipToId, RZ.ShipToId)) and
                                      (CS.ContactType     = 'S' /* Ship */                    ) and
                                      (CS.BusinessUnit    = RR.BusinessUnit                   )
  left outer join ShipVias     ISV on (ISV.ShipVia        = RR.InputShipVia                   ) and
                                      (ISV.BusinessUnit   = RR.BusinessUnit                   )
  left outer join LookUps      IFT on (IFT.LookUpCategory = 'FreightTerms'                    ) and
                                      (IFT.LookUpCode     = RR.InputFreightTerms              ) and
                                      (IFT.BusinessUnit   = RR.BusinessUnit                   )
  left outer join ShipVias     SV  on (SV.ShipVia         = RR.ShipVia                        ) and
                                      (SV.BusinessUnit    = RR.BusinessUnit                   )
  left outer join LookUps      FT  on (FT.LookUpCategory  = 'FreightTerms'                    ) and
                                      (FT.LookUpCode      = RR.FreightTerms                   ) and
                                      (FT.BusinessUnit    = RR.BusinessUnit                   )
  left outer join Contacts     BT  on (BT.ContactRefId    = RR.BillToAccount                  ) and
                                      (BT.ContactType     = 'B' /* BillTo */                  ) and
                                      (BT.BusinessUnit    = RR.BusinessUnit                   )
where (RR.Status = 'A') and
      (RZ.Status = 'A')
;

Go
