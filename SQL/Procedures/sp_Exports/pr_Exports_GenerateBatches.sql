/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/04  VS      pr_Exports_GenerateBatches, pr_Exports_GetNextBatchCriteria: Generate the Export Batches in the Loop (CIMSV3-1471)
  2021/04/08  VS      pr_Exports_GenerateBatches: Generate the Batches for New Status only (CID-1780)
  2020/04/22  MS      pr_Exports_GenerateBatches: Caller signature correction (HA-266)
  2018/03/13  DK      pr_Exports_CaptureData, pr_Exports_GetNextBatchCriteria, pr_Exports_GetData, pr_Exports_GenerateBatches, pr_Exports_CreateBatchesForOrders
  2017/11/12  DK      pr_Exports_GenerateBatches, pr_Exports_GetNextBatchCriteria: Enhanced to create batches for available records in exports in every instance of sql job run (FB-1057)
  2017/11/22  DK      pr_Exports_GenerateBatches: New job procedure to just generate export batches.(FB-1048)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_GenerateBatches') is not null
  drop Procedure pr_Exports_GenerateBatches;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_GenerateBatches:
    This JOB procedure is introduced to just generate export batches based on the params passed and rules set.

    It also reduce the load/burden on DE job in creating the batches and
    allow it just to pick the next batch which is ready to export to host.

    Result:
      This JOB: Continuously runs and generates batches based on params and rules.
      DE   JOB: Continuously pickup the created batches and generate files.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_GenerateBatches
  (@IntegrationType TAction       = null,
   @TransType       TTypeCode     = null,
   @Ownership       TOwnership    = null,
   @SourceSystem    TName         = null,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vBatchNo TBatch;
begin
  /* Process until all the available records in exports are processed */
  while (exists(select * from Exports where ExportBatch = 0 and Status = 'N'))
    begin
      /* Get the criteria to process. As the purpose of this procedure is generating batches, ignore getting BatchNo */
      exec pr_Exports_GetNextBatchCriteria   @IntegrationType output,
                                             @TransType       output,
                                             @Ownership       output,
                                             @SourceSystem    output,
                                             @BatchNo      =  0,
                                             @BusinessUnit =  @BusinessUnit;

      /* Create batch(es) based on criteria returned from rules */
      exec pr_Exports_CreateBatch @TransType, @Ownership, @SourceSystem, @BusinessUnit, @UserId,
                                  @vBatchNo output;

      /* Clear the values for next Transaction Type */
      select @IntegrationType = null,
             @TransType       = null,
             @Ownership       = null,
             @SourceSystem    = null;

      /* If there was no batch generated, then stop trying to generate batches */
      if (@vBatchNo is null)
        break;
    end
end /* pr_Exports_GenerateBatches */

Go
