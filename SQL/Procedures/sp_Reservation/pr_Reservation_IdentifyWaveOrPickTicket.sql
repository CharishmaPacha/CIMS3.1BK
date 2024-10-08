/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/11  TK      pr_Reservation_IdentifyWaveOrPickTicket & pr_Reservation_ValidateWaveOrPickTicket:
  2020/08/06  RIA     pr_Reservation_IdentifyWaveOrPickTicket: Changes to fetch valid values (HA-1263)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Reservation_IdentifyWaveOrPickTicket') is not null
  drop Procedure pr_Reservation_IdentifyWaveOrPickTicket;
Go
/*------------------------------------------------------------------------------
  Proc pr_Reservation_IdentifyWaveOrPickTicket: In LPN Reservation user can
   reserve against a Wave or a PickTicket, So, based upon the input given it is
   to be decided which one to reserve for - meaning - even if wave is given, we
   may still reserve against the PT.
   For example, if Wave is given and that wave has Bulk PT, then we reserve against
   the Bulk PT or if the Wave has only one order, we reserve against that Order.

   output:
   Entity             - 'PickTicket' or 'Wave'
   WaveId/WaveNo      - whether the Entity is Wave of PT, this would be returned
   OrderId/PickTicket - would be returned only if the Entity is PT.
------------------------------------------------------------------------------*/
Create Procedure pr_Reservation_IdentifyWaveOrPickTicket
  (@XMLInput         XML,
   @Entity           TEntity      = null output,
   @WaveId           TRecordId    = null output,
   @WaveNo           TWaveNo      = null output,
   @OrderId          TRecordId    = null output,
   @PickTicket       TPickTicket  = null output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vWaveNo            TWaveNo,
          @vPickTicket        TPickTicket,

          @BusinessUnit       TBusinessUnit,
          @vNumOrders         TCount;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         /* Reset output variables */
         @Entity       = null,
         @WaveId       = null,
         @WaveNo       = null,
         @OrderId      = null,
         @PickTicket   = null;

  /* Fetch the Params from the Input XML */
  select @vWaveNo      = nullif(Record.Col.value('PickBatchNo[1]',  'TPickBatchNo'), ''),
         @vPickTicket  = nullif(Record.Col.value('PickTicket[1]',   'TPickTicket'),  ''),
         @BusinessUnit = Record.Col.value('BusinessUnit[1]',        'TBusinessUnit')
  from @XMLInput.nodes('ConfirmLPNReservations') as Record(Col);

  /* Identify the Entity to be reserved */
  if (@vWaveNo is not null) and (@vPickTicket is null)
    begin
      select @WaveId     = WaveId,
             @WaveNo     = WaveNo,
             @Entity     = 'Wave',
             @vNumOrders = NumOrders
      from Waves
      where (WaveNo = @vWaveNo) and (BusinessUnit = @BusinessUnit);

      /* If the wave has a bulk order then always reserve against it or wave has only one order then allocate inventory
         directly to pick ticket even though user scanned wave */
      if (@WaveId is not null) and (@vNumOrders = 1) and
         (dbo.fn_Pickbatch_IsBulkBatch(@WaveId) = 'N' /* No */)
        select @OrderId    = OrderId,
               @PickTicket = PickTicket,
               @WaveId     = PickBatchId,
               @WaveNo     = PickBatchNo,
               @Entity     = 'PickTicket'
        from OrderHeaders
        where (PickBatchId = @WaveId);
      else
      if (@WaveId is not null)
        select @OrderId    = OrderId,
               @PickTicket = PickTicket,
               @WaveId     = PickBatchId,
               @WaveNo     = PickBatchNo,
               @Entity     = 'PickTicket'
        from OrderHeaders
        where (PickBatchId = @WaveId) and (OrderType = 'B'/* Bulk */);
    end
  else
  /* Check user scanned pick ticket */
  if (@vPickTicket is not null)
    select @OrderId    = OrderId,
           @PickTicket = PickTicket,
           @WaveId     = PickBatchId,
           @WaveNo     = PickBatchNo,
           @Entity     = 'PickTicket'
    from OrderHeaders
    where (PickTicket = @vPickTicket) and (BusinessUnit = @BusinessUnit)

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Reservation_IdentifyWaveOrPickTicket */

Go
