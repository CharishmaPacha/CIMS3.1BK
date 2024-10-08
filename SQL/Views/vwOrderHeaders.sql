/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/05  SAK     Added DownloadedOn (HA-2703)
  2021/04/22  TK      Corrected Load Info mapping (HA-GoLive)
  2021/02/10  SGK     Added ReturnLabelRequired, TotalShipmentValue, ShippedDate, ShipFromCompanyId, UCC128LabelFormat, PackingListFormat, ContentsLabelFormat, PriceStickerFormat, PrevStatus, CreatedOn, ModifiedOn (CIMSV3-1364)
  2021/02/03  TK      Added EstimatedCartons (HA-1964)
  2021/02/23  PKK     Added WaveSeqNo and LoadSeqNo,
              SGK     Added ReturnLabelRequired, TotalShipmentValue, ShippedDate, ShipFromCompanyId, UCC128LabelFormat,
  2021/01/20  AY      Added LoadGroup (HA-1933)
  2020/10/02  AY      Added VASCodes & VASDesc fields to view
  2020/09/24  AY      Change to use WaveType instead of BatchType
  2020/06/01  AY      Added HostNumLines
  2020/05/24  AY      Added ShipViaDesc
  2020/05/18  MS      Added WaveGroup, WaveId & WaveNo (HA-593)
  2019/08/29  YJ      Added ShipToAddressLine2 (OB2-941)
  2019/01/09  AY      Added OrderStatus for V3
  2019/08/06  KBB     Added DeliveryStart & DeliveryEnd fields for Orders (S2GCA-891)
  2019/08/13  MJ      Mapped UDF11 value to the vwOH_UDF1 (FB-1330)
  2018/06/28  YJ      Added SourceSystem (FB-1162)
  2019/07/15  SDC     Added PackedDate field (CID-776)
  2019/07/05  AY      Generic carrier is not invalid. (CID-GoLive)
  2019/06/25  MJ      Added ShipCompletePercent field (CID-609)
  2019/04/12  YJ      Added CartonGroups field (CID-277)
  2018/12/11  MJ      Added ShipperAccountName (S2GCA-443)
  2018/11/28  RV      Added OH.AESNumber and OH.ShipmentRefNumber (S2G-1177)
  2018/09/18  MS      Added StatusGroup Field (OB2-606)
  2018/08/10  SV      Added ColorCode which determined ForeColor in UI (OB2-520)
  2018/08/06  AJ      Added UnitsToAllocate, UnitsToPick, UnitsToPack, UnitsToLoad, UnitsToShip, LPNsToShip and LPNsToLoad (OB2-461)
  2018/07/25  VM      Added NumCases (S2G-1006)
  2018/05/04  MJ      Added WaveDropLocation, WaveShipDate and DeliveryRequirement (S2G-804)
  2018/03/27  OK      Changes to populate Carrier as per the client requirement (S2G-507)
  2018/03/24  VM/AJ   Added ShipToCity, ShipToState, ShipToCountry and ShipToZip (S2G-478)
  2018/03/23  VM      Added Carrier (S2G-CRP)
  2017/08/22  SP      OrderHeaders: Added UDF11 - UDF30 (OB-548)
  2017/05/04  LRA     Changes to resolve the truncate issue with data (CIMS-1326)
  2017/02/20  YJ      Added fields DownloadedDate, QualifiedDate (HPI-1382)
  2016/12/16  KL      Added PrevWaveNo (HPI-1189)
  2016/12/16  SV      Added ProcessOperation (HPI-1175)
  2016/10/15  AY      Added several LPN/Unit fields (HPI-GoLive)
  2016/08/16  PSK     Changed the vwUDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2016/06/28  AY      Added BU to Contact joins (HPI-185)
  2016/06/21  TK      Mapped vwOH_UDF1 with PreProcess Flag (HPI-)
  2016/04/28  OK      Added ShipToName, ShipToAddressLine1, ShipToCityStateZip fields (NBD-428)
  2016/04/04  SV      Added WaveFlag. (NBD-337)
  2016/03/30  SV      Added ShipComplete (NBD-293)
  2015/09/14  YJ      Added ReceiptNumber, vwOH_UDFs (FB-381)
  2015/06/30  YJ      Mapped UDFs with OH_UDF's
  2015/05/24  AY      Added WaveType
  2014/03/11  DK      Added HasNotes
  2013/07/04  NY      Added CustomerName.
  2013/06/21  SP      Added ExchangeStatus field and vwUDF1...vwUDF5.
  2013/04/18  PK      Added  FreightCharges, FreightTerms, BillToAccount, BillToAddress
  2013/03/21  TD      Added TotalWeight, TotalVolume.
  2013/02/09  PK      Added Account, AccountName, OrderCategory1, OrderCategory2,
                        OrderCategory3, OrderCategory4, OrderCategory5.
  2012/10/23  NY      Corrected CancelDays formula
  2012/09/20  PKS     Added ShipToStore, LPNsAssigned.
  2012/09/10  AY      Added CancelDays.
  2012/09/07  NY      Replaced '' with 0.
  2012/09/06  PKS     Temporarily joins for Loads are removed, and empty string value passed
                      for LoadId, LoadNumber.
                      - #VM - This is decided to go for now is when discussed with NB, it will
                      not be so useful to show LoadId in Orderheaders page as an Order can be
                      on multiple Loads and if that is the case, it would be null. Hence showing
                      LoadId/Number on OH page and filtering it by LoadId does not retreive the
                      desired results.
  2012/09/04  SP      Added the fields "LoadId", "LoadNumber".
  2012/07/18  SP      Added the fields MarkForAddress,TotalSalesAmount and TotalDiscount.
  2012/07/03  NY      changed value '' to 0 for UnitsOrdered due to
                      type invalid exception occured in UI.
  2012/06/23  SP      Added UnitsOrdered, Warehouse (SVN Rev#1721)
  2012/05/24  PKS     Added PickZone.
  2012/05/16  PKS     Added NumLines, NumSKUs, NumUnits
  2012/04/25  PK      Added PickBatchId.
  2011/11/28  AA      Added ShortPick
  2011/11/26  SHR     Added Archived.
  2011/07/08  PK      Added ReturnAddrId.
  2011/02/04  PK      Removed cast for ModifiedDate and CreatedDate.
  2010/01/14  PK      Added OrderTypeDescription, StatusDescription.
  2010/09/24  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwOrderHeaders') is not null
  drop View dbo.vwOrderHeaders;
Go

Create View dbo.vwOrderHeaders (
  OrderId,
  PickTicket,
  SalesOrder,
  OrderType,
  OrderTypeDesc,
  OrderStatus,
  OrderStatusDesc,
  StatusGroup,

  OrderDate,
  NB4Date,
  DesiredShipDate,
  CancelDate,
  DeliveryStart,
  DeliveryEnd,
  DownloadedDate,
  QualifiedDate,
  PackedDate,
  CancelDays,

  CustPO,
  Account,
  AccountName,

  Priority,
  SoldToId,
  CustomerName,
  ShipToId,
  ShipToName,
  ShipToAddressLine1,
  ShipToAddressLine2,
  ShipToCityStateZip,
  ShipToCityState,
  ShipToCity,
  ShipToState,
  ShipToZip,
  ShipToCountry,
  ReturnAddress,
  MarkForAddress,
  ShipToStore,

  OrderCategory1,
  OrderCategory2,
  OrderCategory3,
  OrderCategory4,
  OrderCategory5,

  PickBatchId,
  PickBatchNo,
  WaveId,
  WaveNo,
  PrevWaveNo,
  WaveType,
  WaveTypeDesc,
  WaveDropLocation,
  WaveShipDate,

  Carrier,
  ShipVia,
  ShipViaDesc,
  ShipFrom,
  ShipFromCompanyId,

  Ownership,
  Warehouse,
  ShipperAccountName,
  AESNumber,
  ShipmentRefNumber,
  DeliveryRequirement,
  CarrierOptions,

  PickZone,
  PickBatchGroup,
  WaveGroup,
  CartonGroups,
  LoadGroup,

  NumLines,
  NumSKUs,
  NumLPNs,
  NumCases,
  NumUnits,
  EstimatedCartons,

  LPNsAssigned,
  LPNsPicked,
  LPNsPacked,
  LPNsStaged,
  LPNsLoaded,
  LPNsToLoad,
  LPNsShipped,
  LPNsToShip,

  UnitsAssigned,
  UnitsToAllocate,
  UnitsPicked,
  UnitsToPick,
  UnitsPacked,
  UnitsToPack,
  UnitsStaged,
  UnitsLoaded,
  UnitsToLoad,
  UnitsShipped,
  UnitsToShip,

  TotalVolume,
  TotalWeight,
  TotalSalesAmount,
  TotalShipmentValue,
  TotalTax,
  TotalShippingCost,
  TotalDiscount,

  FreightCharges,
  FreightTerms,
  BillToAccount,
  BillToAddress,
  ReceiptNumber,

  WaveSeqNo,
  LoadSeqNo,

  VASCodes,
  VASDescriptions,
  ShortPick,
  Comments,
  HasNotes,
  ShipCompletePercent,
  WaveFlag,

  UCC128LabelFormat,
  PackingListFormat,
  ContentsLabelFormat,
  PriceStickerFormat,
  ReturnLabelRequired,

  PrevStatus,
  PreprocessFlag,
  OrderAge,
  ColorCode,
  HostNumLines,
  ExchangeStatus,
  DateShipped,

  OrderTypeDescription, -- deprecated
  Status,               -- deprecated
  StatusDescription,    -- deprecated
  ShipComplete,         -- deprecated
  ProcessOperation,     -- deprecated

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

  /* Place holders for any new fields, if required */
  vwUDF1,
  vwUDF2,
  vwUDF3,
  vwUDF4,
  vwUDF5,

  /* We should use these only and drop the above ones eventually */
  vwOH_UDF1,
  vwOH_UDF2,
  vwOH_UDF3,
  vwOH_UDF4,
  vwOH_UDF5,

  LoadId,
  LoadNumber,

  SourceSystem,
  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy,
  CreatedOn,
  ModifiedOn,
  DownloadedOn
) As
select
  OH.OrderId,
  OH.PickTicket,
  OH.SalesOrder,
  OH.OrderType,
  OT.TypeDescription, /* OrderTypeDesc - V3 */
  OH.Status, /* OrderStatus */
  OS.StatusDescription, /* OrderStatusDesc */
  case
    when (OH.Status in ('O'/* Downloaded */,'N'/* New */,'W'/* Waved */))
      then 'To Process'
    when (OH.Status in ('S'/* Shipped */,'D'/* Completed */,'X'/* Cancelled */))
      then 'Closed'
    else
      'In Process'
  end, /* StatusGroup */

  cast(convert(varchar, OH.OrderDate,       101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.NB4Date,         101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.DesiredShipDate, 101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, OH.CancelDate,      101 /* mm/dd/yyyy */) as DateTime),
  OH.DeliveryStart,
  OH.DeliveryEnd,
  OH.DownloadedDate,
  OH.QualifiedDate,
  OH.PackedDate,
  datediff(Day, getdate(), OH.CancelDate), /* Cancel Days */

  OH.CustPO,
  OH.Account,
  OH.AccountName,

  OH.Priority,
  OH.SoldToId,
  OH.SoldToName,
  OH.ShipToId,
  OH.ShipToName,
  STA.AddressLine1,
  STA.AddressLine2,
  STA.CityStateZip,
  STA.CityState,
  STA.City,
  STA.State,
  STA.Zip,
  STA.Country,
  OH.ReturnAddress,
  OH.MarkForAddress,
  OH.ShipToStore,
  /* Order categories */
  OH.OrderCategory1,
  OH.OrderCategory2,
  OH.OrderCategory3,
  OH.OrderCategory4,
  OH.OrderCategory5,
  /* Wave info */
  W.RecordId,
  OH.PickBatchNo,
  W.RecordId,     /* Wave Id */
  OH.PickBatchNo, /* Wave No */
  OH.PrevWaveNo,
  W.WaveType,
  PBT.TypeDescription,
  W.DropLocation,
  W.ShipDate,

  /* if shipvia is invalid then carrier should display Invalid, They can process the
     orders as generic and update the carrier later */
  case when (SV.ShipVia is null) or (SV.Status = 'I' /* Inactive */)
       then 'Invalid'
       else SV.Carrier
  end, /* Carrier */
  OH.ShipVia,
  SV.Description, -- ShipViaDesc
  OH.ShipFrom,
  OH.ShipFromCompanyId,
  OH.Ownership,
  OH.Warehouse,

  OH.ShipperAccountName,
  OH.AESNumber,
  OH.ShipmentRefNumber,
  OH.DeliveryRequirement,
  OH.CarrierOptions,

  OH.PickZone,
  OH.PickBatchGroup,
  OH.PickBatchGroup, /* Wave Group */
  OH.CartonGroups,
  OH.LoadGroup,

  OH.NumLines,
  OH.NumSKUs,
  OH.NumLPNs,
  OH.NumCases,
  case when OH.OrderType <> 'B' then OH.NumUnits else 0 end, /* NumUnits */
  OH.EstimatedCartons,

  OH.LPNsAssigned,
  OH.LPNsPicked,
  OH.LPNsPacked,
  OH.LPNsStaged,
  OH.LPNsLoaded,
  OH.LPNsAssigned - OH.LPNsLoaded, /* LPNsToLoad */
  OH.LPNsShipped,
  OH.LPNsAssigned - OH.LPNsShipped, /* LPNsToShip */

  OH.UnitsAssigned,
  OH.NumUnits - OH.UnitsAssigned, /* UnitsToAllocate */
  OH.UnitsPicked,
  OH.UnitsAssigned - OH.UnitsPicked, /* Units To Pick */
  OH.UnitsPacked,
  OH.UnitsAssigned - OH.UnitsPacked, /* Units To Pack */
  OH.UnitsStaged,
  OH.UnitsLoaded,
  OH.UnitsAssigned - OH.UnitsLoaded, /* UnitsToLoad */
  OH.UnitsShipped,
  OH.UnitsAssigned - OH.UnitsShipped, /* UnitsToShip */

  OH.TotalVolume,
  OH.TotalWeight,
  OH.TotalSalesAmount,
  OH.TotalShipmentValue,
  OH.TotalTax,
  OH.TotalShippingCost,
  OH.TotalDiscount,

  OH.FreightCharges,
  OH.FreightTerms,
  OH.BillToAccount,
  OH.BillToAddress,
  OH.ReceiptNumber,

  OH.WaveSeqNo,
  OH.LoadSeqNo,

  OH.VASCodes,
  OH.VASDescriptions,
  OH.ShortPick,
  OH.Comments,
  OH.HasNotes,
  coalesce(OH.ShipCompletePercent, 0),
  OH.WaveFlag,

  OH.UCC128LabelFormat,
  OH.PackingListFormat,
  OH.ContentsLabelFormat,
  OH.PriceStickerFormat,
  OH.ReturnLabelRequired,

  OH.PrevStatus,
  OH.PreprocessFlag,
  datediff(d, OH.OrderDate, getdate()), /* Order Age */
  case
    when OH.Priority = 1
      then ';R' /* Red */
    else
      null
  end,
  OH.HostNumLines,
  OH.ExchangeStatus,
  OH.ShippedDate,

  /* Deprecated fields */
  OT.TypeDescription, /* OrderTypeDescription - V2 */
  OH.Status,
  OS.StatusDescription,
  OH.ShipComplete,
  OH.ProcessOperation,

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

  cast(' ' as varchar(50)), /* vwUDF1 */
  cast(' ' as varchar(50)), /* vwUDF2 */
  cast(' ' as varchar(50)), /* vwUDF3 */
  cast(' ' as varchar(50)), /* vwUDF4 */
  cast(' ' as varchar(50)), /* vwUDF5 */

  case when OH.PreProcessFlag = 'Q' then 'Qualified'
       when OH.PreProcessFlag = 'D' then 'Dis-Qualified'
       when OH.PreProcessFlag = 'Y' then 'Yes'
       when OH.PreProcessFlag = 'N' then 'No'
  end, /* vwOH_UDF1 */
  cast(' ' as varchar(50)), /* vwOH_UDF2 */
  cast(' ' as varchar(50)), /* vwOH_UDF3 */
  cast(' ' as varchar(50)), /* vwOH_UDF4 */
  cast(' ' as varchar(50)), /* vwOH_UDF5 */

  OH.LoadId,
  OH.LoadNumber,

  OH.SourceSystem,
  OH.Archived,
  OH.BusinessUnit,
  OH.CreatedDate,
  OH.ModifiedDate,
  OH.CreatedBy,
  OH.ModifiedBy,
  OH.CreatedOn,
  OH.ModifiedOn,
  OH.DownloadedOn
from
  OrderHeaders OH
    left outer join EntityTypes  OT  on (OT.TypeCode      = OH.OrderType   ) and
                                        (OT.Entity        = 'Order'        ) and
                                        (OT.BusinessUnit  = OH.BusinessUnit)
    left outer join Statuses     OS  on (OS.StatusCode    = OH.Status      ) and
                                        (OS.Entity        = 'Order'        ) and
                                        (OS.BusinessUnit  = OH.BusinessUnit)
    left outer join Waves        W   on (OH.PickBatchNo   = W.WaveNo       ) and
                                        (OH.BusinessUnit  = W.BusinessUnit )
    left outer join Contacts     STA on (OH.ShipToId      = STA.ContactRefId) and
                                        (STA.ContactType   = 'S' /* Ship */ ) and
                                        (OH.BusinessUnit  = STA.BusinessUnit)
    left outer join EntityTypes  PBT on (PBT.TypeCode     = W.WaveType     ) and
                                        (PBT.Entity       = 'Wave'         ) and
                                        (PBT.BusinessUnit = OH.BusinessUnit)
    left outer join ShipVias     SV  on (SV.Shipvia       = OH.ShipVia     );

Go
