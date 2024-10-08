/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/06  RIA     pr_RFC_ExplodePrepack, pr_RFC_ConfirmCreateLPN, pr_RFC_TransferPallet: Changes to pr_LPNs_AddSKU signature (HA-1794)
  2015/03/19  DK      pr_RFC_ExplodePrepack: Validation added to validate ToLPN Status
                      Created procedure pr_RFC_ExplodePrepack.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_RFC_ExplodePrepack') is not null
  drop Procedure pr_RFC_ExplodePrepack;
Go
/*------------------------------------------------------------------------------
  Proc pr_RFC_ExplodePrepack: This procedure will explode a PrepackSKU with
    its components SKUs as individual inventory
------------------------------------------------------------------------------*/
Create Procedure pr_RFC_ExplodePrepack
  (@XmlInput   XML,
   @XmlResult  XML output)
as
  declare @ReturnCode           TInteger,
          @vMessageName         TMessageName,
          @vRecordId            TRecordId,

          @FromLPNId            TRecordId,
          @FromLPN              TLPN,
          @PPSKUToExplode       TSKU,
          @QtyToExplode         TQuantity,

          @ToLPNId              TRecordId,
          @ToLPN                TLPN,
          @ReasonCode           TReasonCode,
          @BusinessUnit         TBusinessUnit,
          @UserId               TUserId,

          @vFromLPN             TLPN,
          @vFromLPNId           TRecordId,
          @vFromLPNSKU          TSKU,
          @vFromLPNSKUId        TRecordId,
          @vFromLPNStatus       TStatus,
          @vFromLPNOnhandStatus TStatus,
          @vFromLPNInnerPacks   TInnerpacks,
          @vFromLPNQuantity     TQuantity,
          @vFromLPNLocation     TLocation,
          @vFromLPNLocationId   TRecordId,

          @vFromLPNDetailId     TRecordId,
          @vFromLPNDetailOS     TStatus,
          @vQuantity            TQuantity,
          @vInnerPacks          TInnerPacks,
          @vCurrentSKUId        TRecordId,
          @vCurrentSKU          TSKU,

          @vToLPN               TLPN,
          @vToLPNId             TRecordId,
          @vToSKU               TSKU,
          @vToSKUId             TRecordId,
          @vToLPNStatus         TStatus,
          @vToLPNOnhandStatus   TStatus,
          @vToLPNInnerpacks     TInnerpacks,
          @vToLPNQuantity       TQuantity,
          @vToLPNLocation       TLocation,
          @vToLPNLocationId     TRecordId,
          @vToLPNDetailId       TRecordId,
          @vToLPNPPAdjQty       TQuantity,

          @vMasterSKU           TSKU,
          @vMasterSKUId         TRecordId,
          @vSKU                 TSKU,
          @vSKUId               TRecordId,

          @vComponentSKUId      TRecordId,
          @vComponentSKU        TSKU,
          @vComponentQuantity   TQuantity,


          @vGenerateExportOnExplode
                                TFlag,

          @vXmlResult           TXML,
          @vTIXMLInput          XML,
          @vAuditComment        TVarchar,
          @vActivityLogId       TRecordId;

  declare @ttComponentSKUs Table
          (RecordId          TRecordId identity (1,1),
           MasterSKUId       TRecordId,
           MasterSKU         TSKU,
           ComponentSKUId    TRecordId,
           ComponentSKU      TSKU,
           ComponentQuantity TQuantity);

