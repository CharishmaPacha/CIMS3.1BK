/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/03/15  ??      pr_LPNs_RecalculateWeight: Initial revision (HPI-Golive)
              VM      Added pr_LPNs_RecalculateWeightVolume (HPI-993)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_RecalculateWeight') is not null
  drop Procedure pr_LPNs_RecalculateWeight;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_RecalculateWeight: Recalculates the weight of the LPN based upon
   the weight of the product in it + the weight of the empty carton.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_RecalculateWeight
  (@LPNId     TRecordId,
   @UserId    TUserId = null)
as
  declare @vLPNCartonType     TCartonType,
          @vLPNType           TTypeCode,
          @vLPNWeight         TWeight,
          @vEmptyCartonWeight TWeight;
begin
  /* Get the carton type of the LPN */
  select @vLPNCartonType = CartonType,
         @vLPNType       = LPNType
  from LPNs
  where (LPNId = @LPNId);

  if (coalesce(@vLPNCartonType, '') <> '')
    select @vEmptyCartonWeight = EmptyWeight
    from CartonTypes
    where (CartonType = @vLPNCartonType);

  select @vLPNWeight = sum(UnitWeight * Quantity)
  from vwLPNDetails
  where LPNId = @LPNId

  /* Update the estimated weight on the LPN */
  update LPNs
  set EstimatedWeight = @vLPNWeight + coalesce(@vEmptyCartonWeight, 0)
  where (LPNId = @LPNId);
end /* pr_LPNs_RecalculateWeight */

Go
