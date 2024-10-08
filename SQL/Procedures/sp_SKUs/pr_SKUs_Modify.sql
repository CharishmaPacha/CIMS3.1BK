/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/19  RKC     pr_SKUs_Modify:Changes to update the UOM, InventoryUoM, UPC fields on SKUs table (HA-539)
  2020/02/11  MS      pr_SKUs_Modify: Changes to modify SKU Dimensions by CIMS (JL-76)
  2019/05/07  RIA     pr_SKUs_Modify: Changes to calculate the Volume when it is auto calculated incorrectly in UI (S2GCA-739)
  2019/02/18  RIA     pr_SKUs_Modify: Changes to consider ModifyPackConfigurations, ModifySKUClasses (CIMSV3-219)
  2018/09/28  CK      pr_SKUs_Modify: Introduce new action ModifyCartonGroups to modify sku (HPI-2044)
  2018/06/19  MJ      pr_SKUs_Modify: Changes to ShipPack field (S2G-967)
  2018/05/30  AY      pr_SKUs_Modify: InnerPacksPerLPN initialized with UnitsPerInnerPack - fixed
  2018/05/15  AJ      pr_SKUs_Modify :Added AlternateSKU field (S2G-844)
  2018/04/02  MJ/YJ   pr_SKUs_Modify :Changes to field CaseUPC field (S2G-528)
  2018/02/07  CK      pr_SKUs_Modify: Enhanced to modify InnerPack dimensions on SKUS (S2G-18)
  2017/08/07  TK      pr_SKUs_Modify: Changes to modify ReplenishClass on SKUs (HPI-1624)
  2016/11/21  CK      pr_SKUs_Modify: Made changes to clear PA Class (HPI-1064)
  2015/05/30  TK      pr_SKUs_Modify: Update PalletTie and PalletHigh.
  2014/03/05  PK      pr_SKUs_Modify: On updating UnitsPerInnerPack also updating InnerPacksPerLPN with the same value.
  2014/03/03  NY      pr_SKUs_Modify: Changed fn_Messages_Build to use fn_Messages_BuildActionResponse to display messages.
  2013/10/10  TD      pr_SKUs_Modify: Calling procedure to preprocess the SKU.
  2103/09/03  NY      pr_SKUs_Modify: Changed Datatype TVarchar ->TFloat.
  2013/08/06  TD      pr_SKUs_Modify: Allow users to modify one field, so changed
  2013/08/05  TD      Added pr_SKUs_Modify.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_SKUs_Modify') is not null
  drop Procedure pr_SKUs_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_SKUs_Modify:
------------------------------------------------------------------------------*/
Create Procedure pr_SKUs_Modify
  (@SKUContents       TXML,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @Message           TNVarChar output)
as
  declare @ReturnCode          TInteger,
          @MessageName         TMessageName,
          @vEntity             TEntity  = 'SKU',
          @vAction             TAction,
          @vPAClass            TCategory,
          @vReplenishClass     TCategory,
          @vABCClass           TCategory,
          @xmlData             xml,
          @vSKUsCount          TCount,
          @vSKUsUpdated        TCount,
          @vBusinessUnit       TBusinessUnit,
          @vUnitLength         TFloat,
          @vUnitWidth          TFloat,
          @vUnitHeight         TFloat,
          @vUnitVolume         TFloat,
          @vUnitWeight         TFloat,
          @vUnitsPerInnerPack  TVarchar,
          @vTransType          TTypeCode,
          @vInnerPacksPerLPN   Tvarchar,
          @vInnerPackLength    TFloat,
          @vInnerPackWidth     TFloat,
          @vInnerPackHeight    TFloat,
          @vInnerPackVolume    TFloat,
          @vInnerPackWeight    TFloat,
          @vCaseUPC            TUPC,
          @vUPC                TUPC,
          @vUOM                TUOM,
          @vInventoryUoM       TUOM,
          @vAlternateSKU       TSKU,
          @vUnitsPerLPN        TFloat,
          @vShipPack           TInteger,
          @vTie                TVarchar,
          @vHigh               TVarchar,
          @vCartonGroup        TCategory;

   declare @vSKUPutawayClassUpdate   TString,
           @vSKUReplenishClassUpdate TString,
           @vSKUABCClassUpdate       TString,
           @vSKUPackInfoUpdate       Tstring,
           @vSKUCubeUpdate           TString,
           @vSKUWeightUpdate         TString,
           @vSKUShipPackUpdate       TString,
           @vSKUPalletTieHighUpdate  Tstring,
           @vSKUDimensionUpdate      TString,
           @vSKUIPDimensionUpdate    TString,
           @vSKUIPCubeUpdate         TString,
           @vSKUIPWeightUpdate       TString,
           @vSKUCaseUPCUpdate        TString,
           @vSKUAlternateSKUUpdate   TString,
           @vSKUUPCsUpdate           TString;

   declare @vNote1                 TDescription,
           @vActivityType          TActivityType,
           @vAuditId               TRecordId,
           @vAuditRecordId         TRecordId;

  /* Temp table to hold all the SKUs to be updated */
  declare @ttSKUs        TEntityKeysTable;
  declare @ttSKUsUpdated TEntityKeysTable;

