/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/01/20  RV      pr_Allocation_InsertShipLabels: Removed code to evaluate insert ship labels as we evaluating in create shipment proc (FBV3-713)
  2021/06/25  RV      pr_Allocation_InsertShipLabels: Included Module/operation in rules data (BK-378)
  2021/06/08  RV      pr_Allocation_InsertShipLabels: Made changes to insert carrier interface (BK-354)
  2021/05/27  RV      pr_Allocation_InsertShipLabels: Made changes to insert entities into outbound transaction table
                        to call UPS API (CIMSV3-1476)
  2021/03/24  MS      pr_Allocation_InsertShipLabels: Changes to insert PickTicket (2413)
  2021/03/10  MS      pr_Allocation_InsertShipLabels: Bug fix to insert missed columns to fix  (BK-192)
  2020/11/21  VS      pr_Allocation_InsertShipLabels, pr_Allocation_UpdateWaveDependencies: Made changes to update Wave.PrintStatus and Task.Printstatus in Waveupdates
                         to update the PrintJob status (S2GCA-1386)
  2020/07/29  RV      pr_Allocation_InsertShipLabels: Made changes to update PrintStatuses on Tasks, Wave and print jobs statuses (S2GCA-1199)
  2020/05/09  TK      pr_Allocation_InsertShipLabels: Code Revamp (HA-468)
  2019/10/31  MS      pr_Allocation_InsertShipLabels: Changes to compute Shiplabels Dimensions (S2GCA-1022)
  2019/02/22  HB      pr_Allocation_InsertShipLabels: Added EntityId (CIMS-2544)
  2018/09/03  RV      pr_Allocation_InsertShipLabels: Made changes to add IsSmallPackageCarrier
                        to the rules data (S2GCA-236)
  2018/07/11  RV      pr_Allocation_InsertShipLabels: Made changes to batch the labels to generate labels at once with respect to the order and max labels to generate (S2G-1020)
  2018/04/16  RV      pr_Allocation_InsertShipLabels: For some wave Temp LPNs info not available on TD.
                        So remove condition to insert ShipLabels (S2G-655)
  2018/04/11  TK      pr_Allocation_AllocateWave: Added new step to generate temp LPNs
                      pr_Allocation_InsertShipLabels: Changes to consider info from LPNTasks
                      pr_Allocation_SumPicksFromSameLocation: Changes to summarize innerpacks info (S2G-619)
  2018/02/23  RV      pr_Allocation_InsertShipLabels: Intial Version (S2G-255)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Allocation_InsertShipLabels') is not null
  drop Procedure pr_Allocation_InsertShipLabels;
Go
/*------------------------------------------------------------------------------
  Proc pr_Allocation_InsertShipLabels:
    This procedure inserts ship cartons into ShipLabels table based upon the rules to generate the ship labels.
------------------------------------------------------------------------------*/
Create Procedure pr_Allocation_InsertShipLabels
  (@WaveId          TRecordId,
   @Operation       TOperation,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vRecordId               TRecordId,

          @vWaveId                 TPickBatchNo,
          @vWaveType               TTypeCode,
          @vWaveNo                 TPickBatchNo,

          @vNextProcessBatch       TBatch,
          @vRecordCount            TCount,
          @vNumBatches             TCount,
          @vMaxLabelsPerBatch      TInteger,
          @vRuleForWaveType        TFlags,
          @xmlRulesData            TXML;

  declare @ttShipLabelsToInsert    TShipLabels;
  declare @ttTasksToUpdate         TEntityKeysTable;

begin /* pr_Allocation_InsertShipLabels */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Get the Wave info */
  select @vWaveId   = RecordId,
         @vWaveNo   = BatchNo,
         @vWaveType = BatchType
  from Waves
  where (RecordId = @WaveId);

  /* Create required hash tables */
  select * into #ShipLabelsToInsert from @ttShipLabelsToInsert;

  /* Max labels to batch to generate labels */
  select @vMaxLabelsPerBatch = dbo.fn_Controls_GetAsInteger('GenerateShipLabels', 'MaxLabelsToGenerate', '200', @BusinessUnit, @UserId)

  /* Build xml to evaluate the rules for insertion cartons into ShipLabels table */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Operation',              @Operation) +
                           dbo.fn_XMLNode('Module',                 'Allocation') +
                           dbo.fn_XMLNode('WaveId',                 @vWaveId)   +
                           dbo.fn_XMLNode('WaveNo',                 @vWaveNo)   +
                           dbo.fn_XMLNode('WaveType',               @vWaveType) +
                           dbo.fn_XMLNode('LPNId',                  '') +
                           dbo.fn_XMLNode('LPN',                    '') +
                           dbo.fn_XMLNode('OrderId',                '') +
                           dbo.fn_XMLNode('Carrier',                '') +
                           dbo.fn_XMLNode('IsSmallPackageCarrier',  '') +
                           dbo.fn_XMLNode('Validation',             'WaveType') +
                           dbo.fn_XMLNode('BusinessUnit',           @BusinessUnit) +
                           dbo.fn_XMLNode('UserId',                 @UserId));

  exec pr_RuleSets_Evaluate 'Allocation_InsertShipLabels', @xmlRulesData, @vRuleForWaveType output;

  /* If WaveType does not require it, then ignore */
  if (@vRuleForWaveType = 'N') return;

  /* Insert carton details into temp table */
  insert into #ShipLabelsToInsert (EntityId, EntityType, EntityKey, CartonType, SKUId, PackageLength, PackageWidth, PackageHeight,
                                   PackageWeight, PackageVolume, OrderId, PickTicket, TaskId, WaveId, WaveNo, WaveType, LabelType,
                                   RequestedShipVia, ShipVia, Carrier, IsSmallPackageCarrier, BusinessUnit, CreatedBy)
    select distinct L.LPNId, 'L' /* LPN */, L.LPN, L.CartonType, L.SKUId, 0.0, 0.0, 0.0,
                    0.0, 0.0, OH.OrderId, OH.PickTicket, L.TaskId, OH.PickBatchId, OH.PickBatchNo, @vWaveType, 'S' /* Ship Label */,
                    OH.ShipVia, OH.ShipVia, coalesce(S.Carrier, ''), S.IsSmallPackageCarrier, @BusinessUnit, @UserId
    from LPNs L
      join OrderHeaders OH on (L.OrderId = OH.OrderId)
      join ShipVias     S  on (OH.ShipVia = S.ShipVia) and (S.IsSmallPackageCarrier = 'Y')
    where (OH.PickBatchId = @vWaveId) and
          (L.LPNType = 'S'/* ShipCarton */) and
          (L.Status = 'F' /* New Temp */) and
          (L.OnhandStatus = 'U'/* Unavailable */);

  /* Determine the carrier interface and process the create shipment of ship label records */
  exec pr_Carrier_CreateShipment 'Allocation', @Operation, @BusinessUnit, @UserId

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Allocation_InsertShipLabels */

Go
