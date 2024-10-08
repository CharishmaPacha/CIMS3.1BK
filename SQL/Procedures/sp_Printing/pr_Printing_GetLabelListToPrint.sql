/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_GetLabelListToPrint') is not null
  drop Procedure pr_Printing_GetLabelListToPrint;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_GetLabelListToPrint: Evaluates the rules and gets the list
   of labels to print
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_GetLabelListToPrint
  (@RulesDataXML         TXML,
   @LabelListToPrintXML  TXML output)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vDebug                   TFlags,
          @vxmlRulesData            XML,
          @vActivityLogId           TRecordId,
          @vEntity                  TEntity,
          @vEntityId                TRecordId,
          @vEntityKey               TEntityKey,
          @vLPNId                   TRecordId,
          @vOrderId                 TRecordId,
          @vLPN                     TLPN,
          @vPickTicket              TPickTicket,
          @vBusinessUnit            TBusinessUnit,
          @vUserId                  TUserId,
          @vOperation               TOperation,
          @vRuleSetType             TRuleSetType,
          @vLabelListToPrintXML     TXML;

  declare @ttLabelListToPrint  TLabelListToPrint;

begin
  /* Initialize */
  select @vLabelListToPrintXML = '',
         @vxmLRulesData        = convert(xml, @RulesDataXML);

  select @vOperation      = Record.Col.value('Operation[1]',      'TOperation'),
         @vEntity         = Record.Col.value('Entity[1]',         'TEntity'),
         @vRuleSetType    = Record.Col.value('RuleSetType[1]',    'TRuleSetType'),
         @vEntityId       = Record.Col.value('EntityId[1]',       'TRecordId'),
         @vLPNId          = Record.Col.value('LPNId[1]',          'TRecordId'),
         @vOrderId        = Record.Col.value('OrderId[1]',        'TRecordId'),
         @vEntity         = Record.Col.value('Entity[1]',         'TEntityKey'),
         @vEntityKey      = Record.Col.value('EntityKey[1]',      'TEntityKey'),
         @vLPN            = Record.Col.value('LPN[1]',            'TLPN'),
         @vPickTicket     = Record.Col.value('PickTicket[1]',     'TPickTicket'),
         @vBusinessUnit   = Record.Col.value('BusinessUnit[1]',   'TBusinessUnit'),
         @vUserId         = Record.Col.value('UserId[1]',         'TUserId')
  from @vxmLRulesData.nodes('/RootNode') as Record(Col);

  exec pr_ActivityLog_AddMessage @vOperation, @vEntityId, @vEntityKey, @vEntity, null /* Message */,
                                 @@ProcId, @RulesDataXML, @vBusinessUnit,
                                 @ActivityLogId = @vActivityLogId out;

  /* Create hash table to be used in the rules */
  if object_id('tempdb..#ttLabelsToPrint') is null
    select * into #ttLabelsToPrint from @ttLabelListToPrint;

  /* Insert the required documents in #ttLabelsToPrint in rules */
  exec pr_RuleSets_ExecuteAllRules @vRuleSetType, @RulesDataXML, @vBusinessUnit;

  if (charindex('D', @vDebug) > 0)
    begin
      select cast(@RulesDataXML as xml);
      select * from #ttLabelsToPrint;
    end

  /* Build xml from #ttLabelsToPrint to print the shipping documents */
  if (exists (select * from #ttLabelsToPrint))
    select @vLabelListToPrintXML = (select *
                                    from #ttLabelsToPrint
                                    for xml raw('Label'), root('ShippingLabelsToPrint'), elements);

  select @LabelListToPrintXML = @vLabelListToPrintXML;

  exec pr_ActivityLog_AddMessage @vOperation, @vEntityId, @vEntityKey, @vEntity, null /* Message */,
                                 @@ProcId, @LabelListToPrintXML, @vBusinessUnit,
                                 @ActivityLogId = @vActivityLogId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Printing_GetLabelListToPrint */

Go