begin /* pr_SKUs_Modify */
begin try
  begin transaction;
  SET NOCOUNT ON;
  set @xmlData = convert(xml, @SKUContents);

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    return

   /* TD: I have changed the variable declaration from float to varchar,
          Yes, the variable declaration is not correct. But it is for one reason.
          I.E If the user wants to change only one filed and remaining all should be
          the same as earlier. So for this I have made this change. */

  /* Get the Action from the xml */
  select @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/ModifySKUs') as Record(Col);

  /* Load all the SKUs into the temp table which are to be updated in SKUs table */
  insert into @ttSKUs (EntityId)
    select Record.Col.value('.', 'TRecordId') SKU
    from @xmlData.nodes('/ModifySKUs/SKUs/SKUId') as Record(Col);

  /* Get number of rows inserted */
  select @vSKUsCount = @@rowcount;

  select @vSKUDimensionUpdate      = dbo.fn_Controls_GetAsString('SKU', 'SKUDimensionUpdate',     'HOST', @BusinessUnit, '');
  select @vSKUShipPackUpdate       = dbo.fn_Controls_GetAsString('SKU', 'SKUShipPackUpdate',      'HOST', @BusinessUnit, '');
  select @vSKUPalletTieHighUpdate  = dbo.fn_Controls_GetAsString('SKU', 'PalletTieHighUpdate',    'HOST', @BusinessUnit, '');
  select @vSKUPackInfoUpdate       = dbo.fn_Controls_GetAsString('SKU', 'SKUPackInfoUpdate',      'HOST', @BusinessUnit, '');
  select @vSKUCubeUpdate           = dbo.fn_Controls_GetAsString('SKU', 'SKUCubeUpdate',          'HOST', @BusinessUnit, '');
  select @vSKUWeightUpdate         = dbo.fn_Controls_GetAsString('SKU', 'SKUWeightUpdate',        'HOST', @BusinessUnit, '');
  select @vSKUIPDimensionUpdate    = dbo.fn_Controls_GetAsString('SKU', 'SKUIPDimensionUpdate',   'HOST', @BusinessUnit, '');
  select @vSKUIPCubeUpdate         = dbo.fn_Controls_GetAsString('SKU', 'SKUIPCubeUpdate',        'HOST', @BusinessUnit, '');
  select @vSKUIPWeightUpdate       = dbo.fn_Controls_GetAsString('SKU', 'SKUIPWeightUpdate',      'HOST', @BusinessUnit, '');
  select @vSKUPutawayClassUpdate   = dbo.fn_Controls_GetAsString('SKU', 'PutawayClassUpdate',     'HOST', @BusinessUnit, '');
  select @vSKUReplenishClassUpdate = dbo.fn_Controls_GetAsString('SKU', 'ReplenishClassUpdate',   'HOST', @BusinessUnit, '');
  select @vSKUABCClassUpdate       = dbo.fn_Controls_GetAsString('SKU', 'ABCClassUpdate',         'HOST', @BusinessUnit, '');
  select @vSKUCaseUPCUpdate        = dbo.fn_Controls_GetAsString('SKU', 'SKUCaseUPCUpdate',       'HOST', @BusinessUnit, '');
  select @vSKUAlternateSKUUpdate   = dbo.fn_Controls_GetAsString('SKU', 'SKUAlternateSKUUpdate',  'HOST', @BusinessUnit, '');
  select @vSKUUPCsUpdate           = dbo.fn_Controls_GetAsString('SKU', 'SKUUPCsUpdate',          'HOST', @BusinessUnit, '');

  if (@vAction in ('ModifySKU', 'ModifyAliases', 'ModifySKUDimensions', 'ModifyPackConfigurations', 'ModifySKUClasses'))
    begin
      select @vPAClass           = nullif(Record.Col.value('PutawayClass[1]',      'TCategory'), ''),
             @vReplenishClass    = nullif(Record.Col.value('ReplenishClass[1]',    'TCategory'), ''),
             @vABCClass          = nullif(Record.Col.value('ABCClass[1]',          'TCategory'), ''),
             @vUnitLength        = nullif(Record.Col.value('UnitLength[1]',        'TVarchar'),  ''),
             @vUnitWidth         = nullif(Record.Col.value('UnitWidth[1]',         'TVarchar'),  ''),
             @vUnitHeight        = nullif(Record.Col.value('UnitHeight[1]',        'TVarchar'),  ''),
             @vUnitVolume        = nullif(Record.Col.value('UnitVolume[1]',        'TVarchar'),  ''),
             @vUnitWeight        = nullif(Record.Col.value('UnitWeight[1]',        'TVarchar'),  ''),
             @vUnitsPerInnerPack = nullif(Record.Col.value('UnitsPerInnerPack[1]', 'TVarchar'),  ''),
             @vUnitsPerLPN       = nullif(Record.Col.value('UnitsPerLPN [1]',      'TVarchar'),  ''),
             @vShipPack          = nullif(Record.Col.value('ShipPack [1]',         'TVarchar'),  ''),
             @vInnerPacksPerLPN  = nullif(Record.Col.value('InnerPacksperLPN [1]', 'TVarchar'),  ''),
             @vInnerPackLength   = nullif(Record.Col.value('InnerPackLength [1]',  'TVarchar'),  ''),
             @vInnerPackWidth    = nullif(Record.Col.value('InnerPackWidth [1]',   'TVarchar'),  ''),
             @vInnerPackHeight   = nullif(Record.Col.value('InnerPackHeight [1]',  'TVarchar'),  ''),
             @vInnerPackVolume   = nullif(Record.Col.value('InnerPackVolume [1]',  'TVarchar'),  ''),
             @vInnerPackWeight   = nullif(Record.Col.value('InnerPackWeight [1]',  'TVarchar'),  ''),
             @vCaseUPC           = nullif(Record.Col.value('CaseUPC [1]',          'TVarchar'),  ''),
             @vUPC               = nullif(Record.Col.value('UPC [1]',               'TVarchar'), ''),
             @vUOM               = nullif(Record.Col.value('UoM [1]',               'TUoM'), ''),
             @vInventoryUoM      = nullif(Record.Col.value('InventoryUoM [1]',      'TUoM'), ''),
             @vAlternateSKU      = nullif(Record.Col.value('AlternateSKU [1]',     'TVarchar'),  ''),
             @vTie               = nullif(Record.Col.value('Tie[1]',               'TVarchar'),  ''),
             @vHigh              = nullif(Record.Col.value('High[1]',              'TVarchar'),  '')
      from @xmlData.nodes('/ModifySKUs/Data') as Record(Col);

      /* If the SKU Dimensions are not maintained on CIMS, then do not accept values from caller */
      if (dbo.fn_IsInList('CIMS', @vSKUDimensionUpdate) = 0)
        select @vUnitLength = null,
               @vUnitWidth  = null,
               @vUnitHeight = null;

      if (dbo.fn_IsInList('CIMS', @vSKUIPDimensionUpdate) = 0)
        select @vInnerPackLength = null,
               @vInnerPackWidth  = null,
               @vInnerPackHeight = null;

      if (dbo.fn_IsInList('CIMS', @vSKUPackInfoUpdate) = 0)
        select @vUnitsPerInnerPack = null,
               @vInnerPacksPerLPN  = null,
               @vUnitsPerLPN       = null;

      if (dbo.fn_IsInList('CIMS', @vSKUCubeUpdate)           = 0) select @vUnitVolume      = null;
      if (dbo.fn_IsInList('CIMS', @vSKUIPCubeUpdate)         = 0) select @vInnerPackVolume = null;
      if (dbo.fn_IsInList('CIMS', @vSKUWeightUpdate)         = 0) select @vUnitWeight      = null;
      if (dbo.fn_IsInList('CIMS', @vSKUIPWeightUpdate)       = 0) select @vInnerPackWeight = null;
      if (dbo.fn_IsInList('CIMS', @vSKUCaseUPCUpdate)        = 0) select @vCaseUPC         = null;
      if (dbo.fn_IsInList('CIMS', @vSKUAlternateSKUUpdate)   = 0) select @vAlternateSKU    = null;
      if (dbo.fn_IsInList('CIMS', @vSKUPutawayClassUpdate)   = 0) select @vPAClass         = null;
      if (dbo.fn_IsInList('CIMS', @vSKUReplenishClassUpdate) = 0) select @vReplenishClass  = null;
      if (dbo.fn_IsInList('CIMS', @vSKUABCClassUpdate)       = 0) select @vABCClass        = null;
      if (dbo.fn_IsInList('CIMS', @vSKUShipPackUpdate)       = 0) select @vShipPack        = null;

      if (dbo.fn_IsInList('CIMS', @vSKUPalletTieHighUpdate) = 0)
        select @vTie  = null,
               @vHigh = null;

      /* Update SKUs */
      update S
      set PutawayClass      = case
                                when  (@vPAClass  = '$ClearPAClass$') then
                                  null
                                else
                                  coalesce(@vPAClass, PutawayClass)
                              end,
          ReplenishClass    = case
                                when  (@vReplenishClass  = '$ClearReplenishClass$') then
                                  null
                                else
                                  coalesce(@vReplenishClass, ReplenishClass)
                              end,
          ABCClass          = case
                                when (@vABCClass = '$ClearABCClass$') then
                                  null
                                else
                                  coalesce(@vABCClass, ABCClass)
                              end,
          UnitLength        = coalesce(@vUnitLength, UnitLength),
          UnitWidth         = coalesce(@vUnitWidth,  UnitWidth),
          UnitHeight        = coalesce(@vUnitHeight, UnitHeight),
          UnitVolume        = case
                                /* If Unit volume is left blank but one of the dimensions is changed, then recompute it */
                                when (@vUnitVolume is null) and
                                     ((coalesce(@vUnitLength, 0) > 0) or
                                      (coalesce(@vUnitWidth,  0) > 0) or
                                      (coalesce(@vUnitHeight, 0) > 0)) then
                                  (coalesce(@vUnitLength, UnitLength, 0) *
                                   coalesce(@vUnitWidth,  UnitWidth,  0) *
                                   coalesce(@vUnitHeight, UnitHeight, 0))
                                /* When unit volume is given as zero by user, then recompute it using new/old dimensions */
                                when (@vUnitVolume = 0) then
                                  (coalesce(@vUnitLength, UnitLength, 0) * coalesce(@vUnitWidth, UnitWidth, 0) * coalesce(@vUnitHeight, UnitHeight, 0))
                                else
                                  coalesce(@vUnitVolume, UnitVolume)
                              end,
          UnitWeight        = coalesce(@vUnitWeight, UnitWeight),
          InnerPackLength   = coalesce(@vInnerPackLength, InnerPackLength),
          InnerPackWidth    = coalesce(@vInnerPackWidth, InnerPackWidth),
          InnerPackHeight   = coalesce(@vInnerPackHeight, InnerPackHeight),
          InnerPackVolume   = case
                                when (@vInnerPackVolume is null) and
                                     ((coalesce(@vInnerPackLength, 0) > 0) or
                                      (coalesce(@vInnerPackWidth,  0) > 0) or
                                      (coalesce(@vInnerPackHeight, 0) > 0)) then
                                  (coalesce(@vInnerPackLength, InnerPackLength, 0) *
                                   coalesce(@vInnerPackWidth,  InnerPackWidth,  0) *
                                   coalesce(@vInnerPackHeight, InnerPackHeight, 0))
                                when (@vInnerPackVolume = 0) then
                                  (coalesce(@vInnerPackLength, InnerPackLength, 0) * coalesce(@vInnerPackWidth, InnerPackWidth, 0) * coalesce(@vInnerPackHeight, InnerPackHeight, 0))
                                else
                                  coalesce(@vInnerPackVolume, InnerPackVolume)
                              end,
          InnerPackWeight   = coalesce(@vInnerPackWeight, InnerPackWeight),
          CaseUPC           = coalesce(rtrim(ltrim(@vCaseUPC)), CaseUPC),
          AlternateSKU      = coalesce(@vAlternateSKU, AlternateSKU),
          UnitsPerLPN       = coalesce(@vUnitsPerLPN, UnitsPerLPN),
          ShipPack          = coalesce(@vShipPack, ShipPack),
          PalletTie         = coalesce(@vTie, PalletTie),
          PalletHigh        = coalesce(@vHigh, PalletHigh),
          UoM               = coalesce(@vUOM, UoM),
          UPC               = coalesce(@vUPC, UPC),
          InventoryUoM      = coalesce(@vInventoryUoM, InventoryUoM),
          UnitsPerInnerPack = coalesce(@vUnitsPerInnerPack, UnitsPerInnerPack),
          InnerPacksPerLPN  = coalesce(@vInnerPacksPerLPN, InnerPacksPerLPN),
          ModifiedDate      = current_timestamp,
          ModifiedBy        = @UserId
      output Inserted.SKUId, Inserted.SKU
      into @ttSKUsUpdated
      from SKUs S
        join @ttSKUs TS on (TS.EntityId = S.SKUId);

      /* Get the count of total number of SKUs Updated */
      set @vSKUsUpdated = @@rowcount;

      /* AT related */
      select @vActivityType = 'SKUDimensionsModified',
             @vNote1        = @vPAClass,
             @vTransType    = 'SKUCh';

      /* call procedure here to recalculate PutawayClass */
      exec pr_SKUs_PreProcess @ttSKUs, null /* SKUId */, @BusinessUnit;
    end
  else
  if (@vAction = 'ModifyCartonGroup') /* To modify Cartongroups on SKU */
    begin
      select @vCartonGroup = nullif(Record.Col.value('CartonGroup[1]', 'TVarchar'), '')
      from @xmlData.nodes('/ModifySKUs/Data') as Record(Col);

      /* Update SKUs */
      update S
      set CartonGroup       = coalesce(@vCartonGroup, CartonGroup),
          ModifiedDate      = current_timestamp,
          ModifiedBy        = @UserId
      output Inserted.SKUId, Inserted.SKU
      into @ttSKUsUpdated
      from SKUs S
        join @ttSKUs TS on (TS.EntityId = S.SKUId);

      /* Get the count of total number of SKUs Updated */
      set @vSKUsUpdated = @@rowcount;

      /* AT related */
      select @vActivityType = 'SKUCartonGroupModified';

      /* call procedure here to recalculate PutawayClass */
      exec pr_SKUs_PreProcess @ttSKUs, null /* SKUId */, @BusinessUnit;
    end
  else
    begin
      /* If the action is not one of the above, send a message to UI saying Unsupported Action*/
      set @MessageName = 'UnsupportedAction';
      goto ErrorHandler;
    end;

  /* Only if any of the SKUs are updated, generate audittrail else skip. */
  If (@vSKUsUpdated > 0)
    begin
     /* Currently we are setting Business Unit as hard coded for this release(12/3).
        we need to further change the signature to pass BusinessUnit also(ta5691 created)*/
      exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                                @BusinessUnit  = @BusinessUnit,
                                @Note1         = @vNote1,
                                @AuditRecordId = @vAuditId output;

      exec pr_AuditTrail_InsertEntities @vAuditId, 'SKU', @ttSKUsUpdated, @BusinessUnit;

     /* Call Export Proc here to export data */
      exec pr_Exports_SKUData  @vTransType, @ttSKUsUpdated, null/* SKUId*/, null /* UPC */, @BusinessUnit, @UserId;
    end

  /* Based upon the number of SKUs that have been modified, give an appropriate message */
  if (coalesce(@Message, '') = '')
    exec @Message = dbo.fn_Messages_BuildActionResponse @vEntity, @vAction, @vSKUsUpdated, @vSKUsCount;

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  if (@@trancount > 0) rollback transaction;

  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_SKUs_Modify */

Go
