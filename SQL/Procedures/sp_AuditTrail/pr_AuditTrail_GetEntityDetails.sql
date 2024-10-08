/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/22  AY      pr_AuditTrail_GetEntityDetails: Removed BusinessUnit as EntityId is unique
  2016/10/07  AY      pr_AuditTrail_GetEntityDetails: For performance reason, show empty for EntityDetails as we are still using it yet (HPI-GoLive)
  2013/05/30  YA      pr_AuditTrail_GetEntityDetails: Modified to accept Ids instead of Key's.
  2013/05/28  VM/YA   pr_AuditTrail_GetEntityDetails: Temporary fix on showing audittrail based on the Id's.(ta8088)
  2012/06/23  AA      pr_AuditTrail_GetEntityDetails: added order by to display data in desc order
  2012/06/20  AA      pr_AuditTrail_GetEntityDetails: left join changed to inner join
                        i.e. there will be no records exists in Audit Entities with out entires in Audit Trail
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AuditTrail_GetEntityDetails') is not null
  drop Procedure pr_AuditTrail_GetEntityDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_AuditTrail_GetEntityDetails:
    This proc will call when user selects Batch Audit tab from UI, by passing the
    selected BatchNo.
------------------------------------------------------------------------------*/
Create Procedure pr_AuditTrail_GetEntityDetails
  (@EntityType     TTypeCode,
   @EntityId       TInteger,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @ReturnCode     TInteger,
          @MessageName    TMessageName,
          @Message        TDescription,
          @vComment       TVarChar;

begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null;

  select AT.UserId as UserId, AT.ActivityDateTime as ActivityDateTime, AT.ActivityType,
         AT.Comment as Comment, datediff(Day, AT.ActivityDateTime, getdate()) as ActivityAge,
         AT.Archived, '' EntityDetails
  from AuditEntities AE join AuditTrail AT on (AT.AuditId = AE.AuditId)
  where (AE.EntityType = @EntityType) and
        (AE.EntityId   = @EntityId)
  order by AT.ActivityDateTime desc, AT.AuditId desc;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_AuditTrail_GetEntityDetails */

Go
