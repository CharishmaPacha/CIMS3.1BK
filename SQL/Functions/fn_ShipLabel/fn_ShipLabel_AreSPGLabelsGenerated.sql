/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/19  OK      fn_ShipLabel_AreSPGLabelsGenerated: Enhanced to support for LPN and Order entities (BK-263)
  2021/03/09  MS      pr_ShipLabel_GenerateLabelsComplete, fn_ShipLabel_AreSPGLabelsGenerated: Changes to return shiplabel status (BK-263)
  2020/07/30  RV      pr_ShipLabel_GenerateLabelsComplete: Made changes to update the print dependencies on Tasks and Waves
                      fn_ShipLabel_AreSPGLabelsGenerated: Intial Version (S2GCA-1199)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_ShipLabel_AreSPGLabelsGenerated') is not null
  drop Function fn_ShipLabel_AreSPGLabelsGenerated;
Go
/*------------------------------------------------------------------------------
  Function fn_ShipLabel_AreSPGLabelsGenerated: Returns the flag whether all the small package labels
  are generated for the Entity WaveId/TaskId/OrderId/LPNId/ProcessBatch.

  return values:
  N  - Not yet generated
  Y - Generated
------------------------------------------------------------------------------*/
Create Function fn_ShipLabel_AreSPGLabelsGenerated
  (@ProcessBatch TBatch        = null,
   @WaveId       TRecordId     = null,
   @TaskId       TRecordId     = null,
   @OrderId      TRecordId     = null,
   @LPNId        TRecordId     = null,
   @BusinessUnit TBusinessUnit = null)
  ------------------------------------
   returns       TFlags
as
begin
  declare @IsSPGLabelsGenerated TFlag;

  select @IsSPGLabelsGenerated = 'N' /* No */;

  /* Verify whether the all labels are generated for the Wave */
  if (@WaveId is not null)
    begin
      if exists (select * from ShipLabels where (Status = 'A') and (WaveId = @WaveId) and (IsValidTrackingNo = 'N') and (Archived = 'N'))
        select @IsSPGLabelsGenerated = 'N' /* No */;
      else
        select @IsSPGLabelsGenerated = 'Y' /* Yes */;
    end
  else
  /* Verify whether the all labels are generated for the Task */
  if (@TaskId is not null)
    begin
      if exists (select * from ShipLabels where Status = 'A' and (TaskId = @TaskId) and (IsValidTrackingNo = 'N') and (Archived = 'N'))
        select @IsSPGLabelsGenerated = 'N' /* No */;
      else
        select @IsSPGLabelsGenerated = 'Y' /* Yes */;
    end
  else
  /* Verify whether the all labels are generated for the Order */
  if (@TaskId is not null)
    begin
      if exists (select * from ShipLabels where Status = 'A' and (OrderId = @OrderId) and (IsValidTrackingNo = 'N') and (Archived = 'N'))
        select @IsSPGLabelsGenerated = 'N' /* No */;
      else
        select @IsSPGLabelsGenerated = 'Y' /* Yes */;
    end
  else
  /* Verify whether the all labels are generated for the Task */
  if (@LPNId is not null)
    begin
      if exists (select * from ShipLabels where Status = 'A' and (Entityid = @LPNId) and (IsValidTrackingNo = 'N') and (Archived = 'N'))
        select @IsSPGLabelsGenerated = 'N' /* No */;
      else
        select @IsSPGLabelsGenerated = 'Y' /* Yes */;
    end

  return @IsSPGLabelsGenerated;
end /* fn_ShipLabel_AreSPGLabelsGenerated */

Go
