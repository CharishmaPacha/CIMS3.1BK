/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/04  VS      pr_OrderHeaders_VoidTempLabels, pr_OrderHeaders_ChangeAddress, pr_OrderHeaders_OnChangeShipDetails,
  2019/09/09/ MJ      pr_OrderHeaders_ChangeAddress: Included AddressLine3 (HPI-2727)
  2017/04/25  SV      pr_OrderHeaders_ChangeAddress, pr_OrderHeaders_Modify, pr_OrderHeaders_RecomputeShipVia:
  2017/04/11  DK      pr_OrderHeaders_ChangeAddress: Enhanced to insert Residential(CIMS-1289)
  2016/12/01  SV      pr_OrderHeaders_ChangeAddress, pr_OrderHeaders_Modify, pr_OrderHeaders_RecomputeShipVia:
  2015/01/07  SV      pr_OrderHeaders_ChangeAddress: Fixed issue of sending the correct number of params to pr_Contacts_AddOrUpdate
  2012/08/01  VM      pr_OrderHeaders_ChangeAddress: output variable 'Message' datatype changed from TMessageName to TMessage
  2012/01/30  YA      Added pr_OrderHeaders_ChangeAddress.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_ChangeAddress') is not null
  drop Procedure pr_OrderHeaders_ChangeAddress;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_ChangeAddress:
    This procedure is used to update Address and
    update ShipLabels by setting EntityKey to EntityKey+'_Void', On reprinting PackingList
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_ChangeAddress
  (@PickTicket      TPickTicket,      --For updating ShipLabels
   @ContactRefId    TContactRefId,
   @ContactType     TContactType,
   @Name            TName,
   @ContactPerson   TName,
   @AddressLine1    TAddressLine,
   @AddressLine2    TAddressLine,
   @AddressLine3    TAddressLine,
   @City            TCity,
   @State           TState,
   @Zip             TZip,
   @Country         TCountry,
   @PhoneNo         TPhoneNo,
   @Email           TEmailAddress,
   @ContactAddrId   TRecordId,
   @OrgAddrId       TRecordId,
   @BusinessUnit    TBusinessUnit,
   @Message         TMessage output)
as
  declare @ReturnCode     TInteger,
          @MessageName    TMessageName,

          @vOrderId       TRecordId,
          @vOrderStatus   TStatus,

          @vContactRefId  TRecordId,
          @vContactId     TRecordId,
          @vCreatedDate   TDateTime,
          @vModifiedDate  TDateTime,
          @vCreatedBy     TUserId,
          @vModifiedBy    TUserId,
          @Reference1     TDescription,
          @Reference2     TDescription,
          @Residential    TFlag;

begin
begin try
  begin transaction
    select @vOrderId     = OH.OrderId,
           @vOrderStatus = OH.Status,
           @vContactId   = C.ContactId
    from OrderHeaders OH
         left outer join Contacts C on (OH.ShipToId = C.ContactRefId)
    where (OH.PickTicket   = @PickTicket) and
          (OH.BusinessUnit = @BusinessUnit);

    /* Call pr_Contacts_AddOrUpdate to update Address */
    exec @Returncode = pr_Contacts_AddOrUpdate @ContactRefId,
                                               @ContactType,
                                               @Name,
                                               @ContactPerson,
                                               @AddressLine1,
                                               @AddressLine2,
                                               @AddressLine3,
                                               @City,
                                               @State,
                                               @Zip,
                                               @Country,
                                               @PhoneNo,
                                               @Email,
                                               @Reference1,
                                               @Reference2,
                                               @Residential,
                                               @ContactAddrId,
                                               @OrgAddrId,
                                               @BusinessUnit,
                                               @vContactId,
                                               @vCreatedDate  output,
                                               @vModifiedDate output,
                                               @vCreatedBy    output,
                                               @vModifiedBy   output;

    if (@ReturnCode = 0)
      begin
        /* perform update ShipLabels */
        /* Validate PickTicekt to Status 'S'(Shipped) */
        if (@vOrderStatus = 'S'/* Shipped */)
            /* call pr_Shipping_VoidShipLabels seperate unwanted Cartons */
          exec @Returncode = pr_Shipping_VoidShipLabels @vOrderId,
                                                        null /* LPNId */,
                                                        default,
                                                        @BusinessUnit,
                                                        default /* RegenerateLabel - No */,
                                                        @Message output;
      end

    if (@ReturnCode = 1)
      raiserror(@Message, 16, 1);

    /* Confirmation Message */
    select @Message = 'Ship To address has been updated successfully';

  commit transaction;
  goto ExitHandler;
end try
begin catch
  if ((@@error <> 0) or (@ReturnCode = 1))
    begin
      select @ReturnCode = 1;
      rollback transaction
    end
end catch;
ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_OrderHeaders_ChangeAddress */

Go
