/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/26  TK      pr_API_UPS_ProcessTrackingInfo, pr_API_USPS_ProcessTrackingInfo,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_USPS_ProcessTrackingInfo') is not null
  drop Procedure pr_API_USPS_ProcessTrackingInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_USPS_ProcessTrackingInfo: This process updates the lastest tracking
    information of the shipment in CarrierTrackingInfo table from the shipment tracking summary
    received from USPS.

  The response received from UsPS carrier is of xml format and smaple file is checked into following path in SVN

  Path:  https://vsvn.foxfireindia.com:8443/svn/ant/aaf/branches/Dev/Documents
  FileName: USPS_TrackingInfo.xml
------------------------------------------------------------------------------*/
Create Procedure pr_API_USPS_ProcessTrackingInfo
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,
          @vTranCount                   TCount,

          @vRawResponse                 TVarchar,
          @vBusinessUnit                TBusinessUnit,

          @vDocumentId                  TInteger;

begin /* pr_API_USPS_ProcessTrackingInfo */
begin try
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vTranCount   = @@trancount;

  if (@vTranCount = 0) begin transaction;

  /* Get Transaction Info */
  select @vRawResponse  = RawResponse,
         @vBusinessUnit = BusinessUnit
  from APIOutboundTransactions
  where (RecordId = @TransactionRecordId);

  /* Prepare xml document */
  exec sp_xml_preparedocument @vDocumentId output, @vRawResponse;

  /* Get the lastest tracking info and insert into #TrackingInfo */
  select * into #TrackingInfo
  from  openxml(@vDocumentId, '/TrackResponse/TrackInfo/TrackSummary', 2)
  with (TrackingNo          TVarchar   '../@ID',
        ShipmentStatus      TVarchar   '../StatusCategory',
        LastEventDate       TDate      './EventDate',
        LastEventTime       TTime      './EventTime',
        LastEvent           TVarchar   './Event',
        LastEventCity       TCity      './EventCity',
        LastEventState      TState     './EventState',
        LastEventZIPCode    TZip       './EventZIPCode')

  /* Update current status on ExportTransactions table */
  update CTI
  set DeliveryStatus     = case when ShipmentStatus = 'Delivered' then 'Delivered' else DeliveryStatus end,
      DeliveryDateTime   = case when ShipmentStatus = 'Delivered' then dbo.fn_ConcatenateDateAndTime(TI.LastEventDate, TI.LastEventTime) else null end,
      LastEvent          = TI.LastEvent,
      LastUpdateDateTime = dbo.fn_ConcatenateDateAndTime(TI.LastEventDate, TI.LastEventTime),
      LastLocation       = LastEventCity + ', ' + LastEventState,
      ActivityInfo       = @vRawResponse,
      APIRecordId        = @TransactionRecordId,
      ResponseReceived   = getdate(),
      ModifiedDate       = getdate(),
      ExportStatus       = 'ToBeExported'
  from CarrierTrackingInfo CTI
    join #TrackingInfo TI on (TI.TrackingNo = CTI.TrackingNo) and
                             (CTI.Archived = 'N') and
                             (CTI.Carrier = 'USPS');

  /* Remove xml document */
  exec sp_xml_removedocument @vDocumentId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  if (@vTranCount = 0) commit transaction;
end try
begin catch
  if (@vTranCount = 0) rollback transaction

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_USPS_ProcessTrackingInfo */

Go
