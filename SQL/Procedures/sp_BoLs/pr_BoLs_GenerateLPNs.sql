/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/09/23  RT/TK   pr_BoLs_GenerateLPNs: New procedure to get the Packed LPNs info instead of loading each LPN through funcion (HA-3112)
              AY      pr_BoLs_GenerateLPNs: Provision for customized grouping of LPNs for custom BoLs (FB-2225)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoLs_GenerateLPNs') is not null
  drop Procedure pr_BoLs_GenerateLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoLs_GenerateLPNs: Generate the list of LPNs in #BoLLPNs to be summarized
    for BoLCarrier Details and BoL Order Details
------------------------------------------------------------------------------*/
Create Procedure pr_BoLs_GenerateLPNs
  (@BoLId            TRecordId,
   @BoLType          TTypeCode,
   @LoadId           TRecordId,
   @xmlRulesData     TXML,
   @Operation        TOperation,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  delete from #BoLLPNs;

  /* If underlying BoL, then consider the LPNs for this shipment only */
  if (@BoLType = 'U' /* Underlying BoL */)
    insert into #BoLLPNs (BolId, LPNId, InnerPacks, Quantity, Packages)
      select @BoLId, L.LPNId, sum(GPI.InnerPacks), sum(GPI.Quantity), 1 /* each LPN is one package */ --sum(GPI.Cases)
      from LPNs L
        join Shipments S on (S.ShipmentId = L.ShipmentId)
        cross apply dbo.fn_LPNs_GetPackedInfo(L.LPNId, @Operation, 'L' /* L - LPN (Option) */) GPI
      where (S.BoLId = @BoLId) and
            (coalesce(S.LoadId, 0) <> 0)
      group by L.LPNId;
  else
  /* If Master BoL, then consider the LPNs for all LPNs on the Load */
  if (@BoLType = 'M' /* Master */)
    insert into #BoLLPNs (BolId, LPNId, InnerPacks, Quantity, Packages)
      select @BoLId, L.LPNId, sum(GPI.InnerPacks), sum(GPI.Quantity), 1 /* each LPN is one package */ -- sum(GPI.Cases)
      from LPNs L
        cross apply dbo.fn_LPNs_GetPackedInfo(L.LPNId, @Operation, 'L' /* L - LPN (Option) */) GPI
      where (L.LoadId = @LoadId)
      group by L.LPNId;

  /* Update LPN and associated info.
     For BOD typically we summarize by CustPO
     For BCD typically we summarize by Load */
  update BL
  set PalletId          = L.PalletId,
      OrderId           = L.OrderId,
      ShipmentId        = L.ShipmentId,
      CustPO            = OH.CustPO,
      ShipToId          = OH.ShipToId,
      ShipToStore       = OH.ShipToStore,
      LPNWeight         = L.LPNWeight,
      LPNVolume         = L.LPNVolume,
      BOD_GroupCriteria = OH.CustPO,
      BCD_GroupCriteria = @LoadId
  from #BoLLPNs BL join LPNs L on (L.LPNId = BL.LPNId)
    left outer join OrderHeaders OH on (OH.OrderId = L.OrderId);
    -- need left outer join as Tranfer Loads may have LPNs not associated with Orders

  /* Process the BoL LPNs to change or Update any fields */
  exec pr_RuleSets_ExecuteAllRules 'BoLLPNs', @xmlRulesData, @BusinessUnit;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_BoLs_GenerateLPNs */

Go
