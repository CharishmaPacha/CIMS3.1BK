/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  Enhanced pr_PickBatch_GetInventorySummary to use TPickBatchSummary.
  2012/10/17  PKS     pr_PickBatch_GetBatchSummaryData renamed to pr_PickBatch_GetInventorySummary
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PickBatch_GetInventorySummary') is not null
  drop Procedure pr_PickBatch_GetInventorySummary;
Go
/*------------------------------------------------------------------------------
Proc pr_PickBatch_GetInventorySummary:
<BATCHPICKSUMMARIES>
  <BATCHPICKSUMMARY>
    <BatchHeader>
      <BatchNo>0829001</BatchNo>
      <Description>Sample Description</Description>
    </BatchHeader>
    <BatchDetails>
      <Line>3</Line>
      <CustSKU></CustSKU>
      <SKU1>MSFT000213</SKU1>
      <SKU2>2BU</SKU2>
      <SKU3>L</SKU3>
      <UnitsOrdered>1722</UnitsOrdered>
      <UnitsPercarton>0</UnitsPercarton>
      <UnitsAuthorizedToShip>1722</UnitsAuthorizedToShip>
      <LPNsToShip>0</LPNsToShip>
      <AvailLPNs>0</AvailLPNs>
      <LPNsShort>0</LPNsShort>
      <LPNsPicked>0</LPNsPicked>
      <LPNsLabeled>0</LPNsLabeled>
    </BatchDetails>
  </BATCHPICKSUMMARY>
 </BATCHPICKSUMMARIES>
------------------------------------------------------------------------------*/
Create Procedure pr_PickBatch_GetInventorySummary
  (@BatchNosXML    XML,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,

          @BatchPickSummaryXML TXML,
          @BatchHeaderXML      TXML,
          @BatchDetailsXML     TXML,
          @vBatchNo            TPickBatchNo;

  declare @ttEntities TEntityKeysTable,
          @ttPickBatchSummary
                      TPickBatchSummary;
begin
begin try
  SET NOCOUNT ON;
  select @ReturnCode  = 0,
         @MessageName = null;

  if (@BatchNosXML is not null)
    insert into @ttEntities (EntityKey)
    select Record.Col.value('.', 'varchar(max)')
    from @BatchNosXML.nodes('/BatchNos/BatchNo') as Record(Col);

  while (exists(select * from @ttEntities))
    begin
      select top 1  @vBatchNo = EntityKey
      from @ttEntities;

       set @BatchHeaderXML = (select top 1 PB.BatchNo, PB.Description
                              from  PickBatches PB
                              join @ttEntities TE on (TE.EntityKey = PB.BatchNo)
                              where (TE.EntityKey    = @vBatchNo) and
                                    (PB.BusinessUnit = @BusinessUnit)
                              for xml raw('BATCHHEADER'), elements);

      /* Fetch Batch Summary from procedure to temp table and build XML */
      insert into @ttPickBatchSummary
        exec pr_PickBatch_BatchSummary @vBatchNo;

      set @BatchDetailsXML = (select *
                              from  @ttPickBatchSummary
                              for xml raw('BATCHDETAILS'), elements);;

      set @BatchPickSummaryXML =  coalesce(@BatchPickSummaryXML,'') +
                                  '<BATCHPICKSUMMARY>'            +
                                  coalesce (@BatchHeaderXML, '')  +
                                  coalesce (@BatchDetailsXML, '') +
                                  '</BATCHPICKSUMMARY>';

      /* Clear batch summary temp table */
      delete from @ttPickBatchSummary;

      delete from @ttEntities
      where (EntityKey =  @vBatchNo);
    end

  select '<BATCHPICKSUMMARIES>'   +
         @BatchPickSummaryXML +
         '</BATCHPICKSUMMARIES>' as result;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;
end try
begin catch
  --rollback transaction

  exec @ReturnCode = pr_ReRaiseError;
end catch
ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_PickBatch_GetInventorySummary */

Go
