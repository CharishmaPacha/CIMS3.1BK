/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/10  TK      pr_CC_CompleteSKUCC: Initial Inv classes to default value if nothing passed in (HA-2236)
  2020/08/31  RIA     pr_CC_CompleteSKUCC: Changes to consider Inv Classes (CIMSV3-773)
  2020/07/20  RIA     pr_CC_CompleteSKUCC: Changes to Add Location proc signature (HA-652)
  2015/03/11  NY      pr_CC_CompleteSKUCC: Passing input parametr Operation to caller procedure pr_RFC_AddSKUToLocation(LL-133)
  2014/07/17  TD      pr_CC_CompleteSKUCC:Changes to ignore if the user doing cc with same quantity.
  2014/05/05  TD      pr_CC_CompleteSKUCC:Changes to do cycle count for Picklane case storage Locations.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_CC_CompleteSKUCC') is not null
  drop Procedure pr_CC_CompleteSKUCC;
Go
/*------------------------------------------------------------------------------
  Proc pr_CC_CompleteSKUCC:
------------------------------------------------------------------------------*/
Create Procedure pr_CC_CompleteSKUCC
  (@SKUCCDetails        XML,
   @BusinessUnit        TBusinessUnit,
   @UserId              TUserId,
   -------------------------------
   @vSKUMisplaced       TFlag output,
   @vFoundNewSKU        TFlag output,
   @vCountChanged       TFlag output)
as
  declare @vLocationId         TRecordId,
          @vLocation           TLocation,
          @vLocStorageType     TTypeCode,
          @vSKUId              TRecordId,
          @vSKU                TSKU,
          @vInnerPacks         TInnerpacks,
          @vSumScannedSKUQty   TQuantity,
          @vSumLocationSKUQty  TQuantity,
          @vSumScannedSKUCases TInnerPacks,
          @vSumLocSKUCases     TQuantity,

          /* Added Inv Classes */
          @vInventoryClass1    TInventoryClass,
          @vInventoryClass2    TInventoryClass,
          @vInventoryClass3    TInventoryClass,

          @vCCReasonCode       TReasonCode,
          @vCCAdjustReasonCode TReasonCode,
          @vMessageName        TMessageName,
          @ReturnCode          TInteger;
begin /* pr_CC_CompleteSKUCC */

  /* Initialize o/p params */
  select @vSKUMisplaced = '',
         @vFoundNewSKU  = '',
         @vCountChanged = '';

  /* Get default Reason code for cycle counting */
  select @vCCReasonCode       = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'CCDefault', '100' /* CIMS Default */, @BusinessUnit, @UserId);
  select @vCCAdjustReasonCode = dbo.fn_Controls_GetAsString('DefaultReasonCodes', 'CCAdjust',  null /* Default */, @BusinessUnit, @UserId);
  select @vCCAdjustReasonCode = coalesce(@vCCAdjustReasonCode, @vCCReasonCode);

  /* Insert the XML result into a temp table */
  select @vLocationId         = Record.Col.value('LocationId[1]'         ,   'TRecordId'  ),
         @vLocation           = Record.Col.value('Location[1]'           ,   'TLocation'  ),
         @vSKUId              = Record.Col.value('SKUId[1]'              ,   'TRecordId'  ),
         @vSKU                = Record.Col.value('SKU[1]'                ,   'TSKU'       ),
         @vInnerpacks         = Record.Col.value('Innerpacks[1]'         ,   'TInnerpacks'),
         @vSumScannedSKUQty   = Record.Col.value('SumScannedSKUQty[1]'   ,   'TQuantity'  ),
         @vSumLocationSKUQty  = Record.Col.value('SumLocationSKUQty[1]'  ,   'TQuantity'  ),
         @vSumScannedSKUCases = Record.Col.value('SumScannedSKUCases[1]' ,   'TInnerPacks'),
         @vSumLocSKUCases     = Record.Col.value('SumLocationSKUCases[1]',   'TQuantity'  )
  from @SKUCCDetails.nodes('CYCLECOUNTLOCATION/LOCATIONSKUINFO') as Record(Col)

  /* Get Location Storage Type here */
  select @vLocStorageType = StorageType
  from Locations
  where (LocationId = @vLocationId);

  /* Fetch the Inventory Classes based on LocationId and SKUId */
  select @vInventoryClass1 = InventoryClass1,
         @vInventoryClass2 = InventoryClass2,
         @vInventoryClass3 = InventoryClass3
  from LPNs
  where (LocationId = @vLocationId) and
        (SKUId      = @vSKUId);

  /* If the Scanned SKU Quantity is zero, then Adjust Location with the Scanned SKU Quantity */
  if ((@vSumScannedSKUQty = 0) and (@vSumScannedSKUCases = 0))
    begin
      exec @ReturnCode = pr_RFC_AdjustLocation @vLocationId,
                                               @vLocation,
                                               @vSKUId,
                                               @vSKU,
                                               0 /* Inner Packs */,
                                               0 /* Quantity    */,
                                               @vCCAdjustReasonCode /* Reason Code */,
                                               @BusinessUnit,
                                               @UserId;

      select @vSKUMisplaced = 'M'; /* SKU Misplaced */
    end
  else
  /* if LocationSKUQty is 0 then it means there is no SKU present and we need to AddSKUToLocation. */
  if (@vSumLocationSKUQty = 0)
    begin
      exec @ReturnCode = pr_RFC_AddSKUToLocation @vLocationId,
                                                 @vLocation,
                                                 @vSKUId,
                                                 @vSKU,
                                                 @vSumScannedSKUCases,
                                                 @vSumScannedSKUQty,
                                                 @vCCAdjustReasonCode /* Reason Code */,
                                                 'AddSKU' /* Operation */,
                                                 @vInventoryClass1,
                                                 @vInventoryClass2,
                                                 @vInventoryClass3,
                                                 @BusinessUnit,
                                                 @UserId;

      select @vFoundNewSKU = 'N'; /* New SKU in Location */
    end
  else
  /* if Scanned SKU qty has changes then update sku qty with Scanned qty - already present sku qty */
  if (((@vSumScannedSKUQty <> @vSumLocationSKUQty) and (@vLocStorageType like 'U%' /* Units */)) or
       ((@vSumScannedSKUCases <> @vSumLocSKUCases) and (@vLocStorageType like 'P%' /* packages */)))
    begin
      exec @ReturnCode = pr_RFC_AdjustLocation @vLocationId,
                                               @vLocation,
                                               @vSKUId,
                                               @vSKU,
                                               @vSumScannedSKUCases,
                                               @vSumScannedSKUQty,
                                               @vCCAdjustReasonCode /* Reason Code */,
                                               @BusinessUnit,
                                               @UserId;

      select @vCountChanged = 'Q'; /* Change in Quantity */
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end   /* pr_CC_CompleteSKUCC */

Go
