/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/08/18  RV      Initial version (BK-1132)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_TrackingInfo_ProcessResponse') is not null
  drop Procedure pr_API_FedEx2_TrackingInfo_ProcessResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_TrackingInfo_ProcessResponse: This process updates the lastest tracking
    information of the shipment in CarrierTrackingInfo table from the shipment tracking summary
    received from FedEx.

  Doc Ref:  https://developer.fedex.com/api/en-us/catalog/track/v1/docs.html
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_TrackingInfo_ProcessResponse
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,

          @vRawResponseJSON             TNVarchar,
          @vBusinessUnit                TBusinessUnit;

  declare @ttTrackingInfo table
          (RecordId                     TRecordId identity(1,1),
           TrackingNumber               TTrackingNo,
           ShipmentStatus               TStatus,
           ErrorCode                    TName,
           ErrorDescription             TVarchar,
           LastEventDateTime            TString,
           LastEvent                    TVarchar,
           LastEventCity                TCity,
           LastEventState               TState,
           LastEventZIPCode             TZip
          )
begin /* pr_API_FedEx2_TrackingInfo_ProcessResponse */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get Transaction Info */
  select @vRawResponseJSON  = RawResponse,
         @vBusinessUnit     = BusinessUnit
  from APIOutboundTransactions
  where (RecordId = @TransactionRecordId);

  /* If invalid recordid, exit */
  if (@@rowcount = 0)  return;

  if (object_id('tempdb..#TrackingInfo') is null) select * into #TrackingInfo from @ttTrackingInfo;

  /* Populate the tracking info from the response */
  insert into #TrackingInfo(TrackingNumber, ShipmentStatus, ErrorCode, ErrorDescription,
                            LastEventDateTime, LastEvent, LastEventCity, LastEventState, LastEventZIPCode)
    select TrackingNumber, ShipmentStatus, ErrorCode, ErrorDescription,
          LastEventDateTime, LastEvent, LastEventCity, LastEventState, LastEventZIPCode
    from OPENJSON (@vRawResponseJSON, '$.output.completeTrackResults')
      with
      (
        TrackingNumber        TTrackingNo       '$.trackingNumber',
        TrackResultsJSON      TNVarchar         '$.trackResults' as json
      )
      as TrackResults
      CROSS APPLY OPENJSON(TrackResults.TrackResultsJSON)
      with
      (
        ShipmentStatus      TStatus   '$.latestStatusDetail.description',
        ErrorCode           TName     '$.error.code',
        ErrorDescription    TVarchar  '$.error.message',
        LastEventDateTime   TString   '$.scanEvents[0].date',
        LastEvent           TVarchar  '$.scanEvents[0].eventDescription',
        LastEventCity       TCity     '$.scanEvents[0].scanLocation.city',
        LastEventState      TState    '$.scanEvents[0].scanLocation.stateOrProvinceCode',
        LastEventZIPCode    TZip      '$.scanEvents[0].scanLocation.postalCode'
      );

  /* Update current status on CarrierTrackingInfo table */
  update CTI
  /* If we get any error then we should update DeliveryStatus as Error otherwise those records will be processed again and again */
  set DeliveryStatus     = case when (ErrorCode is not null) then 'Error'
                                when ShipmentStatus = 'Delivered' then 'Delivered'
                                else DeliveryStatus
                           end,
      DeliveryDateTime   = case when (ShipmentStatus = 'Delivered') then convert(datetime, left(LastEventDateTime, 19), 126) else null end,
      LastEvent          = TI.LastEvent,
      LastUpdateDateTime = convert(datetime, left(LastEventDateTime, 19), 126),
      LastLocation       = LastEventCity + ', ' + LastEventState,
      ActivityInfo       = @vRawResponseJSON,
      APIRecordId        = @TransactionRecordId,
      ResponseReceived   = getdate(),
      ModifiedDate       = getdate(),
      ExportStatus       = 'ToBeExported'
  from CarrierTrackingInfo CTI
    join #TrackingInfo TI on (TI.TrackingNumber = CTI.TrackingNo) and (CTI.BusinessUnit = @vBusinessUnit) and
                             (CTI.Carrier = 'FEDEX');

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_TrackingInfo_ProcessResponse */

Go
