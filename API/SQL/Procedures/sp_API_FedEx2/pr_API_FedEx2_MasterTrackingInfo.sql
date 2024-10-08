/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/02/12  AY      Initial Version (CIMSV3-3395)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx2_MasterTrackingInfo') is not null
  drop Procedure pr_API_FedEx2_MasterTrackingInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx2_MasterTrackingInfo:
  This procedure retrieves the master tracking information for the shipment and the
  number of packages in that shipment.

  Note that an Order can be more than one shipment, so the PackageCount here is not
  the packages of the Order, but when the shipment was first created by Carrier.
  Say The order is partially allocated and  then completely picked and packaged.
  We may generate labels (considered as a shipment) with 5. packages. Trackin no for
  the first one of the packages in this shipment of 5 packages would be considered
  the master Tracking number. The subsequent ones would have a reference to the master
  tracking no.

  Later, say the same order is reallocated and more units picked and packed into another
  carton. This new carton would not be part of the prior shipemnt. It would not
  have a reference of the Master tracking no and it would be an individual shipment.

  In esseence, the package count (if we consider the Order is 6) but for the last carton
  we consider it as a shipment of 1 package only where as for the first 5 packages, they
  are considered as part of 5 packages. This information is hence saved and returned from
  Shiplabels to be used for later logic.

  Sample:
  "masterTrackingId": {
    "formId": "0201",
    "trackingIdType": "EXPRESS",
    "uspsApplicationId": "92",
    "trackingNumber": "49092000070120032835"
  }
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx2_MasterTrackingInfo
  (@TransactionRecordId    TRecordId,
   @OrderId                TRecordId,
   @LPNId                  TRecordId,
   @BusinessUnit           TBusinessUnit,
   @UserId                 TUserId,
   @PackageCount           TInteger  output,
   @MasterTrackingJSON     TNVarchar output)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          /* Package info */
          @vPackageSeqNo               TInteger,
          @vNotifications              TString,
          /* Tracking Info */
          @vCarrier                    TCarrier,
          @vMasterTrackingNo           TTrackingNo;

begin /* pr_API_FedEx2_MasterTrackingInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  /* Get the MasterPackage PackageCount based on PackageSeqNo */
  select @PackageCount      = coalesce(SL.TotalPackages, @PackageCount),
         @vMasterTrackingNo = L.TrackingNo,
         @vNotifications    = SL.Notifications
  from ShipLabels SL
    join LPNs L on (SL.EntityId = L.LPNId) and (L.PackageSeqNo = '1')
  where (SL.OrderId = @OrderId) and (SL.Status = 'A');

  /* Get the package seq no for the package we are generating label for */
  select @vPackageSeqNo = PackageSeqNo
  from #CarrierPackageInfo
  where (LPNId = @LPNId);

  /* To facilitate a multi-package shipment, the initial package's tracking number should be designated as
     the master tracking number for the remaining packages. However, if this is the first package
     or if this is an additional package beyond the original packagecount, thne generate it independently
     and so it won't have a master tracking no */
  if (@vPackageSeqNo = 1) or (@vPackageSeqno > @PackageCount)
    return;

  /* When there is no master tracking no for an order for whatever reason, we
      cannot process other packages either and have to cancel them */
  if (coalesce(@vMasterTrackingNo, '') = '')
    begin
      /* Update the error message of master tracking number */
      update APIOT
      set APIOT.TransactionStatus = 'Canceled',
          APIOT.ProcessStatus     = 'Canceled',
          APIOT.ProcessMessage    = 'Master TrackingNo not yet generated. Reason: ' + @vNotifications
      from APIOutboundTransactions APIOT
      where (APIOT.RecordId = @TransactionRecordId);

      /* Update the reason for not generate the ship label */
      update SL
      set SL.ProcessStatus = 'LGE',
          SL.Notifications = 'ERROR: Master TrackingNo not yet generated. Reason: ' + @vNotifications
      from ShipLabels SL
      where (SL.EntityId = @LPNId) and (SL.EntityType = 'L' /* LPN */) and (SL.Status = 'A');

      set @vReturnCode = 1;
      goto ExitHandler;
    end

  /* Build JSON with master tracking number */
  select @MasterTrackingJSON = (select trackingIdType = @vCarrier,
                                       trackingNumber = @vMasterTrackingNo
                                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx2_MasterTrackingInfo */

Go
