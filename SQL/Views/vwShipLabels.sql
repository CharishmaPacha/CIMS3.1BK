/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/24  MS      Added Missing Fields (HA-2413)
  2020/10/06  MRK     Migrated changes from FB Prod(CIMSV3-1059)
  2017/06/30  NY      Initial Revision.
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwShipLabels') is not null
  drop View dbo.vwShipLabels;
Go

Create View dbo.vwShipLabels (
  RecordId,

  EntityType,
  EntityId,
  EntityKey,

  PackageLength,
  PackageWidth,
  PackageHeight,
  PackageVolume,
  PackageWeight,

  OrderId,
  PickTicket,
  TotalPackages,

  TaskId,

  WaveId,
  WaveNo,

  LabelType,
  TrackingNo,
  TrackingBarcode,
  Barcode,
  Label,
  ZPLLabel,
  RequestedShipVia,
  ShipVia,
  Carrier,
  CarrierInterface,
  ServiceSymbol,
  MSN,
  ListNetCharge,
  AcctNetCharge,
  InsuranceFee,
  Status,

  ProcessStatus,
  ProcessedInstance,
  ProcessBatch,
  ProcessedDateTime,

  ExportStatus,
  ExportInstance,
  ExportBatch,

  Priority,

  ManifestExportStatus,
  ManifestExportTimeStamp,
  ManifestExportBatch,

  AlertSent,

  Reference,
  Notifications,
  NotificationSource,
  NotificationTrace,

  IsValidTrackingNo,

  Archived,
  BusinessUnit,

  CreatedDate,
  CreatedOn,
  ModifiedDate,
  CreatedBy,
  ModifiedBy
) As
select
  S.RecordId,

  S.EntityType,
  S.EntityId,
  S.EntityKey,

  S.PackageLength,
  S.PackageWidth,
  S.PackageHeight,
  S.PackageVolume,
  S.PackageWeight,

  S.OrderId,
  S.PickTicket,
  S.TotalPackages,

  S.TaskId,

  S.WaveId,
  S.WaveNo,

  S.LabelType,
  S.TrackingNo,
  S.TrackingBarcode,
  S.Barcode,
  '', -- S.Label commented for performance reasons
  S.ZPLLabel,
  S.RequestedShipVia,
  S.ShipVia,
  S.Carrier,
  S.CarrierInterface,
  S.ServiceSymbol,
  S.MSN,
  S.ListNetCharge,
  S.AcctNetCharge,
  S.InsuranceFee,
  S.Status,

  S.ProcessStatus,
  S.ProcessedInstance,
  S.ProcessBatch,
  S.ProcessedDateTime,

  S.ExportStatus,
  S.ExportInstance,
  S.ExportBatch,

  S.Priority,

  S.ManifestExportStatus,
  S.ManifestExportTimeStamp,
  S.ManifestExportBatch,

  S.AlertSent,

  S.Reference,
  S.Notifications,
  S.NotificationSource,
  S.NotificationTrace,

  S.IsValidTrackingNo,

  S.Archived,
  S.BusinessUnit,

  S.CreatedDate,
  S.CreatedOn,
  S.ModifiedDate,
  S.CreatedBy,
  S.ModifiedBy
from ShipLabels S
where Archived = 'N';

Go
