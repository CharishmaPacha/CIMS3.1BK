/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/04  MS      pr_OrderHeaders_ExportStatus: New proc to send PTStatus (BK-278)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_ExportStatus') is not null
  drop Procedure pr_OrderHeaders_ExportStatus;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_ExportStatus: Exports the status of the given wave or order
    or the orders in the # table as given in @TempTableName.
    ReasonCode denotes the even that happened. Reference has the actual Status of
    the Order.

  #(@TempTableName) : TEntityKeysTable or a table that has EntityId and EntityKey
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_ExportStatus
  (@WaveId          TRecordId,
   @OrderId         TRecordId,
   @ReasonCode      TReasonCode,
   @TempTableName   TName,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vRecordId         TRecordId,
          @vSQL              TSQL;

  declare @ttOrdersToExport  TEntityKeysTable;
begin

  if (@OrderId is not null)
    insert into @ttOrdersToExport (EntityId, EntityKey)
      select OrderId, PickTicket from OrderHeaders where (OrderId = @OrderId);
  else
  if (@WaveId is not null)
    insert into @ttOrdersToExport (EntityId, EntityKey)
      select OrderId, PickTicket from OrderHeaders where (PickBatchId = @WaveId);
  else
  if (@TempTableName is not null)
    begin
      select @vSQL = 'select distinct EntityId, EntityKey from ' + @TempTableName;

      insert into @ttOrdersToExport (EntityId, EntityKey)
        exec sp_executesql @vSQL;
    end

  if (@ReasonCode is null)
    select @ReasonCode = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'OrderStatusUpdate', 'OSU' /* CIMS Default */, @BusinessUnit, @UserId);

  /* Build temp table which is image of the Exports table */
  create table #ExportRecords (ExpRecordId int identity(1, 1) not null);
  exec pr_PrepareHashTable 'Exports', '#ExportRecords';

  /* Insert OH info into #ExportRecords */
  insert into #ExportRecords (TransType, TransEntity, OrderId, Ownership, Warehouse, SourceSystem,
                              ShipVia, SoldToId, ShipToId, Weight, Volume, ReasonCode, Reference, BusinessUnit)
    select 'PTStatus', 'OH', OrderId, Ownership, Warehouse, SourceSystem,
           ShipVia, SoldToId, ShipToId, TotalWeight, TotalVolume, @ReasonCode,
           dbo.fn_Status_GetDescription('Order', Status, @BusinessUnit), BusinessUnit
    from OrderHeaders OH join @ttOrdersToExport OTE on OH.OrderId = OTE.EntityId;

  exec pr_Exports_InsertRecords 'PTStatus', 'OH' /* TransEntity */, @BusinessUnit;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_ExportStatus */

Go
