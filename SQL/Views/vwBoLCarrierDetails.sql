/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/11  AY      Added ShipTo info (HA-1559)
  2016/08/17  PSK     Changed the vwUDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2012/12/07  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwBoLCarrierDetails') is not null
  drop View dbo.vwBoLCarrierDetails;
Go

Create View dbo.vwBoLCarrierDetails (
  BoLCarrierDetailId,

  BoLId,
  BoLNumber,

  LoadId,
  LoadNumber,

  ShipmentId,
  ShipTo,
  ShipToName,
  ShipToCity,
  ShipToState,
  ShipToZip,
  ShipToCityStateZip,
  ShipToCityState,

  HandlingUnitQty,
  HandlingUnitType,
  PackageQty,
  PackageType,

  Volume,
  Weight,

  Hazardous,
  CommDescription,
  NMFCCode,
  CommClass,

  BCD_UDF1, /* ShipTOStore */
  BCD_UDF2,
  BCD_UDF3,
  BCD_UDF4,
  BCD_UDF5,

  /* Future use */
  vwBCD_UDF1,
  vwBCD_UDF2,
  vwBCD_UDF3,
  vwBCD_UDF4,
  vwBCD_UDF5,

  SortSeq,
  BusinessUnit,
  CreatedDate,
  CreatedBy,
  ModifiedDate,
  ModifiedBy
) As
select
  BCD.BoLCarrierDetailId,

  BCD.BoLId,
  S.BoLNumber,

  S.LoadId,
  S.LoadNumber,

  S.ShipmentId,
  S.ShipTo,
  ST.Name,
  ST.City,
  ST.State,
  ST.Zip,
  ST.CityStateZip,
  ST.CityState,

  BCD.HandlingUnitQty,
  BCD.HandlingUnitType,
  BCD.PackageQty,
  BCD.PackageType,

  BCD.Volume,
  BCD.Weight,

  BCD.Hazardous,
  BCD.CommDescription,
  BCD.NMFCCode,
  BCD.CommClass,

  BCD.UDF1,  /* ShipToStore */
  BCD.UDF2,
  BCD.UDF3,
  BCD.UDF4,
  BCD.UDF5,

  /* Future use */
  cast(' ' as varchar(50)), /* vwBCD_UDF1 */
  cast(' ' as varchar(50)), /* vwBCD_UDF2 */
  cast(' ' as varchar(50)), /* vwBCD_UDF3 */
  cast(' ' as varchar(50)), /* vwBCD_UDF4 */
  cast(' ' as varchar(50)), /* vwBCD_UDF5 */

  BCD.SortSeq,
  BCD.BusinessUnit,
  BCD.CreatedDate,
  BCD.CreatedBy,
  BCD.ModifiedDate,
  BCD.ModifiedBy
From
  BoLCarrierDetails BCD
  join Shipments    S   on (BCD.BoLId =  S.BoLId)
  join Contacts     ST  on (ST.ContactRefId = S.ShipTo) and (ST.ContactType = 'S')
;

Go
