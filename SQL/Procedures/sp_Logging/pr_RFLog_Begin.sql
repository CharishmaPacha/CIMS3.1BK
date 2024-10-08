/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/12/25  AY      Added pr_RFLog_Begin/End procedures for logging
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFLog_Begin') is not null
  drop Procedure pr_RFLog_Begin;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFLog_Begin: Wrapper procedure for using ActivityLog in RF main procedures.

  ** Note the change in order of Params between RFLog_Begin and ActivityLog_AddMessage procedures
  ------------------------------------------------------------------------------*/
Create Procedure pr_RFLog_Begin
  (@xmlData        xml,
   @ProcId         TInteger,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @DeviceId       TDeviceId,

   @EntityId       TRecordId,
   @EntityKey      TEntity,
   @Entity         TEntity,

   @Operation      TDescription  = null,
   @Message        TDescription  = null,
   @Value1         TDescription  = null,
   @Value2         TDescription  = null,
   @Value3         TDescription  = null,
   @Value4         TDescription  = null,
   @Value5         TDescription  = null,
   @ActivityLogId  TRecordId     = null output)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,

          @vXmlData          Txml;
begin
  SET NOCOUNT ON;

  /* convert input xml to string */
  select @vXmlData = cast(@xmlData as varchar(max));

  /* call proc to log Activity */
  exec pr_ActivityLog_AddMessage @Operation, @EntityId, @EntityKey, @Entity, @Message,
                                 @ProcId, @vXmlData, @BusinessUnit, @UserId,
                                 @Value1, @Value2, @Value3, @Value4, @Value5,
                                 @DeviceId, @ActivityLogId output;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_RFLog_Begin */

Go
