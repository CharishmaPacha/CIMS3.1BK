/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2015/10/07  AY      fn_Imports_ValidateInputData: Bug fix - clearing error (CIMS-603)
  2015/02/24  NB      fn_Imports_ValidateInputData: Fix to handle IsInvalid validation with EntityKey
                        modified function signature to accept id field. modified callers to pass in id along with
                        key field value
  2014/12/02  NB      Added functions fn_Imports_ValidateLookUp and fn_Imports_ValidateInputData
                      Modified pr_Imports_ValidateSKU to use new functions for Code optimization
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Imports_ValidateInputData') is not null
  drop Function fn_Imports_ValidateInputData;
Go
/*------------------------------------------------------------------------------
  Function fn_Imports_ValidateInputData:
    Certain fields are to be validated often during import and this logic
    has been repeated in several places and hence all of this code is
    refactored into this one generic procedure. For some imports these fields
    may not exist, so in that case, we would pass in @@  to skip the validation
    of that field.
------------------------------------------------------------------------------*/
Create Function fn_Imports_ValidateInputData
  (
   @EntityType    TTypeCode,
   @EntityKey     TEntity,
   @EntityId      TInteger,
   @RecordAction  TAction,
   @BusinessUnit  TBusinessUnit,
   @Ownership     TOwnership = '@@',
   @Warehouse     TWarehouse = '@@'
  )
  ----------------------------------
   returns           TXML
as
begin /* fn_Imports_ValidateInputData*/
  declare @sValidationResult   TXML,
          @sValidationMessage  TMessageName,
          @vBusinessUnit       TBusinessUnit;

  select @sValidationResult = null;

  select @vBusinessUnit = BusinessUnit
  from vwBusinessUnits
  where (BusinessUnit = @BusinessUnit);

  /* Validate Business Unit */
  if (coalesce(@BusinessUnit, '') = '')
    set @sValidationResult = dbo.fn_Imports_AppendError(@sValidationResult, 'BusinessUnitIsRequired', null)
  else
  if (@vBusinessUnit is null)
    set @sValidationResult = dbo.fn_Imports_AppendError(@sValidationResult, 'Import_InvalidBusinessUnit', @BusinessUnit)

  /* Validate Owner if needed */
  if (coalesce(@Ownership, '') <> '@@')
    set @sValidationResult = coalesce(@sValidationResult, '') + coalesce(dbo.fn_Imports_ValidateLookUp('Owner', @Ownership), '');

  /* Validate Warehouse if needed */
  if (coalesce(@Warehouse, '') <> '@@')
    set @sValidationResult = coalesce(@sValidationResult, '') + coalesce(dbo.fn_Imports_ValidateLookUp('Warehouse', @Warehouse), '');

  /* Validate Entity details

     This function has following inputs EntityKey and EntityId

     EntityKey is the key field value. Ex: PickTicket, SKU, ReceiptOrderNumber
     EntityId is the primary key field value. Ex: OrderId, SKUId, ReceiptId (These are of type TRecordId in general)
     RecordAction is the result of fn_Imports_ResolveAction call, which has validated primary key with control option settings

     When EntityKey is null and the RecordAction is not E (Error), it suggests an attempt to process import without the KeyField value
       this must be responded with an error IsInvalid, as the operation will fail without the KeyField value
     When EntityId is not null and the RecordAction is E (Error), it suggests an attempt to insert operation when the record already exists
       this must be responded with an error AlreadyExists, as the operation will fail to insert that which is existing
     When EntityId is null and the RecordAction is E (Error), it suggests an attempt to update operation when the record does not exist
       this must be responded with an error DoesNotExist, as the operation will fail to update that which is NOT existing
  */
  set @sValidationMessage = case
                             when ((coalesce(@EntityKey, '') = '') and (@RecordAction <> 'E')) then
                               @EntityType + 'IsRequired'
                             when ((coalesce(@EntityId, '') <> '') and (@RecordAction = 'E')) then
                               @EntityType + 'AlreadyExists'
                             when ((coalesce(@EntityId, '') = '') and (@RecordAction = 'E')) then
                               @EntityType + 'DoesNotExist'
                             else
                               null
                             end;

  /* Build Validation Message */
  if (@sValidationMessage is not null)
    set @sValidationResult = dbo.fn_Imports_AppendError(@sValidationResult, @sValidationMessage, @EntityKey);

  return (nullif(@sValidationResult, ''));
end /* fn_Imports_ValidateInputData */

Go
