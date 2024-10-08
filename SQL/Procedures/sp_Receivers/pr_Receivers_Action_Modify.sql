/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/10/20  VS      pr_Receivers_Action_Modify: Added new proc for V3 Modify Receivers action (HA-1600)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_Action_Modify') is not null
  drop Procedure pr_Receivers_Action_Modify;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_Action_Modify:
    This proc is used to Modify Receivers
------------------------------------------------------------------------------*/
Create Procedure pr_Receivers_Action_Modify
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vMessage                    TDescription,
          @vRecordId                   TRecordId,
          /* Audit & Response */
          @vAuditActivity              TActivityType,
          @ttAuditTrailInfo            TAuditTrailInfo,
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,

          @vReceiverNumber             TReceiverNumber,
          @vReceiverDate               TDateTime,
          @vBoLNumber                  TBoLNumber,
          @vContainer                  TContainer,
          @vWarehouse                  TWarehouse,
          @vReference1                 TDescription,
          @vReference2                 TDescription,
          @vReference3                 TDescription,
          @vReference4                 TDescription,
          @vReference5                 TDescription,
          @vOldReceiverDate            TDateTime,
          @vOldBoLNumber               TBoLNumber,
          @vOldContainer               TContainer,
          @vOldWarehouse               TWarehouse,
          @vOldReference1              TDescription,
          @vOldReference2              TDescription,
          @vOldReference3              TDescription,
          @vOldReference4              TDescription,
          @vOldReference5              TDescription,
          @vNote1                      TDescription,
          @vReceiverId                 TRecordId,
          @vReceiverStatus             TStatus,

          @vUDF1                       TUDF,
          @vUDF2                       TUDF,
          @vUDF3                       TUDF,
          @vUDF4                       TUDF,
          @vUDF5                       TUDF;

begin
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0,
         @vNote1         = '';

  /* Get the total count of receivers from #table */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  select @vEntity       = Record.Col.value('Entity[1]',               'TEntity'),
         @vAction       = Record.Col.value('Action[1]',               'TAction'),
         @vReceiverId   = Record.Col.value('(Data/ReceiverId)[1]',    'TRecordId'),
         @vReceiverDate = Record.Col.value('(Data/ReceiverDate)[1]',  'TDateTime'),
         @vBoLNumber    = Record.Col.value('(Data/BoLNo)[1]',         'TBoLNumber'),
         @vWarehouse    = Record.Col.value('(Data/Warehouse)[1]',     'TWarehouse'),
         @vContainer    = Record.Col.value('(Data/ContainerNo)[1]',   'TContainer'),
         @vReference1   = Record.Col.value('(Data/ReceiverRef1)[1]',  'TDescription'),
         @vReference2   = Record.Col.value('(Data/ReceiverRef2)[1]',  'TDescription'),
         @vReference3   = Record.Col.value('(Data/ReceiverRef3)[1]',  'TDescription'),
         @vReference4   = Record.Col.value('(Data/ReceiverRef4)[1]',  'TDescription'),
         @vReference5   = Record.Col.value('(Data/ReceiverRef5)[1]',  'TDescription'),
         @vUDF1         = Record.Col.value('(Data/UDF1)[1]',          'TUDF'),
         @vUDF2         = Record.Col.value('(Data/UDF2)[1]',          'TUDF'),
         @vUDF3         = Record.Col.value('(Data/UDF3)[1]',          'TUDF'),
         @vUDF4         = Record.Col.value('(Data/UDF4)[1]',          'TUDF'),
         @vUDF5         = Record.Col.value('(Data/UDF5)[1]',          'TUDF')
  from @xmlData.nodes('/Root') as Record(Col);

  select @vReceiverNumber  = ReceiverNumber,
         @vReceiverStatus  = Status,
         @vOldWarehouse    = coalesce(Warehouse, ''),
         @vOldReceiverDate = coalesce(ReceiverDate, ''),
         @vOldBoLNumber    = coalesce(BoLNumber, ''),
         @vOldContainer    = coalesce(Container, ''),
         @vOldReference1   = coalesce(Reference1, ''),
         @vOldReference2   = coalesce(Reference2, ''),
         @vOldReference3   = coalesce(Reference3, ''),
         @vOldReference4   = coalesce(Reference4, ''),
         @vOldReference5   = coalesce(Reference5, '')
  from Receivers
  where (ReceiverId = @vReceiverId);

  /* Build the Note for AT & message */
  if (@vOldReceiverDate <> @vReceiverDate) select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Receiver Date', cast(convert(DATE, @vReceiverDate) as varchar));
  if (@vOldBoLNumber <> @vBoLNumber)       select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'BoL #',         @vBoLNumber);
  if (@vOldContainer <> @vContainer)       select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Container #',   @vContainer);
  if (@vOldWarehouse <> @vWarehouse)       select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Warehouse',     @vWarehouse);
  if (@vOldReference1 <> @vReference1)     select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Reference1',    @vReference1);
  if (@vOldReference2 <> @vReference2)     select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Reference2',    @vReference2);
  if (@vOldReference3 <> @vReference3)     select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Reference3',    @vReference3);
  if (@vOldReference4 <> @vReference4)     select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Reference4',    @vReference4);
  if (@vOldReference5 <> @vReference5)     select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Reference5',    @vReference5);

  if (@vReceiverStatus = 'C' /* Closed */)
    select @vMessageName = 'Receiver_Modify_AlreadyClosed';
  else
  if (@vWarehouse is not null) and
     (@vOldWarehouse <> @vWarehouse) and
     (exists (select LPNId from LPNs where ReceiverId = @vReceiverId))
    select @vMessageName = 'Receiver_Modify_CannotChangeWH';
  else
  if (@vNote1 = '')
    select @vMessageName = 'Receiver_Modify_NoChanges'
  else
    select @vMessageName = dbo.fn_IsValidBusinessUnit(@BusinessUnit, @UserId);

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

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

  select @vRecordsUpdated = @@rowcount;

  /* Audit Trail */
  exec pr_AuditTrail_Insert 'ReceiverModified', @UserId, null /* ActivityTimestamp */,
                            @ReceiverId    = @vReceiverId,
                            @BusinessUnit  = @BusinessUnit,
                            @Note1         = @vNote1;

  /* Show the summary message in V3 UI */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords, @vReceiverNumber, @vNote1;

  return(coalesce(@vReturnCode, 0));
end /* pr_Receivers_Action_Modify */

Go
