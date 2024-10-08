/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2012/07/06  TD      Added ShipVia Description
  2012/06/18  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwShipments') is not null
  drop View dbo.vwShipments;
Go

Create View dbo.vwShipments (
  ShipmentId,

  ShipFrom,
  SoldTo,
  ShipTo,
  ShipVia,
  ShipViaDescription,
  BillTo,

  FreightTerms,
  FreightTermsDescription,
  ShipmentValue,

  IsSmallPackage,
  ShipmentType,
  ShipmentTypeDescription,

  Status,
  StatusDescription,
  Priority,

  MaxOrders,
  MaxPallets,
  MaxLPNs,
  MaxUnits,

  NumOrders,
  NumPallets,
  NumLPNs,
  NumPackages,
  NumUnits,

  LoadId,
  LoadNumber,
  LoadSequence,

  BoLId,
  BoLNumber,

  DesiredShipDate,
  ShippedDate,
  DeliveryDate,
  TransitDays,

  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,
  UDF6,
  UDF7,
  UDF8,
  UDF9,
  UDF10,

  Archived,
  BusinessUnit,

  CreatedDate,
  CreatedBy,

  ModifiedDate,
  ModifiedBy
) As
select
  S.ShipmentId,

  S.ShipFrom,
  S.SoldTo,
  S.ShipTo,
  S.ShipVia,
  SV.LookUpDescription,
  S.BillTo,

  S.FreightTerms,
  FT.LookUpDescription,
  S.ShipmentValue,

  S.IsSmallPackage,
  S.ShipmentType,
  ET.TypeDescription,

  S.Status,
  ST.StatusDescription,
  S.Priority,

  S.MaxOrders,
  S.MaxPallets,
  S.MaxLPNs,
  S.MaxUnits,

  S.NumOrders,
  S.NumPallets,
  S.NumLPNs,
  S.NumPackages,
  S.NumUnits,

  S.LoadId,
  S.LoadNumber,
  S.LoadSequence,

  S.BoLId,
  S.BoLNumber,

  S.DesiredShipDate,
  S.ShippedDate,
  S.DeliveryDate,
  S.TransitDays,

  S.UDF1,
  S.UDF2,
  S.UDF3,
  S.UDF4,
  S.UDF5,
  S.UDF6,
  S.UDF7,
  S.UDF8,
  S.UDF9,
  S.UDF10,

  S.Archived,
  S.BusinessUnit,

  S.CreatedDate,
  S.CreatedBy,

  S.ModifiedDate,
  S.ModifiedBy
from
  Shipments S
  left outer join Statuses      ST  on (ST.Entity         = 'Shipment'     ) and
                                       (S.Status          = ST.StatusCode  ) and
                                       (ST.BusinessUnit   = S.BusinessUnit )
  left outer join LookUps       FT  on (FT.LookUpCategory = 'FreightTerms' ) and
                                       (S.FreightTerms    = FT.LookUpCode  ) and
                                       (FT.BusinessUnit   = S.BusinessUnit )
  left outer join LookUps       SV  on (SV.LookUpCategory = 'ShipVia'      ) and
                                       (S.ShipVia         = SV.LookUpCode  ) and
                                       (SV.BusinessUnit   = S.BusinessUnit )
  left outer join EntityTypes   ET  on (ET.Entity         = 'Shipment'     ) and
                                       (S.ShipmentType    = ET.TypeCode    ) and
                                       (ET.BusinessUnit   = S.BusinessUnit );

Go
