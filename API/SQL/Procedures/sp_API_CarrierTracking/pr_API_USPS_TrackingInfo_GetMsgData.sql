/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  pr_API_UPS_TrackingInfo_GetMsgData, pr_API_USPS_TrackingInfo_GetMsgData
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_USPS_TrackingInfo_GetMsgData') is not null
  drop Procedure pr_API_USPS_TrackingInfo_GetMsgData;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_USPS_TrackingInfo_GetMsgData: generates Message data in the format required by USPS Carrier
------------------------------------------------------------------------------*/
Create Procedure pr_API_USPS_TrackingInfo_GetMsgData
  (@IntegrationName    TName,
   @MessageType        TName,
   @EntityType         TTypeCode,
   @EntityId           TRecordId,
   @EntityKey          TEntityKey,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @MessageData        TVarchar   output)
as
  declare @vReturnCode                  TInteger,
          @vMessageName                 TMessageName,
          @vMessage                     TMessage,

          @vUserId                      TUserId,
          @vRawResponse                 TVarchar,
          @vBusinessUnit                TBusinessUnit;

begin /* pr_API_UPS_TrackingInfo_GetMsgData */
  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get UserId from Shipping accounts */
  select @vUserId = UserId
  from ShippingAccounts
  where (Carrier = 'USPS');

  /* Build Message Type */
  select @MessageData = 'XML=<TrackFieldRequest USERID="' + @vUserId + '">' +
                              '<Revision>1</Revision>
                              <ClientIp>122.3.3</ClientIp>
                              <SourceId>CIMS API</SourceId>
                              <TrackID ID="' + TrackingNo + '"/>' +
                              '</TrackFieldRequest>'
  from LPNs
  where (LPNId = @EntityId);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_USPS_TrackingInfo_GetMsgData */

Go
