/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Prod_Dash_Picking_Transfer') is not null
  drop Procedure pr_Prod_Dash_Picking_Transfer;
Go
/*------------------------------------------------------------------------------
  Proc pr_Prod_Dash_Picking_Transfer:
  Wrapper procedure to call pr_Prod_DS_GetUserProductivity with set
  values to return data set to dashboard
------------------------------------------------------------------------------*/
Create Procedure pr_Prod_Dash_Picking_Transfer
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vRecordId          TRecordId;

  declare @vXMLInput          TXML,
          @vXMLOutput         TXML;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  select @vXMLInput = dbo.fn_XMLNode('Root',
                        dbo.fn_XMLNode('Data',
                          dbo.fn_XMLNode('Operation',     'Picking')+
                          dbo.fn_XMLNode('SummarizeBy',   'UserDate')+
                          dbo.fn_XMLNode('WaveType',      'Xfer')+
                          dbo.fn_XMLNode('UserId',        'cimsadmin')+
                          dbo.fn_XMLNode('Mode',          'V')));

  exec pr_Prod_DS_GetUserProductivity @vXMLInput, @vXMLOutput output;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Prod_Dash_Picking_Transfer */

Go
