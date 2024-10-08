/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/21  TK      GenerateShipCartons: Transactions should be handled in procedure (HA-2033)
  2021/02/12  TK      Added More Steps for BPP waves (BK-181)
  2020/11/04  TK      Create pick tasks based on Pick Method
                      New step to Generate API Transaction (CID-1489)
  2020/09/18  AY      PTC: Disabled GenerateShipCartons as PTC orders are packed and we don't predetermine the cartons
  2020/05/13  TK      Renamed Allocate* to AllocateInv_* (HA-86)
  2020/04/05  TK      Allocate  based upon inventory allocation model (HA-385)
  2020/04/22  TK      Allocation Steps for PTC, PTS, RW, XFER & RU wave types (HA-272, 273, 274 & 275)
  2020/04/22  TK      Rules for Case Pick wave (HA-225)
                      Rules for Bulk Pick & Pack wave (HA-226)
  2018/08/10  OK      Added Rule to unwave the orders if not fully allocated (OB2-535)
  2018/07/02  TK      Rules for Dynamic Replenishments (S2GCA-22)
  2018/04/05  TK      Corrected rules for CF and Zone C waves (S2G-582)
  2018/04/04  AY      Setup Allocation Rules for LTL and correct for CF wave.
  2018/04/02  AJ      Added rule to Unwave DisQualified Orders (S2G-492)
  2018/03/29  TK      Allocate Directed Units if there are no cases then can be allocated (S2G-499)
  2018/03/26  AJ      Changes to use union statements while inserting rules (S2G-492)
  2018/03/24  TK      Added Rules for PTL, PTLC (PickToLabel, PickToLabel PerCase) Waves
  2018/03/23  TK      Added Rules for Replenish Cases Wave (S2G-385)
  2018/03/07  RV      Added descriptions for rules and RuleSets (S2G-255)
  2018/02/28  RV      Added new rules to insert cartons into ShipLabel table for SLB and PP waves (S2G-255)
  2016/08/05  TK      Changed AllocateDirectedQty -> AllocateDirectedQtyForBulk (HPI-442)
  2016/06/28  TK      Added New step to create pick tasks (HPI-162)
  2016/06/08  KK      Added rules for VAS Wave (NBD-592)
  2016/05/31  TK      Revised rules for Pick & Pack Waves (HPI-144)
  2016/03/26  OK      Removed the RuleSetId field as it is a auto generated column (CIMS-837)
  2016/03/19  OK      Specified the fields while inserting the Rules and RuleSets (HPI-29)
  2016/02/11  AY      Setup rules for Single Line Order waves
  2015/11/16  AY      Setup UpdateWaveCounts as the last step for all rules
  2015/07/01  TK      Initial version
------------------------------------------------------------------------------*/

Go

declare @vRecordId            TRecordId,
        @vRuleSetType         TRuleSetType,
        @vRuleSetName         TName,
        @vRuleSetDescription  TDescription,
        @vRuleSetFilter       TQuery,

        @vBusinessUnit        TBusinessUnit,

        @vRuleCondition       TQuery,
        @vRuleQuery           TQuery,
        @vRuleQueryType       TTypeCode,
        @vRuleDescription     TDescription,

        @vSortSeq             TSortSeq,
        @vStatus              TStatus;

declare @RuleSets             TRuleSetsTable,
        @Rules                TRulesTable;

/*------------------------------------------------------------------------------*/
/* Allocation Steps Explanation:

  CreateConsolidatedPT: Creates Consolidated Pick Ticket (Bulk Pull)
  GeneratePseudoPicks: Generates Pseudo Picks(tasks without pick from info) for customer orders

  AllocatePreAllocatedCases: Allocates the inventory that is perticualry received/created for an order
                             allocates the inventory that matches the Lot of the Order
  AllocateInv_AvailableCases: Allocates available inventory in cases i,e. if ordered quantity is 100 & units/case is 30 then
                              system allocates 3 cases which is for 90 units only
  AllocateInv_AvailableUnits: Allocates available inventory for residual units of the ordered quantity i,e. if ordered quantity is 100 &
                              units/case is 30 then system allocates 10 units only but if units/case is '0' then
                              system allocates complete 100 units
  AllocateInv_AvailableQty: Allocates available inventory in units irrespective of units/case i,e. if ordered quantity is 100 &
                            units/case is either 30 or 0, system allocated 100 units
  AllocateInv_DirectedCases: It does same as AllocateAvailableCases but it allocates directed quantity
  AllocateInv_DirectedUnits: It does same as AllocateInv_AvailableUnits but it allocates directed quantity
  AllocateInv_DirectedQty: It does same as AllocateInv_AvailableQty but it allocates directed quantity

  GenerateOnDemandOrders: Generates On-Demand replenishment order when picklanes are set up and order being
                          allocated requires more inventory than what is available in the picklane

  CubeOrderDetails: Cubes Order Details of the wave that is being allocated
  CubeTaskDetails: Cubes Task Details of the wave that is being allocated

  ProcessTaskDetails: This does the necessary updates on the tasks details that will be helpful to group them or
                      issue picks to the user while picking in a particular sequence and so on
  CreatePickTasks: This step groups the task details/picks as per the task categories defined and as per the thresholds
                   like MaxUnits, MaxCases, MaxOrders, MaxWeight, MaxVolume etc which are defined in controls
  CreatePickTasks_PTS: This step groups the cubed task details as per the cart cubing logic defined i,e. Shelf Width &
                       Number of Shleves per Picking Cart

  UnWaveDisqualifiedOrders: This step evaluates whether the orders on the wave are qualified to ship or not based upon ship complete rules,
                            and removes the un-qualified orders from wave
  UpdateWaveDependencies: This step updates the dependices on the wave i,e. whether the wave is ready to pick or
                          waiting on replenishment or units are short to start picking and so on
  InsertShipLabels: This step inserts the ship cartons that are to be shipped by small package carriers into shiplabels
                    ship cartons may be generated thru cubing or by some other operation
  FinalizeWaveAllocation: This steps finalizes the updates to be done on waves or orders or tasks
  PrintDocuments_Allocation: This step generate a print request to schedule/print all the required docuents (labels & reports) for the wave
*/
/*------------------------------------------------------------------------------*/

