/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2017/06/13  SV      pr_DropPickedPallet_ClearTempLabels: Bug Fix, deleting the LPND line for the TD which is short picked (HPI-1561)
                      pr_DropPickedPallet_ClearTempLabels: Modified join to consider OrderDetailId, SKUId and modified where clause SKUId, OnhandStatus as well
  2016/09/17  PK      pr_DropPickedPallet_ClearTempLabels: Clear temp labels after the cart has been dropped.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DropPickedPallet_ClearTempLabels') is not null
  drop Procedure pr_DropPickedPallet_ClearTempLabels;
Go
/*------------------------------------------------------------------------------
  Proc pr_DropPickedPallet_ClearTempLabels:
------------------------------------------------------------------------------*/
Create Procedure pr_DropPickedPallet_ClearTempLabels
  (@PalletToDrop  TPallet)
as
  declare @ReturnCode               TInteger,
          @MessageName              TMessageName,
          @Message                  TDescription,
          @vRecordId                TRecordId,
          @vLPNId                   TRecordId,
          @vPalletId                TRecordId;

  declare @ttPickedLPNs table  (RecordId   TRecordId identity(1,1),
                                LPNId      TRecordId);

  declare @ttTempLPNs table (RecordId   TRecordId identity(1,1),
                             LPNId      TRecordId,
                             LPN        TLPN,
                             TaskId     TRecordId,
                             OrderId    TRecordId,
                             Pallet     TPallet);

begin /* pr_DropPickedPallet_ClearTempLabels */

  select @vRecordId = 0;

  /* Get the palletId from Pallets */
  select @vPalletId = PalletId
  from Pallets
  where Pallet = @PalletToDrop;

  /* Insert all TempLPNs which are on the cart */
  insert into @ttTempLPNs (LPNId, LPN, TaskId, OrderId, Pallet)
    select LPNId, LPN, TaskId, OrderId, Pallet
    from LPNs
    where PalletId = @vPalletId and
          LPNType = 'S';

  /* Update the lines if the task status confirms as completed etc */
  update LD
  set LD.OnhandStatus = 'R'
  from LPNDetails LD
    join @ttTempLPNs TL on (TL.LPNId         = LD.LPNId)
    join Tasks       T  on (T.TaskId         = TL.TaskId)
    join TaskDetails TD on (TD.TaskId        = T.TaskId) and
                           (TD.OrderDetailId = LD.OrderDetailId)
  where (TD.SKUId        = LD.SKUId) and
        (LD.OnhandStatus = 'U') and
        (TD.Status       = 'C');

  /* Delete the lines if the Temp lines are short picked while picking,
     clear those lines */
  update LD
  set LD.LPNId = -LD.LPNId,
      LD.UDF5  = 'Removed'
  output Deleted.LPNId into @ttPickedLPNs
  from LPNDetails LD
    join @ttTempLPNs TL on (TL.LPNId         = LD.LPNId)
    join Tasks       T  on (T.TaskId         = TL.TaskId)
    join TaskDetails TD on (TD.TaskId        = T.TaskId) and
                           (TD.TempLabelDetailId = LD.LPNDetailId) and
                           (TD.OrderDetailId = LD.OrderDetailId)
  where (TD.SKUId        = LD.SKUId) and
        (TD.Status       = 'X')

  /* Recount the LPNs if the LPNs are shorting picked while picking */
  if (exists (select * from @ttPickedLPNs where RecordId > @vRecordId))
    begin
      /* Get the top 1 record */
      select top 1 @vLPNId    = LPNId,
                   @vRecordId = @vRecordId
      from @ttPickedLPNs
      where RecordId > @vRecordId
      order by RecordId

      /* Recount LPNs */
      exec pr_LPNs_Recount @vLPNId;
    end

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

end /* pr_DropPickedPallet_ClearTempLabels */

Go
