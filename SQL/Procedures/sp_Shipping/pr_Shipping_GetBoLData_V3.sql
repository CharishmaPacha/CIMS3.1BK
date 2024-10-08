/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/23  MS      pr_Shipping_GetBoLData, pr_Shipping_GetBoLData_V3: Made changes to get ActionId to evaluate printing ConsolidatedAddress for BoLs (HA-2386)
  2020/08/10  NB      pr_Shipping_GetBoLData_V3: added procedure for V3 Reports_GetData generic implementation(CIMSV3-1022)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetBoLData_V3') is not null
  drop Procedure pr_Shipping_GetBoLData_V3;
Go
/*------------------------------------------------------------------------------
Proc pr_Shipping_GetBoLData_V3:

Wrapper procedure called from V3 SQL to invoke pr_Shipping_GetBoLData procedure
and return the xml
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetBoLData_V3
  (@xmlInput          xml,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @xmlResult         xml output)
as
  declare @vEntityId             TRecordId,
          @vActionId             TName,
          @vReportRequestXML     TXML,
          @vReportResultXML      TXML,
          @vLoadInfo             TXML,
          @vBoLTypesToPrintXML   TXML,
          @vOptions              TXML;
begin /* pr_Shipping_GetBoLData_V3 */
  select @vEntityId = Record.Col.value('EntityId[1]', 'TRecordId'),
         @vActionId = Record.Col.value('ActionId[1]', 'TName')
  from @xmlInput.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlInput = null ));

  /* Buid the Request XML */
  select @vLoadInfo = cast((select @vEntityId for XML raw('LoadId'), type, elements, root('Loads')) as varchar(max));
  select @vOptions  = dbo.fn_XMLNode('Options', dbo.fn_XMLNode('Action', @vActionId));

  /* Master, UnderLying Report */
  select @vBoLTypesToPrintXML = cast((select 'MU' for xml raw('BoLTypesToPrint'), elements) as varchar(max));
  select @vReportRequestXML = '<PrintVICSBoL>' +
                                @vLoadInfo +
                                @vBoLTypesToPrintXML +
                                @vOptions +
                              '</PrintVICSBoL>';

  exec pr_Shipping_GetBoLData @vReportRequestXML, @vReportResultXML output;

  select @xmlResult = cast(@vReportResultXML as xml);

end /* pr_Shipping_GetBoLData_V3 */

Go
