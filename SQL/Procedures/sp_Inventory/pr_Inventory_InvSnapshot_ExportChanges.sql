/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/12/28  MS      pr_Inventory_InvSnapshot_ExportChanges, pr_Inventory_InvSnapshot_ExportChanges_GetJsonData: Proc to export invsnapshot changes (BK-981)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Inventory_InvSnapshot_ExportChanges') is not null
  drop Procedure pr_Inventory_InvSnapshot_ExportChanges;
Go
/*------------------------------------------------------------------------------
  Proc pr_Inventory_InvSnapshot_ExportChanges:
------------------------------------------------------------------------------*/
Create Procedure pr_Inventory_InvSnapshot_ExportChanges
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vMessage            TMessage,

          @vBusinessUnit       TBusinessUnit,
          @vUserId             TUserId,
          @vIntegrationName    TName,
          @vMessageType        TName,
          @vMessageData        TVarchar,
          @vTransactionStatus  TStatus,
          @vAPIWorkflow        TName,
          @vAPIBatch           TBatch;
begin /* pr_Inventory_InvSnapshot_ExportChanges */
  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null,
         @vUserId            = 'cimsapi',
         @vIntegrationName   = '',
         @vMessageType       = 'ExportInvSnapshotChanges',
         @vTransactionStatus = 'ReadyToSend',
         @vAPIWorkflow       = 'APIJob',
         @vAPIBatch          = 0;

  select top 1 @vBusinessUnit = BusinessUnit,
               @vUserId       = ModifiedBy
  from #InvSnapshotsModified;

  /* Build json format with required data */
  exec pr_Inventory_InvSnapshot_ExportChanges_GetJsonData @vBusinessUnit, @vUserId, @vMessageData output

  /* Get next batch number for the the outbound transactions batch */
  exec pr_Sequence_GetNext 'Seq_APIOutboundBatch', 1, null /* Userid */, @vBusinessUnit, @vAPIBatch output;

  /* insert records into APIOutboundTransactions */
  if exists(select * from #InvSnapshotsModified)
    insert into APIOutboundTransactions (IntegrationName, MessageType, MessageData, TransactionStatus, EntityType,
                                         APIWorkflow, APIBatch, BusinessUnit, CreatedBy)
      select @vIntegrationName, @vMessageType, @vMessageData, @vTransactionStatus, 'INVSS',
             @vAPIWorkflow, @vAPIBatch, @vBusinessUnit, System_User;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Inventory_InvSnapshot_ExportChanges */

Go
