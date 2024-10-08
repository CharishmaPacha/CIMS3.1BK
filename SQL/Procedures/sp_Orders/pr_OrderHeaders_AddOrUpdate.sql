/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/05/18  VS      pr_OrderHeaders_AddOrUpdate: Changes made for the Consolidate Orders (CID-334)
  2017/08/23  SV      pr_OrderHeaders_AddOrUpdate: Included UDF11 to UDF30 (OB-548)
  2013/09/16  PK      pr_OrderHeaders_AddOrUpdate, pr_OrderHeaders_SetStatus: Changes related to the change of Order Status Code.
                      pr_OrderHeaders_AddOrUpdate: Allow null for SoldToId
  2012/05/24  PK      pr_OrderHeaders_AddOrUpdate: Added Warehouse as it is a not null column.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_AddOrUpdate') is not null
  drop Procedure pr_OrderHeaders_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_AddOrUpdate:
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_AddOrUpdate
  (@PickTicket        TPickTicket,
   @SalesOrder        TSalesOrder,
   @OrderType         TOrderType,
   @Status            TStatus,
   @OrderDate         TDateTime,
   @DesiredShipDate   TDateTime,
   @Priority          TPriority,
   @SoldToId          TCustomerId,
   @ShipToId          TShipToId,
   @ShipVia           TShipVia,
   @ShipFrom          TShipFrom,
   @CustPO            TCustPO,
   @Ownership         TOwnership,
   @Warehouse         TWarehouse,
   @UDF1              TUDF = null,
   @UDF2              TUDF = null,
   @UDF3              TUDF = null,
   @UDF4              TUDF = null,
   @UDF5              TUDF = null,
   @UDF6              TUDF = null,
   @UDF7              TUDF = null,
   @UDF8              TUDF = null,
   @UDF9              TUDF = null,
   @UDF10             TUDF = null,
   @UDF11             TUDF = null,
   @UDF12             TUDF = null,
   @UDF13             TUDF = null,
   @UDF14             TUDF = null,
   @UDF15             TUDF = null,
   @UDF16             TUDF = null,
   @UDF17             TUDF = null,
   @UDF18             TUDF = null,
   @UDF19             TUDF = null,
   @UDF20             TUDF = null,
   @UDF21             TUDF = null,
   @UDF22             TUDF = null,
   @UDF23             TUDF = null,
   @UDF24             TUDF = null,
   @UDF25             TUDF = null,
   @UDF26             TUDF = null,
   @UDF27             TUDF = null,
   @UDF28             TUDF = null,
   @UDF29             TUDF = null,
   @UDF30             TUDF = null,
   @BusinessUnit      TBusinessUnit,
   ------------------------------------
   @OrderId           TRecordId output,
   @CreatedDate       TDateTime = null output,
   @ModifiedDate      TDateTime = null output,
   @CreatedBy         TUserId   = null output,
   @ModifiedBy        TUserId   = null output)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription;

  declare @Inserted table (OrderId TRecordId, CreatedDate TDateTime, CreatedBy TUserId);
