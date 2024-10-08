/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/12  AY      pr_LPNs_Rpt_LPNList: Data sources for LPN List report (HA-2597)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Rpt_LPNList') is not null
  drop Procedure pr_LPNs_Rpt_LPNList;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Rpt_LPNList: Returns data set of list of LPNs to be printed
    for the selected entities.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Rpt_LPNList
 (@xmlInput          xml,
  @BusinessUnit      TBusinessUnit,
  @UserId            TUserId,
  @xmlResult         xml output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vEntityType          TTypeCode,

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

  select top 1 @vEntityType = EntityType
  from #ttSelectedEntities;

  /* Setup @ttLocations based on Entities selected */
  if (@vEntityType = 'LPN')
    select @vReportResultXML = (select *
                                from vwLPNs L
                                join #ttSelectedEntities SE on (L.LPNId = SE.EntityId)
                                order by Location, SKUSortOrder, LPN
                                FOR XML RAW('LocationLPNinfo'), TYPE, ELEMENTS, ROOT('Root'));
  else
  if (@vEntityType = 'Pallet')
    begin
      select @vReportResultXML = (select *
                                  from vwLPNs L
                                  join #ttSelectedEntities SE on (L.PalletId = SE.EntityId)
                                  order by Pallet, SKUSortOrder, LPN
                                  FOR XML RAW('LocationLPNinfo'), TYPE, ELEMENTS, ROOT('Root'));
    end

  set @xmlResult = dbo.fn_XMLNode('REPORTS', convert(varchar(max), @vReportResultXML));

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_Rpt_LPNList */

Go
