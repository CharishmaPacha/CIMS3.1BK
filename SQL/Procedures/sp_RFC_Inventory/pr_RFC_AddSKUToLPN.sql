/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/23  RIA     pr_RFC_AddSKUToLPN: Changes to consider InventoryClass1 (HA-1794)
  2019/07/22  MS      pr_RFC_AddSKUToLPN: Added logging (OB2-871)
  2014/11/28  DK      pr_RFC_AddSKUToLPN: Changed procedure to accept TXML as input parameter.
  2013/03/15  PKS     pr_RFC_AddSKUToLocation & pr_RFC_AddSKUToLPN: Used function fn_SKUs_GetSKU to fetch SKU Information
  2013/03/05  PKS     pr_RFC_AddSKUToLocation & pr_RFC_AddSKUToLPN: Validation added to avoid adding Inactive SKU to Location
                      pr_RFC_AddSKUToLPN: Restricting on adding the same SKU to LPN.
                      pr_RFC_AddSKUToLPN, pr_RFC_AddSKUToLPN(Pending Testing).
                      pr_RFC_AddSKUToLPN, pr_RFC_AdjustLPN, pr_RFC_TransferInventory.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_AddSKUToLPN') is not null
  drop Procedure pr_RFC_AddSKUToLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_AddSKUToLPN:
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_AddSKUToLPN
  (@xmlInput    TXML,
   @xmlResult   xml output)
as
  declare @LPNId           TRecordId,
          @LPN             TLPN,
          @NewSKUId        TRecordId,
          @NewSKU          TSKU,
          @NewInnerPacks   TInnerPacks, /* Future Use */
          @NewQuantity     TQuantity,
          @UoM             TUoM,
          @InventoryClass1 TInventoryClass,
          @InventoryClass2 TInventoryClass,
          @InventoryClass3 TInventoryClass,
          @DeviceId        TDeviceId,
          @BusinessUnit    TBusinessUnit,
          @UserId          TUserId;

  declare @OrderId         TRecordId,
          @ReturnCode      TInteger,
          @MessageName     TMessageName,
          @Message         TDescription,
          @vLPNId          TRecordId,
          @vLPNSKUId       TRecordId,
          @vNewSKUId       TRecordId,
          @vNewSKU         TSKU,
          @vSKUStatus      TStatus,
          @vNewUoM         TUoM,
          @vAuditComment   TVarChar,
          @xmlInputvar     XML,
          @vActivityLogId  TRecordId;
begin
begin try
  SET NOCOUNT ON;

  /* convert input TXML to XML */
  select @xmlInputvar = convert(xml, @xmlInput);

  /* Read Values from input xml */
  select @LPNId           = nullif(Record.Col.value('LPNId[1]',         'TRecordId'),0),
         @LPN             = Record.Col.value('LPN[1]',                  'TLPN'),
         @NewSKUId        = nullif(Record.Col.value('NewSKUId[1]',      'TRecordId'),0),
         @NewSKU          = nullif(Record.Col.value('NewSKU[1]',        'TSKU'),''),
         @NewInnerPacks   = nullif(Record.Col.value('NewInnerPacks[1]', 'TInnerPacks'),''),
         @NewQuantity     = Record.Col.value('NewQuantity[1]',          'TQuantity'),
         @UoM             = Record.Col.value('UoM[1]',                  'TUoM'),
         @InventoryClass1 = Record.Col.value('InventoryClass1[1]',      'TInventoryClass'),
         @InventoryClass2 = Record.Col.value('InventoryClass2[1]',      'TInventoryClass'),
         @InventoryClass3 = Record.Col.value('InventoryClass3[1]',      'TInventoryClass'),
         @BusinessUnit    = Record.Col.value('BusinessUnit[1]',         'TBusinessUnit'),
         @UserId          = Record.Col.value('UserId[1]',               'TUserId')
  from @xmlInputvar.nodes('ConfirmAddSKUToLPN') as Record(Col);

  /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInputvar, @@ProcId, @BusinessUnit, @UserId, @DeviceId,
                      @LPNId, @LPN, 'LPN-SKU','AddSKUToLPN',
                      @Value1 = @NewSKU, @Value2 = @NewInnerPacks, @Value3 = @NewQuantity,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  --select @NewSKUId = nullif(@NewSKUId, 0);

  /* Validate LPN */
  if (@LPNId is null)
    select @LPNId = dbo.fn_LPNs_GetScannedLPN(@LPN, @BusinessUnit, default /* Options */);

  select @LPNId       = LPNId,
         @LPN         = LPN,
         @vLPNId      = LPNId,
         @vLPNSKUId   = SKUId,
         @OrderId     = OrderId
  from LPNs
  where (LPNId = @LPNId);

  /* Validate SKU */
  if (@NewSKUId is not null)
    select @vNewSKUId  = SKUId,
           @vNewSKU    = SKU,
           @vNewUoM    = UoM,
           @vSKUStatus = Status
    from SKUs
    where (SKUId  = @NewSKUId);
  else
    /* Get the latest SKU Info */
    select top 1 @vNewSKUId  = SKUId,
                 @vNewSKU    = SKU,
                 @vNewUoM    = UoM,
                 @vSKUStatus = Status
    from dbo.fn_SKUs_GetScannedSKUs (@NewSKU, @BusinessUnit);

  if (@vLPNId is null)
    set @MessageName = 'LPNDoesNotExist';
  else
  if (@vNewSKUId is null)
    set @MessageName = 'SKUDoesNotExist';
  else
  /* If LPN is reserved for an Order, do not allow adding more */
  if (@OrderId is not null)
    set @MessageName = 'LPNAddSKU_LPNReserved';
  else
  /* Validate if SKU already exist */
  if (@vLPNSKUId = @vNewSKUId)
    set @MessageName = 'SKUAlreadyExists';
  else
  /* Validate UoM */
  if (@vNewUoM = 'PP' /* Prepack */ and @UoM = 'EA' /* Eaches */) or
     (@vNewUoM = 'EA' /* Eaches */  and @UoM = 'PP' /* Prepack */)
    set @MessageName = 'SKUUoMMismatch';
  else
  /* Validate Quantity */
  if (@NewQuantity < 0)
    set @MessageName = 'InvalidQuantity';
  else
  if (@vSKUStatus = 'I' /* Inactive */)
    set @MessageName = 'SKUIsInactive';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Calling Core Procedure */
  exec @ReturnCode = pr_LPNs_AddSKU @LPNId,
                                    @LPN,
                                    @vNewSKUId,
                                    @vNewSKU,
                                    @NewInnerPacks,
                                    @NewQuantity,
                                    0, /* Reason Code */
                                    @InventoryClass1,
                                    @InventoryClass2,
                                    @InventoryClass3,
                                    @BusinessUnit,
                                    @UserId;

  /* Audit Trail */
  if (@ReturnCode = 0)
    begin
      exec pr_AuditTrail_Insert 'AddSKUToLPN', @UserId, null /* ActivityTimestamp */,
                                @LPNId      = @LPNId,
                                @SKUId      = @vNewSKUId,
                                @InnerPacks = @NewInnerPacks,
                                @Quantity   = @NewQuantity,
                                @Comment    = @vAuditComment output;

      exec pr_BuildRFSuccessXML @vAuditComment, @xmlResult output;
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @LPNId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;

  /* Log the error */
  exec pr_RFLog_End @xmlResult, @@ProcId, @EntityId = @LPNId, @ActivityLogId = @vActivityLogId output;

end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_AddSKUToLPN */

Go