/******************************************************************************/
/******************************************************************************/
/* Rules for : Describe the RuleSet Type here */
/******************************************************************************/
/******************************************************************************/
select @vRuleSetType = 'AllocateWave';

delete from @RuleSets;
delete from @Rules;

/******************************************************************************/
/* Rule Set - Bulk Case Pick Waves */
/******************************************************************************/
select @vRuleSetName        = 'Bulk Case Pick Waves',
       @vRuleSetDescription = 'Allocation steps for Bulk Case Pick Waves',
       @vRuleSetFilter      = '~WaveType~ = ''BCP''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules for Bulk Case Pick Wave */
insert into @Rules
            (RuleQuery,                                   Status, SortSeq, RuleCondition,                    TransactionScope, RuleDescription,                         RuleSetName)
      select 'select ''CreateConsolidatedPT''',           'A',     10,     null,                             null,             'Create Consolidated/Bulk PT',           @vRuleSetName
union select 'select ''GeneratePseudoPicks''',            'NA',    11,     null,                             null,             'Generate Pseudo Picks',                 @vRuleSetName
/*----------*/
union select 'select ''AllocatePreAllocatedCases''',      'NA',    20,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate pre allocated cases',          @vRuleSetName
union select 'select ''AllocateInv_AvailableCases''',     'NA',    21,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available cases',              @vRuleSetName
union select 'select ''AllocateInv_AvailableUnits''',     'NA',    22,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available units',              @vRuleSetName
union select 'select ''AllocateInv_AvailableQty''',       'A',     23,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available quantity',           @vRuleSetName
union select 'select ''AllocateInv_DirectedCases''',      'NA',    24,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate directed cases',               @vRuleSetName
union select 'select ''AllocateInv_DirectedUnits''',      'NA',    25,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate directed units',               @vRuleSetName
union select 'select ''AllocateInv_DirectedQty''',        'NA',    26,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate Directed qty',                 @vRuleSetName
/*----------*/
union select 'select ''GenerateOnDemandOrders''',         'NA',    40,     '~IsReplenished~ = ''N''',        null,             'Generate on demand orders',             @vRuleSetName
/*----------*/
union select 'select ''ProcessTaskDetails_PreCubing''',   'NA',    61,     null,                             null,             'Categorize Task Details before Cubing', @vRuleSetName
union select 'select ''CubeOrderDetails''',               'NA',    62,     null,                             'Procedure',      'Cube Order Details',                    @vRuleSetName
union select 'select ''CubeTaskDetails''',                'NA',    63,     null,                             'Procedure',      'Cube Task Details',                     @vRuleSetName
union select 'select ''ProcessTaskDetails''',             'A',     64,     null,                             null,             'Categorize Task Details',               @vRuleSetName
/*----------*/
union select 'select ''CreatePickTasks''',                'A',     71,     null,                             null,             'Generate Pick Tasks',                   @vRuleSetName
union select 'select ''CreatePickTasks_PTS''',            'NA',    72,     null,                             null,             'Generate Pick Tasks for PTS',           @vRuleSetName
/*----------*/
union select 'select ''UnWaveDisqualifiedOrders''',       'NA',    80,     null,                             null,             'Un-Wave Disqualified Orders',           @vRuleSetName
union select 'select ''GenerateShipCartons''',            'A',     81,     null,                             'Procedure',      'Generate Shipping Cartons',             @vRuleSetName
union select 'select ''InsertShipLabels''',               'A',     82,     null,                             null,             'Insert cartons into ShipLabels table',  @vRuleSetName
union select 'select ''UpdateWaveDependencies''',         'A',     83,     null,                             null,             'Update Wave dependencies',              @vRuleSetName
/*----------*/
union select 'select ''FinalizeWaveAllocation''',         'A',     90,     null,                             null,             'Update Wave counts',                    @vRuleSetName
union select 'select ''PrintDocuments_Allocation''',      'A',     91,     null,                             null,             'Create Print service requests',         @vRuleSetName

/******************************************************************************/
/* Rule Set - Bulk Pick & Pack Waves */
/******************************************************************************/
select @vRuleSetName        = 'Bulk Pick & Pack Waves',
       @vRuleSetDescription = 'Allocation steps for Bulk Pick & Pack Waves',
       @vRuleSetFilter      = '~WaveType~ = ''BPP''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules for Bulk Pick & Pack Wave */
insert into @Rules
            (RuleQuery,                                            Status, SortSeq, RuleCondition,                    TransactionScope, RuleDescription,                         RuleSetName)
      select 'select ''CreateConsolidatedPT''',                    'A',    10,      null,                             null,             'Create Consolidated/Bulk PT',           @vRuleSetName
