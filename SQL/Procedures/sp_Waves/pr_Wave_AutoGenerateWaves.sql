/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/03  TD      pr_Wave_AutoGenerateWaves:Changes to add single-line orders to prior wave (OB2-789)
  2018/11/22  AY      pr_Wave_AutoGenerateWaves: New procedure to selectively autowave orders determined by rules (OB2-745)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Wave_AutoGenerateWaves') is not null
  drop Procedure pr_Wave_AutoGenerateWaves;
Go
/*------------------------------------------------------------------------------
  Proc pr_Wave_AutoGenerateWaves: This is the procedure that would be invoked
    from a job to automatically generate waves as per the rules set up. The
    rules would define which orders to process and it would apply the
    systems rules against those orders and generate the appropriate waves.

  The design is that the for each group of orders to process, we would have a
  rule defined with a DataSet that will return all the Orders to be waved. There
  could possible be multiple datasets to process and each would be defined as a
  RuleSet. For example, we may define one RuleSet for Single Line Orders, another
  for Pick To Batch Orders and yet another for Pick To Ship Orders.
------------------------------------------------------------------------------*/
Create Procedure pr_Wave_AutoGenerateWaves
  (@RuleSetType   TName   = 'Wave_AutoGeneration',
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId = null)
as
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TDescription,
          @vRecordId                TRecordId,
          @vRuleSetName             TName,
          @vRules                   TXML,
          @vOrders                  TXML,
          @vAddOrdersToPriorBatches TFlag,
          @vBatchingLevel           TDescription,
          @vxmlEntities             TXML,
          @xmlRulesData             TXML;

  declare @ttAutoGenerateRuleSets   TRuleSetsTable;
  declare @ttEntityKeys             TRecountKeysTable;
begin
  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* Build the rules data */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('BusinessUnit',  @BusinessUnit) +
                           dbo.fn_XMLNode('UserId',        @UserId));

  /* Get all the RuleSets that are applicable to process */
  insert into @ttAutoGenerateRuleSets (RuleSetId, RuleSetType, RuleSetName, SortSeq)
    exec pr_RuleSets_GetRuleSets @RuleSetType, @xmlRulesData, @BusinessUnit;

  while (exists(select * from @ttAutoGenerateRuleSets where RecordId > @vRecordId))
    begin
      select top 1
             @vRecordId    = RecordId,
             @vRuleSetName = RuleSetName,
             @vxmlEntities = null,
             @vOrders      = null
      from @ttAutoGenerateRuleSets
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Get the Orders or OrderDetails that are applicable to this RuleSet */
      insert into @ttEntityKeys (EntityId, EntityKey, EntityType, SortOrder, UDF1, UDF2, UDF3, UDF4, UDF5)
        exec pr_RuleSets_GetDataSet @RuleSetType, @xmlRulesData, @vRuleSetName, @BusinessUnit;

      /* If there are no applicable orders, then process next RuleSet */
      if (not exists(select * from @ttEntityKeys)) continue;

      /* Determine Batching level based upon the EntityType */
      select top 1 @vBatchingLevel           = EntityType,
                   @vAddOrdersToPriorBatches = UDF1   /* UDF1 is used in this case to return additional info from rules */
      from @ttEntityKeys;

      /* select orders to be batched - the vwOrdersToBatch already has criteria
         setup and hence BusinessUnit is sufficient */
      if (@vBatchingLevel = 'OH')
        select @vxmlEntities = (select EntityId OrderId
                                from @ttEntityKeys
                                for xml raw('OrderHeader'), elements);
      else
        select @vxmlEntities = (select EntityId OrderDetailId
                                from @ttEntityKeys
                                for xml raw('OrderDetails'), elements);

      select @vOrders = dbo.fn_XMLNode('Orders', @vxmlEntities);

      /* Generate the Waves */
      exec pr_PickBatch_GenerateBatches @BusinessUnit, @UserId, @vRules, @vOrders, @vAddOrdersToPriorBatches;
    end /* while.. process next auto generate rule */

end /* pr_Wave_AutoGenerateWaves */

Go
