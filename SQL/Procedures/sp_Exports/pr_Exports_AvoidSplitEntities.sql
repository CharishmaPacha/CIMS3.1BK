/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/12/11  AY      pr_Exports_AvoidSplitEntities: For an Order which is not on Load, need to send LPN/LPND and SHIPOH/OD should be in one batch (FB-1058)
  2017/09/19  RV      pr_Exports_AvoidSplitEntities: Exclude orders when export batches , if OH and OD exists outside of the batch (FB-1017)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_AvoidSplitEntities') is not null
  drop Procedure pr_Exports_AvoidSplitEntities;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_AvoidSplitEntities:
    The intention of this procedure is to make sure all orders ship records, which exists in the time of processing
    are not split into multiple batches.

    This procedure is to pick the orders in the given batch and
    identify if they have any other unprocessed ship records other than batch.
    If so, exclude them from the given batch.

    There may be possibility, where some ShipLPN, ShipLPND records are generated first but
    ShipOH, ShipOD are not generated yet. Then, ShipLPN & ShipLPND records are generated in one batch
    and ShipOH & ShipOD records are generated in another batch.
    !!! As above point states, we cannot assure system stop orders not being split into multiple batches, always.
        If any client reports as their orders are split, it could be because of above point and
        hence, we need to verify the records generated timestamp and exports job interval and report.

    Splitting "Ship" LPNs: In no event do we want to split Ship LPN and LPND records into two batches. We
    have therefore enhanced to recognize this and remove the details of the last LPN which may have header
    not included in the current batch.
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_AvoidSplitEntities
  (@BatchNo         TBatch,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @ReturnCode       TInteger,
          @MessageName      TMessageName,
          @vShipDetailLPNId TRecordId,

          @ttOrdersExistsOutsideBatch TEntityKeysTable;
begin
  select @ReturnCode       = 0,
         @MessageName      = null,
         @vShipDetailLPNId = 0;

  /*****************************************************/
  /* Avoid splitting of Orders across multiple batches */

  /* Identify the orders which exist in the given batch that have unprocessed records outside of batch */
  insert into @ttOrdersExistsOutsideBatch(EntityId)
    select distinct OrderId
    from Exports
    where (OrderId in (select distinct OrderId from Exports where ExportBatch = @BatchNo)) and
          (ExportBatch  = 0     ) and (Status = 'N' /* No */) and
          (TransType    = 'Ship') and -- (TransEntity in ('OH' /* Order Headers */, 'OD' /* Order Details */)) and
          (BusinessUnit = @BusinessUnit);

  /* Remove all identified orders from the given batch */
  update E
  set E.ExportBatch = 0
  from Exports E
    join @ttOrdersExistsOutsideBatch OE on (OE.EntityId = E.OrderId)
  where (E.ExportBatch = @BatchNo) and (E.TransType = 'Ship');

  /********************************************************/
  /* Avoid splitting of Ship LPNs across multiple batches */

  /* Get the last LPN of the TransEntity as LPN or LPND and TransType ship to find the order,
     which exist in the given batch that have unprocessed records outside of batch */
  select top 1 @vShipDetailLPNId = LPNId
  from Exports
  where (ExportBatch  = @BatchNo) and (TransType = 'Ship') and
        (TransEntity  = 'LPND' /* LPN Details */) and
        (BusinessUnit = @BusinessUnit)
  order by RecordId desc

  /* Check if LPN header is not included within the existing batch, if not then
     remove all corresponding LPN details from the batch */
  if ((coalesce(@vShipDetailLPNId, 0) != 0) and
      (not exists(select *
                  from Exports
                  where (ExportBatch = @BatchNo) and (TransType    = 'Ship') and
                        (TransEntity = 'LPN'   ) and (LPNId = @vShipDetailLPNId))))
    update Exports
    set ExportBatch = 0
    where (ExportBatch = @BatchNo) and (LPNId         = @vShipDetailLPNId) and
          (TransType   = 'Ship'  ) and (TransEntity   = 'LPND' /* LPN Details */);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Exports_AvoidSplitEntities */

Go