union select 'select ''GeneratePseudoPicks''',                     'NA',   11,      null,                             null,             'Generate Pseudo Picks',                 @vRuleSetName
/*----------*/
union select 'select ''AllocatePreAllocatedCases''',               'NA',   20,      '~InvAllocationModel~ = ''SR''',  null,             'Allocate pre allocated cases',          @vRuleSetName
union select 'select ''AllocateInv_AvailableLPNsFromBulk''',       'A',    21,      '~InvAllocationModel~ = ''SR''',  null,             'Allocate available LPNs from Bulk',     @vRuleSetName
union select 'select ''AllocateInv_AvailableLPNsFromReserve''',    'A',    22,      '~InvAllocationModel~ = ''SR''',  null,             'Allocate available LPNs from Reserve',  @vRuleSetName
union select 'select ''AllocateInv_AvailableCasesFromBulk''',      'A',    23,      '~InvAllocationModel~ = ''SR''',  null,             'Allocate available cases from Bulk',    @vRuleSetName
union select 'select ''AllocateInv_AvailableCasesFromReserve''',   'A',    24,      '~InvAllocationModel~ = ''SR''',  null,             'Allocate available cases from Reserve', @vRuleSetName
union select 'select ''AllocateInv_AvailableQtyFromBulk''',        'A',    25,      '~InvAllocationModel~ = ''SR''',  null,             'Allocate available Qty from Bulk',      @vRuleSetName
union select 'select ''AllocateInv_AvailableQtyFromReserve''',     'A',    26,      '~InvAllocationModel~ = ''SR''',  null,             'Allocate available Qty from Reserve',   @vRuleSetName
union select 'select ''AllocateInv_AvailableQty''',                'A',    27,      '~InvAllocationModel~ = ''SR''',  null,             'Allocate available quantity',           @vRuleSetName
union select 'select ''AllocateInv_DirectedCases''',               'NA',   28,      '~InvAllocationModel~ = ''SR''',  null,             'Allocate directed cases',               @vRuleSetName
union select 'select ''AllocateInv_DirectedUnits''',               'NA',   29,      '~InvAllocationModel~ = ''SR''',  null,             'Allocate directed units',               @vRuleSetName
union select 'select ''AllocateInv_DirectedQty''',                 'NA',   30,      '~InvAllocationModel~ = ''SR''',  null,             'Allocate Directed qty',                 @vRuleSetName
/*----------*/
union select 'select ''GenerateOnDemandOrders''',                  'NA',   40,      '~IsReplenished~ = ''N''',        null,             'Generate on demand orders',             @vRuleSetName
/*----------*/
union select 'select ''ProcessTaskDetails_PreCubing''',            'NA',   61,      null,                             null,             'Categorize Task Details before Cubing', @vRuleSetName
union select 'select ''CubeOrderDetails''',                        'A',    62,      null,                             'Procedure',      'Cube Order Details',                    @vRuleSetName
union select 'select ''CubeTaskDetails''',                         'NA',   63,      null,                             'Procedure',      'Cube Task Details',                     @vRuleSetName
union select 'select ''ProcessTaskDetails''',                      'A',    64,      null,                             null,             'Categorize Task Details',               @vRuleSetName
/*----------*/
union select 'select ''CreatePickTasks''',                         'A',    71,      '~PickMethod~ = ''CIMSRF''',      null,             'Generate Pick Tasks',                   @vRuleSetName
union select 'select ''CreatePickTasks_PTS''',                     'NA',   72,      '~PickMethod~ = ''CIMSRF''',      null,             'Generate Pick Tasks for PTS',           @vRuleSetName
union select 'select ''_GenerateAPITransaction''',                 'NA',   75,      '~PickMethod~ = ''6River''',      null,             'Generate API Transaction',              @vRuleSetName
/*----------*/
union select 'select ''UnWaveDisqualifiedOrders''',                'NA',   80,      null,                             null,             'Un-Wave Disqualified Orders',           @vRuleSetName
union select 'select ''GenerateShipCartons''',                     'NA',   81,      null,                             'Procedure',      'Generate Shipping Cartons',             @vRuleSetName
union select 'select ''InsertShipLabels''',                        'A',    82,      null,                             null,             'Insert cartons into ShipLabels table',  @vRuleSetName
union select 'select ''UpdateWaveDependencies''',                  'A',    83,      null,                             null,             'Update Wave dependencies',              @vRuleSetName
/*----------*/
union select 'select ''FinalizeWaveAllocation''',                  'A',    90,      null,                             null,             'Update Wave counts',                    @vRuleSetName
union select 'select ''PrintDocuments_Allocation''',               'A',    91,      null,                             null,             'Create Print service requests',         @vRuleSetName

/******************************************************************************/
/* Rule Set - Pick To Cart Waves */
/******************************************************************************/
select @vRuleSetName        = 'Pick To Cart Waves',
       @vRuleSetDescription = 'Allocation steps for Pick To Cart Waves',
       @vRuleSetFilter      = '~WaveType~ = ''PTC''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules for Pick To Cart Wave */
insert into @Rules
            (RuleQuery,                                   Status, SortSeq, RuleCondition,                    TransactionScope, RuleDescription,                         RuleSetName)
      select 'select ''CreateConsolidatedPT''',           'NA',    10,     null,                             null,             'Create Consolidated/Bulk PT',           @vRuleSetName
