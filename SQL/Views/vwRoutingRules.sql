/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/04/03  VM      Added Comments (S2G-564)
  2018/03/31  VM      Setup RuleType into UDF1 (S2G-CRP)
  2018/03/26  VM      Initial Revision (S2G-496).
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwRoutingRules') is not null
  drop View dbo.vwRoutingRules;
Go

Create View dbo.vwRoutingRules (
  RecordId,
  SortSeq,

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

  Comments,

  RR_UDF1,
  RR_UDF2,
  RR_UDF3,
  RR_UDF4,
  RR_UDF5,

  Status,
  StatusDesc,

  /* vwUDFs */
  vwRR_UDF1,
  vwRR_UDF2,
  vwRR_UDF3,
  vwRR_UDF4,
  vwRR_UDF5,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  TOP (100) PERCENT

  RR.RecordId,
  RR.SortSeq,

  RR.SoldToId,
  C.Name,
  RR.ShipToId,
  CS.Name,
  RR.Account,

  RR.ShipToZone,
  RR.ShipToState,
  RR.ShipToZipStart,
  RR.ShipToZipEnd,
  RR.ShipToCountry,
  RR.ShipToAddressRegion,

  RR.InputCarrier,
  RR.InputShipVia,
  ISV.Description,
  RR.InputFreightTerms,
  IFT.LookUpDescription,

  RR.MinWeight,
  RR.MaxWeight,

  RR.DeliveryRequirement,

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

  RR.Comments,

  case
    when (nullif(RR.ShipToId, '') is not null) then
      'ShipTo'
    when (nullif(RR.SoldToId, '') is not null) then
      'SoldTo'
    else
      'Default'
  end, /* RuleType */ --RR.UDF1,

  RR.UDF2,
  RR.UDF3,
  RR.UDF4,
  RR.UDF5,

  RR.Status,
  S.StatusDescription,

  cast(' ' as varchar(50)), /* vwUDF1 */
  cast(' ' as varchar(50)), /* vwUDF2 */
  cast(' ' as varchar(50)), /* vwUDF3 */
  cast(' ' as varchar(50)), /* vwUDF4 */
  cast(' ' as varchar(50)), /* vwUDF5 */

  RR.BusinessUnit,
  RR.CreatedDate,
  RR.ModifiedDate,
  RR.CreatedBy,
  RR.ModifiedBy
from
  RoutingRules RR
  left outer join Contacts     C   on (C.ContactRefId     = RR.SoldToId         ) and
                                      (C.ContactType      = 'C' /* Cust */      ) and
                                      (C.BusinessUnit     = RR.BusinessUnit     )
  left outer join Contacts     CS  on (CS.ContactRefId    = RR.ShipToId         ) and
                                      (CS.ContactType     = 'S' /* Ship */      ) and
                                      (CS.BusinessUnit    = RR.BusinessUnit     )
  left outer join ShipVias     ISV on (ISV.ShipVia        = RR.InputShipVia     ) and
                                      (ISV.BusinessUnit   = RR.BusinessUnit     )
  left outer join LookUps      IFT on (IFT.LookUpCategory = 'FreightTerms'      ) and
                                      (IFT.LookUpCode     = RR.InputFreightTerms) and
                                      (IFT.BusinessUnit   = RR.BusinessUnit     )
  left outer join ShipVias     SV  on (SV.ShipVia         = RR.ShipVia          ) and
                                      (SV.BusinessUnit    = RR.BusinessUnit     )
  left outer join LookUps      FT  on (FT.LookUpCategory  = 'FreightTerms'      ) and
                                      (FT.LookUpCode      = RR.FreightTerms     ) and
                                      (FT.BusinessUnit    = RR.BusinessUnit     )
  left outer join Contacts     BT  on (BT.ContactRefId    = RR.BillToAccount    ) and
                                      (BT.ContactType     = 'B' /* BillTo */    ) and
                                      (BT.BusinessUnit    = RR.BusinessUnit     )
  left outer join Statuses     S   on (S.StatusCode       = RR.Status           ) and
                                      (S.Entity           = 'Status'            ) and
                                      (S.BusinessUnit     = RR.BusinessUnit        )
order by RR.SortSeq;

Go
