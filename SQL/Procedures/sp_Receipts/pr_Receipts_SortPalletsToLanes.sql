/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/02/17  AY      pr_Receipts_SortPalletsToLanes: Procedure to map Pallets to Lanes (JL-58)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_SortPalletsToLanes') is not null
  drop Procedure pr_Receipts_SortPalletsToLanes;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_SortPalletsToLanes: When the selected Pallets are to be sorted
    to a selected set of lanes, the # tables are flagged and this procedure is
    invoked. The lanes to be used are flagged with Status = E and Pallets to be
    sorted are Flagged with UDF1 = #. So, caller updates #Pallet.UDF1 with #
    and this procedure updates with the actual Lane.
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_SortPalletsToLanes
  (@BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId,
          @vDebug             TFlags,
          @vNumPallets        TCount,
          @vNumLanes          TCount;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0,
         @vDebug       = 'D';

  select @vNumPallets = count(*) from #Pallets where UDF1 = '#';
  select @vNumLanes = count(*) from #Lanes where Status = 'E' /* Enabled */;

  /* if there are no Lanes or no Pallets, then exit */
  if (@vNumLanes = 0) or (@vNumPallets = 0) goto ExitHandler;

  /* Each lane can have a varying number of Pallets, so generate the pallet positions for each lane
     the Pallet positions are ordered by Pallet position and then Lane */
  select LN.Lane, GS.RecordId, row_number() over (order by GS.RecordId, LN.Lane) SortOrder
  into #PalletPositions
  from #Lanes LN join fn_GenerateSequence(1, null, 100) GS on LN.Status = 'E' and GS.RecordId <= LN.MaxPallets;

  /* For the Pallets which are to be sorted, randomly sort them to assign to lanes */
  with PalletSort as
    (select EntityId, EntityKey, row_number() over (order by newid()) SortOrder from #Pallets where UDF1 = '#')
  update #Pallets set UDF5 = PS.SortOrder
  from #Pallets P join PalletSort PS on P.EntityId = PS.EntityId;

  update P
  set P.UDF1 = coalesce(PP.Lane, '')
  from #Pallets P left outer join #PalletPositions PP on (P.UDF5 = PP.SortOrder)
  where (P.UDF1 = '#');

  if (charindex('D', @vDebug) > 0) select * from #Pallets;
  if (charindex('D', @vDebug) > 0) select * from #PalletPositions;
  if (charindex('D', @vDebug) > 0) select * from #Lanes;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  /* Reset remaining Pallets and status of Lanes for next run */
  update #Pallets set UDF1 = '' where UDF1 = '#';
  update #Lanes set Status = 'D', LaneId = 0;

  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_SortPalletsToLanes */

Go
