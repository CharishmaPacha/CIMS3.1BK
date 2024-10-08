/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/02/22  HB      pr_ShipLabels_Insert: Added EntityId (CIMS-2544)
  2018/07/11  RV      pr_ShipLabels_Insert: Updated ProcessedDateTime while saving shipping label in ShipLabels table (S2G-1021)
  2016/07/15  DK      pr_ShipLabels_Insert: Modified NetChargefield as ListNetChargefield (HPI-216).
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabels_Insert') is not null
  drop Procedure pr_ShipLabels_Insert;
Go
/*----------------------------------------------------------------------------------------------------------
 Proc pr_ShipLabels_Insert:   Inserts data provided into the "ShipLabels" based on the OrderNumber provided.
------------------------------------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabels_Insert
  (@EntityId        TRecordId,
   @EntityKey       TPallet,
   @TrackingNo      TTrackingNo,
   @Label           TShippingLabel,
   @ShipVia         TShipVia,
   @ListNetCharge   TMoney,
   @Reference       TVarChar,
   @Notifications   TVarChar,
   @BusinessUnit    TBusinessUnit,
   @CreatedBy       TUserId,
   @ModifiedBy      TUserId,
   @PickTicket      TPickTicket = null)
as
  declare @OrderId as TPickTicket;

begin
  set @OrderId = @PickTicket;

  if (@OrderId <> '')
    select @OrderId = OH.OrderId
    from OrderHeaders OH
    where (OH.PickTicket = @OrderId);

  insert into ShipLabels(EntityId, EntityKey, TrackingNo, Label, ShipVia, ListNetCharge, ProcessedDateTime, Reference, Notifications, BusinessUnit, CreatedBy, OrderId, PickTicket)
    select @EntityId, @EntityKey, @TrackingNo, @Label, @ShipVia, @ListNetCharge, current_timestamp, @Reference, @Notifications, @BusinessUnit, @CreatedBy, @OrderId, @PickTicket;
end /* pr_ShipLabels_Insert */

Go
