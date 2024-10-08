/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/26  NB      pr_Receivers_Modify: validation verify not associated with Inventory, on Warehouse change(CIMSV3-987)
  2020/06/25  NB      pr_Receivers_Create, pr_Receivers_Modify, pr_Receivers_AutoCreateReceiver
  2014/04/25  DK      pr_Receivers_Close: Modified to send consolidated exports  and
                      pr_Receivers_Modify: Validate ReceiverDate.
  2014/04/16  DK      Added pr_Receivers_Modify, pr_Receivers_AssignASNLPNs.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_Modify') is not null
  drop Procedure pr_Receivers_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_Modify:
  Sample XML:
  <Root>
   <Entity>Receiver</Entity>
   <Action>ModifyReceiver</Action>
   <Data>
    <ReceiverId></ReceiverId>
    <ReceiverDate></ReceiverDate>
    <BoLNo></BoLNo>
    <ContainerNo></ContainerNo>
    <Reference1></Reference1>
    <Reference2></Reference2>
    <Reference3></Reference3>
    <Reference4></Reference4>
    <Reference5></Reference5>
    <UDF1></UDF1>
    <UDF2></UDF2>
    <UDF3></UDF3>
    <UDF4></UDF4>
    <UDF5></UDF5>
   </Data>
  </Root>

------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_Modify
  (@ReceiverContents  XML,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @Message           TMessage = null output)
as
  declare @vReceiverNumber        TReceiverNumber,
          @vReceiverDate          TDateTime,
          @vBoLNumber             TBoLNumber,
          @vContainer             TContainer,
          @vWarehouse             TWarehouse,
          @vReference1            TDescription,
          @vReference2            TDescription,
          @vReference3            TDescription,
          @vReference4            TDescription,
          @vReference5            TDescription,
          @vOldReceiverDate       TDateTime,
          @vOldBoLNumber          TBoLNumber,
          @vOldContainer          TContainer,
          @vOldWarehouse          TWarehouse,
          @vOldReference1         TDescription,
          @vOldReference2         TDescription,
          @vOldReference3         TDescription,
          @vOldReference4         TDescription,
          @vOldReference5         TDescription,
          @vNote1                 TDescription,
          @vUDF1                  TUDF,
          @vUDF2                  TUDF,
          @vUDF3                  TUDF,
          @vUDF4                  TUDF,
          @vUDF5                  TUDF,

          @vReceiverId            TRecordId,
          @vReceiverStatus        TStatus,

          @xmlData                xml,

          @ReturnCode             TInteger,
          @MessageName            TMessageName;
