/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/07/10  NKL     pr_LPNs_CreateInvLPN, pr_LPNs_Recalculate, pr_LPNs_Recount: Changes to pr_LPNs_PreProcess signature (OBV3-1831)
                      pr_LPNs_Recalculate: Changes migrated from FB (CIMSV3-1155)
  2017/03/15  ??      pr_LPNs_RecalculateWeight: Initial revision (HPI-Golive)
  2016/11/10  VM      Added pr_LPNs_Recalculate (HPI-993)
              VM      Added pr_LPNs_RecalculateWeightVolume (HPI-993)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Recalculate') is not null
  drop Procedure pr_LPNs_Recalculate;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Recalculate: This procedure is to recount a number of LPNs at once.
    Note that the input could have duplicate LPN Ids and hence we sort by EntityId
    and recount each LPN only once.

  Flags - C - Recount, P - Preprocess
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Recalculate
  (@LPNsToRecount    TRecountKeysTable readonly,
   @Flags            TFlags = 'C',
   @UserId           TUserId = null,
   @NewStatus        TStatus = null,
   @NewOnhandStatus  TStatus = null)
as
   declare @vLPNId TRecordId;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vLPNId = 0;

  while (exists (select * from @LPNsToRecount where EntityId > @vLPNId))
    begin
      select top 1 @vLPNId = EntityId
      from @LPNsToRecount
      where (EntityId > @vLPNId)
      order by EntityId;

      /* When both are needed, it would be best to do Preprocess first and then Recount */
      if (charindex('P' /* Pre-process */, @Flags) <> 0)
        exec pr_LPNs_Preprocess @vLPNId, default, null /* BusinessUnit */;

      if (charindex('C' /* Re(C)ount */, @Flags) <> 0)
        exec pr_LPNs_Recount @vLPNId; --FYI: Recount calls set status as well

      if (charindex('S' /* Status */, @Flags) <> 0)
        exec pr_LPNs_SetStatus @vLPNId, @NewStatus, @NewOnhandStatus;
    end
end /* pr_LPNs_Recalculate */

Go
