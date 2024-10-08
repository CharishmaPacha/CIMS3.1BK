/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/13  AY      pr_Waves_GetLabelDataByStyle: print labels by Style/Color/Size (HA-2974)
  2021/03/20  KBB     pr_Waves_GetLabelDataByStyle: Added InvAllocationModel (HA-2365)
  2021/02/24  AY/KBB  pr_Waves_GetLabelDataByStyle: Enhanced to print by Style or Style Color (HA-2045)
  2021/01/05  RV      pr_Waves_GetLabelDataByStyle: Initial revision (HA-1855)
  2020/10/20  KBB     pr_Waves_GetLabelData: Including the new procedure (HA-1107)
  2020/08/12  KBB     pr_Waves_GetLabelData: Including the new procedure (HA-1107)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Waves_GetLabelData') is not null
  drop Procedure pr_Waves_GetLabelData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Waves_GetLabelData: This procedure returns the dataset with required
  fields to print on Wave labels
------------------------------------------------------------------------------*/
Create Procedure pr_Waves_GetLabelData
  (@WaveId     TRecordId)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vRecordId           TRecordId,

          @vNumTempLabels      TCount,
          @vCartonsToDisplay   TVarchar;

  declare @ttCartontypes table (RecordId        TRecordId    identity(1,1),
                                NumCartons      TInteger,
                                CartonType      TCartonType,
                                CartonTypeDesc  char(20));
begin
  SET NOCOUNT ON;

  select @vReturnCode       = 0,
         @vMessageName      = null,
         @vRecordId         = 0,
         @vCartonsToDisplay = '';

  /* Get the NumTempLabels info */
  select @vNumTempLabels = sum(NumTempLabels)
  from Tasks
  where (WaveId = @WaveId) and
        (Status <> 'X');

  /* If the wave has temp labels generated, then get the carton types */
  if (@vNumTempLabels > 0)
    begin
      insert into @ttCartonTypes (NumCartons, CartonType, CartonTypeDesc)
        select count(distinct L.LPNId) NumLPNs, CT.CartonType, min(CT.Description)
        from OrderHeaders OH
          join LPNs L         on (L.OrderId = OH.OrderId) and (L.LPNType = 'S')
          join CartonTypes CT on (L.CartonType = CT.CartonType)
        where (OH.PickBatchId = @WaveId)
        group by CT.CartonType, CT.SortSeq
        order by CT.SortSeq;

      /* Pad to 20 so that the NumCartons are all aligned. Add #13#10 so that each one shows
         on a new line like below on the label
         15AM       - 1
         3AM        - 1
         Note: New line characters (\&) having issue while converting to xml, for temp fix replaced with semi colon (;)
      */
      select @vCartonsToDisplay = @vCartonstoDisplay + CartonTypeDesc + ' ' + cast(NumCartons as varchar) + '\& '
      from @ttCartontypes;
    end

  /* Get the values to be printed on Wave Label */
  select W.*, @vCartonsToDisplay CartonTypesList
  from vwWaves W
  where (W.WaveId = @WaveId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Waves_GetLabelData */

Go
