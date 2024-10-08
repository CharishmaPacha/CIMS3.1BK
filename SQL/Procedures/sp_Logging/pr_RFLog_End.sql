/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/08  AY      pr_RFLog_End: Re-order params
  2018/11/13  AY      pr_RFLog_End: Change to log error info on exception
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFLog_End') is not null
  drop Procedure pr_RFLog_End;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFLog_End: Wrapper procedure for using ActivityLog in RF main procedures
    to log the response at the end of the RF call. Only @xmlData is required here along
    with the ActivityLogId.

  ** Note the change in order of Params between RFLog_End and RFLog_Being as well
     as ActivityLog_AddMessage procedures
-----------------------------------------------------------------------------*/
Create Procedure pr_RFLog_End
  (@xmlData        xml,
   @ProcId         TInteger      = 0,
   @Message        TDescription  = null,  -- High potential to use it, so moved it up

   @EntityId       TRecordId     = null,
   @EntityKey      TEntity       = null,
   @Entity         TEntity       = null,

   @Operation      TDescription  = null,
   @Value1         TDescription  = null,
   @Value2         TDescription  = null,
   @Value3         TDescription  = null,
   @Value4         TDescription  = null,
   @Value5         TDescription  = null,

   @BusinessUnit   TBusinessUnit = null,
   @UserId         TUserId       = null,
   @DeviceId       TDeviceId     = null,

   @ActivityLogId  TRecordId     = null output)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TDescription,

          @vXmlData          TXML;
begin
  SET NOCOUNT ON;

  /* convert input xml to string */
  select @vXmlData = cast(@xmlData as varchar(max)),
         @vMessage = ERROR_MESSAGE();

  /* IF user has not given any error and we are in catch block, get the error data to save */
  if (@xmlData is null) and (@vMessage is not null)
    exec pr_BuildRFErrorXML @xmlData out;

  /* call proc to log Activity */
  exec pr_ActivityLog_AddMessage @Operation, @EntityId, @EntityKey, @Entity, @Message,
                                 @ProcId, @vXmlData, @BusinessUnit, @UserId,
                                 @Value1, @Value2, @Value3, @Value4, @Value5,
                                 @DeviceId, @ActivityLogId output;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_RFLog_End */

Go
