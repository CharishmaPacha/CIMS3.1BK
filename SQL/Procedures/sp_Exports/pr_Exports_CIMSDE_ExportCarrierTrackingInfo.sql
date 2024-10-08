/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/10/04  VS      pr_Exports_CIMSDE_ExportCarrierTrackingInfo: Made changes to improve the performance (BK-920)
  2021/05/19  TK      pr_Exports_CIMSDE_ExportCarrierTrackingInfo: Export tracking info for the shipments that are delivered until archived (BK-291)
  2021/02/27  TK      pr_Exports_CIMSDE_ExportCarrierTrackingInfo: Initial Revision (BK-203)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_CIMSDE_ExportCarrierTrackingInfo') is not null
  drop Procedure pr_Exports_CIMSDE_ExportCarrierTrackingInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Exports_CIMSDE_ExportCarrierTrackingInfo: Exports Carrier Tracking Info from CIMS to HOST
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_CIMSDE_ExportCarrierTrackingInfo
  (@BusinessUnit   TBusinessUnit = null,
   @UserId         TUserId       = null)
as
  declare @vReturnCode              TInteger,
          @vRecordType              TTypeCode,
          @vCarrierTrackingInfoXML  xml,

          @vMessage                 TNVarchar,
          @vSourceReference         TDescription,
          @vResultXML               TXML,
          @vTransferToDBMethod      TControlValue;
begin
begin try
  set NOCOUNT ON;

  /* Initialize */
  select @vRecordType = 'CTI' /* Carrier Tracking Info */;

  /* Get the Controls */
  select @vTransferToDBMethod = dbo.fn_Controls_GetAsString ('Exports', 'TransferToDBMethod',  'SQLDATA',  @BusinessUnit, @UserId);

  /* Fetch the Loads shipped today into XML */
  select @vRecordType as RecordType, CTI.TrackingNo, CTI.Carrier, CTI.LPN, CTI.PickTicket,
         CTI.DeliveryStatus, CTI.DeliveryDateTime, CTI.LastEvent, CTI.LastUpdateDateTime, CTI.LastLocation, CTI.ActivityInfo,
         OH.SourceSystem, CTI.BusinessUnit, CTI.CreatedBy, CTI.RecordId as CIMSRecId, 'N' as ExchangeStatus
  into ##CarrierTrackingInfo
                                     from CarrierTrackingInfo CTI
                                       join OrderHeaders OH on (CTI.OrderId = OH.OrderId)
  where (CTI.DeliveryStatus = 'Not Delivered') and
        (CTI.BusinessUnit   = @BusinessUnit) and
        (CTI.Archived = 'N' /* No */);

    /* If CIMSDE is not on the same server then generate XML for processing */
  if (@vTransferToDBMethod <> 'SQLDATA')
    begin
      /* Build xml here with the all open receipts in CIMS  */
      select @vCarrierTrackingInfoXML = (select * from ##CarrierTrackingInfo
                                     FOR XML PATH('TrackingInfo'), ROOT('CarrierTrackingInfo'));

  /* convert xml data to varchar */
      select @vResultXML = convert(varchar(max), @vCarrierTrackingInfoXML); -- not used anymore, will drop after testing
    end

  /* Push the list of Loads Shipped today into CIMSDE database */
  exec CIMSDE_pr_PushExportCarrierTrackingInfoFromCIMS @vCarrierTrackingInfoXML, @UserId, @BusinessUnit, @vTransferToDBMethod;

end try
begin catch
  /* log into Interface table with the failure message for tracking/Research */
  select @vMessage         = Error_Message(),
         @vSourceReference = Object_Name(@@ProcId);

  /* Save the exceptions to InterfaceLog tables so that users can be alerted of the failure */
  exec pr_InterfaceLog_SaveExceptions 'CIMS' /* Source System */, 'CIMSDE' /* Target System */,
                                      @vSourceReference, 'Export' /* Transfer Type */,
                                      'END' /* Process Type */, 'DB' /* RecordTypes */,
                                      @BusinessUnit, @vMessage;

  /* raise an exception if there is any */
  exec pr_ReRaiseError;

end catch;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_CIMSDE_ExportCarrierTrackingInfo */

Go
