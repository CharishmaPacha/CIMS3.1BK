/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/10/30  RV      Initial Version (BK-1148)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS2_TrackingInfo_ProcessResponse') is not null
  drop Procedure pr_API_UPS2_TrackingInfo_ProcessResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS2_TrackingInfo_ProcessResponse: This process updates the lastest tracking
    information of the shipment in CarrierTrackingInfo table from the shipment tracking summary
    received from UPS.
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS2_TrackingInfo_ProcessResponse
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,
          @vTranCount                   TCount,

          @vRawResponse                 TVarchar,
          @vErrors                      TVarchar,
          @vBusinessUnit                TBusinessUnit;

  declare @ttTrackingInfo table
         (RecordId                      TRecordId identity(1,1),
          TrackingNo                    TTrackingNo,
          Activity                      TNVarchar,
          ActivityDesc                  TDescription,
          ActivityDate                  TDate,
          ActivityTime                  TTime,
          City                          TCity,
          State                         TState,
          Zip                           TZip,
          Country                       TCountry,
          Code                          TTypeCode,
          Message                       TMessage);

  declare @ttTrackingWarnings table
         (RecordId                      TRecordId identity(1,1),
          TrackingNo                    TTrackingNo,
          Code                          TTypeCode,
          Message                       TMessage);

begin /* pr_API_UPS2_TrackingInfo_ProcessResponse */
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

  /*-------------------- Create hash tables --------------------*/
  if (object_id('tempdb..#TrackingWarnings') is null) select * into #TrackingWarnings from @ttTrackingWarnings;
  if (object_id('tempdb..#TrackingInfo') is null) select * into #TrackingInfo from @ttTrackingInfo;

  /* Note: For now we only encounter warnings when the request have invalid tracking numbers and getting warning code as TW0001 */
  insert into #TrackingWarnings(TrackingNo, Code, Message)
  select TrackingNo, Code, Message
  from openjson( @vRawResponse, '$.trackResponse.shipment')
  with
  (
    TrackingNo    TTrackingNo       '$.inquiryNumber',
    warnings      TNVarchar         as json
  )
  cross apply openjson(warnings)
  with
  (
    Code      TTypeCode        '$.code',
    Message   TMessage         '$.message'
  )

  /* Get the lastest record and insert into #TrackingInfo */
  insert into #TrackingInfo (TrackingNo, Activity, ActivityDesc, ActivityDate, ActivityTime, City, State, Zip, Country)
  select top 1 TrackingNo, Activity, ActivityDesc, ActivityDate,
               cast(stuff(stuff(ActivityTime, 5, 0, ':') , 3 , 0 , ':') as time) as ActivityTime, -- Converts time format from hhmmss to hh:mm:ss
               City, State, Zip, Country
  from openjson(@vRawResponse, '$.trackResponse.shipment')
  with
  (
    package   nvarchar(max) as json
  )
  cross apply openjson(package)
  with
  (
    TrackingNo          TTrackingNo  '$.trackingNumber',
    activity            nvarchar(max) as json
  )
  cross apply openjson(activity)
  with
  (
    ActivityDate        TVarchar     '$.date',
    ActivityTime        TVarchar     '$.time',
    ActivityDesc        TVarchar     '$.status.description',
    location            nvarchar(max) as json
  )
  cross apply openjson(location)
  with
  (
    City                TCity        '$.address.city',
    State               TState       '$.address.stateProvince',
    Zip                 TZip         '$.address.postalCode',
    Country             TCountry     '$.address.country'
  )
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
    join #TrackingInfo TI on (TI.TrackingNo = CTI.TrackingNo) and (CTI.Carrier = 'UPS')

  /* Note: For now we only encounter warnings when the request have invalid tracking numbers and getting warning code as TW0001 */
  update CTI
  set DeliveryStatus     = case when TW.Code= 'TW0001' then 'Ignored' else DeliveryStatus end,
      ResponseReceived   = getdate(),
      ModifiedDate       = getdate()
  from CarrierTrackingInfo CTI
    join #TrackingWarnings TW on (TW.TrackingNo = CTI.TrackingNo) and (CTI.Carrier = 'UPS')

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS2_TrackingInfo_ProcessResponse */

Go