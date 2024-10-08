/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/03/21  VS      pr_API_UPS_ProcessShipmentResponse: Get the Response Code and Description (BK-1100)
  2021/07/01  RV      pr_API_UPS_ProcessShipmentResponse: Bug fixed to capture the notifications
  2021/06/14  RV      pr_API_UPS_ProcessShipmentResponse: Made changes to rotate the label image based upon label type (CIMSV3-1509)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_ProcessShipmentResponse') is not null
  drop Procedure pr_API_UPS_ProcessShipmentResponse;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_ProcessShipmentResponse: Once UPS API is invoked, we would get
    a response back from UPS which would be saved in the APIOutboundTransaction
    table and the RecordId passed to this procedure for processing the response.
    Process shipment response and save shipment data
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_ProcessShipmentResponse
  (@TransactionRecordId   TRecordId)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,
          @vTranCount                   TCount,

          @vShipmentRequestXML          XML,
          @vResponseStatusCode          TStatus,
          @vNotification                TVarChar,
          @vReference                   TVarChar,
          @vAlerts                      TVarChar,
          @vErrors                      TvarChar,
          @vListNetCharge               TDescription,
          @vAcctNetCharge               TDescription,

          @vLabelImageType              TTypeCode,
          @vLabelRotation               TDescription,

          @vPackagesCount               TCount,
          @vTrackingNo                  TTrackingNo,
          @vTrackingBarcode             TTrackingNo,
          @vLabelImage                  TNVarchar,
          @vRotatedLabelImage           TNVarchar,

          @vRawResponse                 TVarchar,
          @vShippingData                TXML,
          @vBusinessUnit                TBusinessUnit;

declare @ttPackageLabelInfo table(RecordId        TRecordId identity(1,1),
                                  TrackingNo      TTrackingNo,
                                  TrackingBarcode TTrackingNo,
                                  LabelImage      TNVarchar);

