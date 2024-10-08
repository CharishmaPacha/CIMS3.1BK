/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/11/05  TD/MS   pr_Router_SendRouteInstruction: Send ReceiptNumber & CutNo in RI (JL-286)
  2014/08/26  AY      pr_Router_SendRouteInstruction: Send UCCBarcode for ShipDock LPNs
  2014/08/01  TK      pr_Router_SendRouteInstruction: Added fields WaveId and WaveNo.
  2014/07/29  AY      pr_Router_SendRouteInstruction: Changed to send ShippingLane of the Order
                        when Destination is SHIPDOCK
  2014/04/20  PK      pr_Router_SendRouteInstruction: Processing multiple LPNs.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Router_SendRouteInstruction') is not null
  drop Procedure pr_Router_SendRouteInstruction;
Go
/*------------------------------------------------------------------------------
  Proc pr_Router_SendRouteInstruction: Creates a Route instruction in our tables
    to be sent to DCMS. If 'ForceExport' = Y, then it exports immediately in a
    scenario when it is time sensitive. If Destination/WorkId are provide, then
    they are used else they are determined using rules.

  Which LPNs to send?
  Single LPN  - if LPNId and/or LPN input params are given
  #RouterLPNs - if such a temp table exists
  @ttLPNs     - the LPNs that are passed in
------------------------------------------------------------------------------*/
Create Procedure pr_Router_SendRouteInstruction
  (@LPNId         TRecordId,
   @LPN           TLPN,
   @ttLPNs        TEntityKeysTable readonly,
   @Destination   TLocation = null,
   @WorkId        TWorkId   = null,
   @ForceExport   TFlag     = 'N',
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TDescription,

          @vLPNId            TRecordId,
          @vLPN              TLPN,
          @vDestZone         TZoneId,
          @vDestination      TLocation,
          @vRuleDestination  TLocation,
          @vLPNStatus        TStatus,
          @vPickBatchId      TRecordId,
          @vPickBatchNo      TPickBatchNo,
          @vOrderId          TRecordId,
          @vRecordId         TRecordId,
          @vRouteLPN         TLPN,
          @xmlRulesData      TXML,

          @ttLPNsToRoute     TEntityValuesTable;
begin
  select @vReturnCode  = 0,
         @vMessagename = null,
         @vRecordId    = 0;

  /* If a single LPN is given, then insert it into temp table for processing */
  if (@LPNId is not null)
    begin
      insert into @ttLPNsToRoute (EntityId, EntityKey)
        select LPNId, LPN from LPNs where (LPNId = @LPNId);
    end
  else
  if (@LPN is not null)
    begin
      insert into @ttLPNsToRoute (EntityId, EntityKey)
        select LPNId, LPN from LPNs where (LPN = @LPN) and (BusinessUnit = @BusinessUnit);
    end
  else
  if (object_id('tempdb..#RouterLPNs') is not null)
    begin
      /* add the given LPNs to the table for exporting */
      insert into RouterInstruction (LPNId, LPN, RouteLPN, Destination, ReceiptId, ReceiptNumber, RI_UDF1, BusinessUnit, CreatedBy)
        select RL.LPNId, RL.LPN, RL.LPN, coalesce(@Destination, RL.DestLocation), L.ReceiptId, L.ReceiptNumber, L.UDF6, @BusinessUnit, @UserId
        from #RouterLPNs RL
          join LPNs L on (RL.LPNId = L.LPNId);
    end
  else
    begin
      insert into @ttLPNsToRoute (EntityId, EntityKey)
        select EntityId, EntityKey from @ttLPNs;
    end

  /* Get all the info needed to determine the Destination and WorkIds for the LPNs */
  select LPNId, LPN, LPNType, Status as LPNStatus, OrderId, PickTicketNo,
         PickBatchId as WaveId, PickBatchNo as WaveNo,
         DestZone, coalesce(@Destination, DestLocation) DestLocation,
         LPN as RouteLPN, @Destination as RuleDestination, @WorkId as WorkId
  into #LPNsToRoute
  from LPNs L join @ttLPNsToRoute LTR on L.LPNId = LTR.EntityId;

  if (@@rowcount = 0) goto ExportRecords;

  /* Build the data for evaluation of rules to get Destination */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Destination',     @Destination)    +
                           dbo.fn_XMLNode('WorkId',          @WorkId)         +
                           dbo.fn_XMLNode('BusinessUnit',    @BusinessUnit));

  /* Update the Destination, RouteLPN & WorkId */

  -- TODO: Change the rules
  exec pr_RuleSets_ExecuteRules 'Router_SetDestination', @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'Router_SetRouteLPN',    @xmlRulesData;
  exec pr_RuleSets_ExecuteRules 'Router_SetWorkId',      @xmlRulesData;

  /* Insert LPN into RouterInstruction, but if there is no destination, then mark ExportStatus = X
     to indicate of an error */
  insert into RouterInstruction (WaveId, WaveNo, LPNId, LPN, RouteLPN, OrderId, PickTicketNo,
                                 UCCBarCode, TrackingNo, EstimatedWeight,
                                 Destination, WorkId, BusinessUnit, CreatedBy, ExportStatus)
    select L.PickBathcId, L.PickBatchNo, L.LPNId, L.LPN, LTR.RouteLPN, L.OrderId, L.PickTicket,
           L.UCCBarcode, L.TrackingNo, L.LPNWeight,
           LTR.RuleDestination, LTR.WorkId, @BusinessUnit, @UserId,
           case when LTR.RuleDestination is null then 'X' else 'N' end
    from vwLPNs L join #LPNsToRoute LTR on L.LPNId = LTR.LPNId;

ExportRecords:

  /* If the ForceExport flag is yes then export to router */
  if (@ForceExport = 'Y' /* Yes */)
    exec pr_Router_DCMS_ExportInstructions;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end  /* pr_Router_SendRouteInstruction */

Go
