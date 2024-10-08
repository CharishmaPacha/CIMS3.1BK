/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/02/15  TK      pr_Receivers_CreateReceiptInventory: Changes to update InventoryClasses (FBV3-810)
  2021/12/02  SV      pr_Receivers_CreateReceiptInventory, pr_Receivers_CreateReceiptInventory_Validate: Intial version to validate the I/P data
  2020/09/03  PK      pr_Receivers_Create: Corrected the parameter names(HA-1381)
  2020/06/25  NB      pr_Receivers_Create, pr_Receivers_Modify, pr_Receivers_AutoCreateReceiver
                        changes to include Warehouse in Receiver creation and update(CIMSV3-987)
  2020/04/03  RV      pr_Receivers_Create: Made changes to insert the messages information (JL-155)
  2018/03/20  MJ      pr_Receivers_Create: Changes to show created receiver while Createreceiver action from UI(S2G-332)
  2018/03/06  AY/SV   pr_Receivers_AutoCreateReceiver: New procedure to create receivers on the fly
                      pr_Receivers_Create: Return newly created receiver details and bypass BoL requirment on Auto Create
                      fn_Receivers_Summary: Corrected the Receiver's Summary count (S2G-337)
  2014/04/16  DK      Modified pr_Receivers_Create, fn_Receivers_Summary.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receivers_Create') is not null
  drop Procedure pr_Receivers_Create;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receivers_Create:
  Sample XML:
  <Root>
   <Entity>Receiver</Entity>
   <Action>CreateReceiver</Action>
   <Data>
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
Create Procedure pr_Receivers_Create
  (@ReceiverContents  XML,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @Message           TMessage        = null output,
   @ReceiverId        TRecordId       = null output,
   @ReceiverNumber    TReceiverNumber = null output)
as
  declare @vAction              TAction,
          @vReceiverDate        TDateTime,
          @vBoLNumber           TBoLNumber,
          @vWarehouse           TWarehouse,
          @vContainer           TContainer,
          @vReference1          TDescription,
          @vReference2          TDescription,
          @vReference3          TDescription,
          @vReference4          TDescription,
          @vReference5          TDescription,
          @vUDF1                TUDF,
          @vUDF2                TUDF,
          @vUDF3                TUDF,
          @vUDF4                TUDF,
          @vUDF5                TUDF,

          @NextSeqNo            TSequence,
          @vNextSeqNo           TString,
          @vSeqNoMaxLength      TInteger,
          @vReceiverNoToCreate  TReceiverNumber,
          @vReceiverNoFormat    TControlValue,
          @vReceiverId          TRecordId,

          @xmlData              xml,

          @ReturnCode           TInteger,
          @MessageName          TMessageName;

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

  select @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col);

  select @vReceiverDate = Record.Col.value('ReceiverDate[1]', 'TDateTime'),
         @vBoLNumber    = Record.Col.value('BoLNo[1]'       , 'TBoLNumber'),
         @vContainer    = Record.Col.value('ContainerNo[1]' , 'TContainer'),
         @vWarehouse    = Record.Col.value('Warehouse[1]'   , 'TWarehouse'),
         @vReference1   = Record.Col.value('ReceiverRef1[1]', 'TDescription'),
         @vReference2   = Record.Col.value('ReceiverRef2[1]', 'TDescription'),
         @vReference3   = Record.Col.value('ReceiverRef3[1]', 'TDescription'),
         @vReference4   = Record.Col.value('ReceiverRef4[1]', 'TDescription'),
         @vReference5   = Record.Col.value('ReceiverRef5[1]', 'TDescription'),
         @vUDF1         = Record.Col.value('UDF1[1]'        , 'TUDF'),
         @vUDF2         = Record.Col.value('UDF2[1]'        , 'TUDF'),
         @vUDF3         = Record.Col.value('UDF3[1]'        , 'TUDF'),
         @vUDF4         = Record.Col.value('UDF4[1]'        , 'TUDF'),
         @vUDF5         = Record.Col.value('UDF5[1]'        , 'TUDF')
    from @xmlData.nodes('/Root/Data') as Record(Col);

  select @vBoLNumber    = nullif(@vBoLNumber, '');

  /* Validations */
  if (@vBoLNumber is null) and (@vAction not in ('AutoCreate'))
    set @MessageName = 'BoLNumberIsRequired';

  if (@MessageName is not null)
    goto ErrorHandler;

  /* Default to today */
  select @vReceiverDate = coalesce(@vReceiverDate, current_timestamp);

  /* Get the next Receiver Number based on the latest receiverNumber timestamp */
  exec pr_Receivers_GetNextReceiverNo 'Receiver', -- Future use for ReceiverType or any parameter
                                      @BusinessUnit,
                                      @vReceiverNoToCreate output;

  /* Insert in LPNs table - by default Status will be set as 'N' (New) */
  insert into Receivers(ReceiverNumber,
                        ReceiverDate,
                        Status,
                        BoLNumber,
                        Container,
                        Warehouse,
                        Reference1,
                        Reference2,
                        Reference3,
                        Reference4,
                        Reference5,
                        UDF1,
                        UDF2,
                        UDF3,
                        UDF4,
                        UDF5,
                        BusinessUnit,
                        CreatedBy)
                select  @vReceiverNoToCreate,
                        @vReceiverDate,
                        'O' /* Open */,
                        @vBoLNumber,
                        @vContainer,
                        @vWarehouse,
                        @vReference1,
                        @vReference2,
                        @vReference3,
                        @vReference4,
                        @vReference5,
                        @vUDF1,
                        @vUDF2,
                        @vUDF3,
                        @vUDF4,
                        @vUDF5,
                        @BusinessUnit,
                        @UserId;

  select @vReceiverId = Scope_Identity();

  exec @Message = dbo.fn_Messages_Build 'ReceiverCreatedSuccessfully', @vReceiverNoToCreate;

  /* Inserted the messages information to display in V3 application */
  if (object_id('tempdb..#ResultMessages') is not null)
    insert into #ResultMessages (MessageType, MessageText) select 'I' /* Info */, @Message;

  /* Initializing the output parameters */
  select @ReceiverId     = @vReceiverId,
         @ReceiverNumber = @vReceiverNoToCreate,
         @Message        = '<Result>' +
                              '<Message>' + @Message +'</Message>' +
                              '<ReceiverCreated>' + @ReceiverNumber +'</ReceiverCreated>' +
                            '</Result>';

  /* Auditing */
  exec pr_AuditTrail_Insert 'ReceiverCreated', @UserId, null /* ActivityTimestamp */,
                            @ReceiverId    = @vReceiverId,
                            @BusinessUnit  = @BusinessUnit;
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
end /* pr_Receivers_Create */

Go
