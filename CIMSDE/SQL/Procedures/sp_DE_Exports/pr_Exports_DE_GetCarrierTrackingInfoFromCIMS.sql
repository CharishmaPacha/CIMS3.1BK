/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/20  VS      pr_Exports_DE_GetCarrierTrackingInfoFromCIMS: Made changes to improve the performance (BK-920)
  2021/02/27  TK      pr_Exports_DE_GetCarrierTrackingInfoFromCIMS: Initial Revision (BK-203)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Exports_DE_GetCarrierTrackingInfoFromCIMS') is not null
  drop Procedure pr_Exports_DE_GetCarrierTrackingInfoFromCIMS;
Go
/*------------------------------------------------------------------------------
  pr_Exports_DE_GetCarrierTrackingInfoFromCIMS: This procedure will returns the xml which contains
    all Carrier Tracking Info from CIMS

  ##CarrierTrackingInfo:  Defined in pr_Exports_CIMSDE_ExportCarrierTrackingInfo
------------------------------------------------------------------------------*/
Create Procedure pr_Exports_DE_GetCarrierTrackingInfoFromCIMS
  (@xmlCarrierTrackingInfo  XML,
   @UserId                  TUserId       = null,
   @BusinessUnit            TBusinessUnit = null,
   @TransferToDBMethod      TControlValue = null)
as
  declare @vReturnCode           TInteger,
          @vDocumentId           TInteger;
begin
  SET NOCOUNT ON;

  /* If CIMSDE is on the same sql instance, then fetch the data from the global table */
  if (@TransferToDBMethod = 'SQLDATA')
    begin
     insert into ExportCarrierTrackingInfo (TrackingNo, Carrier, LPN, PickTicket, DeliveryStatus, DeliveryDateTime, LastEvent, LastUpdateDateTime,
                                            LastLocation, ActivityInfo, SourceSystem, BusinessUnit, CreatedBy, CIMSRecId, ExchangeStatus)
       select TrackingNo, Carrier, LPN, PickTicket, DeliveryStatus, DeliveryDateTime, LastEvent, LastUpdateDateTime,
              LastLocation, ActivityInfo, SourceSystem, BusinessUnit, CreatedBy, CIMSRecId, ExchangeStatus
       from ##CarrierTrackingInfo
    end
  else
  /* If CIMSDE is not on the same server instance, an XML input data is sent */
  if (@xmlCarrierTrackingInfo is not null)
    begin
  /* Prepare xml document */
  exec sp_xml_preparedocument @vDocumentId output, @xmlCarrierTrackingInfo;

  /* load data into DE table export inventory from the given XML from CIMS */
  insert into ExportCarrierTrackingInfo (
    TrackingNo,
    Carrier,
    LPN,
    PickTicket,

    DeliveryStatus,
    DeliveryDateTime,

    LastEvent,
    LastUpdateDateTime,
    LastLocation,

    ActivityInfo,
    SourceSystem,
    BusinessUnit,
    CreatedBy,
    CIMSRecId,
    ExchangeStatus)
  select *,
         'N' as ExchangeStatus
  from openxml(@vDocumentId, '//CarrierTrackingInfo/TrackingInfo', 2)
  with (TrackingNo            TVarchar,
        Carrier               TCarrier,
        LPN                   TLPN,
        PickTicket            TPickTicket,

        DeliveryStatus        TStatus,
        DeliveryDateTime      TDateTime,

        LastEvent             TDescription,
        LastUpdateDateTime    TDateTime,
        LastLocation          TDescription,

        ActivityInfo          TVarchar,
        SourceSystem          TName,
        BusinessUnit          TBusinessUnit,
        CreatedBy             TUserId,
        CIMSRecId             TRecordId);

  /* Remove xml document */
  exec sp_xml_removedocument @vDocumentId;
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Exports_DE_GetCarrierTrackingInfoFromCIMS */

Go
