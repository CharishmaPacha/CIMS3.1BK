/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/07  OK      pr_LPNs_UI_AdjustLPN: Changes to validate the valid unavailable LPN statuses through controls (HA-2176)
  2020/04/18  MS      pr_LPNs_UI_AdjustLPN: Changes to insert success message in temp table (HA-181)
              RV      pr_LPNs_UI_AdjustLPN: Added validation to not update the unavailable LPN Detail, except Received LPN (HPI-1222)
  2016/05/25  OK      pr_LPNs_UI_AdjustLPN: Enhanced to display the Original Quantity in Audit Trail (HPI-121)
  2014/07/18  PKS     pr_LPNs_UI_AdjustLPN: Reason Code is logged in Audit Trial.
  2014/05/21  PKS     pr_LPNs_UI_AdjustLPN: Considering CurrentInnerPacks value while validating given Qty is same or not.
  2014/03/27  PK      Added pr_LPNs_UI_AdjustLPN, pr_LPNs_ValidateAdjustLPN.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_UI_AdjustLPN') is not null
  drop Procedure pr_LPNs_UI_AdjustLPN;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_UI_AdjustLPN:
  --Input
  <LPNAdjustmentDetails>
    <Header>
      <LPN></LPN>
      <LPNId></LPNId>
      <ReasonCode></ReasonCode>
      <RefNumber></RefNumber>
    </Header>
    <Details>
      <Detail>
        <LPNDetailId></LPNDetailId>
        <SKUId></SKUId>
        <NewQuantity></NewQuantity>
        <NewInnerPacks></NewInnerPacks>
      </Detail>
         ...
         ...
      </Details>
  </LPNAdjustmentDetails>
------------------------------------------------------------------------------
  -- output
  <LPNAdjustmentDetails>
    <Response>
      <Status>Success</Status>
      <ResponseMessage>Message</ResponseMessage>
    </Response>
  </LPNAdjustmentDetails>
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_UI_AdjustLPN
  (@xmlInput       TXML,
   @BusinessUnit   TBusinessUnit,
   @UserId         TUserId,
   @xmlResult      TXML output)
