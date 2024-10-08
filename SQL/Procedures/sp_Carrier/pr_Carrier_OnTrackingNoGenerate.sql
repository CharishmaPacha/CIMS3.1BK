/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Carrier_OnTrackingNoGenerate') is not null
  drop Procedure pr_Carrier_OnTrackingNoGenerate;
Go
/*------------------------------------------------------------------------------
  Proc pr_Carrier_OnTrackingNoGenerate: When tracking no has been generated for
    an LPN or Order, we may have to do some follow up things and this procedure
    takes care of them with the info in #Packages.

  #Packages: TCarrierResponseData
------------------------------------------------------------------------------*/
Create Procedure pr_Carrier_OnTrackingNoGenerate
  (@BusinessUnit         TBusinessUnit,
   @UserId               TUserId
  )
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vRecordId              TRecordId,
          @vLPNId                 TRecordId,
          @vLPN                   TLPN,
          @vLPNStatus             TStatus,
          @vAutoShipOnLabel       TFlag,
          @vLabelType             TTypeCode,
          @vTrackingNo            TTrackingNo,
          @vLabelImage            varbinary(max),
          @vZPLLabel              TVarchar;

begin /* pr_Carrier_OnTrackingNoGenerate */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Update LPN with latest tracking no */
  update L
  set TrackingNo  = PKG.TrackingNo
  from LPNs L
    join #Packages PKG on (PKG.EntityId = L.LPNId)
  where (PKG.LabelType = 'S' /* ShipLabel */)

  /* status update on Labeling the LPN and the order of the Shipped LPN */
  select @vAutoShipOnLabel = dbo.fn_Controls_GetAsBoolean('Shipping', 'AutoShipLPNOnLabel', 'N', @BusinessUnit, @UserId);

  if (@vAutoShipOnLabel =  'Y' /* Yes */) goto ExitHandler;

  while (exists (select * from #Packages where RecordId > @vRecordId))
    begin
      select top 1
             @vRecordId       = RecordId,
             @vLPNId          = EntityId,
             @vLPN            = EntityKey,
             @vLPNStatus      = LPNStatus,
             @vLabelType      = LabelType,
             @vTrackingNo     = TrackingNo,
             @vLabelImage     = Label,
             @vZPLLabel       = ZPLLabel
      from #Packages
      where (RecordId > @vRecordId);

      /* Ignore if LPN is already shipped */
      if (@vLPNStatus = 'S' /* Shipped */) continue;

      /* if we do not have a TrackingNo and label, ignore and continue with next one */
      if (coalesce(@vTrackingNo, '') = '')  or
         ((@vLabelImage is null) and (@vZPLLabel is null)) continue;

      exec pr_Entities_ExecuteInBackGround 'LPN', @vLPNId, @vLPN, default /* ProcessClass */,
                                             @@ProcId, 'LPNAutoShip'/* Operation */, @BusinessUnit;
    end /* while */

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Carrier_OnTrackingNoGenerate */

Go
