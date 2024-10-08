/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/08/10  RV      Initial version (BK-1132)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_TrackingInfo_GetMsgData') is not null
  drop Procedure pr_API_FedEx2_TrackingInfo_GetMsgData;
Go
/*------------------------------------------------------------------------------
  pr_API_FedEx2_TrackingInfo_GetMsgData: Generates Message data in the format
   required by FEDEX API Tracking Info. This is the highest level procedure called
   when the API outbound transactions are being prepared to invoke the external API.
   This proc formats the data for Tracking Info Request as expected by FEDEX.
   The Tracking info could be for LPN.

   Note: For now, we are sending the tracking info request by LPN. In the future,
         we may send it for all the LPNs in the order

  Document Ref: https://developer.fedex.com/api/en-us/catalog/track/v1/docs.html
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_TrackingInfo_GetMsgData
  (@TransactionRecordId  TRecordId,
   @MessageData          TVarchar   output)
as
  declare @vReturnCode         TInteger,
          @vMessageName        TMessageName,
          @vMessage            TMessage,
          @vRecordId           TRecordId,
          @vRulesDataXML       TXML,
          /* LPN Info */
          @vLPNId              TRecordId,
          @vLPN                TLPN,

          /* Order Info */
          @vShipVia             TShipVia,
          /* Processing variables */
          @vEntityId            TRecordId,
          @vEntityKey           TEntityKey,
          @vEntityType          TTypeCode,
          @vTrackingRequestJSON TNVarchar,
          @vOperation           TOperation,
          @vDebug               TFlags,
          @vBusinessUnit        TBusinessUnit,
          @vUserId              TUserId;

  declare @ttCarrierTrackingRequestData table
          (RecordId         TRecordId identity(1,1),
           LPNId            TRecordId,
           LPN              TLPN,
           OrderId          TRecordId,
           PickTicket       TPickTicket,
           TrackingNo       TTrackingNo);

begin /* pr_API_FedEx2_TrackingInfo_GetMsgData */
  /* Initialize */
  select @vReturnCode           = 0,
         @vMessageName          = null,
         @vRecordId             = 0,
         @vShipVia            = 'Track'; /* Initialize with Track to get the accounts for tracking */

  select @vEntityId     = EntityId,
         @vEntityKey    = EntityKey,
         @vEntityType   = EntityType,
         @vBusinessUnit = BusinessUnit
  from APIOutboundTransactions
  where (RecordId = @TransactionRecordId);

  /* If invalid recordid, exit */
  if (@@rowcount = 0)  return;

  exec pr_Debug_GetOptions @@ProcId, null /* Operation */, @vBusinessUnit, @vDebug output;
  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Start', @@ProcId;

  /*-------------------- Create hash tables --------------------*/
  if (object_id('tempdb..#CarrierTrackingRequestData') is null) select * into #CarrierTrackingRequestData from @ttCarrierTrackingRequestData;

  /* Create temp table without identity column */
  select * into #ShippingAccountDetails from ShippingAccounts where (1 = 2)
  union all
  select * from ShippingAccounts where (1 <> 1);

  if (@vEntityType = 'LPN')
    begin
      insert into #CarrierTrackingRequestData(LPNId, LPN, OrderId, PickTicket, TrackingNo)
        select LPNId, LPN, OrderId, PickTicketNo, TrackingNo
        from LPNs
        where (LPNId = @vEntityId);
    end
  else
  if (@vEntityType = 'Order')
    insert into #CarrierTrackingRequestData(LPNId, LPN, OrderId, PickTicket, TrackingNo)
      select LPNId, LPN, OrderId, PickTicketNo, TrackingNo
      from LPNs
      where (OrderId = @vEntityId);

  /* Build Rules data */
  select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('Carrier',          'FEDEX') +
                            dbo.fn_XMLNode('ShipVia',          @vShipVia) +
                            dbo.fn_XMLNode('Operation',        'TrackingInfo'));

  /* Identify the shipping account to use and load details into #ShippingAccountDetails */
  exec pr_Carrier_GetShippingAccountDetails @vRulesDataXML, null, @vBusinessUnit, @vUserId;

  /* Update the APIOT header info with token */
  exec pr_API_FedEx2_UpdateHeaderInfo @TransactionRecordId, @vBusinessUnit;

  /* ShipDateBegin and ShipDateEnd are recommended to narrow the search, reduce lookup time, and avoid duplicates
     when searching for a specific tracking number within a specific date range. Format: YYYY-MM-DD
     shipDateBegin: For now set it to three months from the current date
     shipDateEnd: For now set it to the current date */
  select @vTrackingRequestJSON = (select shipDateBegin                               = convert(varchar(10), dateadd(month, -3, getdate()), 23),
                                         shipDateEnd                                 = convert(varchar(10), getdate(), 23),
                                         [trackingNumberInfo.trackingNumber]         = TrackingNo,
                                         [trackingNumberInfo.trackingNumberUniqueId] = concat(@TransactionRecordId, '-', OrderId, '-', LPNId)
                                  from #CarrierTrackingRequestData
                                  FOR JSON PATH);

  /* Build Message Data
     IncludeDetailedScans: Indicates if detailed scans are requested or not. Valid values are True or False */
  select @MessageData =
    '{
       "includeDetailedScans": true,' +
       '"trackingInfo": ' + @vTrackingRequestJSON +
    '}';

  /* Log the Marker Details */
  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'End_FedEx_TrackingInfo', @@ProcId, @vLPNId;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log default, 'LPN', @vLPNId, @vLPN, 'API_FedEx_TrackingInfo', @@ProcId, 'Markers_FedEx_TrackingInfo', @vUserId, @vBusinessUnit;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_TrackingInfo_GetMsgData */

Go
