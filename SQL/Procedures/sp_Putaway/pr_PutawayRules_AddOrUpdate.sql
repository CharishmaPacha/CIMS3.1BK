/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2013/09/21  NY      pr_PutawayRules_AddOrUpdate:Added PAType
  2012/08/24  AA      pr_PutawayRules_AddOrUpdate: fixed transaction issue (ta3806)
  2012/06/30  SP      Placed the transaction controls in 'pr_PutawayRules_AddOrUpdate'.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_PutawayRules_AddOrUpdate') is not null
  drop Procedure pr_PutawayRules_AddOrUpdate;
Go
/*------------------------------------------------------------------------------
  Proc pr_PutawayRules_AddOrUpdate:
    This proc will add a new putaway rule and edit and update the existing rule with new values..
    Assumes that All other validations done by Caller or from UI.
------------------------------------------------------------------------------*/
Create Procedure pr_PutawayRules_AddOrUpdate
  (@SequenceNo        TInteger,
   @LPNType           TTypeCode,
   @PAType            TTypeCode,
   @SKUPutawayClass   TCategory,
   @LPNPutawayClass   TCategory,
   @LocationType      TLocationType,
   @StorageType       TStorageType,
   @LocationStatus    TStatus,
   @PutawayZone       TLookupCode,
   @Location          TLocation,
   @SKUExists         TFlag,
   @Status            TStatus,
   @BusinessUnit      TBusinessUnit,
   -----------------------------------------------
   @RecordId          TRecordId        output,
   @CreatedDate       TDateTime = null output,
   @ModifiedDate      TDateTime = null output,
   @CreatedBy         TUserId   = null output,
   @ModifiedBy        TUserId   = null output)
as
  declare @ReturnCode  TInteger,
          @MessageName TMessageName,
          @Message     TDescription;

begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null,
         @Status      = coalesce(@Status, 'A' /* Active */);

  /* Need  Validations */
  if (@SequenceNo is null)
    set @MessageName = 'SequenceNoIsNull';
  else
  if (@BusinessUnit is null)
    set @MessageName = 'InvalidBusinessUnit';

  if (@MessageName is not null)
    goto ErrorHandler;

  if (coalesce(@RecordId, 0) = 0)
    begin
      /*if RecordId is null then it will insert.Ie.. add new one.  */
      insert into PutawayRules(SequenceNo,
                               LPNType,
                               PAType,
                               SKUPutawayClass,
                               LPNPutawayClass,
                               LocationType,
                               StorageType,
                               LocationStatus,
                               PutawayZone,
                               Location,
                               SKUExists,
                               Status,
                               BusinessUnit,
                               CreatedBy,
                               CreatedDate )
                        select @SequenceNo,
                               @LPNType,
                               @PAType,
                               @SKUPutawayClass,
                               @LPNPutawayClass,
                               @LocationType,
                               @StorageType,
                               @LocationStatus,
                               @PutawayZone,
                               @Location ,
                               @SKUExists,
                               @Status,
                               @BusinessUnit,
                               coalesce(@CreatedBy,   System_user),
                               coalesce(@CreatedDate, current_timestamp);
    end
  else
    begin
      update PutawayRules
      set SequenceNo       = @SequenceNo,
          LPNType          = @LPNType,
          PAType           = @PAType,
          SKUPutawayClass  = @SKUPutawayClass,
          LPNPutawayClass  = @LPNPutawayClass,
          LocationType     = @LocationType,
          StorageType      = @StorageType,
          LocationStatus   = @LocationStatus,
          PutawayZone      = @PutawayZone,
          Location         = @Location,
          SKUExists        = @SKUExists,
          Status           = @Status,
          BusinessUnit     = coalesce(@BusinessUnit,  BusinessUnit),
          ModifiedBy       = coalesce(@ModifiedBy,    System_User),
          ModifiedDate     = coalesce(@ModifiedDate,  current_timestamp)
      where(RecordId = @RecordId);
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  commit transaction;
end try
begin catch
  /* Handling transactions in case it is rolled back from sub procedures */
  if (@@trancount > 0) rollback transaction;
  exec @ReturnCode = pr_ReRaiseError;
end catch;
  return(coalesce(@ReturnCode, 0));
end /* pr_PutawayRules_AddOrUpdate */

Go
