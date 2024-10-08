/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/03  SGK     Added HostNumLines, PrepareRecvFlag, PreprocessFlag, SourceSystem, ModifiedOn (CIMSV3-1334)
  2020/11/05  MS      Added New Fields SortLanes, SortOptions (JL-294)
  2020/08/05  SJ      Added AppointmentDateTime (HA-1228)
  2020/01/09  RV      Added ReceiptStatus (CIMSV3-671)
  2015/09/14  YJ      Added PickTicket, vwROH_UDFs (FB-381)
  2014/11/01  NY      Corrected the computation of QtyToReceive.
  2013/08/26  AY      Added QtyToReceive
  2013/04/16  PKS     Added BillNo, SealNo, InvoiceNo, ContainerNo, DateShipped, Archived.
  2013/04/09  TD      Added LPNsInTransit,LPNsReceived,UnitsInTransit,UnitsReceived.
  2013/02/09  PK      Added Vessel, NumLPNs, NumUnits, ContainerSize.
  2012/07/06  AY      Dropped BU Description, Added Warehouse
  2011/02/04  PK      Removed cast for ModifiedDate and CreatedDate.
  2011/01/21  PK      Demo Purpose : Showing vendorId as VendorName if VendorName is not avaiable.
  2011/01/14  PK      Added ReceiptTypeDesc, StatusDescription, BusinessUnitDescription.
  2010/10/21  VM      Added VendorName
  2010/09/24  PK      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwReceiptHeaders') is not null
  drop View dbo.vwReceiptHeaders;
Go

Create View dbo.vwReceiptHeaders (
  ReceiptId,
  ReceiptNumber,
  ReceiptType,
  ReceiptTypeDesc,

  Status,
  ReceiptStatus,
  ReceiptStatusDesc,
  StatusDescription,

  VendorId,
  VendorName,
  Ownership,
  Warehouse,

  HostNumLines,
  NumLPNs,
  NumUnits,
  LPNsInTransit,
  LPNsReceived,
  UnitsInTransit,
  UnitsReceived,
  QtyToReceive,

  DateOrdered,
  DateShipped,
  DateExpected,

  Vessel,
  BillNo,
  SealNo,
  InvoiceNo,
  ContainerNo,
  ContainerSize,

  ETACountry,
  ETACity,
  ETAWarehouse,
  AppointmentDateTime,

  PickTicket,

  SortLanes,
  SortOptions,
  PrepareRecvFlag,
  PreprocessFlag,

  /* Having generic UDF fields is wrong, so we would need to drop these eventually. Added ROH_UDF* fields */
  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,

  ROH_UDF1,
  ROH_UDF2,
  ROH_UDF3,
  ROH_UDF4,
  ROH_UDF5,

  vwROH_UDF1,
  vwROH_UDF2,
  vwROH_UDF3,
  vwROH_UDF4,
  vwROH_UDF5,

  SourceSystem,
  Archived,
  BusinessUnit,
  CreatedDate,
  ModifiedDate,
  CreatedBy,
  ModifiedBy,
  ModifiedOn
) As
select
  RH.ReceiptId,
  RH.ReceiptNumber,
  RH.ReceiptType,
  ET.TypeDescription,
  RH.Status,
  RH.Status, /* Mapped to ReceiptStatus column */
  ST.StatusDescription, /* mapped to ReceiptStatusDesc column */
  ST.StatusDescription,

  RH.VendorId,
  coalesce(V.VendorName, RH.VendorId),
  RH.Ownership,
  RH.Warehouse,

  RH.HostNumLines,
  RH.NumLPNs,
  RH.NumUnits,
  RH.LPNsInTransit,
  RH.LPNsReceived,
  RH.UnitsInTransit,
  RH.UnitsReceived,
  /* QtyToReceive */
  RH.QtyToReceive,

  cast(convert(varchar, RH.DateOrdered,  101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, RH.DateShipped,  101 /* mm/dd/yyyy */) as DateTime),
  cast(convert(varchar, RH.DateExpected, 101 /* mm/dd/yyyy */) as DateTime),

  RH.Vessel,
  RH.BillNo,
  RH.SealNo,
  RH.InvoiceNo,
  RH.ContainerNo,
  RH.ContainerSize,

  RH.ETACountry,
  RH.ETACity,
  RH.ETAWarehouse,
  RH.AppointmentDateTime,

  RH.PickTicket,

  RH.SortLanes,
  RH.SortOptions,
  RH.PrepareRecvFlag,
  RH.PreprocessFlag,

  /* Duplicate set, will be dropped eventually */
  RH.UDF1,
  RH.UDF2,
  RH.UDF3,
  RH.UDF4,
  RH.UDF5,

  RH.UDF1,
  RH.UDF2,
  RH.UDF3,
  RH.UDF4,
  RH.UDF5,

  cast(' ' as varchar(50)), /* vwROH_UDF1 */
  cast(' ' as varchar(50)), /* vwROH_UDF2 */
  cast(' ' as varchar(50)), /* vwROH_UDF3 */
  cast(' ' as varchar(50)), /* vwROH_UDF4 */
  cast(' ' as varchar(50)), /* vwROH_UDF5 */

  RH.SourceSystem,
  RH.Archived,
  RH.BusinessUnit,
  RH.CreatedDate,
  RH.ModifiedDate,
  RH.CreatedBy,
  RH.ModifiedBy,
  RH.ModifiedOn
from
ReceiptHeaders RH
 left outer join Vendors         V   on (RH.VendorId     = V.VendorId     )
 left outer join EntityTypes     ET  on (RH.ReceiptType  = ET.TypeCode    ) and
                                        (ET.Entity       = 'Receipt'      ) and
                                        (ET.BusinessUnit = RH.BusinessUnit)
 left outer join Statuses        ST  on (RH.Status       = ST.StatusCode  ) and
                                        (ST.Entity       = 'Receipt'      ) and
                                        (ST.BusinessUnit = RH.BusinessUnit);
Go