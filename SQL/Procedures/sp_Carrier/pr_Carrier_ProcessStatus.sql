/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/21  VS      pr_Carrier_ProcessStatus, pr_Carrier_Response_SaveShipmentData: If we get any error save the error info in Notifications (CIMSV3-1780)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Carrier_ProcessStatus') is not null
  drop Procedure pr_Carrier_ProcessStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_Carrier_ProcessStatus: Get the Process Status based on Severity of Carrier response .
------------------------------------------------------------------------------*/
Create Procedure pr_Carrier_ProcessStatus
  (@Notifications        TVarChar,
   @Carrier              TCarrier,
   @WaveType             TTypeCode,
   @BusinessUnit         TBusinessUnit,
   @ProcessStatus        TStatus output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vSeverity              TStatus,
          @vWaveTypesToExportShippingDocs
                                  TControlValue;

begin /* pr_Carrier_ProcessStatus */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  /* Get the valid wave types to export shipping documents to WSS */
  select @vWaveTypesToExportShippingDocs = dbo.fn_Controls_GetAsString('ExportShippingDocs', 'WaveTypesToExportShippingDocs', '', @BusinessUnit, null /* UserId */)

  if (@Carrier = 'FedEx')
    begin
     select @vSeverity   = HighestSeverity
     from #Notifications;

      select @ProcessStatus = case
                                when (@vSeverity = 'Error') then
                                  'LGE' /* Label Generation Error */
                                when (charindex(@WaveType, @vWaveTypesToExportShippingDocs) > 0) then
                                  'XR' /* Export Required */
                                else
                                  'LG' /* Label Generated */
                              end;
    end
  else
    begin
      /* We are appending 'Error' keyword for error message in all shipping services (exception handling). So, using it verify the error.
         Note: UPS returns empty if shipment successfully created */
      select @ProcessStatus = case
                                 when (charindex('Error', @Notifications) > 0) then
                                   'LGE' /* Label Generation Error */
                                 when (charindex(@WaveType, @vWaveTypesToExportShippingDocs) > 0) then
                                   'XR' /* Export Required */
                                 else
                                   'LG' /* Label Generated */
                               end;
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Carrier_ProcessStatus */

Go
