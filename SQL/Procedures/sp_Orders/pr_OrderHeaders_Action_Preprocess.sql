/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/03/27  LAC     pr_OrderHeaders_Action_Preprocess: Initial revision (BK-1036)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_Action_Preprocess') is not null
  drop Procedure pr_OrderHeaders_Action_Preprocess;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_Action_Preprocess: Flag all selected orders to be preprocessed
    again. Orders are validated based upon the action. i.e. from Waves.. we only allow
    preprocess of Waved Orders i.e. not after it is released.
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_Action_Preprocess
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          @xmlRulesData                TXML,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          /* Process variables */
          @vValidOrderStatus           TControlValue,
          @ttOrdersUpdated             TEntityKeysTable;
begin /* pr_OrderHeaders_Action_Preprocess */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vAuditActivity = 'PreprocessOrder';

  /* Fetching required data from XML */
  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the Control values */
  select @vValidOrderStatus =  dbo.fn_Controls_GetAsString(@vAction, 'ValidOrderStatus', 'ONW', @BusinessUnit, null/* UserId */);

  /* Get total count from temp table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Get the invalid records into a hash table. This is to get all key values and errors at once for performance reasons */
  select OH.OrderId, OH.PickTicket, cast(OH.Status as varchar(30)) as OrderStatus,
  case when (charindex(OH.Status, @vValidOrderStatus) = 0) then 'Orders_Reprocess_InvalidOrderStatus'
  end ErrorMessage
  into #InvalidOrders
  from #ttSelectedEntities SE join OrderHeaders OH on SE.EntityId = OH.OrderId;

  /* Get the status description for the error message */
  update #InvalidOrders
  set OrderStatus = dbo.fn_Status_GetDescription('Order', OrderStatus, @BusinessUnit);

   /* Exclude the orders that are determined to be invalid above */
  delete from SE
  output 'E', IOH.OrderId, IOH.PickTicket, IOH.ErrorMessage, IOH.OrderStatus
  into #ResultMessages (MessageType, EntityId, EntityKey, MessageName, Value2)
  from #ttSelectedEntities SE join #InvalidOrders IOH on (SE.EntityId = IOH.OrderId)
  where (IOH.ErrorMessage is not null);

  /* Perform the actual updates */
  update OH
  set OH.PreprocessFlag = 'N',
      OH.ModifiedDate   = current_timestamp,
      OH.ModifiedBy     = @UserId
  output inserted.OrderId, inserted.PickTicket into @ttOrdersUpdated (EntityId, EntityKey)
  from OrderHeaders OH join #ttSelectedEntities SE on (OH.orderid = SE.Entityid);

  /* Get the total Updated count */
  select @vRecordsUpdated = @@rowcount;

  /*----------------- Audit Trail ----------------*/
  /* Logging AuditTrail for modified locations */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @AuditRecordId = @vAuditRecordId output;

  /* Insert Location Audit Entities */
  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'PickTicket', @ttOrdersUpdated, @BusinessUnit;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_Action_Preprocess */

Go
