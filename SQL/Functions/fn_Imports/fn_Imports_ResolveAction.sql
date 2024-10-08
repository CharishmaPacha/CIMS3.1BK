/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/27  MS      pr_Imports_ReceiptHeaders, fn_Imports_ResolveAction: Made changes to delete records recursively (CIMSV3-1146)
  2016/03/10  TK      fn_Imports_ResolveAction: Validate Action as well (NBD-243)
  2015/09/09  YJ      pr_Imports_CartonTypes: Called function fn_Imports_ResolveAction to resolve Action (ACME-312)
  2013/03/20  TD      Enhanced import and validate procedures to handle Actions based on control values.
                      Added new function fn_Imports_ResolveAction specific to imports.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Imports_ResolveAction') is not null
  drop Function fn_Imports_ResolveAction;
Go
/*------------------------------------------------------------------------------
  Function fn_Imports_ResolveAction:
------------------------------------------------------------------------------*/
Create Function fn_Imports_ResolveAction
  (@Entity           TEntity,
   @Action           TAction,
   @PrimaryKey       TVarchar,
   @BusinessUnit     TBusinessUnit,
   @UserId           TUserId)
  ----------------------------------
   returns           TControlValue
as
begin
  declare @vNewAction        TAction,
          @vValidActionCodes TControlValue,
          @vControlCategory  TCategory;

  /* Based upon the entity, we need to get the appropriate control var */
  select @vControlCategory  = 'Import' + coalesce('_' + @Entity, '');
  select @vValidActionCodes = dbo.fn_Controls_GetAsString(@vControlCategory, 'ValidActionCodes', 'I,U,D' /* Default: Insert, Update, Delete , Delete Recursively, ReOpen, Close */,
                                                          @BusinessUnit, null /* UserId */);

  if ((@PrimaryKey is not null) and (@Action = 'I' /* Insert */))
    select @vNewAction = dbo.fn_Controls_GetAsString(@vControlCategory, 'AddExistingRecord',
                                                    'U' /* Default: Update */, @BusinessUnit, '' /* UserId */);
  else
  if ((@PrimaryKey is null) and (@Action = 'U' /* Update */))
    select @vNewAction = dbo.fn_Controls_GetAsString(@vControlCategory, 'UpdateNonExistingRecord',
                                                    'I' /* Default: Insert */, @BusinessUnit, '' /* UserId */);
  else
  if ((@PrimaryKey is null) and (@Action in ('D', 'DR' /* Delete, Delete Recursively */)))
    select @vNewAction = dbo.fn_Controls_GetAsString(@vControlCategory, 'DeleteNonExistingRecord',
                                                    'E' /* Default: Error */, @BusinessUnit, '' /* UserId */);
  else
  if (@PrimaryKey is null) and (dbo.fn_IsInList(@Action, @vValidActionCodes) <> 0) and (@Action <> 'I' /* Insert */)
    select @vNewAction = dbo.fn_Controls_GetAsString(@vControlCategory, 'ModifyNonExistingRecord',
                                                    'E' /* Default: Error */, @BusinessUnit, '' /* UserId */);
  else
    /* Finally resolve the action */
    select @vNewAction = case when (dbo.fn_IsInList(@Action, @vValidActionCodes) = 0) then 'X' /* Invalid action */
                              else @Action
                         end;

  return(coalesce(@vNewAction, 'E'));
end /* fn_Imports_ResolveAction */

Go
