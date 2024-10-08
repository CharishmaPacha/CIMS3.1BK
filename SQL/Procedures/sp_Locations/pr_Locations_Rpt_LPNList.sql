/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/12  MS      pr_Locations_Rpt_LPNList: Changes to print LPNListing report from LPNs&Pallets page (HA-2597)
  2021/03/10  RV      pr_Locations_Rpt_LPNList: Port back exist Location sort order and SKUSortOrder (HA-2237)
  2021/03/09  SK      pr_Locations_Rpt_LPNList: Using new data source (HA-2208)
  2020/07/28  PHK     pr_Locations_Rpt_LPNList: Added Procedure for LocationLPNList report Data.(HA-1083)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Locations_Rpt_LPNList') is not null
  drop Procedure pr_Locations_Rpt_LPNList;
Go
/*------------------------------------------------------------------------------
  Proc pr_Locations_Rpt_LPNList: Returns data set of list of LPNs for the selected
    Locations.
------------------------------------------------------------------------------*/
Create Procedure pr_Locations_Rpt_LPNList
 (@xmlInput          xml,
  @BusinessUnit      TBusinessUnit,
  @UserId            TUserId,
  @xmlResult         xml output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vContextName         TName,

          @vReportResultXML     XML;

  declare @ttLPNs               TEntityKeysTable;

begin /* pr_Locations_Rpt_LPNList */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null;

  if (@xmlInput is null)
    set @vMessageName = 'InvalidInputData';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Get contextname of the page the action is calling from */
  select @vContextName = Record.Col.value('(UIInfo/ContextName) [1]', 'TName')
  from @xmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlInput = null));

  /* Setup @ttLocations based on Entities selected */
  if (@vContextName = 'List.LPNs')
    select @vReportResultXML = (select *
                                from vwLPNs L
                                join #ttSelectedEntities SE on (L.LPNId = SE.EntityId)
                                order by Location, SKUSortOrder, LPN
                                FOR XML RAW('LocationLPNinfo'), TYPE, ELEMENTS, ROOT('Location'));
  else
  if (@vContextName = 'List.Pallets')
    begin
      insert into @ttLPNs(EntityId)
        select distinct L.LPNId from LPNs L join #ttSelectedEntities SE on (L.PalletId = SE.EntityId)

      select @vReportResultXML = (select *
                                  from vwLPNs L
                                  join @ttLPNs TL on (L.LPNId = TL.EntityId)
                                  order by Location, SKUSortOrder, LPN
                                  FOR XML RAW('LocationLPNinfo'), TYPE, ELEMENTS, ROOT('Location'));
    end
  else
    select @vReportResultXML = (select *
                                from vwLocationLPNs Loc
                                join #ttSelectedEntities SE on (Loc.LocationId = SE.EntityId)
                                order by Location, SKUSortOrder, LPN
                                FOR XML RAW('LocationLPNinfo'), TYPE, ELEMENTS, ROOT('Location'));

  set @xmlResult = dbo.fn_XMLNode('REPORTS', convert(varchar(max), @vReportResultXML));

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Locations_Rpt_LPNList */

Go
