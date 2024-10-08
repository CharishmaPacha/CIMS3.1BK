/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_CT_Export_USPS_GetEventData') is not null
  drop Procedure pr_API_CT_Export_USPS_GetEventData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_CT_Export_USPS_GetEventData:

  #CTI_TrackHist_Data TCarrierTrackingEventData
------------------------------------------------------------------------------*/
Create Procedure pr_API_CT_Export_USPS_GetEventData
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
  insert into #CTI_TrackHist_Data (RecordId, EventDateTime, EventDesc, EventLocation, EventStatusDesc, EventStatusType)
    select RecordId,
           cast( (ActInfo_XML.value('(/TrackResponse/TrackInfo/TrackSummary/EventDate)[1]', 'varchar(25)') + ' ' +
                  ActInfo_XML.value('(/TrackResponse/TrackInfo/TrackSummary/EventTime)[1]', 'varchar(25)')) as datetime),

           ActInfo_XML.value('(/TrackResponse/TrackInfo/TrackSummary/Event)[1]', 'varchar(max)'),

           ActInfo_XML.value('(/TrackResponse/TrackInfo/TrackSummary/EventCity)[1]', 'varchar(25)') + ',' +
           ActInfo_XML.value('(/TrackResponse/TrackInfo/TrackSummary/EventState)[1]', 'varchar(2)') + ',' +
           ActInfo_XML.value('(/TrackResponse/TrackInfo/TrackSummary/EventCountry)[1]', 'varchar(2)'),

           ActInfo_XML.value('(/TrackResponse/TrackInfo/Status)[1]',        'varchar(100)'),
           ActInfo_XML.value('(/TrackResponse/TrackInfo/StatusCategory)[1]','varchar(50)')
    from #CTI_Subset
    where (Carrier = 'USPS');

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_CT_Export_USPS_GetEventData */

Go
