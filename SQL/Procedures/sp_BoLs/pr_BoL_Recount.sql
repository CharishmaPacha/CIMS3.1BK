/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/07/03  TD      Added new procedure pr_BoL_Recount.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoL_Recount') is not null
  drop Procedure pr_BoL_Recount;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_Recount:
   Recount will calculate the  BolOrderDetails counts afresh.
------------------------------------------------------------------------------*/
Create Procedure pr_BoL_Recount
  (@BoLId  TBoLId)
as
  declare @ReturnCode    TInteger,
          @MessageName   TMessageName,
          @vTotalLPNs    TCount,
          @vTotalPallets TCount,
          @vTotalUnits   TCount,
          @vVolume       TFloat,
          @vWeight       TFloat,
          @vBusinessUnit TBusinessUnit,
          @vUserId       TUserId;
begin  /* pr_BoL_Recount */
  SET NOCOUNT ON;

  select @ReturnCode     = 0,
         @MessageName    = null,
         @vTotalPallets  = 0,
         @vTotalLPNs     = 0,
         @vTotalUnits    = 0,
         @vUserId        = System_User;

  /* Get count of the LPns,Pallets, Units here */
  select  @vTotalPallets = count(distinct L.PalletId),
          @vTotalLPNs    = count(L.LPNId),
          @vTotalUnits   = sum(L.Quantity),
          @vVolume       = sum(L.ActualVolume),
          @vWeight       = sum(L.ActualWeight),
          @vBusinessUnit = Min(L.BusinessUnit)
  from LPNs L
       join OrderHeaders   OH on (OH.OrderId   = L.OrderId   )
       join Shipments      S  on (S.ShipmentId = L.ShipmentId)
  where (S.BoLId = @BoLId) and
        (coalesce(S.LoadId, 0) <> 0)
  group by OH.CustPO;

  /* Update Bol Order Details Here */
  update BoLOrderDetails
  set NumLPNs       = @vTotalLPNs,
      NumPallets    = @vTotalPallets,
      NumUnits      = @vTotalUnits,
      Volume        = @vVolume,
      Weight        = @vWeight,
      Palletized    = case when (@vTotalPallets > 0) then 'Y' /* Yes */
                           else dbo.fn_Controls_GetAsString('VICSBoL', 'Palletized', 'N', @vBusinessUnit, @vUserId)
                      end,
      NumShippables = @vTotalLPNs
  where (BoLId = @BoLId);

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_BoL_Recount */

Go