begin /* pr_RFC_ExplodePrepack */
begin try

  SET NOCOUNT ON;

  /* Local variable assignment */
  select @vRecordId     = 0,
         @vAuditComment = 'ExplodePrepack';

  /* Read values from input xml */
  select @FromLPN          = Record.Col.value('FromLPN[1]',         'TLPN'),
         @ToLPN            = Record.Col.value('ToLPN[1]',           'TLPN'),
         @PPSKUToExplode   = Record.Col.value('SKU[1]',             'TSKU'),
         @QtyToExplode     = Record.Col.value('ExplodeQuantity[1]', 'TQuantity'),
         @ReasonCode       = Record.Col.value('ReasonCode[1]',      'TReasonCode'),
         @BusinessUnit     = Record.Col.value('BusinessUnit[1]',    'TBusinessUnit'),
         @UserId           = Record.Col.value('UserId[1]',          'TUserId')
  from @xmlInput.nodes('ExplodePrepack') as Record(Col);

    /* begin the RFLog to capture input details */
  exec pr_RFLog_Begin @xmlInput, @@ProcId, @BusinessUnit, @UserId, null,
                      null /* EntityId */, @FromLPN, 'LPN',
                      @Value1 = @ToLPN, @Value2 = @PPSKUToExplode, @Value3 = @QtyToExplode,
                      @ActivityLogId = @vActivityLogId output;

  begin transaction;

  /* Get the control variables */
  select @vGenerateExportOnExplode = dbo.fn_Controls_GetAsString('Inventory', 'GenerateExportsOnPPExplode', 'N' /* No */,
                                                                 @BusinessUnit, @UserId);

  /* From LPN Info */
  select @vFromLPN             = LPN,
         @vFromLPNId           = LPNId,
         @vFromLPNSKU          = SKU,
         @vFromLPNSKUId        = SKUId,
         @vFromLPNStatus       = Status,
         @vFromLPNOnhandStatus = OnhandStatus,
         @vFromLPNInnerPacks   = Innerpacks,
         @vFromLPNQuantity     = Quantity,
         @vFromLPNLocation     = Location,
         @vFromLPNLocationId   = LocationId
  from LPNs
  where ((LPNId       = @FromLPNId) or
         (LPN         = @FromLPN)) and
        (BusinessUnit = @BusinessUnit);

  /* To LPN Info */
  select @vToLPN             = LPN,
         @vToLPNId           = LPNId,
         @vToSKU             = SKU,
         @vToSKUId           = SKUId,
         @vToLPNStatus       = Status,
         @vToLPNOnhandStatus = OnhandStatus,
         @vToLPNInnerpacks   = Innerpacks,
         @vToLPNQuantity     = Quantity,
         @vToLPNLocation     = Location,
         @vToLPNLocationId   = LocationId
  from LPNs
  where ((LPNId       = @ToLPNId) or
         (LPN         = @ToLPN)) and
        (BusinessUnit = @BusinessUnit);

  /* Master SKU Info */
  select @vSKU   = SKU,
         @vSKUId = SKUId
  from SKUs
  where ((SKU         = @PPSKUToExplode) or
         (SKU         = @vFromLPNSKU)) and
         (UoM         = 'PP' /* Prepack */) and
        (BusinessUnit = @BusinessUnit);

  /* Get the SKUPrepack info */
  select @vMasterSKUId = MasterSKUId,
         @vMasterSKU   = MasterSKU
  from vwSKUPrePacks
  where (MasterSKUId  = @vSKUId) and
        (Status       = 'A' /* Active */) and
        (BusinessUnit = @BusinessUnit);

  /* From LPNDetails Info */
  select @vFromLPNDetailId = LPNDetailId,
         @vFromLPNDetailOS = OnhandStatus,
         @vQuantity        = Quantity,
         @vInnerPacks      = InnerPacks,
         @vCurrentSKUId    = SKUId,
         @vCurrentSKU      = SKU
  from vwLPNDetails
  where (LPNId        = @vFromLPNId) and
        (SKUId        = @vMasterSKUId) and
        (BusinessUnit = @BusinessUnit);

  /* Validations */
  if (@ToLPN is null)
    select @vMessageName = 'ToLPNIsNull';
  else
  if (@vSKU is null)
    select @vMessageName = 'ScannedSKUIsNotAPrepack';
  else
  if (@vToLPNStatus <> 'N'/* New */)
    select @vMessageName = 'ToLPNStatusIsInvalid';
  else
  if (@vFromLPNOnhandStatus <> 'A'/* Available */)
    select @vMessageName = 'CanOnlyExplodeAvailableLPN';
  else
  if ((@vFromLPN = @vToLPN) and (@vFromLPNQuantity <> @QtyToExplode))
    select @vMessageName = 'CannotExplodePartialQtyIfSameLPNIsUsed';

  if (@vMessageName is not null)
    goto ErrorHandler;

  select @vTIXMLInput = (select @FromLPNId           FromLPNId,
                                @FromLPN             FromLPN,
                                @vFromLPNLocationId  FromLocationId,
                                @vFromLPNLocation    FromLocation,
                                @vCurrentSKUId       CurrentSKUId,
                                @vCurrentSKU         CurrentSKU,
                                @QtyToExplode        NewInnerPacks,
                                @QtyToExplode        TransferQuantity,
                                @ToLPNId             ToLPNId,
                                @ToLPN               ToLPN,
                                @vToLPNLocationId    ToLocationId,
                                @vToLPNLocation      ToLocation,
                                @ReasonCode          ReasonCode,
                                @BusinessUnit        BusinessUnit,
                                @UserId              UserId
                         FOR XML PATH('TransferInventory'));

  /* Transfer the inventory from FromLPN to ToLPN which is supposed to be Exploded */
  if (@vFromLPN <> @vToLPN)
    exec pr_RFC_TransferInventory @vTIXMLInput,
                                  @vXmlResult;

  /* Get all component SKUs of the Master SKU into a temp table */
  insert into @ttComponentSKUs (MasterSKUId, MasterSKU, ComponentSKUId, ComponentSKU, ComponentQuantity)
    select MasterSKUId, MasterSKU, ComponentSKUId, ComponentSKU, ComponentQty
    from vwSKUPrePacks
    where (MasterSKUId = @vMasterSKUId) and
          (Status      = 'A' /* Active */);

  /* begin loop */
  while (exists(select * from @ttComponentSKUs where RecordId > @vRecordId))
    begin
      /* select top 1 record */
      select top 1 @vRecordId          = RecordId,
                   @vMasterSKUId       = MasterSKUId,
                   @vMasterSKU         = MasterSKU,
                   @vComponentSKUId    = ComponentSKUId,
                   @vComponentSKU      = ComponentSKU,
                   @vComponentQuantity = (ComponentQuantity * @QtyToExplode)
      from @ttComponentSKUs
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Calling Core Procedure */
      exec @ReturnCode = pr_LPNs_AddSKU @vToLPNId,
                                        @vToLPN,
                                        null, /* SKUId */
                                        @vComponentSKU,
                                        @vComponentQuantity /* InnerPacks */,
                                        @vComponentQuantity /* Quantity */,
                                        @ReasonCode, /* Reason Code */
                                        '', /* InventoryClass1 */
                                        '', /* InventoryClass2 */
                                        '', /* InventoryClass3 */
                                        @BusinessUnit,
                                        @UserId;

      /* Get the LPNDetailId to generate Exports */
      select @vToLPNDetailId = LPNDetailId
      from vwLPNDetails
      where (LPNId = @vToLPNId) and
            (SKU   = @vComponentSKU);

      if (@ReturnCode = 0)
        begin
          /* Generate Exports */
          if (@vGenerateExportOnExplode = 'Y')
            exec pr_Exports_LPNData 'InvCh' /* Inventory Changes */,
                                    @LPNId       = @vToLPNId,
                                    @LPNDetailId = @vToLPNDetailId,
                                    @TransQty    = @vComponentQuantity,
                                    @ReasonCode  = @ReasonCode,
                                    @CreatedBy   = @UserId;

          /* Inser Audit Trail */
          exec pr_AuditTrail_Insert 'ExplodePP_AddSKUToLPN', @UserId, null /* ActivityTimestamp */,
                                    @LPNId      = @vToLPNId,
                                    @SKUId      = @vComponentSKUId,
                                    @Quantity   = @vComponentQuantity;
        end
    end

  /* Get LPNDetails of MasterSKU from ToLPN to adjust */
  select @vToLPNDetailId  = LPNDetailId
  from LPNDetails
  where (LPNId        = @vToLPNId) and
        (SKUId        = @vMasterSKUId) and
        (BusinessUnit = @BusinessUnit);

  /* Adjusting the transfered Prepack LPNDetail line. As the transfered
     quantity is already exploded and added the compnenent SKUs to the ToLPN */
  exec @ReturnCode = pr_LPNs_AdjustQty @vToLPNId,
                                       @vToLPNDetailId,
                                       @vMasterSKUId,
                                       @vMasterSKU,
                                       @QtyToExplode, /* InnerPacks */
                                       @QtyToExplode, /* Quantity */
                                       '-' /* Update Option - Exact Qty */,
                                       @vGenerateExportOnExplode /* Export? Yes */,
                                       @ReasonCode,  /* Reason Code - in future accept reason from User */
                                       null, /* Reference */
                                       @BusinessUnit,
                                       @UserId;

  /* Audit Trail */
  if (@ReturnCode = 0)
    begin
      exec pr_AuditTrail_Insert @vAuditComment, @UserId, null /* ActivityTimestamp */,
                                @LPNId       = @vFromLPNId,
                                @ToLPNId     = @vToLPNId,
                                @SKUId       = @vMasterSKUId,
                                @LocationId  = @vFromLPNLocationId,
                                @InnerPacks  = @QtyToExplode,
                                @Comment     = @vAuditComment output;

      /* Build Success Message */
      exec pr_BuildRFSuccessXML @vAuditComment, @XmlResult output;
    end
ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Log the result */
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec pr_BuildRFErrorXML @xmlResult output;
  exec pr_RFLog_End @xmlResult, @@ProcId, @ActivityLogId = @vActivityLogId output;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_RFC_ExplodePrepack */

Go
