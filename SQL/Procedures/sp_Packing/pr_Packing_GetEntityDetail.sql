/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/11/11  RV      pr_Packing_GetBulkDetailsToPack: Initial version
                      pr_Packing_GetEntityDetail: Made changes to send entity details for bulk order packing (FBV3-421)
                      pr_Packing_GetEntityDetail chages to address EntityType change(CIMSV3-156)
  2021/05/03  NB      Added pr_Packing_GetDetails_V3, pr_Packing_GetEntityDetail(CIMSV3-156)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Packing_GetEntityDetail') is not null
  drop Procedure pr_Packing_GetEntityDetail;
Go
/*------------------------------------------------------------------------------
  Proc pr_Packing_GetEntityDetail:
   This procedure will return the dataset of entity which will be used in Packing Entity Info
  InputXml:
   '<Root>
      <EntityType>Packing_EntityInfo_Order</EntityType>
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
Create Procedure pr_Packing_GetEntityDetail
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
  set @vDatasetName = case when (@vEntityType = 'Packing_EntityInfo_StandardOrderPacking' ) then 'vwOrderHeaders'
                           when (@vEntityType = 'Packing_EntityInfo_BulkOrderPacking')      then 'vwOrderHeaders'
                           when (@vEntityType = 'Packing_EntityInfo_SLBOrderPacking')       then 'vwWaves'
                           when (@vEntityType = 'Packing_EntityInfo_Wave'  )                then 'vwWaves'
                           when (@vEntityType = 'Packing_EntityInfo_Pallet')                then 'vwPallets'
                           else null
                      end;

  /* Build SQL Query */
  select @vSQL = 'select * from ' + @vDatasetName +
                 ' where ' + @vFieldName + ' = ' + @vFilterValue + ';'

  /* Execute SQL Statements */
  exec (@vSQL);

end /* pr_Packing_GetEntityDetail */

Go