union select 'select ''GeneratePseudoPicks''',            'NA',    11,     null,                             null,             'Generate Pseudo Picks',                 @vRuleSetName
/*----------*/
union select 'select ''AllocatePreAllocatedCases''',      'NA',    20,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate pre allocated cases',          @vRuleSetName
union select 'select ''AllocateInv_AvailableCases''',     'NA',    21,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available cases',              @vRuleSetName
union select 'select ''AllocateInv_AvailableUnits''',     'NA',    22,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available units',              @vRuleSetName
union select 'select ''AllocateInv_AvailableQty''',       'A',     23,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available quantity',           @vRuleSetName
union select 'select ''AllocateInv_DirectedCases''',      'NA',    24,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate directed cases',               @vRuleSetName
union select 'select ''AllocateInv_DirectedUnits''',      'NA',    25,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate directed units',               @vRuleSetName
union select 'select ''AllocateInv_DirectedQty''',        'A',     26,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate Directed qty',                 @vRuleSetName
/*----------*/
union select 'select ''GenerateOnDemandOrders''',         'A',     40,     '~IsReplenished~ = ''N''',        null,             'Generate on demand orders',             @vRuleSetName
/*----------*/
union select 'select ''ProcessTaskDetails_PreCubing''',   'NA',    61,     null,                             null,             'Categorize Task Details before Cubing', @vRuleSetName
union select 'select ''CubeOrderDetails''',               'NA',    62,     null,                             'Procedure',      'Cube Order Details',                    @vRuleSetName
union select 'select ''CubeTaskDetails''',                'NA',    63,     null,                             'Procedure',      'Cube Task Details',                     @vRuleSetName
union select 'select ''ProcessTaskDetails''',             'A',     64,     null,                             null,             'Categorize Task Details',               @vRuleSetName
/*----------*/
union select 'select ''CreatePickTasks''',                'A',     71,     '~PickMethod~ = ''CIMSRF''',      null,             'Generate Pick Tasks',                   @vRuleSetName
union select 'select ''CreatePickTasks_PTS''',            'NA',    72,     '~PickMethod~ = ''CIMSRF''',      null,             'Generate Pick Tasks for PTS',           @vRuleSetName
union select 'select ''_GenerateAPITransaction''',        'NA',    75,     '~PickMethod~ = ''6River''',      null,             'Generate API Transaction',              @vRuleSetName
/*----------*/
union select 'select ''UnWaveDisqualifiedOrders''',       'NA',    80,     null,                             null,             'Un-Wave Disqualified Orders',           @vRuleSetName
union select 'select ''GenerateShipCartons''',            'NA',    81,     null,                             'Procedure',      'Generate Shipping Cartons',             @vRuleSetName
union select 'select ''InsertShipLabels''',               'NA',    82,     null,                             null,             'Insert cartons into ShipLabels table',  @vRuleSetName
union select 'select ''UpdateWaveDependencies''',         'A',     83,     null,                             null,             'Update Wave dependencies',              @vRuleSetName
/*----------*/
union select 'select ''FinalizeWaveAllocation''',         'A',     90,     null,                             null,             'Update Wave counts',                    @vRuleSetName
union select 'select ''PrintDocuments_Allocation''',      'A',     91,     null,                             null,             'Create Print service requests',         @vRuleSetName

/******************************************************************************/
/* Rule Set - Pick To Ship Waves */
/******************************************************************************/
select @vRuleSetName        = 'Pick To Ship Waves',
       @vRuleSetDescription = 'Allocation steps for Pick To Ship Waves',
       @vRuleSetFilter      = '~WaveType~ = ''PTS''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules for Pick To Ship Wave */
insert into @Rules
            (RuleQuery,                                   Status, SortSeq, RuleCondition,                    TransactionScope, RuleDescription,                         RuleSetName)
      select 'select ''CreateConsolidatedPT''',           'NA',    10,     null,                             null,             'Create Consolidated/Bulk PT',           @vRuleSetName
union select 'select ''GeneratePseudoPicks''',            'NA',    11,     null,                             null,             'Generate Pseudo Picks',                 @vRuleSetName
/*----------*/
union select 'select ''AllocatePreAllocatedCases''',      'NA',    20,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate pre allocated cases',          @vRuleSetName
union select 'select ''AllocateInv_AvailableCases''',     'NA',    21,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available cases',              @vRuleSetName
union select 'select ''AllocateInv_AvailableUnits''',     'NA',    22,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available units',              @vRuleSetName
union select 'select ''AllocateInv_AvailableQty''',       'A',     23,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available quantity',           @vRuleSetName
union select 'select ''AllocateInv_DirectedCases''',      'NA',    24,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate directed cases',               @vRuleSetName
union select 'select ''AllocateInv_DirectedUnits''',      'NA',    25,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate directed units',               @vRuleSetName
union select 'select ''AllocateInv_DirectedQty''',        'A',     26,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate Directed qty',                 @vRuleSetName
/*----------*/
union select 'select ''GenerateOnDemandOrders''',         'A',     40,     '~IsReplenished~ = ''N''',        null,             'Generate on demand orders',             @vRuleSetName
/*----------*/
union select 'select ''ProcessTaskDetails_PreCubing''',   'NA',    61,     null,                             null,             'Categorize Task Details before Cubing', @vRuleSetName
union select 'select ''CubeOrderDetails''',               'NA',    62,     null,                             'Procedure',      'Cube Order Details',                    @vRuleSetName
union select 'select ''CubeTaskDetails''',                'A',     63,     null,                             'Procedure',      'Cube Task Details',                     @vRuleSetName
union select 'select ''ProcessTaskDetails''',             'A',     64,     null,                             null,             'Categorize Task Details',               @vRuleSetName
/*----------*/
union select 'select ''CreatePickTasks''',                'NA',    71,     '~PickMethod~ = ''CIMSRF''',      null,             'Generate Pick Tasks',                   @vRuleSetName
union select 'select ''CreatePickTasks_PTS''',            'A',     72,     '~PickMethod~ = ''CIMSRF''',      null,             'Generate Pick Tasks for PTS',           @vRuleSetName
union select 'select ''_GenerateAPITransaction''',        'A',     75,     '~PickMethod~ = ''6River''',      null,             'Generate API Transaction',              @vRuleSetName
/*----------*/
union select 'select ''UnWaveDisqualifiedOrders''',       'NA',    80,     null,                             null,             'Un-Wave Disqualified Orders',           @vRuleSetName
union select 'select ''GenerateShipCartons''',            'NA',    81,     null,                             'Procedure',      'Generate Shipping Cartons',             @vRuleSetName
union select 'select ''InsertShipLabels''',               'A',     82,     null,                             null,             'Insert cartons into ShipLabels table',  @vRuleSetName
union select 'select ''UpdateWaveDependencies''',         'A',     83,     null,                             null,             'Update Wave dependencies',              @vRuleSetName
/*----------*/
union select 'select ''FinalizeWaveAllocation''',         'A',     90,     null,                             null,             'Update Wave counts',                    @vRuleSetName
union select 'select ''PrintDocuments_Allocation''',      'A',     91,     null,                             null,             'Create Print service requests',         @vRuleSetName

