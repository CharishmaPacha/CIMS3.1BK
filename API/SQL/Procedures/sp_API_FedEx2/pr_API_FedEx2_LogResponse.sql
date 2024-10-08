/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  27/04/2024  RV      Initial Version (CIMSV3-3532)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_LogResponse') is not null
  drop Procedure pr_API_FedEx2_LogResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_LogResponse: For all completed FedEx API requests this procedure
    used to log in the AT and/or Notifications
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_LogResponse
  (@AuditTrailInfo   TAuditTrailInfo Readonly,
   @ActivityType     TName,
   @Severity         TDescription,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @EntityType       TTypeCode,
   @EntityId         TRecordId,
   @EntityKey        TEntityKey,
   @Value2           TMessage = null,
   @Value3           TMessage = null,
   @Value4           TMessage = null,
   @Value5           TMessage = null)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage

  declare @ttAuditTrailInfo             TAuditTrailInfo,
          @ttValidations                TValidations;
begin /* pr_API_FedEx2_LogResponse */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Suffix with _Success or _Fail */
  select @ActivityType += '_' + iif(@Severity in ('Error', 'Failure', 'Fault'), 'Fail', 'Success');

  /*----------------- Audit Trail ----------------*/
  if exists (select * from @AuditTrailInfo)
    insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
      select EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment
      from @AuditTrailInfo
  else
  if (@ActivityType is not null)
    insert into @ttAuditTrailInfo (EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, UserId, Comment)
      select @EntityType, @EntityId, @EntityKey, @ActivityType, @BusinessUnit, @UserId,
             dbo.fn_Messages_Build(@ActivityType, @EntityKey, @Value2, @Value3, @Value4, @Value5)

  /* Insert records into AT */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

  /*----------------- Notifications ----------------*/
  if (object_id('tempdb..#Validations') is null) and (@Severity in ('Error', 'Failure', 'Fault'))
    begin
      /* Create #Validations if it doesn't exist */
      select * into #Validations from @ttValidations;

      /* Insert the Validations */
      insert into #Validations (MasterEntityType, MasterEntityId, MasterEntityKey, EntityType, EntityId, EntityKey, MessageType, MessageName, Message)
        select ATI.EntityType, ATI.EntityId, ATI.EntityKey, ATI.EntityType, ATI.EntityId, ATI.EntityKey, 'E' /* Error Message*/,
               ATI.ActivityType, NT.Message
        from @ttAuditTrailInfo ATI, #Notifications NT;
    end

  /* Save Validations to Notifications table */
  exec pr_Notifications_SaveValidations @EntityType, @EntityId, @EntityKey, 'NO', 'CIMSFEDEX2', @BusinessUnit, @UserId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_LogResponse */

Go