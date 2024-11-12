/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/11/07  CHP     Initial Version (BK-1150)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CC_Rpt_CCResultsList') is not null
  drop Procedure pr_CC_Rpt_CCResultsList;
Go
/*------------------------------------------------------------------------------
  Proc pr_CC_Rpt_CCResultsList: Returns data set of list of selected
    from Cycle count results page.
------------------------------------------------------------------------------*/
Create Procedure pr_CC_Rpt_CCResultsList
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

begin /* pr_CC_Rpt_CCResultsList */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null;

  if (@xmlInput is null)
    set @vMessageName = 'InvalidInputData';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  select @vReportResultXML = (select *
                              from vwCycleCountResults CCR
                                            join #ttSelectedEntities SE on (CCR.LocationId = SE.EntityKey)
                              order by BatchNo
                              FOR XML RAW('CCResultsInfo'), TYPE, ELEMENTS XSINIL, binary base64, ROOT('CCResultsList'));

  set @xmlResult = dbo.fn_XMLNode('REPORTS', convert(varchar(max), @vReportResultXML));

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_CC_Rpt_CCResultsList */

Go
