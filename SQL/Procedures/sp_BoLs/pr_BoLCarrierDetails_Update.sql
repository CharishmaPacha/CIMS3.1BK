/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/18  OK      pr_BoLCarrierDetails_Update: Changes to return success message to caller (HA-1005)
  2016/06/16  KL      pr_BoLOrderDetails_Update / pr_BoLCarrierDetails_Update: Update weight on Loads when manually edit weight on BoL details (FB-708)
  2013/04/05  PKS     pr_BoLOrderDetails_Update / pr_BoLCarrierDetails_Update: Weight of BolOrderDetails are updated then same was updated
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoLCarrierDetails_Update') is not null
  drop Procedure pr_BoLCarrierDetails_Update;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoLCarrierDetails_Update:
    This Procedure will update the BoL Carrier Details
------------------------------------------------------------------------------*/
Create Procedure pr_BoLCarrierDetails_Update
  (@BoLCarrierDetailId  TRecordId,
   @BoLNumber           TBoLNumber,
   @HandlingUnitQty     TQuantity,
   @HandlingUnitType    TTypeCode,
   @PackageQty          TQuantity,
   @PackageType         TTypeCode,
   @Volume              TVolume,
   @Weight              TWeight,
   @Hazardous           TFlag,
   @NMFCDescription     TDescription,
   @NMFCCode            TLookUpCode,
   @NMFCClass           TCategory,
   @Message             TDescription output)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @vBoLId      TBoLId,
          @LoadId      TLoadId,
          @MasterBoL     TBoLNumber,
          @vBoLOrderDetailCount  TCount;
begin  /* pr_BoLCarrierDetails_Update */

  select @ReturnCode  = 0,
         @Message     = null,
         @MessageName = null;

  if (@BoLCarrierDetailId is null)
    set @MessageName = 'BoLCarrierDetailIdIsRequired';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Update BoL Carrier Details for that BoL NUmber */
  update BoLCarrierDetails
  set @vBoLId          = BoLId,
      HandlingUnitQty  = @HandlingUnitQty,
      HandlingUnitType = @HandlingUnitType,
      PackageQty       = @PackageQty,
      PackageType      = @PackageType,
      Volume           = @Volume,
      Weight           = @Weight,
      Hazardous        = @Hazardous,
      CommDescription  = @NMFCDescription,
      NMFCCode         = @NMFCCode,
      CommClass        = @NMFCClass
  where (BoLCarrierDetailId = @BoLCarrierDetailId);

  /* Check how many BoLOrderDetails exist */
  select @vBoLOrderDetailCount = count(*)
  from BolOrderDetails
  where (BolId = @vBoLId);

  /* If there is only one OrderDetailRecord, then update it */
  if (@vBoLOrderDetailCount = 1)
    begin
      With BoLWeight(BoLId, Weight) As
      (
        /* Will get the total weight for the BoL */
        select @vBoLId, sum(Weight)
        from BoLCarrierDetails
        where (BoLId = @vBoLId)
      )
      update BOD
      set BOD.Weight = BW.Weight
      from BoLOrderDetails BOD
        join BoLWeight BW on (BW.BoLId = BOD.BoLId)
      where BOD.BoLId = @vBoLId;
    end

  /* To update weight on loads when manually edit weight on BoL Details */
  select @LoadId = LoadId
  from vwBoLCarrierDetails
  where (@BoLCarrierDetailId = BoLCarrierDetailId);

  /* Update weight on Load. BoLCarrierDetails weight is used as the Load.Weight when available */
  exec pr_Load_Recount @LoadId;

  /* Build the success message */
  set @Message = dbo.fn_Messages_GetDescription('BoL_CarrierDetailsModify_Successful');

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_BoLCarrierDetails_Update */

Go
