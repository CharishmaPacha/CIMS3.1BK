/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/26  TK      pr_API_UPS_ProcessTrackingInfo, pr_API_USPS_ProcessTrackingInfo,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_ProcessTrackingInfo') is not null
  drop Procedure pr_API_UPS_ProcessTrackingInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_ProcessTrackingInfo: This process updates the lastest tracking
    information of the shipment in CarrierTrackingInfo table from the shipment tracking summary
    received from UPS.

  The response received from UPS carrier is of JSON format and sample file is checked into following path in SVN

  Path:  https://vsvn.foxfireindia.com:8443/svn/ant/aaf/branches/Dev/Documents
  FileName: UPS_TrackingInfo.txt
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_ProcessTrackingInfo
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,
          @vTranCount                   TCount,

          @vRawResponse                 TVarchar,
          @vBusinessUnit                TBusinessUnit;

begin /* pr_API_UPS_ProcessTrackingInfo */
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

  /* Get the lastest record and insert into #TrackingInfo */
  select top 1 TrackingNo, Activity, ActivityDesc, ActivityDate,
               cast(stuff(stuff(ActivityTime, 5, 0, ':') , 3 , 0 , ':') as time) as ActivityTime, -- Converts time format from hhmmss to hh:mm:ss
               City, State, Zip, Country
  into #TrackingInfo
  from openjson(@vRawResponse, '$.trackResponse.shipment') with (package   nvarchar(max) as JSON)
  cross apply openjson(package)  with (TrackingNo          TTrackingNo  '$.trackingNumber',
                                       activity            nvarchar(max) as JSON)
  cross apply openjson(activity) with (ActivityDate        TVarchar     '$.date',
                                       ActivityTime        TVarchar     '$.time',
                                       ActivityDesc        TVarchar     '$.status.description',
                                       location            nvarchar(max) as JSON)
  cross apply openjson(location) with (City                TCity        '$.address.city',
                                       State               TState       '$.address.stateProvince',
                                       Zip                 TZip         '$.address.postalCode',
                                       Country             TCountry     '$.address.country')
  order by ActivityDate desc, ActivityTime desc;  -- Get the latest trackinginfo

  /* Update current status on ExportTransactions table */
  update CTI
  set DeliveryStatus     = case when ActivityDesc = 'Delivered' then 'Delivered' else DeliveryStatus end,
      DeliveryDateTime   = case when ActivityDesc = 'Delivered' then dbo.fn_ConcatenateDateAndTime(ActivityDate, ActivityTime) else null end,
      LastEvent          = ActivityDesc,
      LastUpdateDateTime = dbo.fn_ConcatenateDateAndTime(ActivityDate, ActivityTime),
      LastLocation       = City + ', ' + State + ' ' + Country,
      ActivityInfo       = Activity,
      APIRecordId        = @TransactionRecordId,
      ResponseReceived   = getdate(),
      ModifiedDate       = getdate(),
      ExportStatus       = 'ToBeExported'
  from CarrierTrackingInfo CTI
    join #TrackingInfo TI on (TI.TrackingNo = CTI.TrackingNo) and
                             (CTI.Archived = 'N') and
                             (CTI.Carrier = 'UPS');

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
end /* pr_API_UPS_ProcessTrackingInfo */

Go
