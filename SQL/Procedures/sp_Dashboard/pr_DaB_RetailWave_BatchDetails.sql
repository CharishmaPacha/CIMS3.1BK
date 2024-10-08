/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_RetailWave_BatchDetails') is not null
  drop Procedure pr_DaB_RetailWave_BatchDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_RetailWave_BatchDetails: Used to show the summary of Orders, Lines,
    SKUs and Units on the Batch
------------------------------------------------------------------------------*/
Create Procedure pr_DaB_RetailWave_BatchDetails
  (@PickBatchNo      TPickBatchNo)
as
begin
  SET NOCOUNT ON;

  select *
  from vwPickBatches
  where (BatchNo = @PickBatchNo);
end /* pr_DaB_RetailWave_BatchDetails */

Go