as
  declare @ReturnCode              TInteger,
          @MessageName             TMessageName,
          @vMessage                TDescription,

          @vRecordId               TRecordId,
          @LPNId                   TRecordId,
          @LPN                     TLPN,
          @vLPNStatus              TStatus,
          @vLPNDetailId            TRecordId,
          @vSKUId                  TRecordId,
          @vSKU                    TSKU,
          @vCurrentSKUId           TRecordId,
          @vCurrentInnerPacks      TQuantity,
          @vCurrentQuantity        TQuantity,
          @ReasonCode              TReasonCode,
          @RefNumber               TReference,
          @vNewInnerPacks          TInnerPacks,
          @vNewQuantity            TQuantity,
          @vLDOnhandStatus         TStatus,
          @vTotalLPNDetailsCount   TCount,
          @vValidUnavailableLPNStatuses
                                   TControlValue,
          @xmlLPNAdjustmentDetails xml;

  declare @ttLPNDetails table(RecordId         TRecordId Identity(1,1),
                              LPNDetailId      TRecordId,
                              SKUId            TRecordId,
                              SKU              TSKU,
                              NewQuantity      TQuantity,
                              NewInnerPacks    TQuantity);
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @xmlLPNAdjustmentDetails = convert(xml, @xmlInput);

  /* Get Header info */
  select @LPNId      = Record.Col.value('LPNId[1]',      'TRecordId'),
         @LPN        = Record.Col.value('LPN[1]',        'TLPN'),
         @ReasonCode = Record.Col.value('ReasonCode[1]', 'TReasonCode'),
         @RefNumber  = Record.Col.value('RefNumber[1]',  'TReceiverNumber')
  from @xmlLPNAdjustmentDetails.nodes('/LPNAdjustmentDetails/Header') as Record(Col);

  /* Take all details/lines into a temp table */
  insert into @ttLPNDetails (LPNDetailId, SKUId, SKU, NewQuantity, NewInnerPacks)
    select Record.Col.value('LPNDetailId[1]',   'TRecordId'),
           Record.Col.value('SKUId[1]',         'TRecordId'),
           Record.Col.value('SKU[1]',           'TSKU'),
           Record.Col.value('NewQuantity[1]',   'TQuantity'),
           Record.Col.value('NewInnerPacks[1]', 'TInnerpacks')
    from @xmlLPNAdjustmentDetails.nodes('/LPNAdjustmentDetails/Details/Detail') as Record(Col);

  /* Get the inserted row count */
  select @vTotalLPNDetailsCount = @@rowcount;

  select @vValidUnavailableLPNStatuses = dbo.fn_Controls_GetAsString('LPN_Adjust', 'ValidUnavailableLPNStatuses', 'RN' /* Received, New */, @BusinessUnit, @UserId);

  /* Validations */
  exec @ReturnCode = pr_LPNs_ValidateAdjustLPN @LPNId, @LPN, @ReasonCode, @RefNumber, @BusinessUnit, @UserId;

  /* Fetch first detail from the details temp table */
  select top 1 @vRecordId      = RecordId,
               @vLPNDetailId   = LPNDetailId,
               @vSKUId         = SKUId,
               @vSKU           = SKU,
               @vNewQuantity   = NewQuantity,
               @vNewInnerPacks = NewInnerPacks
  from @ttLPNDetails
  order by RecordId;

  while (@@rowcount > 0)
    begin
      select @vLPNStatus         = LPNStatus,
             @vCurrentSKUId      = SKUId,
             @vCurrentInnerPacks = InnerPacks,
             @vCurrentQuantity   = Quantity,
             @vLDOnhandStatus    = OnhandStatus
      from vwLPNDetails
      where (LPNDetailId = @vLPNDetailId) and
            (SKUId       = @vSKUId);

      /* Validations */
      if (@vNewQuantity < 0)
        set @MessageName = 'InvalidQuantity';
      else
      if (@vLPNDetailId is null)
        set @MessageName = 'SKUNotInLPN';
      else
      if (@vLDOnhandStatus = 'U' /* Unavailable */) and (charindex(@vLPNStatus, @vValidUnavailableLPNStatuses) = 0)
        set @MessageName = 'LPNAdjust_UnavailableLine';
      else
      if ((@vNewInnerPacks = @vCurrentInnerPacks) and
          (@vNewQuantity = @vCurrentQuantity))
        set @MessageName = 'LPNAdjust_SameQuantity';

      /* If there are any validations then go to ErrorHandler */
      if (@MessageName is not null)
        goto ErrorHandler;

      /* Calling Core Procedure */
      exec @Returncode = pr_LPNs_AdjustQty @LPNId,
                                           @vLPNDetailId,
                                           @vSKUId,
                                           @vSKU,
                                           @vNewInnerPacks,
                                           @vNewQuantity,
                                           '=' /* Update Option - Exact Qty */,
                                           'Y' /* Export? Yes */,
                                           @ReasonCode,
                                           @RefNumber,
                                           @BusinessUnit,
                                           @UserId;

      if (@ReturnCode > 0)
        goto ErrorHandler;

      /* Audit Trail */
      if (@ReturnCode = 0)
        begin
          exec pr_AuditTrail_Insert 'LPNAdjustQty', @UserId, null /* ActivityTimestamp */,
                                    @LPNId          = @LPNId,
                                    @LPNDetailId    = @vLPNDetailId,
                                    @InnerPacks     = @vNewInnerPacks,
                                    @Quantity       = @vNewQuantity,
                                    @PrevInnerPacks = @vCurrentInnerPacks,
                                    @PrevQuantity   = @vCurrentQuantity,
                                    @ReasonCode     = @ReasonCode;
        end

      /* Fetch first detail from the details temp table */
      select top 1 @vRecordId      = RecordId,
                   @vLPNDetailId   = LPNDetailId,
                   @vSKUId         = SKUId,
                   @vSKU           = SKU,
                   @vNewQuantity   = NewQuantity,
                   @vNewInnerPacks = NewInnerPacks
      from @ttLPNDetails
      where (RecordId > @vRecordId)
      order by RecordId;
    end;

  /* Build Message */
  exec @vMessage = dbo.fn_Messages_Build 'LPNAdjustment', @LPN, @vNewQuantity, @vSKU;

  /* Inserted the messages information to display in V3 application */
  if (object_id('tempdb..#ResultMessages') is not null)
     insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, @vMessage;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

commit transaction;
end try
begin catch
  rollback transaction;

ExitHandler:
  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end  /* pr_LPNs_UI_AdjustLPN */

Go
