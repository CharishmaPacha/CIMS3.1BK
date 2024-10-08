/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/12/11  AY      pr_SKUs_PreProcess: Allow to send SKUs to preprocess using hash table (CIMSV3-1717)
                      pr_SKUs_PreProcess: Clean up and move code to Rules
  2019/02/06  RIA     pr_SKUs_PreProcess: Update SKUSortOrder on the SKUs (CID-51)
  2019/01/31  AY      pr_SKUs_PreProcess: Changes to update fields on SKUs based on the rules (CID-51)
  2019/01/29  TK      pr_SKUs_PreProcess: Default InventoryUoM to Eaches (S2GMI-83)
  2018/03/14  TK      pr_SKUs_PreProcess: Changes not to override Nesting Factor to '0'
  2018/01/22  OK      pr_SKUs_PreProcess: Set InnerPacksPerLPN value to zero if it is null or empty passed (S2G-141)
  2017/08/24  TK      pr_SKUs_PreProcess: Changes to update ReplenishClass (HPI-1626)
  2015/10/19  TD      pr_SKUs_PreProcess: Updating Ownership
  2015/06/06  AY      pr_SKUs_PreProcess: Calculate UnitsPerLPN
  2015/02/19  SV      pr_SKUs_PreProcess: Resolved the issue of Modifying PA Class of SKU to 01 for any PA Class
  2015/02/10  AK      pr_SKUs_PreProcess: Modified to update InnerpacksPerLPN.
  2014/12/08  TK      pr_SKUs_PreProcess: Modified to update PutawayClass and UoM.
  2014/02/25  PK      pr_SKUs_PreProcess: Inserting SKU attributes for the SKU.
  2103/10/10  TD      Added pr_SKUs_PreProcess.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SKUs_PreProcess') is not null
  drop Procedure pr_SKUs_PreProcess;
Go
/*------------------------------------------------------------------------------
  Proc pr_SKUs_PreProcess: When new SKUs are imported, we have to process the
    SKUs to establish some default and/or setup fields like SKUPAClass, SKUSortOrder
    that may not be given by the Host.
------------------------------------------------------------------------------*/
Create Procedure pr_SKUs_PreProcess
  (@SKUs          TEntityKeysTable readonly,
   @SKUId         TRecordId,
   @Businessunit  TBusinessUnit)
As
  declare @ReturnCode         TInteger,
          @MessageName        TMessageName,
          @ttSKUs             TEntityKeysTable,

          @vOperation         TOperation,
          @vEntityId          TRecordId,
          @vRecordId          TRecordId,
          @vSKUId             TRecordId,
          @vSKU               TSKU,
          @vUPC               TUPC,
          @vSetupDefaultUPCs  TFlags = 'N',
          @vOwnership         TOwnership,
          @xmlRulesData       TXML;
begin
  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* Create hash table to be used in the rules */
  select * into #SKUsToProcess from @ttSKUs;

  /* Assumption: If SKUId is not null then user sends single SKU only */
  if (coalesce(@SKUId, 0) <> 0)
    insert into #SKUsToProcess (EntityId) select @SKUId;
  else
    insert into #SKUsToProcess (EntityId, EntityKey) select EntityId, EntityKey from @SKUs;

  /* If there are no SKUs to process, exit */
  if (@@rowcount = 0) return;

  /* Get top 1 owner from LookUps */
  select top 1 @vOwnership = LookUpCode
  from vwLookUps
  where (LookUpCategory = 'Owner') and
        (BusinessUnit   = @Businessunit);

  /* Prepare XML for rules */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                           dbo.fn_XMLNode('Ownership',            @vOwnership) +
                           dbo.fn_XMLNode('Operation',            'UpdatePAClass'));

  /* Check if there are any updates to be done in preprocess for PA Class */
  exec pr_RuleSets_ExecuteRules 'SKU_PreprocessUpdates', @xmlRulesData;

  /* Initialize fields with defaults */
  select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'Operation', 'UpdateDefaults');
  exec pr_RuleSets_ExecuteRules 'SKU_PreprocessUpdates', @xmlRulesData;

end /* pr_SKUs_PreProcess */

Go
