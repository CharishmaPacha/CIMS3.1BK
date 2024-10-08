/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/05  AY      pr_BoLs_Action_MasterBoLShipToModify: Bug fixes to handle input of ContactRefId instead of ContactId (HA-2754)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoLs_Action_MasterBoLShipToModify') is not null
  drop Procedure pr_BoLs_Action_MasterBoLShipToModify;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoLs_Action_MasterBoLShipToModify:
------------------------------------------------------------------------------*/
Create Procedure pr_BoLs_Action_MasterBoLShipToModify
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
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vAuditRecordId              TRecordId,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vBoLId                      TRecordId,
          @vNewShipToAddress           TContactRefId,
          /* Processing variables */
          @vLoadId                     TRecordId,
          @vBoLType                    TTypeCode,
          @vMasterBoLNumber            TBoLNumber,
          @vNewShipToAddressId         TRecordId,
          @vNewShipToAddressName       TName;

begin /* pr_BoL_Action_MasterBoLShipToModify */
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessage       = null,
         @vRecordId      = 0,
         @vTotalRecords  = 1,
         @vAuditActivity = 'Load_MasterBoLShipToModified';

  select @vEntity           = Record.Col.value('(Entity)[1]',               'TEntity'),
         @vAction           = Record.Col.value('(Action)[1]',               'TAction'),
         @vBoLId            = Record.Col.value('(Data/BoLId)[1]',           'TRecordId'),
         @vMasterBoLNumber  = Record.Col.value('(Data/MasterBoL)[1]',       'TBoLNumber'),
         @vNewShipToAddress = Record.Col.value('(Data/ShipToAddressId)[1]', 'TContactRefId')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  select @vBoLType = BoLType
  from BoLs
  where (BoLId = @vBoLId);

  select @vNewShipToAddressId   = ContactId,
         @vNewShipToAddressName = Name
  from Contacts
  where (ContactType  in ('FC', 'S')) and
        (ContactRefId = @vNewShipToAddress) and
        (BusinessUnit = @BusinessUnit);

  if (@vBoLId is null)
    set @vMessageName = 'InvalidBoL';
  else
  if (@vBoLType <> 'M')
    set @vMessageName = 'BoL_CanOnlyChangeShiptoOnMasterBoL';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Update BoL */
  update BoLs
  set ShipToAddressId = @vNewShipToAddressId,
      @vLoadId        = LoadId
  where (BoLId = @vBoLId);

  select @vRecordsUpdated = @@rowcount;

  /* Audit Trail */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @LoadId = @vLoadId, @Note1 = @vNewShipToAddressName;

  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_BoLs_Action_MasterBoLShipToModify */

Go
