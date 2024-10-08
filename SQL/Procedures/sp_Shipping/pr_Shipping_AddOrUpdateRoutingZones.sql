/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/03/26  VM      Added pr_Shipping_AddOrUpdateRoutingRules, pr_Shipping_AddOrUpdateRoutingZones (S2G-496)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_AddOrUpdateRoutingZones') is not null
  drop Procedure pr_Shipping_AddOrUpdateRoutingZones;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_AddOrUpdateRoutingZones:
    This proc will add a new routing zones or Update an existing routing zone with new values.
    Assumes that all other validations done by caller or from UI.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_AddOrUpdateRoutingZones
  (@ZoneName             TName,

   @SoldToId             TCustomerId,
   @ShipToId             TShipToId,

   @ShipToCity           TCity,
   @ShipToState          TState,
   @ShipToZipStart       TZip,
   @ShipToZipEnd         TZip,
   @ShipToCountry        TCountry,

   @TransitDays          TInteger,
   @DeliveryRequirement  TDescription,

   @UDF1                 TUDF,
   @UDF2                 TUDF,
   @UDF3                 TUDF,
   @UDF4                 TUDF,
   @UDF5                 TUDF,

   @Status               TStatus,
   @SortSeq              TInteger,
   @BusinessUnit         TBusinessUnit,
   -----------------------------------------------
   @RecordId             TRecordId        output,
   @CreatedDate          TDateTime = null output,
   @ModifiedDate         TDateTime = null output,
   @CreatedBy            TUserId   = null output,
   @ModifiedBy           TUserId   = null output)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null,
         @Status      = coalesce(@Status, 'A' /* Active */);

  /* Need  Validations */
  if (@BusinessUnit is null)
    set @MessageName = 'InvalidBusinessUnit';

  if (@MessageName is not null)
    goto ErrorHandler;

  if (coalesce(@RecordId, 0) = 0)
    begin
      /*if RecordId is null then it will insert.Ie.. add new one.  */
      insert into RoutingZones(ZoneName,
                               SoldToId,
                               ShipToId,
                               ShipToCity,
                               ShipToState,
                               ShipToZipStart,
                               ShipToZipEnd,
                               ShipToCountry,
                               TransitDays,
                               DeliveryRequirement,
                               UDF1,
                               UDF2,
                               UDF3,
                               UDF4,
                               UDF5,
                               Status,
                               SortSeq,
                               BusinessUnit,
                               CreatedBy,
                               CreatedDate)
                        select @ZoneName,
                               @SoldToId,
                               @ShipToId,
                               @ShipToCity,
                               @ShipToState,
                               @ShipToZipStart,
                               @ShipToZipEnd,
                               @ShipToCountry,
                               @TransitDays,
                               @DeliveryRequirement,
                               @UDF1,
                               @UDF2,
                               @UDF3,
                               @UDF4,
                               @UDF5,
                               @Status,
                               @SortSeq,
                               @BusinessUnit,
                               coalesce(@CreatedBy,   System_user),
                               coalesce(@CreatedDate, current_timestamp);
    end
  else
    begin
      update RoutingZones
      set ZoneName             = @ZoneName,
          SoldToId             = @SoldToId,
          ShipToId             = @ShipToId,
          ShipToCity           = @ShipToCity,
          ShipToState          = @ShipToState,
          ShipToZipStart       = @ShipToZipStart,
          ShipToZipEnd         = @ShipToZipEnd,
          ShipToCountry        = @ShipToCountry,
          TransitDays          = @TransitDays,
          DeliveryRequirement  = @DeliveryRequirement,
          UDF1                 = @UDF1,
          UDF2                 = @UDF2,
          UDF3                 = @UDF3,
          UDF4                 = @UDF4,
          UDF5                 = @UDF5,
          Status               = @Status,
          SortSeq              = @SortSeq,
          BusinessUnit         = coalesce(@BusinessUnit,  BusinessUnit),
          ModifiedBy           = coalesce(@ModifiedBy,    System_User),
          ModifiedDate         = coalesce(@ModifiedDate,  current_timestamp)
      where(RecordId = @RecordId);
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  /* Handling transactions in case it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_Shipping_AddOrUpdateRoutingZones */

Go
