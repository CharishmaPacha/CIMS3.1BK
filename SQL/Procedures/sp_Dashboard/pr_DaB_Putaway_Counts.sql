/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_DaB_Putaway_Counts') is not null
  drop Procedure pr_DaB_Putaway_Counts;
Go
/*------------------------------------------------------------------------------
  Proc pr_DaB_Putaway_Counts: Returns the statistics for Putaway for the given
    date. If no date is provided it defaults to current date
------------------------------------------------------------------------------*/
Create Procedure pr_DaB_Putaway_Counts
  (@Date      TDate = null)
as
  declare @vLPNsReceived  TCount,
          @vCasesReceived TCount,
          @vUnitsReceived TCount,
          @vValueReceived TMoney,

          @vLPNsPutaway   TCount,
          @vCasesPutaway  TCount,
          @vUnitsPutaway  TCount,
          @vValuePutaway  TMoney;
begin
  SET NOCOUNT ON;

  /* If no date is given, default to today */
  select @Date = coalesce(@Date, current_timestamp);

  /* Return the following: LPNs, Cases, Units in Received status,
                           LPNs, Cases, Units Putaway today */
  select @vLPNsReceived  = count(L.LPNId),
         @vCasesReceived = sum(L.InnerPacks),
         @vUnitsReceived = sum(L.Quantity),
         @vValueReceived = sum(L.Quantity * S.UnitCost)
  from LPNs L join SKUs S on L.SKUId = S.SKUId
  where (L.Status = 'R' /* Received */);

  select @vLPNsPutaway  = count(L.LPNId),
         @vCasesPutaway = sum(L.InnerPacks),
         @vUnitsPutaway = sum(L.Quantity),
         @vValuePutaway = sum(L.Quantity * S.UnitCost)
  from LPNs L join SKUs S on L.SKUId = S.SKUId
  where (L.Status       = 'P' /* Putaway */) and
        (cast(L.LastMovedDate as date) = @Date) and
        (L.LPNType      = 'C' /* Carton */);

  select @vLPNsReceived  LPNsInReceivedStatus,
         @vCasesReceived CasesInReceivedStatus,
         @vUnitsReceived UnitsInReceivedStatus,
         @vValueReceived ValueOfReceivedProduct,
         @vLPNsPutaway   LPNsPutaway,
         @vCasesPutaway  CasesPutaway,
         @vUnitsPutaway  UnitsPutaway,
         @vValuePutaway  ValueofPutawayProduct;
end /* pr_DaB_Putaway_Counts */

Go