/******************************************************************************/
/* Rule Set - Rework Waves */
/******************************************************************************/
select @vRuleSetName        = 'Rework Waves',
       @vRuleSetDescription = 'Allocation steps for Rework Waves',
       @vRuleSetFilter      = '~WaveType~ = ''RW''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules for Rework Wave */
insert into @Rules
            (RuleQuery,                                   Status, SortSeq, RuleCondition,                    TransactionScope, RuleDescription,                         RuleSetName)
      select 'select ''CreateConsolidatedPT''',           'NA',    10,     null,                             null,             'Create Consolidated/Bulk PT',           @vRuleSetName
union select 'select ''GeneratePseudoPicks''',            'NA',    11,     null,                             null,             'Generate Pseudo Picks',                 @vRuleSetName
/*----------*/
union select 'select ''AllocatePreAllocatedCases''',      'NA',    20,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate pre allocated cases',          @vRuleSetName
union select 'select ''AllocateInv_AvailableCases''',     'NA',    21,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available cases',              @vRuleSetName
union select 'select ''AllocateInv_AvailableUnits''',     'NA',    22,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available units',              @vRuleSetName
union select 'select ''AllocateInv_AvailableQty''',       'A',     23,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available quantity',           @vRuleSetName
union select 'select ''AllocateInv_DirectedCases''',      'NA',    24,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate directed cases',               @vRuleSetName
union select 'select ''AllocateInv_DirectedUnits''',      'NA',    25,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate directed units',               @vRuleSetName
union select 'select ''AllocateInv_DirectedQty''',        'NA',    26,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate Directed qty',                 @vRuleSetName
/*----------*/
union select 'select ''GenerateOnDemandOrders''',         'NA',    40,     '~IsReplenished~ = ''N''',        null,             'Generate on demand orders',             @vRuleSetName
/*----------*/
union select 'select ''ProcessTaskDetails_PreCubing''',   'NA',    61,     null,                             null,             'Categorize Task Details before Cubing', @vRuleSetName
union select 'select ''CubeOrderDetails''',               'NA',    62,     null,                             'Procedure',      'Cube Order Details',                    @vRuleSetName
union select 'select ''CubeTaskDetails''',                'NA',    63,     null,                             'Procedure',      'Cube Task Details',                     @vRuleSetName
union select 'select ''ProcessTaskDetails''',             'A',     64,     null,                             null,             'Categorize Task Details',               @vRuleSetName
/*----------*/
union select 'select ''CreatePickTasks''',                'A',     71,     null,                             null,             'Generate Pick Tasks',                   @vRuleSetName
union select 'select ''CreatePickTasks_PTS''',            'NA',    72,     null,                             null,             'Generate Pick Tasks for PTS',           @vRuleSetName
/*----------*/
union select 'select ''UnWaveDisqualifiedOrders''',       'NA',    80,     null,                             null,             'Un-Wave Disqualified Orders',           @vRuleSetName
union select 'select ''GenerateShipCartons''',            'NA',    81,     null,                             'Procedure',      'Generate Shipping Cartons',             @vRuleSetName
union select 'select ''InsertShipLabels''',               'NA',    82,     null,                             null,             'Insert cartons into ShipLabels table',  @vRuleSetName
union select 'select ''UpdateWaveDependencies''',         'A',     83,     null,                             null,             'Update Wave dependencies',              @vRuleSetName
/*----------*/
union select 'select ''FinalizeWaveAllocation''',         'A',     90,     null,                             null,             'Update Wave counts',                    @vRuleSetName
union select 'select ''PrintDocuments_Allocation''',      'A',     91,     null,                             null,             'Create Print service requests',         @vRuleSetName

/******************************************************************************/
/* Rule Set - Transfer Waves */
/******************************************************************************/
select @vRuleSetName        = 'Transfer Waves',
       @vRuleSetDescription = 'Allocation steps for Transfer Waves',
       @vRuleSetFilter      = '~WaveType~ = ''XFER''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules for Transfer Wave */
insert into @Rules
            (RuleQuery,                                   Status, SortSeq, RuleCondition,                    TransactionScope, RuleDescription,                         RuleSetName)
      select 'select ''CreateConsolidatedPT''',           'NA',    10,     null,                             null,             'Create Consolidated/Bulk PT',           @vRuleSetName
