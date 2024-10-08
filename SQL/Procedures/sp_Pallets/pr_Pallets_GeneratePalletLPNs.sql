/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/11/05  RIA     pr_Pallets_GeneratePalletLPNs: Made changes to generate char seq for cart positions as per the requirement (OB2-651)
  2016/07/25  TK      pr_Pallets_GeneratePalletLPNs: Update Pallet along with PalletId on the Cart Positions (HPI-368)
  2016/04/05  TK      pr_Pallets_GeneratePalletLPNs: Retrieve Pallet/LPN formats before Validations (NBD-340)
  2016/03/24  KL      pr_Pallets_GeneratePalletLPNs: Added validation to do not allow users to genarate pallets with invalid pallet formats (CIMS-810).
  2015/12/29  OK      pr_Pallets_GeneratePalletLPNs: Changed to display user defined error message instead of display SQL Error message(NBD-61)
  2015/09/08  RV      pr_Pallets_GeneratePalletLPNs: While generating Pallets avoid Creating positions for Inventory Pallets (FB-363)
  2014/08/07  TK      pr_Pallets_GeneratePalletLPNs: Updated not to allow Generating Pallets Types which are in view status.
  2014/06/11  TK      pr_Pallets_GeneratePalletLPNs: Included fn_Messages_Build to display message from
                         SQL side rather than displaying from UI.
  2013/11/19  AY      pr_Pallets_GeneratePalletLPNs: Do not create Pallet positions except for Carts
  2013/04/01  AY      pr_Pallets_GeneratePalletLPNs: Enhanced to have alphabetic sequence for LPNs
  2012/09/10  AY      pr_Pallets_GeneratePalletLPNs: Set Warehouse to null if not specified.
  2012/08/07  NY      pr_Pallets_GeneratePalletLPNs: Passing Warehouse in pallets table
  2012/07/31  YA      pr_Pallets_GeneratePalletLPNs: Modified to include audittrail on each pallet.
  2012/06/30  SP      Placed the transaction controls in 'pr_Pallets_GeneratePalletLPNs'
  2011/11/25  TD      pr_Pallets_GeneratePalletLPNs:Added DestWarehouse.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Pallets_GeneratePalletLPNs') is not null
  drop Procedure pr_Pallets_GeneratePalletLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Pallets_GeneratePalletLPNs: This procedure generates the requested
    type of Pallets and the LPNs and locates the LPNs on the pallet.
------------------------------------------------------------------------------*/
Create Procedure pr_Pallets_GeneratePalletLPNs
  (@PalletType            TTypeCode      = 'P',                    /* Pallet  */
   @NumPalletsToCreate    TCount,
   @PalletFormat          TDescription,
   @NumLPNsPerPallet      TCount,
   @LPNType               TTypeCode      = 'C',                    /* Carton    */
   @LPNFormat             TDescription,
   @DestWarehouse         TWarehouse,
   @BusinessUnit          TBusinessUnit,
   @UserId                TUserId,
   ---------------------------------------------------
   @FirstPalletId         TRecordId     = null output,
   @FirstPallet           TPallet       = null output,
   @LastPalletId          TRecordId     = null output,
   @LastPallet            TPallet       = null output,
   @NumPalletsCreated     TCount        = null output,
   @Message               TDescription  = null output)
As
  declare @ReturnCode                TInteger,
          @vMessageName              TMessageName,
          @vPalletToCreate           TPallet,
          @vPalletsCreated           TInteger,
          @vPalletSeqNoMaxLength     TInteger,
          @vPalletNextSeqNo          bigint,
          @vPalletNextSeqNoStr       TPallet,
          @vLPNToCreate              TLPN,
          @vLPNsCreated              TInteger,
          @vLPNNextSeqNo             bigint,
          @vLPNSeqNoMaxLength        TInteger,
          @vLPNNextSeqNoStr          TLPN,
          @vPalletControlCategory    TCategory,
          @vErrNum                   TInteger;

  declare @ttPalletsGenerated             TEntityKeysTable,
          @ttLPNsGenerated                TEntityKeysTable,
          @vAuditLPNRecordId              TRecordId,
          @vAuditPalletRecordId           TRecordId,
          @vAuditActivity                 TActivityType;

  declare @ttPallets Table
          (Pallet         TPallet,
           NumLPNs        TCount,
           PalletType     TTypeCode,
           BusinessUnit   TBusinessUnit,
           CreatedBy      TUserId);

  declare @ttLPNs Table
          (Pallet         TPallet,
           LPN            TLPN,
           LPNType        TTypeCode,
          --PalletId      TRecordId,
           BusinessUnit   TBusinessUnit,
           CreatedBy      TUserId);
