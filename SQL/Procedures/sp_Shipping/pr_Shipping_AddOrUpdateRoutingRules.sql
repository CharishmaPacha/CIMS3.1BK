/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/04/03  VM      pr_Shipping_AddOrUpdateRoutingRules: Added Comments (S2G-564)
  2018/03/26  VM      Added pr_Shipping_AddOrUpdateRoutingRules, pr_Shipping_AddOrUpdateRoutingZones (S2G-496)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_AddOrUpdateRoutingRules') is not null
  drop Procedure pr_Shipping_AddOrUpdateRoutingRules;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_AddOrUpdateRoutingRules:
    This proc will add a new routing rule or Update an existing rule with new values.
    Assumes that all other validations done by caller or from UI.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_AddOrUpdateRoutingRules
  (@SoldToId             TCustomerId,
   @ShipToId             TShipToId,
   @Account              TAccount,

   @ShipToZone           TName,
   @ShipToState          TState,
   @ShipToZipStart       TZip,
   @ShipToZipEnd         TZip,
   @ShipToCountry        TCountry,
   @ShipToAddressRegion  TDescription,

   @InputCarrier         TCarrier,
   @InputShipVia         TShipVia,
   @InputFreightTerms    TDescription,

   @MinWeight            TWeight,
   @MaxWeight            TWeight,

   @DeliveryRequirement  TDescription,

   @ShipFrom             TShipFrom,
   @Ownership            TOwnership,
   @Warehouse            TWarehouse,

   @Criteria1            TDescription,
   @Criteria2            TDescription,
   @Criteria3            TDescription,
   @Criteria4            TDescription,
   @Criteria5            TDescription,

   @ShipVia              TShipVia,
   @FreightTerms         TDescription,
   @BillToAccount        TBillToAccount,

   @Comments             TVarChar,

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
      insert into RoutingRules(SoldToId,
                               ShipToId,
                               Account,
                               ShipToZone,
                               ShipToState,
                               ShipToZipStart,
                               ShipToZipEnd,
                               ShipToCountry,
                               ShipToAddressRegion,
                               InputCarrier,
                               InputShipVia,
                               InputFreightTerms,
                               MinWeight,
                               MaxWeight,
                               DeliveryRequirement,
                               ShipFrom,
                               Ownership,
                               Warehouse,
                               Criteria1,
                               Criteria2,
                               Criteria3,
                               Criteria4,
                               Criteria5,
                               ShipVia,
                               FreightTerms,
                               BillToAccount,
                               Comments,
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
                        select @SoldToId,
                               @ShipToId,
                               @Account,
                               @ShipToZone,
                               @ShipToState,
                               @ShipToZipStart,
                               @ShipToZipEnd,
                               @ShipToCountry,
                               @ShipToAddressRegion,
                               @InputCarrier,
                               @InputShipVia,
                               @InputFreightTerms,
                               @MinWeight,
                               @MaxWeight,
                               @DeliveryRequirement,
                               @ShipFrom,
                               @Ownership,
                               @Warehouse,
                               @Criteria1,
                               @Criteria2,
                               @Criteria3,
                               @Criteria4,
                               @Criteria5,
                               @ShipVia,
                               @FreightTerms,
                               @BillToAccount,
                               @Comments,
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
      update RoutingRules
      set SoldToId             = @SoldToId,
          ShipToId             = @ShipToId,
          Account              = @Account,
          ShipToZone           = @ShipToZone,
          ShipToState          = @ShipToState,
          ShipToZipStart       = @ShipToZipStart,
          ShipToZipEnd         = @ShipToZipEnd,
          ShipToCountry        = @ShipToCountry,
          ShipToAddressRegion  = @ShipToAddressRegion,
          InputCarrier         = @InputCarrier,
          InputShipVia         = @InputShipVia,
          InputFreightTerms    = @InputFreightTerms,
          MinWeight            = @MinWeight,
          MaxWeight            = @MaxWeight,
          DeliveryRequirement  = @DeliveryRequirement,
          ShipFrom             = @ShipFrom,
          Ownership            = @Ownership,
          Warehouse            = @Warehouse,
          Criteria1            = @Criteria1,
          Criteria2            = @Criteria2,
          Criteria3            = @Criteria3,
          Criteria4            = @Criteria4,
          Criteria5            = @Criteria5,
          ShipVia              = @ShipVia,
          FreightTerms         = @FreightTerms,
          BillToAccount        = @BillToAccount,
          Comments             = @Comments,
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
end /* pr_Shipping_AddOrUpdateRoutingRules */

Go
