/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/04/29  HYP     pr_LPNs_CreateInvLPNs & pr_LPNs_CreateInvLPN: Added InventoryClass1 (CIMSV3-861)
  2019/01/18  KSK     pr_LPNs_CreateInvLPNs, pr_LPNs_Void: Added Reference and Generating export while creating Inventory for LPNs (S2GCA-460&461)
  2018/07/26  NB      pr_LPNs_CreateInvLPNs: Added condition to check trancount before rollback call(CIMSV3-299)
  2018/05/07  CK      pr_LPNs_CreateInvLPNs: Restricted to not allow non standard cases (S2G-745)
  2016/05/04  TK      pr_LPNs_CreateInvLPNs: We can have more than one Prepack in LPN (FB-648)
  2014/09/23  AK      pr_LPNs_CreateInvLPNs: Set to display error if Quantity not equal to UnitsPerCase * Innerpacks.
  2014/05/23  PKS     pr_LPNs_CreateInvLPN, pr_LPNs_CreateInvLPNs: Added CreatedDate
  2014/02/25  TD      pr_LPNs_CreateInvLPNs, pr_LPNs_CreateInvLPN: Changes to update ExpiryDate and Lot to LPNs.
  2012/12/01  YA      pr_LPNs_CreateInvLPNs: Fix validations to not consider inactive SKUPrepacks.
  2012/10/11  AY      pr_LPNs_CreateInvLPNs: Pass reason code for creating Inventory
  2012/10/09  VM      pr_LPNs_CreateInvLPNs: Added valid messages when pallet is validated
  2012/09/28  AA      pr_LPNs_CreateInvLPNs: Added validation to not allow to create inventory for In active SKUs
  2012/06/30  SP      Placed the transaction controls in 'pr_LPNs_CreateInvLPNs' and 'pr_LPNs_Void'.
  2012/06/30  PKS     pr_LPNs_CreateInvLPNs: Success message added.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_LPNs_CreateInvLPNs') is not null
  drop Procedure pr_LPNs_CreateInvLPNs;
Go
/*------------------------------------------------------------------------------
  Proc pr_LPNs_CreateInvLPNs:

  Generate Pallet: Now we have added 3 options here
       1. If user selects generate then we need to generate a pallet.  Flag is -Y
       2. if user selcted Scan then he should scan the Pallet, otherwise we will
          raise an error.  Flag Is N
       3. If user selects ignore then we do not generate any Pallet, we do not
          raise any  error. Flag is I
------------------------------------------------------------------------------*/
Create Procedure pr_LPNs_CreateInvLPNs
  (@LPNType          TTypeCode = 'C' /* Carton */,
   @SKU              TSKU,
   @InnerPacks       TInnerPacks,
   @Quantity         TQuantity,
   @UnitsPerCase     TQuantity = null,
   @NumLPNs          TCount,
   @Lot              TLot,
   @Expirydate       TDate,
   @CoO              TCoO,
   @Ownership        TOwnership,
   @DestWarehouse    TWarehouse,
   @ReasonCode       TReasonCode,
   @InventoryClass1  TInventoryClass,
   @InventoryClass2  TInventoryClass = null,
   @InventoryClass3  TInventoryClass = null,
   @Reference        TReference,
   @GeneratePallet   TFlag,-- which will be passed to get the option whether to generate palletor not
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId,
   @CreatedDate      TDateTime,
   @FirstLPNId       TRecordId    = null output,
   @FirstLPN         TLPN         = null output,
   @LastLPNId        TRecordId    = null output,
   @LastLPN          TLPN         = null output,
   @Pallet           TPallet      = null output,
   @NumLPNsCreated   TCount       = null output,
   @Message          TDescription        output)
as
  /* Declare local variables */
  declare @MessageName            TMessageName,
          @ReturnCode             TInteger,

          @vPalletType            TTypeCode,
          @vPalletId              TRecordId,
          @vPalletFormat          TDescription,
          @vLPNFormat             TControlValue,
          @LPNId                  TRecordId,
          @LPNDetailsId           TRecordId,
          @LPN                    TLPN,
          @vSKUId                 TRecordId,
          @vNumLPNs               TCount,
          @vPallet                TPallet,
          @vPalletStatus          TStatus,
          @vSKUStatus             TStatus,
          @vSKUUoM                TUoM,
          @vSKUUnitsPerInnerPack  TInteger,

          @vCreateInventoryForInactiveSKUs  TControlValue,
          @vAllowNonStandardPackConfig      TControlValue;

  select @ReturnCode  = 0,
         @MessageName = null;

