/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/18  YJ      Added PickTicket, WaveNo (CIMSV3-1212)
  2019/01/22  TK      Corrected UDFs (S2GMI-81)
  2019/01/18  RT      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwSerialNos') is not null
  drop View dbo.vwSerialNos;
Go

Create View dbo.vwSerialNos (
  RecordId,

  SerialNo,
  SerialNoStatus,
  SerialNoStatusDesc,

  LPNId,
  LPN,
  Pallet,
  Location,

  PickTicket,
  WaveNo,

  SKU,
  SKU1,
  SKU2,
  SKU3,
  SKU4,
  SKU5,

  LPNDetailId,
  SKUId,

  SN_UDF1,
  SN_UDF2,
  SN_UDF3,
  SN_UDF4,
  SN_UDF5,

  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  SN.RecordId,

  SN.SerialNo,
  SN.SerialNoStatus,
  SLS.StatusDescription,

  SN.LPNId,
  L.LPN,
  L.Pallet,
  L.Location,

  L.PickTicketNo,
  L.PickBatchNo,

  L.SKU,
  L.SKU1,
  L.SKU2,
  L.SKU3,
  L.SKU4,
  L.SKU5,

  SN.LPNDetailId,
  SN.SKUId,

  SN.SN_UDF1,
  SN.SN_UDF2,
  SN.SN_UDF3,
  SN.SN_UDF4,
  SN.SN_UDF5,

  SN.Archived,
  SN.BusinessUnit,
  SN.CreatedDate,
  SN.ModifiedDate,
  SN.CreatedBy,
  SN.ModifiedBy
from SerialNos SN
  left outer join LPNs               L on (L.LPNId          = SN.LPNId         )
  left outer join Statuses         SLS on (SLS.StatusCode   = SN.SerialNoStatus) and
                                          (SLS.Entity       = 'SerialNo'       ) and
                                          (SLS.BusinessUnit = SN.BusinessUnit  );

Go
