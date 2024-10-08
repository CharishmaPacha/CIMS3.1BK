/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  ********************************* IMPORTANT *********************************
  There is a Base version of this Table exists. Taken here for additional fields.
  So, if there are any common fields to be added, MUST consider adding the same in Base version as well.
  *****************************************************************************

  2020/07/16  NB      Devices: Added LabelPrinterName, ReportPrinterName (CIMSV3-1012)
  2020/07/07  NB      Devices: Added LastLogoutDateTime, DeviceConfigIP (CIMSV3-1011)
  2020/04/06  RT      Devices: Included defaultPrinter (HA-81)
  2017/07/05  TD      Added Devices.LPN (GNC-1582)
  2015/02/19  AY      Added Devices.LastLoginDateTime, LastUsedDateTime
  2015/02/18  AY      Added Devices.PickPathPosition
------------------------------------------------------------------------------*/

Go

if object_id('dbo.Devices') is not null
/*------------------------------------------------------------------------------
  Table: Devices

  WMS fields
  PickingDirection - 1 Forward, 2 Backward path for Cart Picking
------------------------------------------------------------------------------*/
alter table Devices add
  PickPathPosition         varchar(max),   -- where the user is in the Pick Path at the moment
  PickSequence             TPickSequence,  -- where the user is in the Pick Path at the moment
  PickingDirection         TFlags,

  BatchNo                  TPickBatchNo,
  Location                 TLocation,
  Row                      TLocation,
  AisleId                  TLocation,
  LPN                      TLPN,
  Cart                     TPallet,

  CurrentPickingResponse   varchar(max);

Go
