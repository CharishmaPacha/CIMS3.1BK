/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2016/11/09  VM      pr_LPNDetails_Unallocate: Bug-fix: Merge the DR line quantity to its replenish order D line (HPI-1016)
              VM      Added pr_LPNs_RecalculateWeightVolume (HPI-993)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_RecalculateWeightVolume') is not null
  drop Procedure pr_LPNs_RecalculateWeightVolume;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_RecalculateWeightVolume: Updates the LPNDetails weight and volume.
   LPNs_Recount already takes care of considering the carton type etc. and adding
   those details.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_RecalculateWeightVolume
  (@LPNId  TRecordId,
   @UserId TUserId = null)
as
begin
  /* Calculate the product weight & volume */
  update LD
  set LD.Weight = coalesce(S.UnitWeight * LD.Quantity, 0),
      LD.Volume = coalesce(S.UnitVolume * LD.Quantity, 0)
  from LPNDetails LD join SKUs S on LD.SKUId = S.SKUId
  where (LD.LPNId = @LPNId);

  /* Update the estimated weight/volume considering the carton type etc. */
  exec pr_LPNs_Recount @LPNId;
end /* pr_LPNs_RecalculateWeightVolume */

Go
