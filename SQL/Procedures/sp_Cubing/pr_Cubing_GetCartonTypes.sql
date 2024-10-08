/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/06  TK      pr_Cubing_Execute & pr_Cubing_GetCartonTypes:
                        Changes to cube single carton carton orders to improve performance
                      pr_Cubing_CubeSingleCartonOrders: Initial Revision (HA-1487)
  2020/06/29  AY      pr_Cubing_GetCartonTypes: Remove old code that uses CartonGroup.Account
                      Change to add where clause in code instead of in view
  2019/02/04  TK      pr_Cubing_GetCartonTypes: Changes to use vwCartonGroupsAndTypes to retrieve Carton Types (HPI-2380)
  2018/05/04  TK      pr_Cubing_GetCartonTypes: Bug fix to return appropriate carton types depending upon carton type filter (S2G-822)
  2018/02/08  TD      pr_Cubing_Execute,pr_Cubing_GetCartonTypes,pr_Cubing_FindAvailableCarton:Changes to cube based on
                        cases and unit picks (S2G-107)
  2017/04/10  TK      pr_Cubing_GetCartonTypes: Changes to consider Account instead of SoldToId (HPI-1494)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Cubing_GetCartonTypes') is not null
  drop Procedure pr_Cubing_GetCartonTypes;
Go
/*------------------------------------------------------------------------------
  pr_Cubing_GetCartonTypes:  This function returns the Carton Types available
    for the SoldToId of a given Order.
------------------------------------------------------------------------------*/
Create Procedure pr_Cubing_GetCartonTypes
  (@OrderId       TRecordId,
   @WaveId        TRecordId,
   @BusinessUnit  TBusinessUnit)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,

          @vOrderType        TTypeCode,
          @vCartonGroup      TDescription,
          @vOwnership        TOwnership,
          @vWarehouse        TWarehouse,
          @vXMLData          TXML,
          @vLPNPicks         TCount,
          @vCasePicks        TCount,
          @vUnitPicks        TCount,
          @vWaveType         TTypeCode;
begin
  /* Initialize */
  delete from #CartonTypes;

  if not exists (select * from #OrdersToCube)
    return;

  /* Get batch type here for the given batchid */
  select @vWaveType = BatchType
  from Waves
  where (RecordId = @WaveId);

  /* Beyond carton types being defined for SoldTo, there may be other criteria
     needed to identify the carton types that are applicable for an order. We
     encapsulate that in CartonType.UDF1 and use rules to filter using the
     data from the Order.

     Example: At Acme, Spanx Orders of Type H should only use Hosiery Cartons, I should
     Intimate Apparel Cartons and B should also use IA cartons only! */
  select @vXMLData = dbo.fn_XMLNode('RootNode',
                          dbo.fn_XMLNode('OrderId',     @OrderId) +
                          dbo.fn_XMLNode('WaveId',      @WaveId) +
                          dbo.fn_XMLNode('WaveType',    @vWaveType));

  /* Determine the Carton Group for the Orders in #OrdersToCube */
  exec pr_RuleSets_ExecuteAllRules 'Cubing_CartonGroups', @vXMLData, @BusinessUnit;

  /* If the carton group is defined on for the order then return the carton types for that perticular group */
  if exists (select * from #OrdersToCube where OrderCartonGroup is not null)
    insert into #CartonTypes (CartonGroup, CartonType, EmptyCartonSpace, EmptyWeight, MaxWeight, MaxUnits, MaxCartonDimension,
                              FirstDimension, SecondDimension, ThirdDimension)
    select CGT.CartonGroup, CGT.CartonType, CGT.AvailableSpace, CGT.EmptyWeight, CGT.MaxWeight, CGT.MaxUnits, CGT.MaxInnerDimension,
           CGT.FirstDimension, CGT.SecondDimension, CGT.ThirdDimension
    from vwCartonGroupsAndTypes CGT
      join (select distinct OrderCartonGroup from #OrdersToCube) OTC on (CGT.CartonGroup = OTC.OrderCartonGroup)
    where (CGT_Status = 'A') and (CT_Status = 'A') and
          (BusinessUnit = @BusinessUnit);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Cubing_GetCartonTypes */

Go