union select 'select ''GeneratePseudoPicks''',            'NA',    11,     null,                             null,             'Generate Pseudo Picks',                 @vRuleSetName
/*----------*/
union select 'select ''AllocatePreAllocatedCases''',      'NA',    20,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate pre allocated cases',          @vRuleSetName
union select 'select ''AllocateInv_AvailableCases''',     'NA',    21,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available cases',              @vRuleSetName
union select 'select ''AllocateInv_AvailableUnits''',     'NA',    22,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available units',              @vRuleSetName
union select 'select ''AllocateInv_AvailableQty''',       'A',     23,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate available quantity',           @vRuleSetName
union select 'select ''AllocateInv_DirectedCases''',      'NA',    24,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate directed cases',               @vRuleSetName
union select 'select ''AllocateInv_DirectedUnits''',      'NA',    25,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate directed units',               @vRuleSetName
union select 'select ''AllocateInv_DirectedQty''',        'NA',    26,     '~InvAllocationModel~ = ''SR''',  null,             'Allocate Directed qty',                 @vRuleSetName
/*----------*/
union select 'select ''GenerateOnDemandOrders''',         'NA',    40,     '~IsReplenished~ = ''N''',        null,             'Generate on demand orders',             @vRuleSetName
/*----------*/
union select 'select ''ProcessTaskDetails_PreCubing''',   'NA',    61,     null,                             null,             'Categorize Task Details before Cubing', @vRuleSetName
union select 'select ''CubeOrderDetails''',               'NA',    62,     null,                             'Procedure',      'Cube Order Details',                    @vRuleSetName
union select 'select ''CubeTaskDetails''',                'NA',    63,     null,                             'Procedure',      'Cube Task Details',                     @vRuleSetName
union select 'select ''ProcessTaskDetails''',             'A',     64,     null,                             null,             'Categorize Task Details',               @vRuleSetName
/*----------*/
union select 'select ''CreatePickTasks''',                'A',     71,     null,                             null,             'Generate Pick Tasks',                   @vRuleSetName
union select 'select ''CreatePickTasks_PTS''',            'NA',    72,     null,                             null,             'Generate Pick Tasks for PTS',           @vRuleSetName
/*----------*/
union select 'select ''UnWaveDisqualifiedOrders''',       'NA',    80,     null,                             null,             'Un-Wave Disqualified Orders',           @vRuleSetName
union select 'select ''GenerateShipCartons''',            'NA',    81,     null,                             'Procedure',      'Generate Shipping Cartons',             @vRuleSetName
union select 'select ''InsertShipLabels''',               'NA',    82,     null,                             null,             'Insert cartons into ShipLabels table',  @vRuleSetName
union select 'select ''UpdateWaveDependencies''',         'A',     83,     null,                             null,             'Update Wave dependencies',              @vRuleSetName
/*----------*/
union select 'select ''FinalizeWaveAllocation''',         'A',     90,     null,                             null,             'Update Wave counts',                    @vRuleSetName
union select 'select ''PrintDocuments_Allocation''',      'A',     91,     null,                             null,             'Create Print service requests',         @vRuleSetName

/******************************************************************************/
/* Rule Set - Single Line Bulk Wave */
/******************************************************************************/
select @vRuleSetName        = 'AllocateWave_SingleLineWave',
       @vRuleSetDescription = 'SLB: Allocate Wave steps for Single Line Bulk wave',
       @vRuleSetFilter      = '~WaveType~ = ''SLB''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules for Single Line Bulk Wave */
insert into @Rules
            (RuleQuery,                                              RuleDescription,                                  RuleCondition,  Status, SortSeq, TransactionScope, RuleSetName)
      select 'select ''CreateConsolidatedPT''',                      'Create consolidated PickTicket/Bulk PT',         null,           'A',    1,       null,             @vRuleSetName
union select 'select ''AllocateInv_LPNsFromReserve''',               'Allocate LPNs from Reserve',                     null,           'A',    2,       null,             @vRuleSetName
union select 'select ''AllocateInv_AvailableQtyFromPicklanes''',     'Allocate available qty from picklanes',          null,           'A',    3,       null,             @vRuleSetName
union select 'select ''AllocateInv_DirectedQtyFromPicklanes''',      'Allocate directed qty from picklanes',           null,           'A',    4,       null,             @vRuleSetName
/*----------*/
union select 'select ''GenerateOnDemandOrders''',                    'Generate on demand orders',                      '~IsReplenished~ = ''N''',
                                                                                                                                       'A',    6,       null,             @vRuleSetName
union select 'select ''AllocateInv_AvailableQtyFromReserve''',       'Allocate from Reserve Locations',                null,           'A',    7,       null,             @vRuleSetName
/*----------*/
union select 'select ''ProcessTaskDetails_PostCubing''',             'Process Task Details',                           null,           'A',    8,       null,             @vRuleSetName
union select 'select ''CreatePickTasks''',                           'Generate pick tasks',                            '~PickMethod~ = ''CIMSRF''',
                                                                                                                                       'A',    9,       null,             @vRuleSetName
union select 'select ''_GenerateAPITransaction''',                   'Generate API Transaction',                      '~PickMethod~ = ''6River''',
                                                                                                                                       'A',    10,      null,             @vRuleSetName
union select 'select ''GenerateShipCartons''',                       'Generate Shipping Cartons',                      '~WaveStatus~ = ''R''',
                                                                                                                                       'A',    11,      'Procedure',      @vRuleSetName
/*----------*/
union select 'select ''InsertShipLabels''',                          'Insert cartons into ShipLabels table',           null,           'A',    40,      null,             @vRuleSetName
union select 'select ''UpdateWaveDependencies''',                    'Update Wave dependencies',                       null,           'A',    42,      null,             @vRuleSetName
union select 'select ''UpdateWaveCounts''',                          'Update wave counts',                             null,           'A',    99,      null,             @vRuleSetName


/******************************************************************************/
/* Rule Set - Pick to Label Waves */
/******************************************************************************/
select @vRuleSetName        = 'AllocateWave_PickToLabelWave',
       @vRuleSetDescription = 'PTL: Allocate Wave steps for Pick To Label Wave',
       @vRuleSetFilter      = '~WaveType~ = ''PTL''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules for Pick to Label Wave */
insert into @Rules
            (RuleQuery,                              RuleDescription,                   RuleCondition,  Status, SortSeq, RuleSetName)
      select 'select ''AllocatePreAllocatedCases''', 'Allocate pre allocated cases',    null,           'NA',   1,       @vRuleSetName
union select 'select ''AllocateInv_AvailableCases''','Allocate available Cases',        null,           'A',    2,       @vRuleSetName
union select 'select ''AllocateInv_AvailableUnits''','Allocate available units',        null,           'A',    3,       @vRuleSetName
union select 'select ''AllocateInv_DirectedCases''', 'Allocate directed cases',         null,           'A',    4,       @vRuleSetName
union select 'select ''AllocateInv_DirectedUnits''', 'Allocate directed units',         null,           'A',    5,       @vRuleSetName
union select 'select ''GenerateOnDemandOrders''',    'Generate on demand orders',       '~IsReplenished~ = ''N''',
                                                                                                        'A',    6,       @vRuleSetName