begin
begin try
  begin transaction
  SET NOCOUNT ON;

  select @ReturnCode     = 0,
         @MessageName    = null,
         @NumLPNsCreated = 0,
         @Pallet         = nullif(rtrim(ltrim(@Pallet)), '');

  select @vCreateInventoryForInactiveSKUs = dbo.fn_Controls_GetAsString('Inventory', 'CreateInvForInactiveSKUs', 'N', @BusinessUnit, @UserId),
         @vAllowNonStandardPackConfig     = dbo.fn_Controls_GetAsString('LPN_INV', 'AllowNonStandardPackConfig', 'N', @BusinessUnit, @UserId);

  /*
  1. Validate SKU, LPNtype, DestWarehouse, BusinessUnit.
  2. If the flag for Generate pallet is true, then create a new pallet and pass the PalletId to the proc pr_LPN_CreateLPN.
  3. Loop through the procedure pr_LPNs_CreateLPN on the count mentioned in @NumLPNs.
  3. return Count, Start and end LPNs created.
  */

  if (@InnerPacks > 0) and (@Quantity <> @UnitsPerCase * @Innerpacks)
    set @MessageName = 'LPN quantity and total units per case mismatch.'
  else
  /* Create pallets in case GeneratePallets flag is true and Pallet is not sent as i/p param */
  if (@GeneratePallet = 'Y' /* Yes */)
    begin
      select @vPalletType = 'I'; /* Inventory Pallet */

      exec @ReturnCode = pr_Pallets_GeneratePalletLPNs  @vPalletType  /* PalletType */,
                                                        1             /* NumPalletsToCreate */,
                                                        @vPalletFormat/* PalletFormat */,
                                                        0             /* NUMLPNs */ ,
                                                        null          /* LPNType */,
                                                        null          /* LPNFormat */ ,
                                                        @DestWarehouse/* DestWarehouse */,
                                                        @BusinessUnit /* BusinessUnit */,
                                                        @UserId       /* UserId */,
                                                        @vPalletId output,
                                                        @Pallet    output;

      if (@ReturnCode > 0)
        goto ExitHandler;
    end
  else
  if (@GeneratePallet = 'N' /* generate - No, User will scan */) and
     (@Pallet is not null) /* Validate, if Pallet is given */
    begin
      select @vPalletId     = PalletId,
             @vPalletStatus = Status
      from Pallets
      where (Pallet       = @Pallet) and
            (BusinessUnit = @Businessunit);

      if (@vPalletId is null)
        set @MessageName = 'LPN_CreateInvLPNs_InvalidPallet';
      else
      if (@vPalletStatus not in ('E' /* Empty */, 'R'/* Received */))
        set @MessageName = 'LPN_CreateInvLPNs_InvalidPalletStatus';
    end

  /* If Error, then return Error Code/Error Message */
  if (@MessageName is not null)
    goto ErrorHandler;

  select @vSKUId                = SKUId,
         @vSKUStatus            = Status,
         @vSKUUoM               = UoM,
         @vSKUUnitsPerInnerPack = UnitsPerInnerPack
  from SKUs
  where (SKU = @SKU);

  /* Check SKU status */
  if (@vSKUStatus = 'I' /* Inactive */) and (@vCreateInventoryForInactiveSKUs = 'N')
    set @MessageName = 'SKUIsInactive';
  else
  if ((@vAllowNonStandardPackConfig  = 'N' /* No */) and (@UnitsPercase <> @vSKUUnitsPerInnerPack))
    set @MessageName = 'NonStandardCasesNotAllowed';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Loop through and create LPNs */
  while (@NumLPNsCreated < @NumLPNs)
    begin
      exec @ReturnCode = pr_LPNs_CreateInvLPN @LPNType,
                                              @vSKUId,
                                              @InnerPacks,
                                              @Quantity,
                                              @CoO,
                                              @vPalletId,
                                              @Lot,
                                              @ExpiryDate,
                                              @Ownership,
                                              @DestWarehouse,
                                              @ReasonCode,
                                              @InventoryClass1,
                                              @InventoryClass2,
                                              @InventoryClass3,
                                              @Reference,
                                              @BusinessUnit,
                                              @UserId,
                                              @CreatedDate,
                                              @LastLPNId    output,
                                              @LastLPN      output,
                                              @LPNDetailsId output,
                                              @Message      output;

      if (@ReturnCode > 0)
        goto ExitHandler;

      /* select values in to variables and send it as o/p's */
      if (@FirstLPNId is null)
        select @FirstLPNId = @LastLPNId,
               @FirstLPN   = @LastLPN;

      select @NumLPNsCreated = @NumLPNsCreated + 1;
    end

  if (@NumLPNsCreated = 1)
    exec @Message = dbo.fn_Messages_Build 'LPN_CreateInvLPNs_Successful1', Default, @FirstLPN;
  else
  if (@NumLPNsCreated > 1)
    exec @Message = dbo.fn_Messages_Build 'LPN_CreateInvLPNs_Successful2',
                      @NumLPNsCreated, @FirstLPN, @LastLPN;
  else
    exec @Message = dbo.fn_Messages_Build 'LPN_CreateInvLPNs_NoneCreated';

  /* If LPNs created then return the data to print the labels */
  if (@NumLPNsCreated > 0)
    insert into #ResultData (FieldName, FieldValue)
            select 'FirstLPNId', cast(@FirstLPNId as varchar)
      union select 'FirstLPN', @FirstLPN
      union select 'LastLPNId', cast(@LastLPNId as varchar)
      union select 'LastLPN', @LastLPN;

  /* Inserted the messages information to display in V3 application */
  if (object_id('tempdb..#ResultMessages') is not null)
    insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, @Message;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_LPNs_CreateInvLPNs */

Go
