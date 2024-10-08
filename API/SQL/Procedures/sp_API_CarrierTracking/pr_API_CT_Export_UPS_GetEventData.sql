/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_CT_Export_UPS_GetEventData') is not null
  drop Procedure pr_API_CT_Export_UPS_GetEventData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_CT_Export_UPS_GetEventData:

  #CTI_TrackHist_Data TCarrierTrackingEventData
------------------------------------------------------------------------------*/
Create Procedure pr_API_CT_Export_UPS_GetEventData
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
    select CTI.RecordId,
           convert(datetime, stuff(stuff(jdata.datestr, 5, 0, '-'), 8, 0, '-') +' '+ stuff(stuff(jdata.timestr, 3, 0, ':'), 6, 0, ':'), 120)
                                                                as checkpoint_date,
           jdata.status                                         as tracking_detail,
           (jdata.city+','+jdata.state+','+jdata.country)       as location,
           jdata.status                                         as checkpoint_delivery_status,
           jdata.statussub                                      as checkpoint_delivery_substatus
    from #CTI_Subset CTI
      cross apply openjson(CTI.ActivityInfo)
        with (datestr   varchar(8)   '$.date',
              timestr   varchar(8)   '$.time',
              status    varchar(512) '$.status.description',
              city      varchar(100) '$.location.address.city',
              state     varchar(100) '$.location.address.stateProvince',
              country   varchar(5)   '$.location.address.country',
              statussub varchar(25)  '$.status.type') as jdata
    where (CTI.Carrier = 'UPS');

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_CT_Export_UPS_GetEventData */

Go
