/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/04  VS      pr_Exports_GenerateBatches, pr_Exports_GetNextBatchCriteria: Generate the Export Batches in the Loop (CIMSV3-1471)
  2020/11/21  VS      pr_Exports_GetData, pr_Exports_GetNextBatchCriteria: Made changes to export the Batch to host after Batch creation only (FB-2194)
  2018/03/13  DK      pr_Exports_CaptureData, pr_Exports_GetNextBatchCriteria, pr_Exports_GetData, pr_Exports_GenerateBatches, pr_Exports_CreateBatchesForOrders
  2017/12/27  DK      pr_Exports_GetNextBatchCriteria: Bug fix to handle in case Ownership is null in exports (FB-1068)
  2017/11/12  DK      pr_Exports_GenerateBatches, pr_Exports_GetNextBatchCriteria: Enhanced to create batches for available records in exports in every instance of sql job run (FB-1057)
  2016/09/04  VM      pr_Exports_GetNextBatchCriteria: Bug-fix - Exclude using substring when no pair found in Target value (CIMS-1079)
  2016/02/16  NB      pr_Exports_GetNextBatchCriteria: Added code to default input params to null when blanks values are passed in
  2016/02/11  NB/AY   pr_Exports_GetNextBatchCriteria: changes to consider integration type mapping set in returning output values(NBD-108)
  2016/02/10  NB      pr_Exports_GetNextBatchCriteria: changes to properly return output values(NBD-108)
  2016/01/27  TK      pr_Exports_GetNextBatchCriteria: Changes made to return TransType and Entity based upon Integration Type (NBD-108)
                      pr_Exports_GetNextBatchCriteria: Initial Revision (NBD-105)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_GetNextBatchCriteria') is not null
  drop Procedure pr_Exports_GetNextBatchCriteria;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_GetNextBatchCriteria: This procedure will return TransType,
    Ownership & ExportBatchNo of first record which is not yet processed.
    If IntegrationType is given, then it will limit the records to the Owner and
    TransType for it. So, for example if IntegrationType = 'ExportTrans_EDI' then
    it will look up the mapping to see which Owners and transactions require EDI
    export of transactions and return the first one of those to create a batch later.

    If Ownership is passed in, then the results are restricted to the specific owner only
    If the passed in IntegrationType is defined in the Mapping, then TransType is ignored
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_GetNextBatchCriteria
  (@IntegrationType TAction    = null output,
   @TransType       TTypeCode  = null output,
   @Ownership       TOwnership = null output,
   @SourceSystem    TName      = null output,
   @BatchNo         TBatch     = null output,
   @BusinessUnit    TBusinessUnit)
as
  /* Local variables for output params */
  declare @vTransType    TTypeCode,
          @vOwnership    TOwnership,
          @vSourceSystem TName,
          @vBatchNo      TBatch;

  declare @ttMappingSet table (SourceValue   TDescription,
                               TargetValue   TDescription);

  declare @ttTransEntities table (IntegrationType  TDescription,
                                  Ownership        TOwnership,
                                  TransType        TTypeCode,
                                  RecordId         TInteger identity(1,1));
begin
  /* DataExchange is passing in empty strings when any of these inputs are undefined in the config */
  select @IntegrationType = nullif(@IntegrationType, ''),
         @TransType       = nullif(@TransType,       ''),
         @Ownership       = nullif(@Ownership,       ''),
         @SourceSystem    = nullif(@SourceSystem,    '');

  /* Get the mapped set of values */
  insert into @ttMappingSet(SourceValue, TargetValue)
    select SourceValue, TargetValue
    from dbo.fn_GetMappedSet('CIMS', 'HOST', 'Ownership', 'Integration' /* Operation */,  @BusinessUnit)

  /* extract Ownership & TransType from mapped values */
  insert into @ttTransEntities
    select SourceValue,
           substring(TargetValue, 1, charindex(',', TargetValue) - 1),
           substring(TargetValue, charindex(',', TargetValue) + 1, len(TargetValue))
    from @ttMappingSet
    where charindex(',', TargetValue) > 0;

  /* If integrationType is given and there is mapping setup for it, then get only
     the matching records */
  if (exists (select * from @ttMappingSet where SourceValue = @IntegrationType))
    begin
      /* get the details of first record which is not yet processed */
      select top 1 @vTransType = E.TransType,
                   @vOwnership = E.Ownership,
                   @vBatchNo   = E.ExportBatch
      from Exports E
        inner join @ttTransEntities TE on (E.Ownership = TE.Ownership) and
                                          (E.TransType = TE.TransType) and
                                          (TE.IntegrationType = @IntegrationType)
      where (E.Ownership    = coalesce(@Ownership, E.Ownership)) and
            (E.ExportBatch  = coalesce(@BatchNo,   E.Exportbatch)) and
            (E.Status       = 'N' /* Not Yet Processed */) and
            (E.BusinessUnit = @BusinessUnit) and
            (E.SourceSystem = @SourceSystem) and
            (datediff(second, E.CreatedDate, getdate()) > 60)
      order by E.RecordId;
    end
  else
    /* There is no integration type or there are no mappings for the given integration type,
       then get records which do not have any mapping defined */
    begin
      /* get the details of first record which is not yet processed */
      select top 1 @vTransType    = E.TransType,
                   @vOwnership    = E.Ownership,
                   @vSourceSystem = E.SourceSystem,
                   @vBatchNo      = E.ExportBatch
      from Exports E left outer join @ttTransEntities TE on  (E.Ownership = TE.Ownership) and
                                                             (E.TransType = TE.TransType)
      where (E.TransType               = coalesce(@TransType, E.TransType)) and
            (coalesce(E.Ownership, '') = coalesce(@Ownership, E.Ownership, '')) and
            (E.SourceSystem            = coalesce(@SourceSystem, E.SourceSystem, '')) and
            (E.ExportBatch             = coalesce(@BatchNo,   E.Exportbatch)) and
            (E.Status                  = 'N' /* Not Yet Processed */) and
            (E.BusinessUnit            = @BusinessUnit) and
            (datediff(second, E.CreatedDate, getdate()) > 60) and
            (TE.RecordId is null /* There is no mapping for this Ownership-TransType */)
      order by E.RecordId;
    end

  /* Pass back the identified values to the output parameters */
  select @TransType    = @vTransType,
         @Ownership    = @vOwnership,
         @SourceSystem = @vSourceSystem,
         @BatchNo      = @vBatchNo;
end /* pr_Exports_GetNextBatchCriteria */

Go