begin
begin try
  begin transaction;

  SET NOCOUNT ON;

  /* Initialize */
  select @ReturnCode             = 0,
         @vMessageName           = null,
         @vPalletsCreated        = 0,
         @DestWarehouse          = nullif(@DestWarehouse, ''),
         @vPalletControlCategory = 'Pallet_' + @PALLETTYPE,
         @vAuditActivity         = case when @NumLPNsPerPallet > 0 then
                                     'PalletsGeneratedWithLPNs'
                                   else
                                     'PalletsGenerated'
                                   end;

  /* Read Pallet and LPN Formats from the Controls
     Read NextSeqNo and MaxLength information from Controls */
  select @PalletFormat          = coalesce(@PalletFormat,
                                           dbo.fn_Controls_GetAsString(@vPalletControlCategory, 'PalletFormat', 'P<SeqNo>',
                                                                       @BusinessUnit, @UserId)),
         @vPalletSeqNoMaxLength = dbo.fn_Controls_GetAsInteger(@vPalletControlCategory, 'PalletSeqNoMaxLength', '10',
                                                               @BusinessUnit, @UserId),
         @LPNFormat             = coalesce(@LPNFormat,
                                           dbo.fn_Controls_GetAsString(@vPalletControlCategory, 'PalletLPNFormat', '<PalletNo>-<SeqNo>',
                                                                       @BusinessUnit, @UserId)),
         @vLPNSeqNoMaxLength    = dbo.fn_Controls_GetAsInteger(@vPalletControlCategory, 'LPNSeqNoMaxLength', '10',
                                                               @BusinessUnit, @UserId);

  /* Only carts can have positions, so for all other pallets, clear the NumLPNsPerPallet */
  if (charindex(@PalletType, 'CTHF' /* Cart/Trolley */) = 0)
    select @NumLPNsPerPallet = 0;

  /* Validations */
  if (coalesce(@NumPalletsToCreate, 0) <= 0)
    set @vMessageName = 'NumPalletsToCreateNotDefined';
  else
  if (@NumLPNsPerPallet < 0)
    set @vMessageName = 'NumLPNsToCreateNotDefined';
  else
  if (not exists(select LookUpDescription
                 from vwLookUps
                 where (LookUpCategory like 'PalletFormat_' + @PalletType) and
                       (LookUpDescription = @PalletFormat)))
    set @vMessageName = 'InvalidPalletFormat';
  else
  if (@BusinessUnit is null)
    set @vMessageName = 'BusinessUnitIsInvalid';
  else
  if (@PalletType in (select Typecode
                      from EntityTypes
                      where Entity = 'Pallet' and
                            Status = 'V'))
    set @vMessageName = 'PalletTypeIsLimitedOnlyToView';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* Get the next Seq No */
  exec pr_Controls_GetNextSeqNo @vPalletControlCategory, @NumPalletsToCreate,
                                @UserId, @BusinessUnit,
                                @vPalletNextSeqNo output;

  if (@vPalletNextSeqNo is null)
    begin
      select @vMessageName = 'NextSeqNoMissing';
      goto ErrorHandler;
    end

  /* Create pallet and pallet's lpns */
  while (@vPalletsCreated < @NumPalletsToCreate)
    begin
      /* Build the Pallet Number as desired in the format */
      select @vPalletToCreate     = @PalletFormat,
             /* Prepare SeqNo and replace with <SeqNo> */
             @vPalletNextSeqNoStr = dbo.fn_LeftPadNumber(@vPalletNextSeqNo, @vPalletSeqNoMaxLength),
             @vPalletToCreate     = replace(@vPalletToCreate, '<SeqNo>', @vPalletNextSeqNoStr),
             @vLPNsCreated        = 0;

      /* Save First Pallet Created Information */
      if (@vPalletsCreated = 0)
        select @FirstPallet = @vPalletToCreate;

      /* Record the Pallet information in the Temporary Table */
      insert into @ttPallets
        select @vPalletToCreate, @NumLPNsPerPallet, @PalletType, @BusinessUnit, @UserId;

      /* It is possible that NumLPNsPerPallet is zero, in other words saying that generate only Pallets */
      select @vLPNNextSeqNo = 1;
      while (@vLPNsCreated < @NumLPNsPerPallet)
        begin
          /* Build the LPN Number as desired in the Format */
          select @vLPNToCreate     = @LPNFormat,
                 @vLPNToCreate     = replace(@vLPNToCreate, '<PalletNo>', @vPalletToCreate),
                 @vLPNNextSeqNoStr = dbo.fn_LeftPadNumber(@vLPNNextSeqNo, @vLPNSeqNoMaxLength),
                 @vLPNToCreate     = replace(@vLPNToCreate, '<SeqNo>', @vLPNNextSeqNoStr),
                 @vLPNToCreate     = Case /* Made changes to generate seq from A-Z, then AA,AB...AZ, BA..BZ, CA.. till 99 poistions */
                                       when @vLPNNextSeqNo <= 26
                                         then replace(@vLPNToCreate, '<CharSeq>', Char(64+@vLPNNextSeqNo))
                                       when @vLPNNextSeqNo % 26 = 0
                                         then replace(@vLPNToCreate, '<CharSeq>', Char(64+@vLPNNextSeqNo/26-1) + 'Z')
                                       else
                                         replace(@vLPNToCreate, '<CharSeq>', Char(64 + cast(@vLPNNextSeqNo/26 as integer)) + Char(64+@vLPNNextSeqNo%26))
                                     end;

          /* Record the LPN information in the Temporary Table */
          insert into @ttLPNs
            select @vPalletToCreate, @vLPNToCreate, @LPNType, @BusinessUnit, @UserId;

         select @vLPNNextSeqNo = @vLPNNextSeqNo + 1,
                @vLPNsCreated  = @vLPNsCreated + 1;
        end /* @vLPNsCreated < @NumLPNsPerPallet */

      select @vPalletsCreated  = @vPalletsCreated + 1, /* Increment Count */
             @vPalletNextSeqNo = @vPalletNextSeqNo + 1;
    end /* @vPalletsCreated < @NumPalletsToCreate */

  /* Save Last Pallet Created Information */
  select @LastPallet = @vPalletToCreate;

  /* Insert all Pallets saved in the Temp table */
  insert into Pallets(Pallet, NumLPNs, PalletType, Warehouse, BusinessUnit, CreatedBy)
      output Inserted.PalletId, Inserted.Pallet
      into @ttPalletsGenerated
    select Pallet, NumLPNs, PalletType, @DestWarehouse, BusinessUnit, CreatedBy
    from @ttPallets;

  /* capture the number of pallet created */
  select @NumPalletsCreated = @@rowcount;

  if (@NumLPNsPerPallet <> 0)
    begin
      /* Insert all LPNs saved in the Temp table */
      insert into LPNs (LPN, LPNType, UniqueId, PalletId, Pallet, Ownership, DestWarehouse, BusinessUnit, CreatedBy)
          output Inserted.LPNId, Inserted.LPN
          into @ttLPNsGenerated
        select L.LPN, L.LPNType, L.LPN, P.PalletId, P.Pallet, L.BusinessUnit, @DestWarehouse, L.BusinessUnit, L.CreatedBy
        from @ttLPNs L
             join Pallets P on (L.Pallet = P.Pallet);

        /* Audit Trail for generated LPNs */
        exec pr_AuditTrail_Insert 'LPNsGenerated', @UserId, null /* ActivityTimestamp */,
                                  @BusinessUnit  = @BusinessUnit,
                                  @AuditRecordId = @vAuditLPNRecordId output;

        /* If multiple LPNs and Pallets are created and only one audit record is created for all on pallets and LPNs of
        them, then associate the created LPNs and Pallets with the Audit records */
        exec pr_AuditTrail_InsertEntities @vAuditLPNRecordId, 'LPN', @ttLPNsGenerated, @BusinessUnit;
    end

  /* Generate Audit trail for Pallets and link with all Pallets generated */
  exec pr_AuditTrail_Insert @vAuditActivity, @UserId, null /* ActivityTimestamp */,
                            @NumLPNs       = @NumLPNsPerPallet,
                            @BusinessUnit  = @BusinessUnit,
                            @AuditRecordId = @vAuditPalletRecordId output;

  exec pr_AuditTrail_InsertEntities @vAuditPalletRecordId, 'Pallet', @ttPalletsGenerated, @BusinessUnit;

  /* Grab the First PalletId and Last Pallet Id to return */
  select @FirstPalletId = PalletId from Pallets where Pallet = @FirstPallet;
  select @LastPalletId  = PalletId from Pallets where Pallet = @LastPallet;

  /* Based upon the number of Pallets Generated we need to display an appropriate message */
  exec @Message = dbo.fn_Messages_Build 'PalletsCreatedSuccessfully', @NumPalletsCreated, @FirstPallet, @LastPallet;

ErrorHandler:
  if (@vMessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @vMessageName;

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
end /* pr_Pallets_GeneratePalletLPNs */

Go

/* Used to retrieve pallet id by scanning a Pallet or an LPN on the pallet */
