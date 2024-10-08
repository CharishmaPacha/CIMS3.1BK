/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/04  RBV     Corrected the MaxUnits and MaxWeight default value 999999 to 99999 (HA-1654)
  2020/10/08  AY      Corrections to not show deprecated fields, removed Ownership & WH (HA-1553)
  2020/04/27  TK      Added MaxUnits (HA-298)
  2019/07/30  AY      Added NoLock hint
  2019/05/28  AY      Do not return carton types that are not visible
  2018/10/17  AY      Added MaxInnerDimension & several other fields (S2GCA-383)
  2103/04/27  TD      Added DisplayDescription.
  2011/08/26  AA      Initial Revision.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.vwCartonTypes') is not null
  drop View dbo.vwCartonTypes;
Go

Create View dbo.vwCartonTypes (
  RecordId,
  CartonType,
  Description,
  DisplayDescription,

  InnerLength,
  InnerWidth,
  InnerHeight,
  InnerVolume,

  EmptyWeight,
  MaxWeight,
  MaxUnits,
  MaxInnerDimension,
  CartonTypeFilter,  -- deprecated
  AvailableSpace,

  Account,  -- deprecated
  SoldToId, -- deprecated
  ShipToId, -- deprecated

  --Ownership, -- deprecated
  --Warehouse, -- deprecated

  Status,
  SortSeq,
  Visible,

  OuterLength,
  OuterWidth,
  OuterHeight,
  OuterVolume,

  CT_UDF1,
  CT_UDF2,
  CT_UDF3,
  CT_UDF4,
  CT_UDF5,

  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy)
as
select
  CT.RecordId,
  CT.CartonType,
  CT.Description,
  CT.CartonType + ' - ' + CT.Description,

  CT.InnerLength,
  CT.InnerWidth,
  CT.InnerHeight,
  CT.InnerVolume,

  CT.EmptyWeight,
  coalesce(nullif(CT.MaxWeight, 0), 99999),
  coalesce(nullif(CT.MaxUnits, 0), 99999),
  dbo.fn_MaxOfThree(CT.InnerLength, CT.InnerWidth, CT.InnerHeight),
  CT.CartonTypeFilter,  -- deprecated
  CT.AvailableSpace,

  CT.Account,  -- deprecated
  CT.SoldToId, -- deprecated
  CT.ShipToId, -- deprecated

  --CT.Ownership,
  --CT.Warehouse,

  CT.Status,
  CT.SortSeq,
  CT.Visible,

  CT.OuterLength,
  CT.OuterWidth,
  CT.OuterHeight,
  CT.OuterVolume,

  CT.CT_UDF1,
  CT.CT_UDF2,
  CT.CT_UDF3,
  CT.CT_UDF4,
  CT.CT_UDF5,

  CT.BusinessUnit,
  CT.CreatedDate,
  CT.ModifiedDate,
  CT.CreatedBy,
  CT.ModifiedBy
from
  CartonTypes CT with (NoLock)
where Visible = 1;

Go
