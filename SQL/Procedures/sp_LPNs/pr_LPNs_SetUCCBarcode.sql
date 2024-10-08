/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/05/09  OK      pr_LPNs_SetUCCBarcode: Changes to do not override existing PackageSeqNo on LPN (S2G-772)
  2016/03/17  AY      pr_LPNs_SetUCCBarcode: enhanced to send rules and use that to determine if
  2014/07/14  TD      Added new procedure pr_LPNs_SetUCCBarcode, pr_LPNs_MarkAsLoaded.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_SetUCCBarcode') is not null
  drop Procedure pr_LPNs_SetUCCBarcode;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_SetUCCBarcode:
    This procedure will update the UCCBarcode on the given LPNs which are not have
    any barcode labels on that.
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_SetUCCBarcode
  (@LPNId          TRecordId,
   @LPNs           TEntityKeysTable readonly,
   @OrderId        TRecordId,
   @xmlRulesData   TXML = null,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @vMessage          TDescription,
          @vRecordId         TRecordId,

          @vLPNId            TRecordId,
          @vLPN              TLPN,
          @vUCCBarcode       TBarCode,
          @vPackageSeqNo     TInteger,
          @vNextPackageSeqNo TInteger,
          @vOrderId          TRecordId,
          @vGenerateUCCBarcode TResult;

  declare @ttLPNs Table
          (RecordId      TRecordId  identity (1,1),
           LPNId         TRecordId,
           LPN           TLPN,
           OrderId       TRecordId,
           UCCBarcode    TBarcode,
           PackageSeqNo  TInteger,
           Primary Key   (RecordId));

begin
  SET NOCOUNT ON;

  select @vRecordId = 0;

  /* inser all the lpns for the Order/Give LPN*/
  if (@LPNId is not null)
    insert into @ttLPNs (LPNId, LPN, OrderId, UCCBarcode, PackageSeqNo)
      select LPNId, LPN, OrderId, UCCBarcode, PackageSeqNo
      from LPNs
      where (LPNId = @LPNId) and
            (UCCBarcode is null)
  else
  if (@OrderId is not null)
    insert into @ttLPNs (LPNId, LPN, OrderId, UCCBarcode, PackageSeqNo)
      select LPNId, LPN, OrderId, UCCBarcode, PackageSeqNo
      from LPNs
      where (OrderId = @OrderId) and
            (UCCBarcode is null);
  else
    /* insert all the LPNs into temp table */
    insert into @ttLPNs (LPNId, LPN, OrderId, UCCBarcode, PackageSeqNo)
      select L.LPNId, L.LPN, L.OrderId, L.UCCBarcode, L.PackageSeqNo
      from @LPNs TL join LPNs L on (L.LPN = TL.Entitykey)
      where L.UCCBarcode is null

  while (exists(select * from @ttLPNs where RecordId > @vRecordId))
    begin
      /* select top 1 here */
      select top 1 @vLPNId        = LPNId,
                   @vLPN          = LPN,
                   @vUCCBarcode   = null,
                   @vOrderId      = OrderId,
                   @vPackageSeqNo = PackageSeqNo,
                   @vRecordId     = RecordId
      from @ttLPNs
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Verify rules to Generate UCC Barcode or not */
      exec pr_RuleSets_Evaluate 'GenerateUCCBarcode', @xmlRulesData, @vGenerateUCCBarcode output;

      /* if this LPN does not require a UCCBarcode, then continue with next one */
      if (@xmlRulesData is not null) and (@vGenerateUCCBarcode = 'N') continue;

      /* Call procedure here to generate next UCCBarcode */
      exec pr_ShipLabel_GetSSCCBarcode @UserId, @BusinessUnit, @vLPN, default /* barcode Type */,
                                       @vUCCBarcode output;

      /* get the max seq number generated for the Order, if the LPN doesn't have one */
      if (@vPackageSeqNo is null)
        select @vNextPackageSeqNo = Max(coalesce(PackageSeqNo, 0)) + 1
        from LPNs
        where (OrderId = @vOrderId);

      /* Update LPNs here */
      update LPNs
      set UCCBarcode   = @vUCCBarcode,
          PackageSeqNo = coalesce(PackageSeqNo, @vNextPackageSeqNo)
      where (LPNId = @vLPNId);
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_LPNs_SetUCCBarcode */

Go
