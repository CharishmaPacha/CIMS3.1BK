/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Packing_OrderPacking_Start') is not null
  drop Procedure pr_AMF_Packing_OrderPacking_Start;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Packing_OrderPacking_Start : This is the initial step of the
   Order packing workflow. The user scans an Entity (Order, LPN, Cart etc.)
   that would be used to uniquely identify the order to be packed.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Packing_OrderPacking_Start
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vxmlInput                 xml,
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vScannedEntity            TEntity,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vPalletId                 TRecordId,
          @vPallet                   TPallet,
          @vWaveNo                   TPickBatchNo,
          @vPalletOrderId            TRecordId,
          @vPalletStatus             TStatus,
          @vOrderId                  TRecordId,
          @vPickTicket               TPickTicket,
          @vOrderType                TOrderType,
          @vOrderStatus              TStatus,
          @vQuantity                 TQuantity,
          @vRFFormAction             TMessageName,
          @vMessage                  TMessage,
          @vActivityLogId            TRecordId,
          @vSuccessMessage           TMessage;
begin /* pr_AMF_Packing_OrderPacking_Start */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML     = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML   = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML    = null,
         @InfoXML     = null,
         @vPickTicket = null,
         @vOrderType  = null;

  /* read values form input */
  select @vBusinessUnit     = Record.Col.value('(SessionInfo/BusinessUnit)[1]',     'TBusinessUnit'),
         @vUserId           = Record.Col.value('(SessionInfo/UserName)[1]',         'TUserId'      ),
         @vDeviceId         = Record.Col.value('(SessionInfo/DeviceId)[1]',         'TDeviceId'    ),
         @vScannedEntity    = Record.Col.value('(Data/ScannedEntity)[1]',           'TEntity'      )
  from @vxmlInput.nodes('/Root')  as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Assume user scanned a PickTicket */
  select @vOrderId = OrderId
  from OrderHeaders
  where (PickTicket   = @vScannedEntity) and
        (BusinessUnit = @vBusinessUnit );

  /* If user did not scan PT, check if it is an LPN or Tote */
  if (@vOrderId is null)
    select @vLPNId   = LPNId,
           @vOrderId = OrderId
    from LPNs
    where (LPN          = @vScannedEntity) and
          (BusinessUnit = @vBusinessUnit );

  /* If it wasn't PT, LPN/Tote, check for Cart (if it has a single Order on it) */
  if (@vOrderId is null)
    select @vPalletId      = PalletId,
           @vPallet        = Pallet,
           @vPalletOrderId = OrderId,
           @vOrderId       = OrderId,
           @vPalletStatus  = Status
    from Pallets
    where (Pallet       = @vScannedEntity) and
          (BusinessUnit = @vBusinessUnit );

  /* Get Order info */
  select @vPickTicket  = PickTicket,
         @vOrderId     = OrderId,
         @vOrderType   = OrderType,
         @vWaveNo      = PickBatchNo,
         @vOrderStatus = Status
  from OrderHeaders
  where (OrderId = @vOrderId);

  /* Validations */
  if (@vOrderStatus = 'S' /* Shipped */)
    select @vMessageName = 'AMF_Packing_OrderAlreadyShipped'
  else
  if (@vOrderStatus = 'K' /* Packed */)
    select @vMessageName = 'AMF_Packing_OrderAlreadyPacked'
  else
  if (@vOrderStatus = 'X' /* Cancelled */)
    select @vMessageName = 'AMF_Packing_OrderAlreadyCancelled'
  else
  if (@vOrderStatus in ('N', 'W' /* New, Waved, Allocated */))
    select @vMessageName = 'AMF_Packing_OrderNotAllocated'
  else
  if (@vLPNId is not null) and (@vOrderId is null)
    select @vMessageName = 'AMF_Packing_ScannedLPNNotAllocated'
  else
  if (@vPalletId is not null) and (@vPalletOrderId is null)
    select @vMessageName = 'AMF_Packing_PalletNotAssociatedWithSingleOrder'
  else
  if (@vOrderId is null)
    select @vMessageName = 'AMF_Packing_UnableToIdentifyOrder'

    -- else
    -- if (dbo.fn_OrderHeaders_OrderQualifiedToShip(@vOrderId, 'Packing', 'K' /* Kit Validation */) = 'N')
    --   select @vMessageName = 'Packing_PartialKitsOnOrder';
    -- else
    -- if (dbo.fn_OrderHeaders_OrderQualifiedToShip(@vOrderId, 'Packing', 'S' /* Ship Complete */) = 'N')
    --   select @vMessageName = 'Packing_ViolatesSCRule';


  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

    -- /* ensure Pallet is not being packed by another user */
    -- if (@vPalletStatus = 'G' /* Packing */) and
    --    ((coalesce(@vPackingUser, '' ) <> '') and (@vPackingUser <>  @UserId /* validate user */))/* and
    --    (dbo.fn_Permissions_IsAllowed(@UserId, 'ORPackedByAnotherUser') <> '0') */
    --   set @MessageName = 'PalletBeingPackedByAnotherUser';
    -- else
    -- /* check if wave type is valid */
    -- if (charindex(',' + @vPickBatchType + ',' , ','+ @vInvalidWaveTypes +',') > 0)
    --   select @MessageName = 'Packing_InvalidWaveType', @vValue1 = @vPickBatchTypeDesc;
    -- else
    -- /* check pallet is ready for packing */
    -- if (charindex(@vPalletStatus, @vValidPalletStatuses) = 0)
    --   set @MessageName = 'Packing_InvalidPalletStatus';
    -- else
    -- /* Check whether Pallet has pending tasks associated or not with Task's PalletId instead of using TaskDetail's PalletId.
    --    We are updating PalletId on TaskDetails once after picking started */
    -- if (((@vScannedEntity = 'P' /* Pallet */) or (@vScannedEntity = 'L' /* LPN */)) and
    --     (exists(select *
    --             from Pallets P
    --               join Tasks T on (T.PalletId = P.PalletId)
    --             where (T.BatchNo  = @vPickBatchNo) and
    --                   (P.PalletId = @PalletId) and
    --                   (T.Status   = 'I' /* In Progress */))))
    --   set @MessageName = 'Packing_PalletHasOutstandingPicks';
    --
    -- if (@MessageName is not null)
    --   goto ErrorHandler;
    --
    -- /* Update Pallet Status to Packing */
    -- Update Pallets
    -- set Status        = 'G',                             /* Packing                            */
    --     LocationId    = @vPackingStationId,              /* LocationId of the Packing Station  */
    --     PackingByUser = @UserId,
    --     ModifiedBy    = coalesce(@UserId, System_User),  /* Current user working on the pallet */
    --     ModifiedDate  = current_timestamp
    -- where (PalletId = @PalletId);
    --
    -- /* set Pick Batch status to Packing */
    -- exec pr_PickBatch_SetStatus @vPickBatchNo, 'A' /* Packing */, @UserId;
    --
    -- /* Audittrail */
    -- exec pr_AuditTrail_Insert 'PackingStartBatch', @UserId, null /* ActivityTimestamp */,
    --                           @PickBatchId   = @vPickBatchId,
    --                           @PalletId      = @PalletId;
    --

  /* Call the proc to build response */
  exec pr_AMF_Packing_BuildPackInfo @vOrderId, @vPickTicket, @vBusinessUnit, @vUserId, @DataXML output;

end /* pr_AMF_Packing_OrderPacking_Start */

Go

