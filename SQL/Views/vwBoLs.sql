/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/15  MJ      Added ShipToName (S2G-1205)
  2015/06/19  YJ      Added FoB,BoLCID,UDF1,BoLInstructions.
  2013/01/12  AY      Corrected UDFs.
  2012/12/07  TD      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwBoLs') is not null
  drop View dbo.vwBoLs;
Go

Create View dbo.vwBoLs (
  BoLId,
  BoLNumber ,
  VICSBoLNumber,
  LoadId,
  LoadNumber,

  /* Future Use - these are actually defined on Load for now */
  TrailerNumber,
  SealNumber,
  ProNumber,

  ShipVia,
  ShipViaDescription,
  ShipFromAddressId,
  ShipToAddressId,
  ShipToName,
  ShipToLocation, /* Store No */
  FoB,
  BoLCID,
  UDF1,
  BillToAddressId,

  BoLType,
  BoLTypeDesc,
  MasterBoL,
  FreightTerms,
  BoLInstructions,

  BoL_UDF1,
  BoL_UDF2,
  BoL_UDF3,
  BoL_UDF4,
  BoL_UDF5,
  BoL_UDF6,
  BoL_UDF7,
  BoL_UDF8,
  BoL_UDF9,
  BoL_UDF10,

  BusinessUnit,
  CreatedDate,
  CreatedBy,
  ModifiedDate,
  ModifiedBy
) As
select
  B.BoLId,  /* Bill of lading Id */
  B.BoLNumber,  /* Bill of lading Number */
  B.VICSBoLNumber,
  B.LoadId,
  L.LoadNumber,

  B.TrailerNumber,
  B.SealNumber,
  B.ProNumber,

  B.ShipVia,
  S.Description,
  B.ShipFromAddressId,
  B.ShipToAddressId,
  SHTA.Name,
  B.ShipToLocation,
  B.FoB,
  B.BoLCID,
  B.UDF1,
  B.BillToAddressId,

  B.BoLType,
  B.BoLTypeDesc,
  substring( B.MasterBoL, 8, 9), /* MasterBoL - show only the Sequence part */
  B.FreightTerms,
  B.BoLInstructions,

  B.UDF1,
  B.UDF2,
  B.UDF3,
  B.UDF4,
  B.UDF5,
  B.UDF6,
  B.UDF7,
  B.UDF8,
  B.UDF9,
  B.UDF10,

  B.BusinessUnit,
  B.CreatedDate,
  B.CreatedBy,
  B.ModifiedDate,
  B.ModifiedBy
From
  BoLs B
  left outer join ShipVias S    on (S.ShipVia         = B.ShipVia     )
  left outer join Contacts SHTA on (B.ShipToAddressId = SHTA.ContactId) -- BoL.ShipToAddressId is ContactId not ContactRefId
  left outer join Loads    L    on (B.LoadId          = L.LoadId      )
;

Go
