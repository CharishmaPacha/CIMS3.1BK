/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/31  KBB     pr_Loads_Action_ModifyBoLInfo: Added BoLStatus (HA-2467)
  2021/02/22  AY      pr_Loads_Action_ModifyBoLInfo: Save the Consolidator Address on Master BoL (HA-2042)
  2021/01/20  PK      pr_Load_GenerateBoLs, pr_Loads_Action_ModifyBoLInfo, pr_Load_Recount: Ported back changes are done by Pavan (HA-1749) (Ported from Prod)
  2020/07/19  OK      Added pr_Loads_Action_ModifyApptDetails and pr_Loads_Action_ModifyBoLInfo (HA-1146, HA-1147)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_Action_ModifyBoLInfo') is not null
  drop Procedure pr_Loads_Action_ModifyBoLInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_Action_ModifyBoLInfo: This proc will modify the BoL info of the Load with user inputs
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_Action_ModifyBoLInfo
  (@EntityXML       xml,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @ResultXML       TXML = null output)
as
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vMessage                   TMessage,

          @vFoB                       TFlags,
          @vBoLCID                    TBoLCID,
          @vMasterBoL                 TBoLNumber,
          @vMasterTrackingNo          TTrackingNo,
          @vConsolidatorAddressId     TContactRefId,
          @vBoLStatus                 TStatus,

          @vEntity                    TEntity,
          @vAction                    TAction,
          @vRecordsUpdated            TCount,
          @vTotalRecords              TCount,
          @vActivityType              TActivityType,
          @vAuditRecordId             TRecordId,
          @vNote1                     TDescription;

  declare @ttLoadsUpdated             TEntityKeysTable;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vNote1       = '';

  /* Get the Action from the xml */
  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @EntityXML.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR (@EntityXML = null ) );

  /* Read inputs from XML */
  select @vFoB                    = nullif(Record.Col.value('FoB[1]',                   'TFlags'),        ''),
         @vBoLCID                 = nullif(Record.Col.value('BoLCID[1]',                'TBoLCID'),       ''),
         @vMasterBoL              = nullif(Record.Col.value('MasterBoL[1]',             'TBoLNumber'),    ''),
         @vMasterTrackingNo       = nullif(Record.Col.value('MasterTrackingNo[1]',      'TTrackingNo'),   ''),
         @vConsolidatorAddressId  = nullif(Record.Col.value('ConsolidatorAddressId[1]', 'TContactRefId'), ''),
         @vBoLStatus              = nullif(Record.Col.value('BoLStatus[1]',             'TStatus'),       '')
  from @EntityXML.nodes('/Root/Data') as Record(Col);

  /* Get the total no. of Loads */
  select @vTotalRecords = count(*) from #ttSelectedEntities;
  select @vActivityType = @vAction;

  /* Update the Load. If BoL_CID is given and client load is not, copy it */
  update L
  set FoB                   = coalesce(@vFoB,                   FoB),
      BoLCID                = coalesce(@vBoLCID,                BoLCID),
      ClientLoad            = coalesce(nullif(ClientLoad, ''),  @vBoLCID),
      MasterBoL             = coalesce(@vMasterBoL,             MasterBoL),
      MasterTrackingNo      = coalesce(@vMasterTrackingNo,      MasterTrackingNo),
      ConsolidatorAddressId = coalesce(@vConsolidatorAddressId, ConsolidatorAddressId),
      BoLStatus             = coalesce(@vBoLStatus,             BoLStatus)
  output Inserted.LoadId, Inserted.LoadNumber into @ttLoadsUpdated (EntityId, EntityKey)
  from Loads L
    join #ttSelectedEntities ttSE on (L.LoadId = ttSE.EntityId);

  /* Get the updated Loads count */
  select @vRecordsUpdated = @@rowcount;

  /* Update the consolidator address on Master BoL as well */
  update B
  set B.ShipToAddressId = C.ContactId
  from BoLs B
    join Loads LD on (B.LoadId = LD.LoadId) and (BoLType = 'M')
    join @ttLoadsUpdated LU on (LD.LoadId = LU.EntityId)
    join Contacts C on C.ContactType = 'FC' and (C.ContactRefId = LD.ConsolidatorAddressId);

  /* Build Note to log AT */
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'FoB',                  @vFoB);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'BoL CID',              @vBoLCID);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Master BoL',           @vMasterBoL);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Master TrackingNo',    @vMasterTrackingNo);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Consolidator Address', @vConsolidatorAddressId);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'BoL Status',           @vBoLStatus);
  select @vNote1 = '(' + @vNote1 + ')';

  /* Audit Trail */
  exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @Note1         = @vNote1,
                            @AuditRecordId = @vAuditRecordId output;

  exec pr_AuditTrail_InsertEntities @vAuditRecordId, @vEntity, @ttLoadsUpdated, @BusinessUnit;

  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_Action_ModifyBoLInfo */

Go
