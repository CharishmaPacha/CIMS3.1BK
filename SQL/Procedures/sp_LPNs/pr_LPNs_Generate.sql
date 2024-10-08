/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/26  VS      pr_LPNs_Generate: Add AuditTrail when generate LPNs from UI (HA-2885)
  2021/06/01  AY      pr_LPNs_Generate: Optimize for performance (HA-2859)
  2018/03/13  SV      pr_LPNs_Generate: Corrections to create LPNs with Ownership as "EA" but not "S2G" (S2G-329)
  2016/05/03  OK      pr_LPNs_Generate: Changed to display the proper message (HPI-83)
  2015/12/29  TK      pr_LPNs_Generate: Changed to display user defined error message instead of display SQL Error message(NBD-61)
  2015/08/05  VM      pr_LPNs_Generate: Get LPN category from Rules (FB-288)
  2013/09/03  PK      pr_LPNs_Generate: Generating LPNs for Warehouse specific.
  2013/05/22  SP      pr_LPNs_Generate: Added Warehouse field.
  2012/08/17  PKS     pr_LPNs_Generate: Success message added.
  2011/09/20  TD      pr_LPNs_Generate: Bug fix in handling LPN format which did not have <SeqNo>
  2011/08/15  AY      pr_LPNs_Generate: Intialized UniqueId as with Multiple SKUs in
  2011/01/27  VM      pr_LPNs_Generate, pr_LPNs_AddOrUpdate:
  2011/01/18  VM      pr_LPNs_Generate: Set default values to o/p's as the caller can use them as optional
                      pr_LPNs_Generate Procedure
  2010/12/07  VK      Made Changes in the  pr_LPNs_Generate Procedure
  2010/11/22  VM      pr_LPNs_AdjustQty, pr_LPNs_AddSKU, pr_LPNs_Generate, pr_LPNs_Recount: Procedures completed
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_Generate') is not null
  drop Procedure pr_LPNs_Generate;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_Generate:
    Caller should take care of sending the LPNFormat based on user selection and
    should make sure that <SeqNo> is added, if user made a custom selection
    ??? if the user does not want SeqNo and exactly wants the LPNNo (LPNFormat) only ??? ex: 'AAAXXX'
    Ex:
      if user custom selection is 'MyCase', LPNFormat should be 'MyCase<SeqNo>'
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_Generate
  (@LPNType          TTypeCode = 'C' /* Carton */,
   @NumLPNsToCreate  TCount,
   @LPNFormat        TControlValue,  /* It can also be a LPNNumber??? - specific LPNNumber */
   @Warehouse        TWarehouse,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   ------------------------------------------
   @FirstLPNId       TRecordId    = null output,
   @FirstLPN         TLPN         = null output,
   @LastLPNId        TRecordId    = null output,
   @LastLPN          TLPN         = null output,
   @NumLPNsCreated   TCount       = null output,
   @Message          TDescription = null output)
as
  declare @ReturnCode           TInteger,
          @MessageName          TMessageName,
          @CurrentSeqNo         TSequence,
          @NextSeqNo            TSequence,
          @vNextSeqNo           TString,
          @NewNextSeqNo         TSequence,
          @SeqNoMaxLength       TInteger,
          @LPNToCreate          TLPN,
          @LPNIdCreated         TRecordId,
          @ControlRecordId      TRecordId,
          @vLPNControlCategory  TCategory,
          @xmlRulesData         TXML,
          @vRulesResult         TResult,
          @vLPNTypeDescription  TDescription,
          @vOwnership           TOwnership,
          @vErrNum              TInteger,
          @vAuditLPNRecordId    TRecordId;

  declare @ttLPNs               TEntityKeysTable;
  declare @ttLPNsGenerated      TEntityKeysTable;
