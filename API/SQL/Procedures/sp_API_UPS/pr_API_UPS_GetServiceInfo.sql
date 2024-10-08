/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_GetServiceInfo') is not null
  drop Procedure pr_API_UPS_GetServiceInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_GetServiceInfo:
   Returns the service code json

  Sample output:
  {
   "Code":"03",
   "Description":"UPS Ground"
  }
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_GetServiceInfo
  (@InputXML          xml,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @ServiceInfoJSON   TNVarchar output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName;
begin /* pr_API_UPS_GetServiceInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Build Service info json */
  select @ServiceInfoJSON = (select Code        = dbo.fn_GetMappedValue('CIMS', Record.Col.value('CARRIERSERVICECODE[1]', 'TDescription'), 'UPSAPI', 'ShipVia', null, @BusinessUnit),
                                    Description = Record.Col.value('ServiceLevel[1]', 'TDescription')
                             from @InputXML.nodes('/SHIPPINGINFO/REQUEST/SHIPVIA') Record(Col)
                             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                             OPTION (OPTIMIZE FOR ( @InputXML = null ));

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_GetServiceInfo */

Go