begin
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null,
         @Status      = coalesce(@Status, 'N' /* New/Initial */);

  /*  Validate PickTicket */
  if(@PickTicket is null)
    set @MessageName = 'PickTicketIsInvalid';
  else
  /* Validate SalesOrder */
  if(@SalesOrder is null)
    set @MessageName = 'SalesOrderIsInvalid';
  else
  if (@OrderType is null)
    set @MessageName = 'OrderTypeIsInvalid';
  else
  if (not exists(select *
                 from EntityTypes
                 where (TypeCode = @OrderType) and
                       (Entity   = 'Order') and
                       (Status   = 'A' /* Active */)))
    set @MessageName = 'OrderTypeDoesNotExist';
  else
  /* Validating SoldToId */
  if ((coalesce(@SoldToId, '') <> '') and
      (@OrderType not in ('B'/* Bulk */, 'R', 'RU', 'RP' /* Replenish */)) and
      (not exists(select *
                  from Customers
                  where (CustomerId = @SoldToId) and
                        (Status     = 'A' /* Active */))))

    set @MessageName = 'CustomerDoesNotExist';
  else
  if ((coalesce(@ShipToId, '') <> '') and
      (@OrderType not in ('B'/* Bulk */, 'R', 'RU', 'RP' /* Replenish */)) and
      (not exists(select *
                  from vwShipToAddress
                  where (ShipToId = @ShipToId) and
                        (Status   = 'A' /* Active */))))
    set @MessageName = 'ShipToIdDoesNotExist';
  else
  if (@BusinessUnit is null)
    set @BusinessUnit = 'BusinessUnitIsInvalid';

  if (@MessageName is not null)
    goto ErrorHandler;

  if (not exists(select *
                 from OrderHeaders
                 where OrderId = @OrderId))
    begin
      insert into OrderHeaders(PickTicket,
                               SalesOrder,
                               OrderType,
                               Status,
                               OrderDate,
                               DesiredShipDate,
                               Priority,
                               SoldToId,
                               ShipToId,
                               ShipVia,
                               ShipFrom,
                               CustPO,
                               Ownership,
                               Warehouse,
                               UDF1,
                               UDF2,
                               UDF3,
                               UDF4,
                               UDF5,
                               UDF6,
                               UDF7,
                               UDF8,
                               UDF9,
                               UDF10,
                               UDF11,
                               UDF12,
                               UDF13,
                               UDF14,
                               UDF15,
                               UDF16,
                               UDF17,
                               UDF18,
                               UDF19,
                               UDF20,
                               UDF21,
                               UDF22,
                               UDF23,
                               UDF24,
                               UDF25,
                               UDF26,
                               UDF27,
                               UDF28,
                               UDF29,
                               UDF30,
                               BusinessUnit,
                               CreatedBy)
                        output inserted.OrderId, inserted.CreatedDate, inserted.CreatedBy
                          into @Inserted
                        select @PickTicket,
                               @SalesOrder,
                               @OrderType,
                               @Status,
                               coalesce(@OrderDate, current_timestamp),
                               @DesiredShipDate,
                               @Priority,
                               @SoldToID,
                               @ShipToID,
                               @ShipVia,
                               @ShipFrom,
                               @CustPO,
                               @Ownership,
                               @Warehouse,
                               @UDF1,
                               @UDF2,
                               @UDF3,
                               @UDF4,
                               @UDF5,
                               @UDF6,
                               @UDF7,
                               @UDF8,
                               @UDF9,
                               @UDF10,
                               @UDF11,
                               @UDF12,
                               @UDF13,
                               @UDF14,
                               @UDF15,
                               @UDF16,
                               @UDF17,
                               @UDF18,
                               @UDF19,
                               @UDF20,
                               @UDF21,
                               @UDF22,
                               @UDF23,
                               @UDF24,
                               @UDF25,
                               @UDF26,
                               @UDF27,
                               @UDF28,
                               @UDF29,
                               @UDF30,
                               @BusinessUnit,
                               coalesce(@CreatedBy, system_user);

      select @OrderId     = OrderId,
             @CreatedDate = CreatedDate,
             @CreatedBy   = CreatedBy
      from @Inserted;
    end
  else
    begin
      update OrderHeaders
      set
        Status        = @Status,
        Priority      = @Priority,
        SoldToID      = @SoldToID,
        ShipToID      = @ShipToID,
        ShipVia       = @ShipVia,
        ShipFrom      = @ShipFrom,
        CustPO        = @CustPO,
        Ownership     = @Ownership,
        Warehouse     = @Warehouse,
        UDF1          = @UDF1,
        UDF2          = @UDF2,
        UDF3          = @UDF3,
        UDF4          = @UDF4,
        UDF5          = @UDF5,
        UDF6          = @UDF6,
        UDF7          = @UDF7,
        UDF8          = @UDF8,
        UDF9          = @UDF9,
        UDF10         = @UDF10,
        UDF11         = @UDF11,
        UDF12         = @UDF12,
        UDF13         = @UDF13,
        UDF14         = @UDF14,
        UDF15         = @UDF15,
        UDF16         = @UDF16,
        UDF17         = @UDF17,
        UDF18         = @UDF18,
        UDF19         = @UDF19,
        UDF20         = @UDF20,
        UDF21         = @UDF21,
        UDF22         = @UDF22,
        UDF23         = @UDF23,
        UDF24         = @UDF24,
        UDF25         = @UDF25,
        UDF26         = @UDF26,
        UDF27         = @UDF27,
        UDF28         = @UDF28,
        UDF29         = @UDF29,
        UDF30         = @UDF30,
        @ModifiedDate = ModifiedDate = current_timestamp,
        @ModifiedBy   = ModifiedBy   = coalesce(@ModifiedBy, system_user)
      where OrderId = @OrderId
    end

ErrorHandler:
  if (@MessageName is not null)
  begin
    select @Message    = dbo.fn_Messages_GetDescription(@MessageName),
           @ReturnCode = 1;
    raiserror(@Message, 16, 1);
  end

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_OrderHeaders_AddOrUpdate */

Go