begin /* pr_API_UPS_ProcessShipmentResponse */
begin try
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vTranCount    = @@trancount,
         @vReference    = '',
         @vNotification = '',
         @vAlerts       = '',
         @vErrors       = '';

  if (@vTranCount = 0) begin transaction;

  /* Get Raw response and shipment request from APIoutbound transaction */
  select @vRawResponse        = RawResponse,
         @vShipmentRequestXML = UDF1
  from APIOutboundTransactions
  where (RecordId = @TransactionRecordId);

  /* Extract required data from XML */
  select @vLabelImageType = Record.Col.value('(LABELATTRIBUTES/LabelImageType)[1]', 'TTypeCode'),
         @vLabelRotation  = Record.Col.value('(LABELATTRIBUTES/LabelRotation)[1]',  'TDescription')
  from @vShipmentRequestXML.nodes('/SHIPPINGINFO/REQUEST') Record(Col)
  OPTION (OPTIMIZE FOR (@vShipmentRequestXML = null));

  /* Parse the response code and notifications from response json */
  select @vResponseStatusCode = json_value(@vRawResponse, '$.ShipmentResponse.Response.ResponseStatus.Code');
  select @vNotification       = 'Status Code/Desc: ' + @vResponseStatusCode + '/' +
                                                     + json_value(@vRawResponse, '$.ShipmentResponse.Response.ResponseStatus.Description') + ' ';

  select @vAlerts += [Code] + '/' + [Description] + '; '
  from openjson( @vRawResponse, '$.ShipmentResponse.Response.Alert' )
  with ([Code] TNvarchar '$.Code', [Description] TNvarchar '$.Description');

  select @vNotification += coalesce('Alerts Code/Desc: ' + @vAlerts, '');

  /* If response code is 1 then the request is success, otherwise error in shipment request */
  if (@vResponseStatusCode = '1')
    begin
      /* Save Disclaimers in Reference */
      select  @vReference = 'Disclaimer Code/Desc: ' + Code + '/' + Description
      from OPENJSON (@vRawResponse, '$.ShipmentResponse.ShipmentResults.Disclaimer')
         with
         (
           Code         TTrackingNo    '$.Code',
           Description  nvarchar(max)  '$.Description'
         );

      /* Get Packages count from shipment request */
      select @vPackagesCount = max(@vShipmentRequestXML.value('count(/SHIPPINGINFO/RESPONSE/PACKAGES/PACKAGE)', 'int'));

      /* Insert the packages label info from response json */
      insert into @ttPackageLabelInfo (TrackingNo, TrackingBarcode, LabelImage)
        select  TrackingNumber, USPSPICNumber, GraphicImage
          from OPENJSON (@vRawResponse, '$.ShipmentResponse.ShipmentResults.PackageResults')
          with
          (
            TrackingNumber TTrackingNo    '$.TrackingNumber',
            USPSPICNumber  TTrackingNo    '$.USPSPICNumber',
            GraphicImage   nvarchar(max)  '$.ShippingLabel.GraphicImage'
          );

      /* Loop through all packages to modify the tracking number and LabelImage (ZPL) */
      while (@vPackagesCount > 0)
        begin
          select @vTrackingNo      = TrackingNo,
                 @vTrackingBarcode = TrackingBarcode,
                 @vLabelImage      = LabelImage
          from @ttPackageLabelInfo
          where (RecordId = @vPackagesCount);

          /* For other than ZPL image type like png, gif rotate based upon the label rotation if required by using CLR method */
          if (@vLabelImageType <> 'ZPL') and (coalesce(@vLabelRotation, '') <> '')
            exec pr_CLR_RotateBase64Image @vLabelImage, @vLabelRotation, @vRotatedLabelImage out;

          /* Get rotated image if exists */
          select @vLabelImage = coalesce(@vRotatedLabelImage, @vLabelImage);

          /* Update the tracking number on the response xml */
          set @vShipmentRequestXML.modify
          ('replace value of ((/SHIPPINGINFO/RESPONSE/PACKAGES/PACKAGE/TRACKINGNO)[sql:variable("@vPackagesCount")]/text())[1]
            with sql:variable("@vTrackingNo")')

          /* Update the tracking barcode on the response xml */
          if (coalesce(@vTrackingBarcode, '') <> '')
            set @vShipmentRequestXML.modify
            ('replace value of ((/SHIPPINGINFO/RESPONSE/PACKAGES/PACKAGE/TRACKINGBARCODE)[sql:variable("@vPackagesCount")]/text())[1]
              with sql:variable("@vTrackingBarcode")')

          /* Update the Label image on the response xml */
          set @vShipmentRequestXML.modify
          ('replace value of ((/SHIPPINGINFO/RESPONSE/PACKAGES/PACKAGE/IMAGELABEL)[sql:variable("@vPackagesCount")]/text())[1]
            with sql:variable("@vLabelImage")')

          set @vPackagesCount = @vPackagesCount - 1;
        end
    end
  else
    /* Request was not successful */
    begin
      /* Get all Response.errors into Notifications */
      select @vErrors += [code] + '/' + [Message] + '; '
      from openjson( @vRawResponse, '$.response.errors' )
      with ([code] TNvarchar '$.code', [Message] TNvarchar '$.message');

      /* SaveShipmentData looks for the 'Error' in Notifications to determine if the request was successful or
         not, so add it */
      select @vNotification = coalesce(@vNotification, '') + 'Error (Code/Message): ' +  @vErrors;
    end

  select @vListNetCharge = coalesce(json_value(@vRawResponse, '$.ShipmentResponse.ShipmentResults.ShipmentCharges.TotalCharges.MonetaryValue'), '0.0');
  select @vAcctNetCharge = coalesce(json_value(@vRawResponse, '$.ShipmentResponse.ShipmentResults.NegotiatedRateCharges.TotalCharge.MonetaryValue'), '0.0');

  /* Modify the ListNet and AcctNet charges in shipment XML, Reference and notifications */
  set @vShipmentRequestXML.modify('replace value of (/SHIPPINGINFO/RESPONSE/LISTNETCHARGES/text())[1] with sql:variable("@vListNetCharge")');
  set @vShipmentRequestXML.modify('replace value of (/SHIPPINGINFO/RESPONSE/ACCTNETCHARGES/text())[1] with sql:variable("@vAcctNetCharge")');
  set @vShipmentRequestXML.modify('replace value of (/SHIPPINGINFO/RESPONSE/REFERENCES/text())[1] with sql:variable("@vReference")');
  set @vShipmentRequestXML.modify('replace value of (/SHIPPINGINFO/RESPONSE/NOTIFICATIONS/text())[1] with sql:variable("@vNotification")');

  /* Save the shipment response in ship labels table */
  select @vShippingData = cast(@vShipmentRequestXML as varchar(max));
  exec pr_Shipping_SaveShipmentData null, null, null, null, @vShippingData;

  if (@vTranCount = 0) commit transaction;
end try
begin catch
  /* if there is an error, then rollback */
  if (@@trancount > 0) rollback transaction

  exec @vReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_ProcessShipmentResponse */

Go
