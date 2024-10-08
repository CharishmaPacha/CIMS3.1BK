/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/12/02  SV      pr_Receivers_CreateReceiptInventory, pr_Receivers_CreateReceiptInventory_Validate: Intial version to validate the I/P data
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_CreateReceiptInventory_Validate') is not null
  drop Procedure pr_Receivers_CreateReceiptInventory_Validate;
Go
/*-----------------------------------------------------------------------------------------------
  Proc pr_Receivers_CreateReceiptInventory_Validate:
    Validate the inputs for pr_Receivers_CreateReceiptInventory procedure.
    This should be the procedure to add any validations for CreateReceiptInventory action.
-------------------------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_CreateReceiptInventory_Validate
  (@xmlInput xml)
as
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,

          /* Input params */
          @vNumLPNsToCreate            TCount,
          @vReceiptId                  TRecordId,
          @vReceiptNumber              TReceiptNumber,
          @vReceiptDetailId            TRecordId,
          @vSKU                        TSKU,
          @vUserId                     TUserId;

  declare @ttReceiptDetailsInfo table (ReceiptId             TRecordId,
                                       ReceiptDetailId       TRecordId,
                                       SKUId                 TRecordId,
                                       SKU                   TSKU,
                                       UnitsPerLPN           TQuantity,
                                       TotalUnitsReceiving   TQuantity,
                                       ExtraQuantity         TQuantity, -- TotalUnitsReceiving - RD_QtyToReceive
                                       RD_QtyOrdered         TQuantity,
                                       RD_QtyReceived        TQuantity,
                                       RD_QtyToReceive       TQuantity, -- RD_QtyOrdered - RD_QtyReceived
                                       RD_MaxQtyToReceive    TQuantity, -- QtyOrdered + ExtraQtyAllowed - QtyReceived
                                       RD_ExtraQtyAllowed    TQuantity,
                                       ErrorMessage          TMessageName,
                                       RecordId              TRecordId identity(1,1));
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Temp table */
  select * into #ReceiptDetailsInfo from @ttReceiptDetailsInfo;

  /* Read the Input data */
  select @vNumLPNsToCreate = Record.Col.value('(Data/NumLPNsToCreate)[1]',  'TCount'),
         @vUserId          = Record.Col.value('(SessionInfo/UserId)[1]',    'TUserId')
  from @xmlInput.nodes('/Root') as Record(Col);

  /* Populate the I/P for validation. */
  insert into #ReceiptDetailsInfo (ReceiptId, ReceiptDetailId, SKUId, SKU, UnitsPerLPN)
    select Record.Col.value('(ReceiptId)[1]',         'TRecordId'),
           Record.Col.value('(ReceiptDetailId)[1]',   'TRecordId'),
           Record.Col.value('(SKUId)[1]',             'TRecordId'),
           Record.Col.value('(SKU)[1]',               'TSKU'),
           Record.Col.value('(UnitsPerLPN)[1]',       'TQuantity')
    from @xmlInput.nodes('/Root/Data/SKUDetail/Detail') as Record(Col);

  update RDI
  set TotalUnitsReceiving    = @vNumLPNsToCreate * RDI.UnitsPerLPN,
      RDI.RD_QtyOrdered      = RD.QtyOrdered,
      RDI.RD_QtyReceived     = RD.QtyReceived,
      RDI.RD_QtyToReceive    = RD.QtyToReceive,
      RDI.RD_MaxQtyToReceive = RD.QtyOrdered + RD.ExtraQtyAllowed - RD.QtyReceived,
      RDI.RD_ExtraQtyAllowed = RD.ExtraQtyAllowed
  from #ReceiptDetailsInfo RDI
    join ReceiptDetails RD on (RD.ReceiptDetailId = RDI.ReceiptDetailId);

  /* If user is receiving over and above the Qty Ordered, show the info as a warning - even
     if the user has permissions to do so. If user does not have permissions, we not only
     give this info, but also let user know that he/she does not have permissions */
  insert into #ResultMessages (MessageType, MessageName, Value1, Value2, Value3)
    select 'W' /* Warning */, 'CreateRecvInv_ReceivingBeyondMaxQty', SKU, RD_MaxQtyToReceive, TotalUnitsReceiving
    from #ReceiptDetailsInfo
    where (TotalUnitsReceiving > RD_MaxQtyToReceive);

  insert into #ResultMessages (MessageType, MessageName, Value1, Value2, Value3)
    select 'W' /* Warning */, 'CreateRecvInv_ReceivingExtraQty', SKU, RD_QtyToReceive, TotalUnitsReceiving
    from #ReceiptDetailsInfo
    where (TotalUnitsReceiving > RD_QtyToReceive);

  /* Check for permissions for over Receiving for the user role.
     If valid user to over receive, then ErrorMessage will be updated as null else with error. */
  update #ReceiptDetailsInfo
  set ErrorMessage = dbo.fn_Receipts_ValidateOverReceiving(ReceiptDetailId, @vNumLPNsToCreate * UnitsPerLPN, @vUserId);

ErrorHandler:
  if (exists(select * from #ReceiptDetailsInfo where ErrorMessage is not null))
    begin
      /* Build error message to display at UI */
      insert into #ResultMessages (MessageType, MessageName)
        select distinct 'E' /* Error */, ErrorMessage
        from #ReceiptDetailsInfo

      exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;
    end

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receivers_CreateReceiptInventory_Validate */

Go