begin
begin try
  begin transaction;
  SET NOCOUNT ON;

  select @ReturnCode  = 0,
         @MessageName = null;

  /* Validate Business Unit */
  select @MessageName = dbo.fn_IsValidBusinessUnit(@BusinessUnit, @UserId);

  set @xmlData = convert(xml, @ReceiverContents);

  /* Return if there is no xmlData sent */
  if (@xmlData is null)
    begin
      set @MessageName = 'InvalidData';
      goto ErrorHandler;
    end

  select @vReceiverId   = Record.Col.value('ReceiverId[1]' ,  'TRecordId'),
         @vReceiverDate = Record.Col.value('ReceiverDate[1]', 'TDateTime'),
         @vBoLNumber    = Record.Col.value('BoLNo[1]'      ,  'TBoLNumber'),
         @vWarehouse    = Record.Col.value('Warehouse[1]'  ,  'TWarehouse'),
         @vContainer    = Record.Col.value('ContainerNo[1]',  'TContainer'),
         @vReference1   = Record.Col.value('Reference1[1]' ,  'TDescription'),
         @vReference2   = Record.Col.value('Reference2[1]' ,  'TDescription'),
         @vReference3   = Record.Col.value('Reference3[1]' ,  'TDescription'),
         @vReference4   = Record.Col.value('Reference4[1]' ,  'TDescription'),
         @vReference5   = Record.Col.value('Reference5[1]' ,  'TDescription'),
         @vUDF1         = Record.Col.value('UDF1[1]'       ,  'TUDF'),
         @vUDF2         = Record.Col.value('UDF2[1]'       ,  'TUDF'),
         @vUDF3         = Record.Col.value('UDF3[1]'       ,  'TUDF'),
         @vUDF4         = Record.Col.value('UDF4[1]'       ,  'TUDF'),
         @vUDF5         = Record.Col.value('UDF5[1]'       ,  'TUDF')
    from @xmlData.nodes('/Root/Data') as Record(Col);

  select @vReceiverNumber = ReceiverNumber,
         @vReceiverStatus = Status,
         @vOldWarehouse   = coalesce(Warehouse, '')
  from Receivers
  where (ReceiverId   = @vReceiverId);

  if (@vReceiverStatus = 'C' /* Closed */)
    select @MessageName = 'Receiver_Modify_AlreadyClosed';
  else
  if (@vWarehouse is not null) and
     (@vOldWarehouse <> @vWarehouse) and
     (exists (select LPNId from LPNs where ReceiverId = @vReceiverId))
    select @MessageName = 'Receiver_Modify_CannotChangeWH';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Get the old values to log if there is any change */
  select @vOldReceiverDate = coalesce(ReceiverDate, ''),
         @vOldBoLNumber    = coalesce(BoLNumber, ''),
         @vOldContainer    = coalesce(Container, ''),
         @vOldReference1   = coalesce(Reference1, ''),
         @vOldReference2   = coalesce(Reference2, ''),
         @vOldReference3   = coalesce(Reference3, ''),
         @vOldReference4   = coalesce(Reference4, ''),
         @vOldReference5   = coalesce(Reference5, '')
  from Receivers
  where (ReceiverId = @vReceiverId);

  update Receivers
  set ReceiverDate    = coalesce(@vReceiverDate, ReceiverDate),
      BoLNumber       = coalesce(@vBoLNumber,    BoLNumber),
      Container       = coalesce(@vContainer,    Container),
      Warehouse       = coalesce(@vWarehouse,    Warehouse),
      Reference1      = coalesce(@vReference1,   Reference1),
      Reference2      = coalesce(@vReference2,   Reference2),
      Reference3      = coalesce(@vReference3,   Reference3),
      Reference4      = coalesce(@vReference4,   Reference4),
      Reference5      = coalesce(@vReference5,   Reference5),
      ModifiedDate    = current_timestamp,
      ModifiedBy      = coalesce(@UserId,        System_user)
  where (ReceiverId = @vReceiverId);

  select @vNote1 ='';

  if (@vOldReceiverDate <> @vReceiverDate)
    set @vNote1 = @vNote1 + 'Receiver Date to '  + cast(convert(DATE , @vReceiverDate) as varchar) + ','

  if (@vOldBoLNumber <> @vBoLNumber)
    set @vNote1 = @vNote1 + 'BoL # to '          + @vBoLNumber +  ','

  if (@vOldContainer <> @vContainer)
    set @vNote1 = @vNote1 + 'Container # to '    + @vContainer +  ','

  if (@vOldWarehouse <> @vWarehouse)
    set @vNote1 = @vNote1 + 'Warehouse to '      + @vWarehouse +  ','

  if (@vOldReference1 <> @vReference1)
    set @vNote1 = @vNote1 + 'Reference 1 to  '   + @vReference1 + ','

  if (@vOldReference2 <> @vReference2)
    set @vNote1 = @vNote1 + 'Reference 2 to  '   + @vReference2 + ','

  if (@vOldReference3 <> @vReference3)
    set @vNote1 = @vNote1 + 'Reference 3 to  '   + @vReference3 + ','

  if (@vOldReference4 <> @vReference4)
    set @vNote1 = @vNote1 + 'Reference 4 to   '  + @vReference4 + ','

  if (@vOldReference5 <> @vReference5)
    set @vNote1 = @vNote1 + 'Reference 5 to    ' + @vReference5 + ','

  if (@vNote1 = '')
    select @MessageName = 'Receiver_Modify_NoChanges';

  if (@MessageName is not null)
    goto ErrorHandler;

  select @vNote1 = LEFT(@vNote1, DATALENGTH(@vNote1) - 1)

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'ReceiverModified', @UserId, null /* ActivityTimestamp */,
                            @ReceiverId    = @vReceiverId,
                            @BusinessUnit  = @BusinessUnit,
                            @Note1         = @vNote1;

  exec @Message = dbo.fn_Messages_Build 'ReceiverUpdatedSuccessfully', @vReceiverNumber;

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
end /* pr_Receivers_Modify */

Go