begin
begin try
  begin transaction;

  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null,
         @LPNFormat   = nullif(@LPNFormat, '');

  /* Validations */
  if (coalesce(@NumLPNsToCreate, 0) = 0)
    set @MessageName = 'NumLPNsToCreateNotDefined';
  else
  if (not exists(select *
                 from EntityTypes
                 where (TypeCode = @LPNType) and
                       (Entity   = 'LPN') and
                       (Status   = 'A' /* Active */)))
    set @MessageName = 'LPNTypeDoesNotExist'
  else
  if (@BusinessUnit is null)
    set @MessageName = 'BusinessUnitIsInvalid';

  /* select LPNType description to build the message */
  select @vLPNTypeDescription = TypeDescription
  from EntityTypes
  where (TypeCode = @LPNType) and
        (Entity   = 'LPN');

  /* Fetch the Ownership */
  select top 1 @vOwnership = LookUpCode
  from vwLookUps
  where (LookUpCategory = 'Owner')
  order by SortSeq;

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Build LPN Control Category */
  /* Build the data for rule evaluation */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                         dbo.fn_XMLNode('Operation', 'GenerateLPN') +
                         dbo.fn_XMLNode('LPNType',   @LPNType)      +
                         dbo.fn_XMLNode('Warehouse', @Warehouse));

  /* Return the Control category to decide whether to use default LPN category or any specific */
  exec pr_RuleSets_Evaluate 'ControlCategory', @xmlRulesData, @vLPNControlCategory output;

  /* Get the default LPN format, if user does not pass it */
  select @LPNFormat      = coalesce(@LPNFormat,
                                    dbo.fn_Controls_GetAsString(@vLPNControlCategory, 'LPNFormat', '<LPNType><SeqNo>',
                                                                @BusinessUnit, @UserId)),
         @SeqNoMaxLength = dbo.fn_Controls_GetAsInteger(@vLPNControlCategory, 'SeqNoMaxLength', '9',
                                                        @BusinessUnit, @UserId);

  select @NumLPNsCreated = 0,
         @LPNFormat = replace(@LPNFormat, '<LPNType>', @LPNType), -- replace LPNType, if it is in format
         @LPNFormat = replace(@LPNFormat, '<BusinessUnit>', @BusinessUnit); -- replace BusinessUnit, if it is in format

  /* If the format has a <SeqNo>, then get the next one to start the loop */
  if (charindex('<SeqNo>', @LPNFormat) > 0)
    begin
      /* Sequences begin with Seq, so if there isn't one, then prefix it */
      if (@vLPNControlCategory not like 'Seq%') select @vLPNControlCategory = 'Seq_' + @vLPNControlCategory;

      exec pr_Sequence_GetNext @vLPNControlCategory, @NumLPNsToCreate,
                               @UserId, @BusinessUnit, @NextSeqNo output;

      if (@NextSeqNo is null)
        begin
          select @MessageName = 'NextSeqNoMissing_LPN';
          goto ErrorHandler;
        end
    end

  while (@NumLPNsCreated < @NumLPNsToCreate)
    begin
      select @LPNToCreate = @LPNFormat,
             /* Prepare SeqNo and replace with <SeqNo> */
             @vNextSeqNo  = dbo.fn_LeftPadNumber(@NextSeqNo, @SeqNoMaxLength),
             @LPNToCreate = rtrim(replace(@LPNToCreate, '<SeqNo>', coalesce(@vNextSeqNo, '')));

      insert into @ttLPNs (EntityKey) select @LPNToCreate;

      select @NextSeqNo      = @vNextSeqNo + 1,
             @NumLPNsCreated = @NumLPNsCreated + 1;
    end

  /* Insert in LPNs table - by default Status will be set as 'N' (New) */
  insert into LPNs(LPN, LPNType, UniqueId, DestWarehouse, Ownership, BusinessUnit, CreatedBy)
    output inserted.LPNId, inserted.LPN into @ttLPNsGenerated(EntityId, EntityKey)
    select EntityKey, @LPNType, @LPNToCreate, @Warehouse, @vOwnership, @BusinessUnit, @UserId
    from @ttLPNs;

  select @NumLPNsCreated = @@rowcount;

  select top 1 @FirstLPNId = EntityId,
               @FirstLPN   = EntityKey
  from @ttLPNsGenerated
  order by RecordId;

  /* Grab the Last LPN and its Id to return */
  select top 1 @LastLPNId = EntityId,
               @LastLPN   = EntityKey
  from @ttLPNsGenerated
  order by RecordId desc;

  /* Audit Trail for generated LPNs */
  exec pr_AuditTrail_Insert 'LPNsGenerated', @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @AuditRecordId = @vAuditLPNRecordId output;

  /* If multiple LPNs are created and only one audit record is created for all LPNs of
  them, then associate the created LPNs with the Audit records */
  exec pr_AuditTrail_InsertEntities @vAuditLPNRecordId, 'LPN', @ttLPNsGenerated, @BusinessUnit;

  exec @Message = dbo.fn_Messages_Build 'LPNsCreatedSuccessfully', @NumLPNsCreated, @FirstLPN, @LastLPN;

ErrorHandler:
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName, @vLPNTypeDescription;

  commit transaction;
end try
begin catch
  rollback transaction;

  /* get the error number */
  select @vErrNum =  ERROR_NUMBER();

  /* Error Number "2627" is for Violation of Unique Key constraint Error, which will be more often due to
     missing controls we need to display user defined message rather than displaying SQL Error message */
  if (@vErrNum = 2627)
    exec @ReturnCode = pr_Messages_ErrorHandler 'ConfigurationsMissing';
  else
    /* Re-raise the error */
    exec pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNs_Generate */

Go
