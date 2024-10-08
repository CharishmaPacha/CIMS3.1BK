/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/05  SAK     pr_Entities_GetSummaryInfo added EntityType RH (HA-2723)
  2020/06/30  NB      pr_Entities_GetSummaryInfo: changes for Shipping Docs Entity Info(CIMSV3-963)
  2020/06/08  RT      pr_Entities_GetSummaryInfo: Included Load as EntityType (HA-824)
  2020/05/21  MS      pr_Entities_GetSummaryInfo: Added procedure to return EntityInfo Summary (HA-568)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Entities_GetSummaryInfo') is not null
  drop Procedure pr_Entities_GetSummaryInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Entities_GetSummaryInfo:
   This procedure will return the dataset of entity which will be used in Summary
   of EntityInfo
  InputXml:
   '<Root>
      <EntityType>OH_EntityInfo</EntityType>
      <SelectionFilters>
       <Filter>
        <FieldName>OrderId</FieldName>
        <FilterOperation>Equals</FilterOperation>
        <FilterValue>1875</FilterValue>
        <FilterType>L</FilterType>
        <Visible>N</Visible>
       </Filter>
      </SelectionFilters>
    </Root>'
------------------------------------------------------------------------------*/
Create Procedure pr_Entities_GetSummaryInfo
  (@InputXml      TXML,
   @UserId        TUserId,
   @BusinessUnit  TBusinessUnit)
as
  declare @vInputXml        xml,
          @vSQL             TSQL,
          @vFieldName       TName,
          @vFilterOperation TName,
          @vFilterValue     TName,

          @vDatasetName     TName,
          @vEntity          TName,
          @vEntityType      TName;

begin
  select @vInputXml = cast(@InputXml as xml);

  /* Get the filter values */
  select @vFieldName       = Record.Col.value('FieldName[1]',       'TName'),
         @vFilterOperation = Record.Col.value('FilterOperation[1]', 'TName'),
         @vFilterValue     = Record.Col.value('FilterValue[1]',     'TName')
  from @vInputXml.nodes('Root/SelectionFilters/Filter') as Record(Col);

  /* Get the EntityType */
  select @vEntityType = Record.Col.value('EntityType[1]', 'TName')
  from @vInputXml.nodes('Root') as Record(Col);

  /* Setup DatasetName */
  set @vDatasetName = case when (@vEntityType like 'RCV_%'   )  then 'vwReceivers'
                           when (@vEntityType like 'RH_%'    )  then 'vwReceiptHeaders'
                           when (@vEntityType like 'OH_%'    ) or (@vEntityType = 'ShippingDocs_EntityInfo_Order' ) then 'vwPackingListHeaders'
                           when (@vEntityType like 'Wave_%'  ) or (@vEntityType = 'ShippingDocs_EntityInfo_Wave'  ) then 'vwWaves'
                           when (@vEntityType like 'Load_%'  ) or (@vEntityType = 'ShippingDocs_EntityInfo_Load'  ) then 'vwLoads'
                           when (@vEntityType = 'ShippingDocs_EntityInfo_LPN'   )                                   then 'vwLPNPackingListHeaders'
                           when (@vEntityType like 'LPN_%'   )                                                      then 'vwLPNs'
                           when (@vEntityType like 'Pallet_%') or (@vEntityType = 'ShippingDocs_EntityInfo_Pallet') then 'vwPallets'
                           when (@vEntityType like 'Task_%')   then 'vwUIPickTasks'
                           else null
                      end;

  /* Build SQL Query */
  select @vSQL = 'select * from ' + @vDatasetName +
                 ' where ' + @vFieldName + ' = ' + @vFilterValue + ';'

  /* Execute SQL Statements */
  exec (@vSQL);

end /* pr_Entities_GetSummaryInfo */

Go
