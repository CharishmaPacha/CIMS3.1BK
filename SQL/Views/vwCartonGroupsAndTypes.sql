/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/24  TK      Added Dimensions (S2GCA-1202)
  2020/06/30  AY      Added fields from CG and CT for presentation
  2020/06/26  HYP     Removed the fields (HA-796)
  2019/07/30  AY      Added NoLock hint
  2019/02/04  TK      Initial Revision (HPI-2380)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.vwCartonGroupsAndTypes') is not null
  drop View dbo.vwCartonGroupsAndTypes;
Go

Create View dbo.vwCartonGroupsAndTypes (
  RecordId,

  CartonGroup,
  CartonType,
  CartonGroupDesc,
  CartonTypeDesc,
  CartonGroupDisplayDesc,
  CartonTypeDisplayDesc,

  AvailableSpace,
  MaxWeight,
  MaxUnits,

  CG_AvailableSpace,
  CG_MaxWeight,
  CG_MaxUnits,

  CT_AvailableSpace,
  CT_MaxWeight,
  CT_MaxUnits,

  CT_InnerDimensions,
  MaxInnerDimension,
  FirstDimension,
  SecondDimension,
  ThirdDimension,
  InnerLength,
  InnerWidth,
  InnerHeight,
  InnerVolume,
  EmptyWeight,

  CT_OuterDimensions,
  OuterLength,
  OuterWidth,
  OuterHeight,
  OuterVolume,

  CGT_Status,
  CG_Status,
  CG_SortSeq,
  CG_Visible,

  CT_Status,
  CT_SortSeq,
  CT_Visible,

  CG_UDF1,
  CG_UDF2,
  CG_UDF3,
  CG_UDF4,
  CG_UDF5,

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
  CG.RecordId,

  CG.CartonGroup,
  CG.CartonType,
  CG.Description,
  CT.Description,
  CG.CartonGroup + ' - ' + CG.Description,
  CT.CartonType + ' - ' + CT.Description,

  coalesce(CG.AvailableSpace, CT.AvailableSpace),     -- Available Space can be defined at CartonGroup level or at Carton Level
  coalesce(CG.MaxWeight,      CT.MaxWeight, 999999),  -- same as above
  coalesce(CG.MaxUnits,       CT.MaxUnits,  999999),  -- same as above

  CG.AvailableSpace,
  CG.MaxWeight,
  CG.MaxUnits,

  CT.AvailableSpace,
  CT.MaxWeight,
  CT.MaxUnits,

  CT.InnerDimensions,
  dbo.fn_MaxOfThree(CT.InnerLength, CT.InnerWidth, CT.InnerHeight),
  FN.FirstNumber,
  FN.SecondNumber,
  FN.ThirdNumber,
  CT.InnerLength,
  CT.InnerWidth,
  CT.InnerHeight,
  CT.InnerVolume,
  CT.EmptyWeight,

  CT.OuterDimensions,
  CT.OuterLength,
  CT.OuterWidth,
  CT.OuterHeight,
  CT.OuterVolume,

  case when CG.Status = 'A' and CT.Status = 'A' then 'A' else 'I' end, -- CGT_Status

  CG.Status,
  CG.SortSeq,
  CG.Visible,

  CT.Status,
  CT.SortSeq,
  CT.Visible,

  CG.CG_UDF1,
  CG.CG_UDF2,
  CG.CG_UDF3,
  CG.CG_UDF4,
  CG.CG_UDF5,

  CT.CT_UDF1,
  CT.CT_UDF2,
  CT.CT_UDF3,
  CT.CT_UDF4,
  CT.CT_UDF5,

  CG.BusinessUnit,
  CG.CreatedDate,
  CG.ModifiedDate,
  CG.CreatedBy,
  CG.ModifiedBy
from CartonGroups CG with (NoLock)
  left outer join CartonTypes CT with (NoLock) on (CG.CartonType = CT.CartonType)
  cross apply dbo.fn_SortValuesAscending(CT.InnerLength, CT.InnerWidth, CT.InnerHeight) FN;

Go
