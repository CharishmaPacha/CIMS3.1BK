/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_CT_Export_FedEx_GetEventData') is not null
  drop Procedure pr_API_CT_Export_FedEx_GetEventData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_CT_Export_FedEx_GetEventData: For each CTI record, builds the
    Tracking history data from the response received from FedEx

  #CTI_TrackHist_Data TCarrierTrackingEventData
------------------------------------------------------------------------------*/
Create Procedure pr_API_CT_Export_FedEx_GetEventData
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Process carrier response and create json data */
  ;with XMLNAMESPACES(
    'http://schemas.xmlsoap.org/soap/envelope/' AS e
  )
  insert into #CTI_TrackHist_Data (RecordId, EventDateTime, EventDesc, EventLocation, EventStatusDesc, EventStatusType)
    select RecordId,
           ActInfo_XML.value('(e:Envelope/e:Body/TrackReply/CompletedTrackDetails/TrackDetails/Events/Timestamp)[1]', 'datetime'),
           ActInfo_XML.value('(e:Envelope/e:Body/TrackReply/CompletedTrackDetails/TrackDetails/Events/EventDescription)[1]', 'varchar(max)'),

           ActInfo_XML.value('(e:Envelope/e:Body/TrackReply/CompletedTrackDetails/TrackDetails/Events/Address/City)[1]', 'varchar(25)') + ',' +
           ActInfo_XML.value('(e:Envelope/e:Body/TrackReply/CompletedTrackDetails/TrackDetails/Events/Address/StateOrProvinceCode)[1]', 'varchar(2)') + ',' +
           ActInfo_XML.value('(e:Envelope/e:Body/TrackReply/CompletedTrackDetails/TrackDetails/Events/Address/CountryCode)[1]', 'varchar(2)'),

           ActInfo_XML.value('(e:Envelope/e:Body/TrackReply/CompletedTrackDetails/TrackDetails/StatusDetail/Description)[1]', 'varchar(20)'),
           ActInfo_XML.value('(e:Envelope/e:Body/TrackReply/CompletedTrackDetails/TrackDetails/StatusDetail/Code)[1]', 'varchar(5)')
    from #CTI_Subset
    where (Carrier = 'FedEx');

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_CT_Export_FedEx_GetEventData */

Go