union select 'select ''AllocateInv_AvailableQty''',  'Allocate available quantity',     null,           'A',    7,       @vRuleSetName
union select 'select ''AllocateInv_DirectedQty''',   'Allocate available Directed qty', null,           'A',    8,       @vRuleSetName
union select 'select ''Cubing''',                    'Cube task details',               null,           'A',    9,       @vRuleSetName
union select 'select ''ProcessTaskDetails''',        'Categorize created task details', null,           'A',    10,      @vRuleSetName
union select 'select ''CreatePickTasks''',           'Generate pick tasks',             null,           'A',    11,      @vRuleSetName
union select 'select ''UnWaveDisqualifiedOrders''',  'Un-Wave Disqualified Orders',     null,           'NA',   12,      @vRuleSetName
union select 'select ''InsertShipLabels''',          'Insert cartons into ShipLabels table',
                                                                                        null,           'A',    13,      @vRuleSetName
union select 'select ''UpdateWaveDependencies''',    'Update Wave dependencies',        null,           'A',    14,      @vRuleSetName
union select 'select ''UpdateWaveCounts''',          'Update Wave counts',              null,           'A',    15,      @vRuleSetName

/******************************************************************************/
/* Rule Set - Pick to Label Per case Waves */
/******************************************************************************/
select @vRuleSetName        = 'AllocateWave_PickToLabelPerCaseWave',
       @vRuleSetDescription = 'PTLC: Allocate Wave steps for Pick To Label Per Case Wave',
       @vRuleSetFilter      = '~WaveType~ = ''PTLC''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules for Pick to Label Per case Wave */
insert into @Rules
            (RuleQuery,                              RuleDescription,                   RuleCondition,  Status, SortSeq, RuleSetName)
      select 'select ''AllocatePreAllocatedCases''', 'Allocate pre allocated cases',    null,           'NA',   1,       @vRuleSetName
union select 'select ''AllocateInv_AvailableCases''','Allocate available Cases',        null,           'A',    2,       @vRuleSetName
union select 'select ''AllocateInv_AvailableUnits''','Allocate available units',        null,           'NA',   3,       @vRuleSetName
union select 'select ''AllocateInv_DirectedCases''', 'Allocate directed cases',         null,           'NA',   4,       @vRuleSetName
union select 'select ''AllocateInv_DirectedUnits''', 'Allocate directed units',         null,           'I',    5,       @vRuleSetName
union select 'select ''GenerateOnDemandOrders''',    'Generate on demand orders',       '~IsReplenished~ = ''N''',
                                                                                                        'A',    6,       @vRuleSetName
union select 'select ''AllocateInv_AvailableQty''',  'Allocate available quantity',     null,           'NA',   7,       @vRuleSetName
union select 'select ''AllocateInv_DirectedQty''',   'Allocate available Directed qty', null,           'NA',   8,       @vRuleSetName
union select 'select ''Cubing''',                    'Cube task details',               null,           'I',    9,       @vRuleSetName
union select 'select ''ProcessTaskDetails''',        'Categorize created task details', null,           'A',    10,      @vRuleSetName
union select 'select ''CreatePickTasks''',           'Generate pick tasks',             null,           'A',    11,      @vRuleSetName
union select 'select ''UnWaveDisQualifiedOrders''',  'Un-Wave DisQualified Orders',     null,           'NA',   12,      @vRuleSetName
union select 'select ''GenerateTempLabels''',        'Generate Temp Labels for cases',  null,           'A',    13,      @vRuleSetName
union select 'select ''InsertShipLabels''',          'Insert cartons into ShipLabels table',
                                                                                        null,           'A',    14,      @vRuleSetName
union select 'select ''UpdateWaveDependencies''',    'Update Wave dependencies',        null,           'A',    15,      @vRuleSetName
union select 'select ''UpdateWaveCounts''',          'Update Wave counts',              null,           'A',    16,      @vRuleSetName


/******************************************************************************/
/* Rule Set - LTL Waves */
/******************************************************************************/
select @vRuleSetName        = 'AllocateWave_LTLWave',
       @vRuleSetDescription = 'LTL: Allocate Wave steps for LTL Wave',
       @vRuleSetFilter      = '~WaveType~ = ''LTL''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules for LTL Wave */
insert into @Rules
            (RuleQuery,                                              RuleDescription,                                  RuleCondition,  Status, SortSeq, TransactionScope, RuleSetName)
      select 'select ''AllocateInv_LPNsFromReserve''',               'Allocate LPNs from Reserve',                     null,           'A',    10,      null,             @vRuleSetName
union select 'select ''AllocateInv_AvailableQtyFromPicklanes''',     'Allocate available qty from picklanes',          null,           'A',    11,      null,             @vRuleSetName
union select 'select ''AllocateInv_DirectedQtyFromPicklanes''',      'Allocate directed qty from picklanes',           null,           'A',    12,      null,             @vRuleSetName
/*----------*/
union select 'select ''GenerateOnDemandOrders''',                    'Generate on demand orders',                      '~IsReplenished~ = ''N''',
                                                                                                                                       'A',    20,      null,             @vRuleSetName
