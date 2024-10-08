/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/18  RIA     pr_SerialNos_Capture, pr_SerialNos_ValidateScannedLPN, pr_SerialNos_Clear: Changes and corrections (CIMSV3-1211)
  2019/04/22  SK/RV   pr_SerialNos_Clear: Procedure to clear Serial nos (S2GCA-589)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SerialNos_Clear') is not null
  drop Procedure pr_SerialNos_Clear;
Go
/*------------------------------------------------------------------------------
  Proc pr_SerialNos_Clear: Used to clear LPN for serial nos given

  xmlInput:
    <Root>
      <Entity>SerialNos</Entity>
      <Action>Clear</Action>
      <SelectedRecords>
        <EntityKey>LPN</EntityKey>
      </SelectedRecords>
      <Options>
        <ApplyToAllRecords>FALSE</ApplyToAllRecords>
      </Options>
      <UIInfo>
        <LayoutDescription>Standard</LayoutDescription>
        <ContextName>List.LPNs</ContextName>
      </UIInfo>
      <SessionInfo>
        <UserId>rfcadmin</UserId>
        <BusinessUnit>SCT</BusinessUnit>
      </SessionInfo>
    </Root>

  xmlResult:
    <Message></Message>
------------------------------------------------------------------------------*/
Create Procedure pr_SerialNos_Clear
  (@xmlInput     xml,
   @Entity       TEntity,
   @Action       TAction,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId,
   @xmlResult    TXML output,
   @MessageName  TMessageName output)
as
  declare @vReturnCode      TInteger,
          @vRecordId        TInteger,
          @vMessageName     TMessageName,


          @vLPNId           TRecordId,
          @vValidStatuses   TDescription,
          @vTotalRecords    TCount,
          @vRecordsUpdated  TCount,
          @vMessage         TMessage;

  declare @ttLPNs           TEntityKeysTable;
begin
begin try
  SET NOCOUNT ON;

  select  @vReturnCode      = 0,
          @vRecordId        = 0,
          @vMessageName     = null,

          @vTotalRecords    = 0,
          @vRecordsUpdated  = 0;

  /* Validations */
  if (@xmlInput is null)
    select @MessageName = 'SerialNos_InputXMLIsNull';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get valid LPN Statuses to clear */
  select @vValidStatuses = dbo.fn_Controls_GetAsString('SerialNos', 'ValidLPNStatuses', 'UKGDEL', @BusinessUnit, @UserId/* UserId */);

  /* Extract LPNs from XML */
  insert into @ttLPNs(EntityKey)
    select Record.Col.value('.',  'TEntityKey')
    from @xmlInput.nodes('Root/SelectedRecords/EntityKey') as Record(Col);

  /* Total Records inserted above statement*/
  select @vTotalRecords = @@rowcount;

  update ttL
  set ttL.EntityId = L.LPNId
  from @ttLPNs ttL
    join LPNs L on (ttL.EntityKey = L.LPN) and (L.BusinessUnit = @BusinessUnit);

  /* Remove the invalid LPNs from the temp table */
  delete ttL
  from @ttLPNs ttL
       left outer join LPNs L on (ttL.EntityId = L.LPNId)
  where (charindex(L.Status, @vValidStatuses) = 0) and
        (L.LPNType in ('L' /* Logical */, 'A' /* Cart Positions */));

  begin transaction;

  /* Process to clear Serial nos looping through the LPNs given */
  while (exists(select * from @ttLPNs where RecordId > @vRecordId))
    begin
      select top 1 @vRecordId       = RecordId,
                   @vLPNId          = EntityId,
                   @vRecordsUpdated = @vRecordsUpdated + 1
      from @ttLPNs
      where RecordId > @vRecordId
      order by RecordId;

      /* Clearing out the LPNs */
      update SerialNos
      set LPNId          = 0,
          SerialNoStatus = 'R'/* Ready To Use */,
          PrintBatch     = 0,
          ModifiedDate   = current_timestamp
      where (LPNId = @vLPNId);
    end

  /* Building the output Message */
  exec @vMessage = dbo.fn_Messages_BuildActionResponse @Entity, @Action, @vRecordsUpdated, @vTotalRecords;

  /* Result XML with output message */
  select @xmlResult = dbo.fn_XMLNode('Message', @vMessage);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  commit;
end try
begin catch
  if (@@trancount > 0) rollback;

  exec @vReturnCode = pr_ReRaiseError;
end catch;

end /* pr_SerialNos_Clear */

Go
