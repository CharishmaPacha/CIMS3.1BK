/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/20  MS/RKC  pr_Alerts_ShipmentNotification: Bugfix: SoldToId => ShipToId (BK-75)
  2021/01/21  VS      pr_Alerts_ShipmentNotification: Latest changes migrated from HPI and CID (BK-117)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Alerts_ShipmentNotification') is not null
  drop Procedure pr_Alerts_ShipmentNotification;
Go
/*------------------------------------------------------------------------------
  Proc pr_Alerts_ShipmentNotification:
    This proc will email shipment notifications to the end customers.
------------------------------------------------------------------------------*/
Create Procedure pr_Alerts_ShipmentNotification
  (@BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode      TInteger,
          @vRecordId        TRecordId,
          @vProcessAlertId  TRecordId,
          @vEntity          TEntity,
          @vEntityId        TRecordId,
          @vOrderId         TRecordId,
          @vLPNId           TRecordId,
          @vEntityKey       TEntity,
          @vCategory        TCategory,
          @vSubCategory     TCategory,
          @vRecipients      TVarchar,
          @vEmailBody       TVarChar,
          @vEmailItemId     TInteger;

  declare @ttProcessAlerts table (RecordId       TRecordId Identity(1,1),
                                  ProcessAlertId TRecordId,
                                  Entity         TEntity,
                                  EntityId       TRecordId,
                                  EntityKey      TEntity,
                                  Category       TCategory,
                                  SubCategory    TCategory)
begin
  select @vRecordId = 0;

  /* Get the pending Shipconfirmation Alerts into temp table for processing */
  insert into @ttProcessAlerts (ProcessAlertId, Entity, EntityId, EntityKey, Category, SubCategory)
    select RecordId, Entity, EntityId, EntityKey, Category, SubCategory
    from ProcessAlerts with (nolock)
    where (Status       = 'P' /* Pending */ ) and
          (SubCategory  = 'ShipConfirmation') and
          (BusinessUnit = @BusinessUnit     );

  /* Loop through all records and process those to send emails */
  while (exists (select * from @ttProcessAlerts where RecordId > @vRecordId))
    begin
      /* select each record and process the alerts */
      select top 1 @vRecordId       = RecordId,
                   @vProcessAlertId = ProcessAlertId,
                   @vEntity         = Entity,
                   @vEntityId       = EntityId,
                   @vOrderId        = case when Entity = 'PickTicket' then EntityId else null end,
                   @vLPNId          = case when Entity = 'LPN'        then EntityId else null end,
                   @vEntityKey      = EntityKey,
                   @vCategory       = Category,
                   @vSubCategory    = SubCategory
      from @ttProcessAlerts
      where (RecordId > @vRecordId)
      order by RecordId;

      /* if we have LPN, then OrderId as well */
      if (@vEntity = 'LPN')
        select @vOrderId = OrderId from LPNs with (nolock) where LPNId = @vLPNId;

      /* Get Ship to email */
      select top 1 @vRecipients = C.Email
      from Orderheaders OH with (nolock)
        join Contacts C    with (nolock) on C.ContactRefId = OH.ShipToId
      where (OH.OrderId = @vOrderId) and coalesce(Email,'') <> '';

      /* Build the ship confirmation email and send it */
      exec @vReturnCode = pr_OrderHeaders_SendShipConfirmationEmail @vEntityId,
                                                                    default /* Template name */,
                                                                    @vProcessAlertId,
                                                                    @Recipients  = @vRecipients output,
                                                                    @EmailItemId = @vEmailItemId output,
                                                                    @EmailBody   = @vEmailBody output;

      /* Mark the Alert as queued - will check the system queue and update as
         completed when email is confirmed as being sent. update sent details back to Alerts */
      update ProcessAlerts
      set Status            = case when @vReturnCode = 0 then 'Q' /* Queued */ else 'E' /* Error */ end,
          StatusDescription = case when coalesce(@vRecipients,'') = '' then 'Receipients is Empty'
                                   when coalesce(@vEmailBody,'') = ''  then 'Configuration missing'
                              else
                              null
                              end,
          EmailItemId      = @vEmailItemId,
          EmailId          = @vRecipients,
          ModifiedDate     = current_timestamp
      where (RecordId = @vProcessAlertId)
    end
end /* pr_Alerts_ShipmentNotification */

Go