/*----------*/
union select 'select ''AllocateInv_UnitsFromReserve''',              'Allocate units from Reserve Locations',          null,           'I',    30,      null,             @vRuleSetName
/*----------*/
union select 'select ''ProcessTaskDetails_PreCubing''',              'Categorize created Task Details and update PG',  null,           'NA',   39,      null,             @vRuleSetName
union select 'select ''Cubing''',                                    'Cube Task details',                              null,           'I',    40,      'procedure',      @vRuleSetName
union select 'select ''ProcessTaskDetails_PostCubing''',             'Categorize created Task Details',                null,           'A',    41,      null,             @vRuleSetName
union select 'select ''CreatePickTasks''',                           'Generate Pick Tasks',                            null,           'A',    42,      null,             @vRuleSetName
/*----------*/
union select 'select ''UnWaveDisqualifiedOrders''',                  'Un-Wave Disqualified Orders',                    null,           'A',    80,      null,             @vRuleSetName
union select 'select ''InsertShipLabels''',                          'Insert cartons into ShipLabels table',           null,           'I',    81,      null,             @vRuleSetName
union select 'select ''UpdateWaveDependencies''',                    'Update Wave dependencies',                       null,           'A',    82,      null,             @vRuleSetName
/*----------*/
union select 'select ''UpdateWaveCounts''',                          'Update Wave counts',                             null,           'A',    99,      null,             @vRuleSetName

/******************************************************************************/
/* Rule Set - Replenish Dynamic PickLanes */
/******************************************************************************/
select @vRuleSetName        = 'AllocateWave_ReplenishDynamicPickLanes',
       @vRuleSetDescription = 'RUD: Allocate Wave steps for Replenishment of Dynamic picklanes',
       @vRuleSetFilter      = '~WaveType~ = ''RU'' and ~WaveCategory1~ = ''DynamicReplenishments''',
       @vSortSeq            = 100,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules for Replenish Units Wave */
insert into @Rules
            (RuleQuery,                              RuleDescription,                   RuleCondition,  Status, SortSeq, TransactionScope, RuleSetName)
      select 'select ''AllocateCasesForDynamicReplenishments''',
                                                     'Allocate cases for Dynamic Repl', null,           'A',     1,      null,             @vRuleSetName
union select 'select ''AllocateUnitsForDynamicReplenishments''',
                                                     'Allocate units for Dynamic Repl', null,           'A',     2,      null,             @vRuleSetName
/*----------*/
union select 'select ''ProcessTaskDetails''',        'Categorize created Task Details', null,           'A',    31,      null,             @vRuleSetName
union select 'select ''CreatePickTasks''',           'Generate pick tasks',             null,           'A',    32,      null,             @vRuleSetName
/*----------*/
union select 'select ''UpdateWaveDependencies''',    'Update Wave dependencies',        null,           'A',    41,      null,             @vRuleSetName
/*----------*/
union select 'select ''UpdateWaveCounts''',          'Update Wave counts',              null,           'A',    90,      null,             @vRuleSetName


/******************************************************************************/
/* Rule Set - Replenish Case PickLanes */
/******************************************************************************/
select @vRuleSetName        = 'AllocateWave_ReplenishCasePickLanes',
       @vRuleSetDescription = 'RP: Allocate Wave steps for Replenishiment of Case pickLanes',
       @vRuleSetFilter      = '~WaveType~ = ''RP''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules for Replenish Cases Wave */
insert into @Rules
            (RuleQuery,                              RuleDescription,                   RuleCondition,  Status, SortSeq, TransactionScope, RuleSetName)
      select 'select ''AllocateInv_AvailableQty''',  'Allocate available units',        null,           'A',     1,      null,             @vRuleSetName
/*----------*/
union select 'select ''ProcessTaskDetails''',        'Categorize created Task Details', null,           'A',    31,      null,             @vRuleSetName
union select 'select ''CreatePickTasks''',           'Generate pick tasks',             null,           'A',    32,      null,             @vRuleSetName
/*----------*/
union select 'select ''UpdateWaveDependencies''',    'Update Wave dependencies',        null,           'A',    41,      null,             @vRuleSetName
/*----------*/
union select 'select ''UpdateWaveCounts''',          'Update Wave counts',              null,           'A',    90,      null,             @vRuleSetName


/******************************************************************************/
/* Rule Set - Replenish Unit PickLanes */
/******************************************************************************/
select @vRuleSetName        = 'AllocateWave_ReplenishUnitPickLanes',
       @vRuleSetDescription = 'RU: Allocate Wave steps Replenishment of Unit picklanes',
       @vRuleSetFilter      = '~WaveType~ = ''RU''',
       @vSortSeq            = null,
       @vStatus             = 'A' /* Active */;

insert into @RuleSets (RuleSetName, RuleSetDescription, RuleSetType, RuleSetFilter, SortSeq, Status, BusinessUnit)
  select @vRuleSetName, @vRuleSetDescription, @vRuleSetType, @vRuleSetFilter, coalesce(@vSortSeq, 0), @vStatus, @vBusinessUnit;

/*----------------------------------------------------------------------------*/
/* Rules for Replenish Units Wave */
insert into @Rules
            (RuleQuery,                              RuleDescription,                   RuleCondition,  Status, SortSeq, TransactionScope, RuleSetName)
      select 'select ''AllocateInv_FromReserve''',   'Allocate available units',        null,           'A',     1,      null,             @vRuleSetName
/*----------*/
union select 'select ''ProcessTaskDetails''',        'Categorize created Task Details', null,           'A',    31,      null,             @vRuleSetName
union select 'select ''CreatePickTasks''',           'Generate pick tasks',             null,           'A',    32,      null,             @vRuleSetName
/*----------*/
union select 'select ''UpdateWaveDependencies''',    'Update Wave dependencies',        null,           'A',    41,      null,             @vRuleSetName
/*----------*/
union select 'select ''UpdateWaveCounts''',          'Update Wave counts',              null,           'A',    90,      null,             @vRuleSetName

/******************************************************************************/
exec pr_Rules_Setup @RuleSets, @Rules, 'R'/* Replace */;

Go
