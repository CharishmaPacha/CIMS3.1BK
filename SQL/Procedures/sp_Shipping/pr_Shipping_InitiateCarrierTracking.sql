/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2023/02/23  SK      pr_Shipping_InitiateCarrierTracking: New value SourceSystem included (BK-1025)
  2022/10/12  VS      pr_Shipping_InitiateCarrierTracking: Initiate carrier tracking for FedEx carrier (BK-939)
  2022/10/11  TK      pr_Shipping_InitiateCarrierTracking: Do not initiate carrier tracking for FedEx carrier (BK-944)
  2021/10/07  TK      pr_Shipping_InitiateCarrierTracking: Initial Revision (BK-626)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_InitiateCarrierTracking') is not null
  drop Procedure pr_Shipping_InitiateCarrierTracking;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_InitiateCarrierTracking generates Tracking requests for the LPNs that are in
    Shipped today. This is used as an end of day process before archiving.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_InitiateCarrierTracking
  (@Operation          TOperation  = null,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,

          @vShippedDate            TDate;
begin /* pr_Shipping_InitiateCarrierTracking */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vShippedDate = convert(date, getdate()-1);

  /* Insert all the LPNs that are shipped thru a small package carrier and there is no record that already exists in
     CarrierTrackingInfo table */
  insert into CarrierTrackingInfo (TrackingNo, Carrier, LPNId, LPN, OrderId, PickTicket,
                                   WaveId, WaveNo, SourceSystem, BusinessUnit, CreatedBy)
    select L.TrackingNo, SV.Carrier, L.LPNId, L.LPN, OH.OrderId, OH.PickTicket,
           OH.PickBatchId, OH.PickBatchNo, OH.SourceSystem, @BusinessUnit, @UserId
    from LPNs L
      join OrderHeaders OH  on (L.OrderId = OH.OrderId)
      join ShipVias     SV  on (OH.ShipVia = SV.ShipVia) and
                               (OH.BusinessUnit = SV.BusinessUnit) and
                               (SV.IsSmallPackageCarrier = 'Y' /* Yes */)
      left outer join CarrierTrackingInfo CTI on (L.LPNId = CTI.LPNId)
   where (L.Archived =  'N' /* No */) and
         (L.Status = 'S' /* Shipped */) and
         (L.ModifiedOn >= @vShippedDate) and
         (CTI.RecordId is null);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_InitiateCarrierTracking */

Go
