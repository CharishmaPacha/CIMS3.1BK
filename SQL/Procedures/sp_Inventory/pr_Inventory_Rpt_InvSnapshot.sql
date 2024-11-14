/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/11/05  RV      Initial Version (BK-1149)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Inventory_Rpt_InvSnapShot') is not null
  drop Procedure pr_OnhandInventory_Rpt_InvSnapShot;
Go
/*------------------------------------------------------------------------------
  Proc pr_Inventory_Rpt_InvSnapShot: Returns the xml with the selected records
------------------------------------------------------------------------------*/
Create Procedure pr_Inventory_Rpt_InvSnapShot
 (@xmlInput          xml,
  @BusinessUnit      TBusinessUnit,
  @UserId            TUserId,
  @xmlResult         xml output)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,

          @vReportResultXML     XML;

  declare @ttLPNs               TEntityKeysTable;

begin /* pr_Inventory_Rpt_InvSnapShot */
  SET NOCOUNT ON;

  select @vReturnCode     = 0,
         @vMessageName    = null;

  if (@xmlInput is null)
    set @vMessageName = 'InvalidInputData';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  select @vReportResultXML = (select EOI.*
                              from vwExportsOnhandInventory EOI
                                             join #ttSelectedEntities SE on (EOI.LPNDetailId = SE.EntityId)
                              order by SE.RecordId
                              FOR XML RAW('InvSnapshot'), TYPE, ELEMENTS XSINIL, binary base64, ROOT('Inventory'));

  set @xmlResult = dbo.fn_XMLNode('REPORTS', convert(varchar(max), @vReportResultXML));

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Inventory_Rpt_InvSnapShot */

Go
