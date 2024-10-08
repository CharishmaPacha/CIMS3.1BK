/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx_TrackingInfo_ProcessResponse') is not null
  drop Procedure pr_API_FedEx_TrackingInfo_ProcessResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx_TrackingInfo_ProcessResponse: This process updates the lastest tracking
    information of the shipment in CarrierTrackingInfo table from the shipment tracking summary
    received from FedEx.

  The response received from FedEx carrier is of xml format and sample file is checked into following path in SVN

  Path:  https://vsvn/svn/ant/aaf/branches/Dev/Documents
  FileName: FedExTrackingResponse.xml
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx_TrackingInfo_ProcessResponse
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,
          @vTranCount                   TCount,

          @vRawResponse                 TVarchar,
          @vBusinessUnit                TBusinessUnit,

          @vDocumentId                  TInteger;

begin /* pr_API_FedEx_TrackingInfo_ProcessResponse */
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

  /* Remove the Unwanted text in the Node to get the data from Xml */
  set @vRawResponse = replace(convert(varchar(max),@vRawResponse), '<TrackReply xmlns="http://fedex.com/ws/track/v16">', '<TrackReply>');

  /* Prepare xml document */
  exec sp_xml_preparedocument @vDocumentId output, @vRawResponse , '<root xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"/>'

  select * into #TrackingInfo
  from openxml(@vDocumentId,'soap:Envelope/soap:Body/TrackReply/CompletedTrackDetails/TrackDetails')
  with
  (
    TrackingNumber      TVarchar  './TrackingNumber',
    ShipmentStatus      TVarchar  './StatusDetail/Description',
    NotificationStatus  TVarchar  './Notification/Severity',
    LastEventDateTime   TDatetime './Events/Timestamp',
    LastEvent           TVarchar  './Events/EventDescription',
    LastEventCity       TCity     './Events/Address/City',
    LastEventState      TState    './Events/Address/StateOrProvinceCode',
    LastEventZIPCode    TZip      './Events/Address/PostalCode'
  )

  /* Update current status on CarrierTrackingInfo table */
  update CTI
  set DeliveryStatus     = case when NotificationStatus = 'ERROR' then 'Ignore' /* If we get any error then we should update DeliveryStatus as Ignore otherwise those records will be processed again and agin */
                                when ShipmentStatus = 'Delivered' then 'Delivered'
                                else DeliveryStatus
                           end,
      DeliveryDateTime   = case when ShipmentStatus = 'Delivered' then LastEventDateTime else null end,
      LastEvent          = TI.LastEvent,
      LastUpdateDateTime = LastEventDateTime,
      LastLocation       = LastEventCity + ', ' + LastEventState,
      ActivityInfo       = @vRawResponse,
      APIRecordId        = @TransactionRecordId,
      ResponseReceived   = getdate(),
      ModifiedDate       = getdate(),
      ExportStatus       = 'ToBeExported'
  from CarrierTrackingInfo CTI
    join #TrackingInfo TI on (TI.TrackingNumber = CTI.TrackingNo) and
                             (CTI.Carrier = 'FEDEX');

  /* Remove xml document */
  exec sp_xml_removedocument @vDocumentId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx_TrackingInfo_ProcessResponse */

Go
