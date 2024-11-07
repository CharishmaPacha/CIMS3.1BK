/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/10/30  RV      Initial Version (BK-1148)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS2_TrackingInfo_GetMsgData') is not null
  drop Procedure pr_API_UPS2_TrackingInfo_GetMsgData;
Go
/*------------------------------------------------------------------------------
  pr_API_UPS2_TrackingInfo_GetMsgData: Generates Message data in the format
   required by UPS API Tracking Info. This is the highest level procedure called
   when the API outbound transactions are being prepared to invoke the external API.
   This proc formats the data for Tracking Info Request as expected by UPS.
   The Tracking info could be for LPN.

   Note: For now, we are sending the tracking info request by LPN. In the future,
         we may send it for all the LPNs in the order

  Document Ref: https://developer.ups.com/api/reference?loc=en_US#tag/Tracking
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS2_TrackingInfo_GetMsgData
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

          /* Processing variables */
          @vEntityId            TRecordId,
          @vEntityKey           TEntityKey,
          @vEntityType          TTypeCode,
          @vDebug               TFlags,
          @vBusinessUnit        TBusinessUnit,
          @vUserId              TUserId;

begin /* pr_API_UPS2_TrackingInfo_GetMsgData */
  /* Initialize */
  select @vReturnCode           = 0,
         @vMessageName          = null,
         @vRecordId             = 0;

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
  /* Create temp table without identity column */
  select * into #ShippingAccountDetails from ShippingAccounts where (1 = 2)
  union all
  select * from ShippingAccounts where (1 <> 1);

  /* Build Rules data */
  select @vRulesDataXML = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('Carrier',    'UPS') +
                            dbo.fn_XMLNode('Operation',  'TrackingInfo'));

  /* Identify the shipping account to use and load details into #ShippingAccountDetails */
  exec pr_Carrier_GetShippingAccountDetails @vRulesDataXML, null, @vBusinessUnit, @vUserId;

  /* Update the APIOT header info with token */
  exec pr_API_UPS2_UpdateHeaderInfo @TransactionRecordId, @vBusinessUnit;

  select @MessageData = TrackingNo
  from LPNs
  where (LPNId = @vEntityId);

  /* Log the Marker Details */
  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'End_UPS_TrackingInfo', @@ProcId, @vLPNId;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log default, 'LPN', @vLPNId, null, 'API_UPS_TrackingInfo', @@ProcId, 'Markers_UPS_TrackingInfo', @vUserId, @vBusinessUnit;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS2_TrackingInfo_GetMsgData */

Go