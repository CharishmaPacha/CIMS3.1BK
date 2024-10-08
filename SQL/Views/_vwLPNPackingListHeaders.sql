/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/26  PHK     Using PL_UDF3 for printing the SKU on Label (BK-531)
  2021/04/30  SJ      Made changes to get ShipVia.SCAC instead of StandardAttributes.SCAC (HA-2693)
  2021/02/18  MS      Added WaveSeqNo (BK-174)
  2020/06/30  MS      Added SCAC (HA-1046)
  2020/06/26  AY      Made changes to get the Warehouse lookup description (HA-924 & HA-925)
  2019/01/17  SAK     Added Pallet and PalletId fields taken from GNC (CIMS-2791)
  2019/11/21  RBV     Added ShipToAddressLine3 (HPI-2802)
  2019/07/26  RT      Included TrailerNumber (GNC-2305)
  2019/07/24  KSK     Added new fields ShipFromContactPerson, SoldToContactPerson,ShipToContactPerson (CID-853)
  2019/07/01  KSK     Added new fields ShipFromCountryName, ShipmentRefNumber, SoldToCountryName, ShipToCountryName, TaxId (CID-632)
  2019/05/16  RT      To use convert instead of cast to avoid special charaters in the xml (S2GCA-629)
  2019/03/20  AJ      Added TotalVolume (CID-195)
  2018/10/25  MS      Master Copy (CIMS 2063 & HPI 2050)
  2018/08/10  MS      Added UnitsAssigned field (S2GCA-358)
  2018/07/26  RT      Added WaveNo, Service Level and NumCases fields and changed the NumInnerpacks to Num cases(S2GCA-85)
  2018/07/25  RT      Extended the PL_UDFs to 20 fields and Mapped Service Level to PL_UDF3 and NumInnerPacks to PL_UDF5(S2G-1006)
  2018/07/17  RT      Mapped SERVICELEVEL node from Standard attribute to PL_UDF3 field,
                      Made changes to get the SoldToId details if there no BillToId details(S2GCA-61)
  2018/06/18  TK      Added AlternateLPN (S2GCA-61)
  2018/04/25  CK      Mapped DeliveryRequirement with OH_UDF10 field (S2G-704)
  2018/04/03  CK      Added UCCBarcode, PickZone (S2G-494)
  2017/08/28  SV      Introduced OH_UDF11 to OH_UDF30 (OB-553)
  2016/09/21  KL      Map Carrier to PL_UDF4 field (HPI-713)
  2016/08/16  PSK     Changed the PL_UDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2016/07/16  TD/AY   Added join with BU for contacts
  2016/07/12  KL      Added TaskId field (HPI-258)
  2016/06/29  KL      Added Account, AccountName fields (HPI-106)
  2016/05/19  YJ      Sync up vwLPNPackingListHeaders and vwPackingListHeaders,
                        because we use common filed for both pakinglist (NBD-483)
  2015/10/27  TK      Retrieve NumLPNs assigned to the order(ACME-384)
  2015/10/26  TK      Added Display Address (ACME-351)
  2015/10/20  AY      Added CartonTypeDesc
  2015/09/14  TK      Added Mark For address fields (ACME-323)
  2015/07/30  RV      Map Pick Batch to PL_UDF2 (ACME-257).
  2015/06/24  RV      Added ShipToStore.
  2015/06/06  AY      Changed to use fn_Contacts_GetShipToAddress
  2015/05/21  RV      Added FreightTerms.
  2015/05/12  RV      Added CartonType.
  2015/04/23  VM      Retreive ShipTo Address from ContactType 'S'
                        - If we remove this, there is a chance of double header in Packging lists
                          when contact exists in multiple types (ex:'S' and 'C')
  2015/04/10  AK      Added SoldToPhoneNo and ShipToPhoneNo.
  2015/01/16  PKS     NumLPNs count set to one.
  2014/12/29  PKS     Added FreightCharges,NumLPNs
  2014/12/23  SV      Included 'Comments' as well (required for Cabela's gift order customized message)
                        and added BillTo info.
  2014/03/31  AY      Moved fields around and added Load fields freeing up UDFs again
  2014/02/12  NY      Added Warehouse.
  2013/10/23  TD      XSSpecifc--Passing NumPallets and LoadInfo.
  2013/05/06  AY      Changed to use views for SoldTo and ShipTo addresses
  2013/04/06  PK      Added OrderType, OrderTypeDescription, CustPO, CancelDate,
                       PL_UDF1, PL_UDF2, PL_UDF3, PL_UDF4, PL_UDF5.
  2011/10/27  AA      Package sequence number to display in report footer
  2011/10/26  AA      LPN created, modified or current date as shipped date
  2011/10/09  AY      Get SoldTo/ShipTo addresses directly from Contacts
  2011/08/24  AA      Initial Revision.
------------------------------------------------------------------------------*/
Go

/* Need to keep this in sync with vwPackingListHeaders */

if object_id('dbo.vwLPNPackingListHeaders') is not null
  drop View dbo.vwLPNPackingListHeaders;
Go

Create View dbo.vwLPNPackingListHeaders (
  LPNId,
  LPN,
  LPNType,
  CartonType,
  CartonTypeDesc,
  Status,

  CoO,
  InnerPacks,
  Quantity,
  EstimatedWeight,
  ActualWeight,
  EstimatedVolume,
  ActualVolume,

  PalletId,
  Pallet,
  Ownership,
  OwnershipDesc,

  ShipmentId,
  LoadId,
  ASNCase,
  TrackingNo,
  PackageSeqNo,
  Warehouse,
  PickZone,
  UCCBarcode,

  /* Order - Key info */
  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  OrderTypeDescription,
  CustPO,
  ShipmentRefNumber,
  OrderDate,
  DesiredShipDate,
  CancelDate,
  ShippedDate,
  ShowOrderTotals,
  Comments,
  Account,
  AccountName,
  TaskId,
  WaveNo,
  AlternateLPN,

  /* Bill To Address */
  BillToId,
  BillToCustomerName,
  BillToAddressLine1,
  BillToAddressLine2,
  BillToCity,
  BillToState,
  BillToZip,
  BillToCityStateZip,
  BillToCountry,
  BillToAddressDisplay,
  BillToPhoneNo,

  /* Ship From Address */
  ShipFrom,
  ShipFromName,
  ShipFromAddressLine1,
  ShipFromAddressLine2,
  ShipFromCity,
  ShipFromState,
  ShipFromZip,
  ShipFromCityStateZip,
  ShipFromCountry,
  ShipFromCountryName,
  ShipFromAddressDisplay,
  ShipFromPhoneNo,
  ShipFromContactPerson,
  ShipFromTaxId,

  /* Sold To Address */
  SoldToId,
  SoldToCustomerName,
  SoldToAddressLine1,
  SoldToAddressLine2,
  SoldToCity,
  SoldToState,
  SoldToZip,
  SoldToCityStateZip,
  SoldToCountry,
  SoldToCountryName,
  SoldToAddressDisplay,
  SoldToPhoneNo,
  SoldToContactPerson,
  SoldToTaxId,
  SoldToReference1,
  SoldToReference2,

  /* Ship To Address */
  ShipToId,
  ShipToCustomerName,
  ShipToAddressLine1,
  ShipToAddressLine2,
  ShipToAddressLine3,
  ShipToCity,
  ShipToState,
  ShipToZip,
  ShipToCityStateZip,
  ShipToCountry,
  ShipToCountryName,
  ShipToAddressDisplay,
  ShipToPhoneNo,
  ShipToEmailId,
  ShipToContactPerson,
  ShipToTaxId,
  ShipToReference1,
  ShipToReference2,

  ShipToStore,

  /* Mark For Address */
  MarkForAddress,
  MarkForCustomerName,
  MarkForAddressLine1,
  MarkForAddressLine2,
  MarkForCity,
  MarkForState,
  MarkForZip,
  MarkForCityStateZip,
  MarkForCountry,
  MarkForAddressDisplay,
  MarkForPhoneNo,

  /* ReturnAddress */
  ReturnAddress,
  ReturnToName,
  ReturnToAddressLine1,
  ReturnToAddressLine2,
  ReturnToCity,
  ReturnToState,
  ReturnToZip,
  ReturnToCityStateZip,
  ReturnToCountry,
  ReturnAddressDisplay,
  ReturnToPhoneNo,

  /* ShipVia */
  ShipVia,
  DeliveryRequirement,
  ShipViaDescription,   /* ShipVia Description */
  Carrier,
  ServiceLevel,
  SCAC,

  TotalSalesAmount,
  TotalTax,
  TotalShippingCost,
  FreightCharges,
  FreightTerms,
  TotalDiscount,

  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,

  /* Load */
  LoadNumber,
  TrailerNumber,
  MasterBoL,
  ClientLoad,
  NumPallets,

  NumLPNs,
  NumUnits,
  LPNsAssigned,
  NumCases,
  UnitsAssigned,

  TotalWeight,
  TotalVolume,

  WaveSeqNo,

  /* Order UDFs */
  OH_UDF1,
  OH_UDF2,
  OH_UDF3,
  OH_UDF4,
  OH_UDF5,
  OH_UDF6,
  OH_UDF7,
  OH_UDF8,
  OH_UDF9,
  OH_UDF10,
  OH_UDF11,
  OH_UDF12,
  OH_UDF13,
  OH_UDF14,
  OH_UDF15,
  OH_UDF16,
  OH_UDF17,
  OH_UDF18,
  OH_UDF19,
  OH_UDF20,
  OH_UDF21,
  OH_UDF22,
  OH_UDF23,
  OH_UDF24,
  OH_UDF25,
  OH_UDF26,
  OH_UDF27,
  OH_UDF28,
  OH_UDF29,
  OH_UDF30,

  /* LPN UDFs */
  LPN_UDF1,
  LPN_UDF2,
  LPN_UDF3,
  LPN_UDF4,
  LPN_UDF5,

  /* PL UDFs for Future Use */
  PL_UDF1,
  PL_UDF2,
  PL_UDF3,
  PL_UDF4,
  PL_UDF5,
  PL_UDF6,
  PL_UDF7,
  PL_UDF8,
  PL_UDF9,
  PL_UDF10,
  PL_UDF11,
  PL_UDF12,
  PL_UDF13,
  PL_UDF14,
  PL_UDF15,
  PL_UDF16,
  PL_UDF17,
  PL_UDF18,
  PL_UDF19,
  PL_UDF20,

  BusinessUnit
) As
select
  L.LPNId,
  L.LPN,
  L.LPNType,
  L.CartonType,
  CT.Description,
  L.Status,

  L.CoO,
  L.InnerPacks,
  L.Quantity,

  L.EstimatedWeight,
  coalesce(nullif(L.ActualWeight, 0), L.EstimatedWeight),
  L.EstimatedVolume,
  L.ActualVolume,

  L.PalletId,
  L.Pallet,
  L.Ownership,
  OWR.LookupDescription,

  L.ShipmentId,
  L.LoadId,
  L.ASNCase,
  L.TrackingNo,
  L.PackageSeqNo,
  L.DestWarehouse,
  OH.PickZone,
  L.UCCBarcode,

  L.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  OT.TypeDescription,
  OH.CustPO,
  OH.ShipmentRefNumber,
  cast(convert(varchar, OH.OrderDate,   101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.DesiredShipDate, 101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.CancelDate, 101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, coalesce(L.ModifiedDate, L.CreatedDate, getdate()),  101 /* mm/dd/yyyy */) as DateTime),

  case when (coalesce(OH.UDF2,'N') = 'Y') then
         'N'
       when (coalesce(OH.ShortPick,'N') = 'Y') then
         'N'
       when (OH.Status = 'C' /* Picking */) then
         'N' /* Order Not Picked Completely */
       when (OH.Status = 'P' /* Picked */) then
         'Y' /* Order Picked Completely */
       when (OH.Status = 'K' /* Packed */) then
         'Y' /* Order Packed */
       when (OH.Status = 'S' /* Shipped */) then
         'Y' /* Order Shipped  */
       when (OH.Status = 'D' /* Completed */) then
         'Y' /* Order Completed  */
  else
    'N'
  end,

  OH.Comments,
  OH.Account,
  OH.AccountName,
  L.TaskId,
  OH.PickBatchNo,
  L.AlternateLPN,

  /* Bill To */
  coalesce(nullif(OH.BillToAddress, ''), OH.SoldToId),
  coalesce(nullif(BTA.Name, ''),         STA.Name),
  coalesce(nullif(BTA.AddressLine1, ''), STA.AddressLine1),
  coalesce(nullif(BTA.AddressLine2, ''), nullif(STA.AddressLine2, '')),
  coalesce(nullif(BTA.City, ''),         STA.City),
  coalesce(nullif(BTA.State, ''),        STA.State),
  coalesce(nullif(BTA.Zip, ''),          STA.Zip),
  coalesce(nullif(BTA.CityStateZip, ''), STA.CityStateZip),
  coalesce(nullif(BTA.Country, ''),      STA.Country),
  /* BillToAddressDisplay */
  coalesce(nullif(BTA.Name, '') + '|', '') +
  coalesce(nullif(BTA.AddressLine1, '') + '|', '') +
  coalesce(nullif(BTA.AddressLine2, '') + '|', '') +
  (coalesce(nullif(MFA.City, '')+', ', '') + coalesce(nullif(MFA.State, '')+' ', '') + coalesce(nullif(MFA.Zip,''), '')),
  BTA.PhoneNo,

  /* Ship From */
  OH.ShipFrom,
  SHFR.Name,
  SHFR.AddressLine1,
  SHFR.AddressLine2,
  SHFR.City,
  SHFR.State,
  SHFR.Zip,
  SHFR.CityStateZip,
  SHFR.Country,
  dbo.fn_LookUps_GetDesc('Country', SHFR.Country, OH.BusinessUnit, default),

  /* ShipFromAddressDisplay */
  coalesce(nullif(SHFR.Name, '') + '|', '') +
  coalesce(nullif(SHFR.AddressLine1, '') + '|', '') +
  coalesce(nullif(SHFR.AddressLine2, '') + '|', '') +
  (coalesce(nullif(SHFR.City, '')+', ', '') + coalesce(nullif(SHFR.State, '')+' ', '') + coalesce(nullif(SHFR.Zip,''), '')),
  SHFR.PhoneNo,
  SHFR.ContactPerson,
  SHFR.TaxId,

  /* Sold To */
  OH.SoldToId,
  STA.Name,
  STA.AddressLine1,
  nullif(STA.AddressLine2, ''),
  STA.City,
  STA.State,
  STA.Zip,
  STA.CityStateZip,
  STA.Country,
  dbo.fn_LookUps_GetDesc('Country', STA.Country, OH.BusinessUnit, default),
  /* SoldToAddressDisplay */
  coalesce(nullif(STA.Name, '') + '|', '') +
  coalesce(nullif(STA.AddressLine1, '') + '|', '') +
  coalesce(nullif(STA.AddressLine2, '') + '|', '') +
  (coalesce(nullif(STA.City, '')+', ', '') + coalesce(nullif(STA.State, '')+' ', '') + coalesce(nullif(STA.Zip,''), '')),
  STA.PhoneNo,
  STA.ContactPerson,
  STA.TaxId,
  STA.Reference1,
  STA.Reference2,

  /* Ship To */
  OH.ShipToId,
  SHTA.Name,
  SHTA.AddressLine1,
  nullif(SHTA.AddressLine2, ''),
  SHTA.AddressLine3,
  SHTA.City,
  SHTA.State,
  SHTA.Zip,
  SHTA.CityStateZip,
  SHTA.Country,
  dbo.fn_LookUps_GetDesc('Country', SHTA.Country, OH.BusinessUnit, default),
  /* ShipToAddressDisplay */
  coalesce(nullif(SHTA.Name, '') + '|', '') +
  coalesce(nullif(SHTA.AddressLine1, '') + '|', '') +
  coalesce(nullif(SHTA.AddressLine2, '') + '|', '') +
  coalesce(nullif(SHTA.AddressLine3, '') + '|', '') +
  (coalesce(nullif(SHTA.City, '')+', ', '') + coalesce(nullif(SHTA.State, '')+' ', '') + coalesce(nullif(SHTA.Zip,''), '')),
  SHTA.PhoneNo,
  SHTA.Email,
  SHTA.ContactPerson,
  SHTA.TaxId,
  SHTA.Reference1,
  SHTA.Reference2,

  OH.ShipToStore,

  /* Mark For */
  OH.MarkForAddress,
  MFA.Name,
  MFA.AddressLine1,
  MFA.AddressLine2,
  MFA.City,
  MFA.State,
  MFA.Zip,
  MFA.CityStateZip,
  MFA.Country,
  /* MarkForAddressDisplay */
  coalesce(nullif(MFA.Name, '') + '|', '') +
  coalesce(nullif(MFA.AddressLine1, '') + '|', '') +
  coalesce(nullif(MFA.AddressLine2, '') + '|', '') +
  (coalesce(nullif(MFA.City, '')+', ', '') + coalesce(nullif(MFA.State, '')+' ', '') + coalesce(nullif(MFA.Zip,''), '')),
  MFA.PhoneNo,

  /* ReturnAddress */
  OH.ReturnAddress,
  RTA.Name,
  RTA.AddressLine1,
  RTA.AddressLine2,
  RTA.City,
  RTA.State,
  RTA.Zip,
  RTA.CityStateZip,
  RTA.Country,
  /* ReturnAddressDisplay */
  coalesce(nullif(RTA.Name, '') + '|', '') +
  coalesce(nullif(RTA.AddressLine1, '') + '|', '') +
  coalesce(nullif(RTA.AddressLine2, '') + '|', '') +
  (coalesce(nullif(RTA.City, '')+', ', '') + coalesce(nullif(RTA.State, '')+' ', '') + coalesce(nullif(RTA.Zip,''), '')),
  RTA.PhoneNo,

  OH.ShipVia,
  OH.DeliveryRequirement,
  SV.Description,   /* ShipVia Description */
  SV.Carrier,
  coalesce(nullif(cast(SV.StandardAttributes as xml).value('(/SERVICELEVEL/node())[1]', 'TVarchar'), ''), SV.Description), /* ShipVia SERVICELEVEL */
  SV.SCAC,

  OH.TotalSalesAmount,
  OH.TotalTax,
  OH.TotalShippingCost,
  OH.FreightCharges,
  OH.FreightTerms,
  OH.TotalDiscount,

  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,

  LD.LoadNumber,
  LD.TrailerNumber,
  LD.MasterBoL,
  LD.ClientLoad,
  LD.NumPallets,

  OH.NumLPNs,
  OH.NumUnits,
  OH.LPNsAssigned, /* NumLPNs */
  OH.NumCases,     /* NumCases */
  case
    /* Consider NumUnits when the Status is New or Waved */
    when (OH.Status in ('N', 'W' /* New, Batched */)) then
      OH.NumUnits /* NumUnits */
    else
      OH.UnitsAssigned
  end /* UnitsAssigned */,
  coalesce(OH.TotalWeight,''),
  coalesce(OH.TotalVolume,''),

  OH.WaveSeqNo,

  OH.UDF1,
  OH.UDF2,
  OH.UDF3,
  OH.UDF4,
  OH.UDF5,
  OH.UDF6,
  OH.UDF7,
  OH.UDF8,
  OH.UDF9,
  OH.UDF10,
  OH.UDF11,
  OH.UDF12,
  OH.UDF13,
  OH.UDF14,
  OH.UDF15,
  OH.UDF16,
  OH.UDF17,
  OH.UDF18,
  OH.UDF19,
  OH.UDF20,
  OH.UDF21,
  OH.UDF22,
  OH.UDF23,
  OH.UDF24,
  OH.UDF25,
  OH.UDF26,
  OH.UDF27,
  OH.UDF28,
  OH.UDF29,
  OH.UDF30,

  L.UDF1, /* LPN UDF1 */
  L.UDF2, /* LPN UDF2 */
  L.UDF3, /* LPN UDF3 */
  L.UDF4, /* LPN UDF4 */
  L.UDF5, /* LPN UDF5 */

  cast('Carton Packing List' as varchar(50)), /* Report Caption */
  cast(dbo.fn_LookUps_GetDesc('Warehouse', OH.Warehouse, OH.BusinessUnit, default) as varchar(50)), /* Warehouse Desc */
  L.SKU,                    /* PL_UDF3  - SKU */
  cast(' ' as varchar(50)), /* PL_UDF4  - Future use */
  cast(' ' as varchar(50)), /* PL_UDF5  - Future use */
  cast(' ' as varchar(50)), /* PL_UDF6  - Future use */
  cast(' ' as varchar(50)), /* PL_UDF7  - Future use */
  cast(' ' as varchar(50)), /* PL_UDF8  - Future use */
  cast(' ' as varchar(50)), /* PL_UDF9  - Future use */
  cast(' ' as varchar(50)), /* PL_UDF10 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF11 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF12 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF13 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF14 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF15 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF16 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF17 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF18 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF19 - Future use */
  cast(' ' as varchar(50)), /* PL_UDF20 - Future use */

  L.BusinessUnit
from LPNs                          L
             join OrderHeaders    OH   on (L.OrderId          = OH.OrderId          )
  left outer join ShipVias        SV   on (OH.ShipVia         = SV.ShipVia          )
  left outer join vwSoldToAddress STA  on (STA.ContactRefId   = OH.SoldToId         )      /* Sold To Address */
  left outer join Contacts        BTA  on (BTA.ContactRefId   = OH.BillToAddress    ) and  /* Bill To Address */
                                          (BTA.ContactType    = 'B' /* Bill To */   ) and
                                          (BTA.BusinessUnit   = OH.BusinessUnit     )
  left outer join Contacts        SHFR on (SHFR.ContactRefId  = OH.ShipFrom         ) and  /* Ship From Address */
                                          (SHFR.ContactType   = 'F' /* Ship From */ ) and
                                          (SHFR.BusinessUnit  = OH.BusinessUnit     )
  left outer join Contacts        RTA  on (RTA.ContactRefId   = OH.ReturnAddress    ) and  /* Return Address */
                                          (RTA.ContactType    = 'R' /* Return */    ) and
                                          (RTA.BusinessUnit   = OH.BusinessUnit     )
  left outer join Contacts        MFA  on (MFA.ContactRefId   = OH.MarkForAddress   ) and  /* Mark For Address */
                                          (MFA.ContactType    = 'S' /* Ship To */   ) and
                                          (MFA.BusinessUnit   = OH.BusinessUnit     )
  left outer join Lookups         OWR  on (OWR.LookupCode     = OH.Ownership        ) and
                                          (OWR.LookupCategory = 'Owner'             ) and
                                          (OWR.BusinessUnit   = OH.BusinessUnit     )
  left outer join EntityTypes     OT   on (OT.TypeCode        = OH.OrderType        ) and
                                          (OT.Entity          = 'Order'             ) and
                                          (OT.BusinessUnit    = OH.BusinessUnit     )
  left outer join Loads           LD   on (L.LoadId           = LD.LoadId           )
  left outer join CartonTypes     CT   on (L.CartonType       = CT.CartonType       )
  cross apply dbo.fn_Contacts_GetShipToAddress(OH.OrderId, OH.ShipToId) SHTA              /* Ship To Address */
where (L.LPNType in ('C' /* Carton */, 'S' /* Ship Carton */));

Go
