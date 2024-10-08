/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/08/18  RV      Made changes to use the CIMSFEDEX2 integration for carrier FedEx (BK-1132)
  2023/02/13  SK      pr_API_*_TrackingInfo_ProcessResponse: Enhanced to be able to update records to send exports of tracking response
                      pr_API_RequestTrackingInfo: Change reverted (BK-1010)
  2022/11/12  SK      pr_API_RequestTrackingInfo: Enhanced to be able to update records to send exports of tracking response (BK-956)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_RequestTrackingInfo') is not null
  drop Procedure pr_API_RequestTrackingInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_RequestTrackingInfo generates API outbound transaction for the shipments in
    CarrierTrackingInfo that are not delivered yet
------------------------------------------------------------------------------*/
Create Procedure pr_API_RequestTrackingInfo
  (@Carrier            TCarrier,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vOperation              TOperation,

          @vWaveId                 TRecordId,
          @vWaveNo                 TWaveNo,
          @vWavePickMethod         TPickMethod;

  declare @ttCTRecords             TEntityKeysTable;
begin /* pr_API_RequestTrackingInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get the records to be inserted for outbound processing */
  insert into @ttCTRecords (EntityId)
    select CTI.RecordId
    from CarrierTrackingInfo CTI
    where (CTI.Carrier = coalesce(@Carrier, CTI.Carrier)) and
          (CTI.BusinessUnit   = @BusinessUnit) and
          (CTI.DeliveryStatus = 'Not Delivered');

  /* Generate outbound tracking request
     For FedEx using CIMSFEDEX2 integration */
  insert into APIOutboundTransactions (IntegrationName, MessageType, EntityType, EntityId, EntityKey, BusinessUnit, CreatedBy)
    select concat('CIMS', CTI.Carrier, iif(CTI.Carrier = 'FEDEX', '2', null)), CTI.Carrier + 'Tracking', 'LPN', CTI.LPNId, CTI.LPN, @BusinessUnit, @UserId
    from @ttCTRecords TT
      join CarrierTrackingInfo CTI on TT.EntityId = CTI.RecordId;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_RequestTrackingInfo */

Go
