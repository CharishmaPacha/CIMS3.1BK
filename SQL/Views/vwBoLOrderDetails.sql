/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/03  AY      Added new fields NumPackages & Reference fields (FB-2225)
  2020/10/11  AY      Added ShipTo info (HA-1559)
  2016/08/17  PSK     Changed the vwUDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2012/12/07  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwBoLOrderDetails') is not null
  drop View dbo.vwBoLOrderDetails;
Go

Create View dbo.vwBoLOrderDetails (
  BoLOrderDetailId,
  BoLId,
  BoLNumber,

  LoadId,
  LoadNumber,

  CustomerOrderNo,

  ShipmentId,
  ShipTo,
  ShipToName,
  ShipToCity,
  ShipToState,
  ShipToZip,
  ShipToCityStateZip,
  ShipToCityState,

  NumPallets,
  NumLPNs,
  NumInnerPacks,
  NumUnits,
  NumPackages,
  NumShippables, /* Future use */

  Volume,
  Weight,
  Palletized,

  ShipperInfo,
  SortSeq,
  BODGroupCriteria,

  BOD_Reference1,
  BOD_Reference2,
  BOD_Reference3,
  BOD_Reference4,
  BOD_Reference5,

  BOD_UDF1, /* ShipTOStore */
  BOD_UDF2,
  BOD_UDF3,
  BOD_UDF4,
  BOD_UDF5,

  /* Future use */
  vwBOD_UDF1,
  vwBOD_UDF2,
  vwBOD_UDF3,
  vwBOD_UDF4,
  vwBOD_UDF5,

  BusinessUnit,
  CreatedDate,
  CreatedBy,
  ModifiedDate,
  ModifiedBy
) As
select
  BOD.BoLOrderDetailId,
  BOD.BoLId,
  S.BoLNumber,

  S.LoadId,
  S.LoadNumber,

  BOD.CustomerOrderNo,

  S.ShipmentId,
  S.ShipTo,
  ST.Name,
  ST.City,
  ST.State,
  ST.Zip,
  ST.CityStateZip,
  ST.CityState,

  BOD.NumPallets,
  BOD.NumLPNs,
  BOD.NumInnerPacks,
  BOD.NumUnits,
  BOD.NumPackages,
  BOD.NumShippables,

  BOD.Volume,
  BOD.Weight,
  BOD.Palletized,

  BOD.ShipperInfo,
  BOD.SortSeq,
  BOD.BODGroupCriteria,

  BOD.BOD_Reference1,
  BOD.BOD_Reference2,
  BOD.BOD_Reference3,
  BOD.BOD_Reference4,
  BOD.BOD_Reference5,

  BOD.UDF1, /* ShipToStore */
  BOD.UDF2,
  BOD.UDF3,
  BOD.UDF4,
  BOD.UDF5,

  /* Future use */
  cast(' ' as varchar(50)), /* vwBOD_UDF1 */
  cast(' ' as varchar(50)), /* vwBOD_UDF2 */
  cast(' ' as varchar(50)), /* vwBOD_UDF3 */
  cast(' ' as varchar(50)), /* vwBOD_UDF4 */
  cast(' ' as varchar(50)), /* vwBOD_UDF5 */

  BOD.BusinessUnit,
  BOD.CreatedDate,
  BOD.CreatedBy,
  BOD.ModifiedDate,
  BOD.ModifiedBy
From
  BoLOrderDetails BOD
  join Shipments    S on (BOD.BoLId =  S.BoLId)
  join Contacts    ST on (ST.ContactRefId = S.ShipTo) and (ST.ContactType = 'S')
;

Go
