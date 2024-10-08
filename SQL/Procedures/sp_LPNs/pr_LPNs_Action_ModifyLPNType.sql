/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/26  AJM     pr_LPNs_Action_ModifyLPNType: Initial Revision (CIMSV3-1450)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Action_ModifyLPNType') is not null
  drop Procedure pr_LPNs_Action_ModifyLPNType;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Action_ModifyLPNType: This procedure used to change the
    LPNType on selected lpns
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Action_ModifyLPNType
  (@xmlData          xml,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @ResultXML        TXML    = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vLPNType                    TTypeCode,
          /* Process variables */
          @vLPNTypeDesc                TDescription;

  declare @ttLPNsUpdated               TEntityKeysTable;
begin /* pr_LPNs_Action_ModifyLPNType */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null,
         @vAuditActivity  = 'LPNTypeModified'

  select @vEntity  = Record.Col.value('Entity[1]',         'TEntity'),
         @vAction  = Record.Col.value('Action[1]',         'TAction'),
         @vLPNType = Record.Col.value('(Data/LPNType)[1]', 'TTypeCode')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get the total count of LPNs from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Get the Look up description for the give look up code */
  select @vLPNTypeDesc = dbo.fn_LookUps_GetDesc ('LPNTypeForModify', @vLPNType, @BusinessUnit, default);

  /* Validations */
  /* Check if the LPNType is passed or not */
  if (@vLPNType is null)
    set @vMessageName = 'LPNTypeIsRequired';
  else
  /* Check if the LPNType is Active or not */
  if (not exists(select *
                     from vwEntityTypes
                     where (Entity       = 'LPN') and
                           (TypeCode     = @vLPNType) and
                           (BusinessUnit = @BusinessUnit)))
   set @vMessageName = 'LPNTypeIsInvalid';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Delete the LPNs which already have selected LPNType */
  delete ttSE
  output 'E', 'LPNs_ModifyLPNType_SameLPNType', L.LPN, @vLPNTypeDesc
  into #ResultMessages (MessageType, MessageName, Value1, Value2)
  from LPNs L
    join #ttSelectedEntities ttSE on (L.LPNId = ttSE.EntityId)
  where (L.LPNType = @vLPNType);

  /* Update the remaining LPNs */
  update L
  set LPNType      = @vLPNType,
      ModifiedDate = current_timestamp,
      ModifiedBy   = @UserId
  output deleted.LPNId, deleted.LPN
  into @ttLPNsUpdated(EntityId, EntityKey)
  from LPNs L
    join #ttSelectedEntities ttSE on (L.LPNId = ttSE.EntityId)

  select @vRecordsUpdated = @@rowcount;

  /* Logging AuditTrail for modified locations */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @Note1         = @vLPNTypeDesc,
                            @AuditRecordId = @vAuditRecordId output;

  /* Insert Location Audit Entities */
  exec pr_AuditTrail_InsertEntities @vAuditRecordId, 'LPN', @ttLPNsUpdated, @BusinessUnit;

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Action_ModifyLPNType */

Go
