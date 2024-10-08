/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/08/07  VS      pr_Reservation_AutoActivation: Drop and create KeyValue column (HA-3065)
                      pr_Reservation_AutoActivation & pr_Reservation_AutoActivation_Qualification:
  2020/11/29  PK      pr_Reservation_AutoActivation: Cannot use transactions in loop when we use #tabels (HA-1723).
  2020/11/27  SK      pr_Reservation_AutoActivation: change logic to process minimum waves (HA-1125)
  2020/07/03  SK      pr_Reservation_AutoActivation: Further enhancement (HA-906)
  2020/06/24  SK      pr_Reservation_AutoActivation: Refactoring (HA-906)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_AutoActivation') is not null
  drop Procedure pr_Reservation_AutoActivation;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_AutoActivation:
    Here @Warehouse can be comma separated list of Warehouses

    1. Determine Waves and/or SKUs to be auto-activated
    2. Then load FromLPNs and ToLPNs based on the wave short short list
    3. Apply Exclusion Criteria:
       wave level  - all counts should match for the entire waves
       sku level   - sku level counts matched are allowed to be activated
       (Future) This could be enhanced with more controls
    4. Process all possible wave in a loop. Transaction to be at wave level
------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_AutoActivation
  (@Warehouse        TWarehouse,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  /* Declare local variables */
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vMessage               TDescription,
          @vRecordId              TRecordId,
          @vValue1                TString,
          @vValue2                TString,
          @vDebug                 TFlags,
          @xmlInput               xml,
          @vRulesInputXML         TXML,
          @vRulesOutput           TString,
          @vProcInputXML          TXML,
          @vMaxRecords            TControlValue,
          @vRecordsProcessed      TCount,
          @vQualified             TFlag,
          /* Wave Info */
          @vWaveId                TRecordId,
          @vWaveNo                TWaveNo,
          @vWaveType              TTypeCode;

  declare @ttOrderDetails         TOrderDetails,
          @ttWaveInfo             TWaveInfo,
          @ttLPNDetails           TLPNDetails,
          @ttAuditTrailInfo       TAuditTrailInfo,
          @ttEntityKeysTable      TEntityKeysTable;
begin
  SET NOCOUNT ON;

  select @vReturnCode       = 0,
         @vRecordId         = 0,
         @vMessageName      = null,
         @vMessage          = null,
         @vRecordsProcessed = 0;

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @BusinessUnit, @vDebug output;

  /* Temporary tables */
  select * into #Waves                from @ttWaveInfo;
  select * into #WaveToLPNEntities    from @ttEntityKeysTable;
  select * into #WaveFromLPNEntities  from @ttEntityKeysTable;

  select * into #ToLPNDetails         from @ttLPNDetails;
  alter table #ToLPNDetails add KeyValue as cast(SKUId as varchar) + '-' + Warehouse + '-' + Ownership + '-' +
                                            InventoryClass1 + '-' + InventoryClass2 + '-' + InventoryClass3;

  select * into #FromLPNDetails       from @ttLPNDetails;
  alter table #FromLPNDetails add KeyValue as cast(SKUId as varchar) + '-' + Warehouse + '-' + Ownership + '-' +
                                              InventoryClass1 + '-' + InventoryClass2 + '-' + InventoryClass3;

  /* Get Controls */
  select @vMaxRecords = dbo.fn_Controls_GetAsString('AutoActivation', 'MaxWavesToProcess', 2, @BusinessUnit, @UserId);

  /* Rules data input */
  select @vRulesInputXML = dbo.fn_XMLNode('RootNode',
                              dbo.fn_XMLNode('Operation',         'SelectWaves') +
                              dbo.fn_XMLNode('Warehouse',         @Warehouse) +
                              dbo.fn_XMLNode('BusinessUnit',      @BusinessUnit) +
                              dbo.fn_XMLNode('MaxWavesToProcess', @vMaxRecords) +
                              dbo.fn_XMLNode('WaveId',            '') +
                              dbo.fn_XMLNode('WaveType',          ''));

  /* Get the list of potential Waves to be considered for the available inventory */
  exec pr_RuleSets_ExecuteAllRules 'AutoActivation', @vRulesInputXML, @BusinessUnit;

  /* Exit process if there are no records */
  if ((select count(WaveId) from #Waves) = 0) goto ExitHandler;

  /* Populate XML input for activating LPNs procedure */
  select @vProcInputXML = dbo.fn_XMLNode('ConfirmLPNReservations',
                            dbo.fn_XMLNode('LPNType',       'S' /* Ship Carton */) +
                            dbo.fn_XMLNode('BusinessUnit',  @BusinessUnit) +
                            dbo.fn_XMLNode('UserId',        @UserId) +
                            dbo.fn_XMLNode('Warehouse',     @Warehouse));

  if (charindex('D' /* Display */, @vDebug) > 0) select 'AutoActivation_Waves', * from #Waves;

  /* Process each wave */
  while (exists(select * from #Waves where RecordId > @vRecordId))
    begin
      begin try
        --begin transaction

        /* Fetch wave info */
        select top 1 @vRecordId = RecordId,
                     @vWaveId   = WaveId,
                     @vWaveNo   = WaveNo,
                     @vWaveType = WaveType
        from #Waves
        where (RecordId > @vRecordId);

        /* Reset hash tables */
        delete from #FromLPNDetails;
        delete from #ToLPNDetails;

        select @vRulesInputXML = dbo.fn_XMLStuffValue(@vRulesInputXML, 'WaveId',   @vWaveId);
        select @vRulesInputXML = dbo.fn_XMLStuffValue(@vRulesInputXML, 'WaveType', @vWaveType);

        /* Populate FromLPNs */
        select @vRulesInputXML = dbo.fn_XMLStuffValue(@vRulesInputXML, 'Operation', 'SelectFromLPNs')
        exec pr_RuleSets_ExecuteAllRules 'AutoActivation', @vRulesInputXML, @BusinessUnit;

        /* Populate ToLPNs */
        select @vRulesInputXML = dbo.fn_XMLStuffValue(@vRulesInputXML, 'Operation', 'SelectToLPNs')
        exec pr_RuleSets_ExecuteAllRules 'AutoActivation', @vRulesInputXML, @BusinessUnit;

        /* Exclusions - Filter Waves or SKUs */
        exec pr_Reservation_AutoActivation_Qualification @vWaveId, @Warehouse, null /* RulesXML */,
                                                         @BusinessUnit, @UserId, @vQualified output;

        /* Process the wave for auto activation based on the flag above */
        if (@vQualified = 'Y' /* Yes */)
          begin
            exec pr_Reservation_ActivateLPNs @vProcInputXML; /* Call procedure to Activate the ToLPNs */

            select @vRecordsProcessed += 1;
          end
        else
          /* Raise error that would be caught and capture in the audit trail */
          exec pr_Messages_ErrorHandler 'AutoActivation_WaveNotQualified' /* Message Name */, @vWaveNo /* Value1 */;

        /* insert into activity log */
        insert into @ttAuditTrailInfo(EntityType, EntityId, EntityKey, ActivityType, BusinessUnit, Comment, UserId)
                select distinct 'Wave', @vWaveId, @vWaveNo, 'AutoActivation', @BusinessUnit, 'Wave Auto Activated', @UserId
          union select distinct 'LPN', LPNId, null, 'AutoActivation', @BusinessUnit, 'LPN Auto Activated', @UserId from #FromLPNDetails where (WaveId = @vWaveId) and (ReservedQty > 0)
          union select distinct 'LPN', LPNId, null, 'AutoActivation', @BusinessUnit, 'Ship Carton Auto Activated', @UserId from #ToLPNDetails where (WaveId = @vWaveId) and (ProcessedFlag = 'A' /* Activate */)

        /* if we have processed the required number of records, then exit loop */
        if (@vRecordsProcessed = @vMaxRecords) break;
        --commit;
      end try
      begin catch
        select @vMessage = ERROR_MESSAGE();

        insert into @ttAuditTrailInfo(EntityType, EntityId, ActivityType, BusinessUnit, Comment, UserId)
          select distinct 'Wave', @vWaveId, 'AutoActivation', @BusinessUnit, @vMessage, @UserId;

        --if (@@trancount > 0) rollback transaction;
      end catch
    end /* End While loop */

  /* Log all audit trail entries */
  exec pr_AuditTrail_InsertRecords @ttAuditTrailInfo;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Reservation_AutoActivation */

Go
