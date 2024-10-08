/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/30  SJ      pr_Receipts_Action_ChangeArrivalInfo: New procedure (HA-1228)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Receipts_Action_ChangeArrivalInfo') is not null
  drop Procedure pr_Receipts_Action_ChangeArrivalInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Receipts_Action_ChangeArrivalInfo: Action to change the information about
    the arrival of the RO i.e. on what Container and when it is coming etc.
------------------------------------------------------------------------------*/
Create Procedure pr_Receipts_Action_ChangeArrivalInfo
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  declare @vReturnCode                TInteger,
          @vRecordId                  TRecordId,
          @vMessageName               TMessageName,
          @vMessage                   TDescription,

          @vEntity                    TEntity,
          @vAction                    TAction,
          @vRecordsUpdated            TCount,
          @vTotalRecords              TCount,

          @vVessel                    TVessel,
          @vContainerNo               TContainer,
          @vContainerSize             TContainerSize,
          @vBillNo                    TBoLNumber,
          @vETACountry                TDate,
          @vETACity                   TDate,
          @vETAWarehouse              TDate,
          @vAppointmentDateTime       TDateTime,
          @vNote1                     TDescription,
          @vAuditRecordId             TRecordId;
  declare @ttReceipts                 TEntityKeysTable;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null;

  select @vEntity              = Record.Col.value('Entity[1]',                    'TEntity'       ),
         @vAction              = Record.Col.value('Action[1]',                    'TAction'       ),
         @vVessel              = Record.Col.value('(Data/Vessel)[1]',             'TVessel'       ),
         @vContainerNo         = Record.Col.value('(Data/ContainerNo)[1]',        'TContainer'    ),
         @vContainerSize       = Record.Col.value('(Data/ContainerSize)[1]',      'TContainerSize'),
         @vBillNo              = Record.Col.value('(Data/BillNo)[1]',             'TBoLNumber'    ),
         @vETACountry          = Record.Col.value('(Data/ETACountry)[1]',         'TDate'         ),
         @vETACity             = Record.Col.value('(Data/ETACity)[1]',            'TDate'         ),
         @vETAWarehouse        = Record.Col.value('(Data/ETAWarehouse)[1]',       'TDate'         ),
         @vAppointmentDateTime = Record.Col.value('(Data/AppointmentDateTime)[1]','TDateTime'     )
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  /* Get all the selected Receipts */
  insert into @ttReceipts (EntityId, EntityKey)
    select EntityId, EntityKey from #ttSelectedEntities;

  set @vTotalRecords = @@rowcount;

  /* Validations */

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Update the Records */
  update RH
  set Vessel              = coalesce(@vVessel,              Vessel),
      ContainerNo         = coalesce(@vContainerNo,         ContainerNo),
      ContainerSize       = coalesce(@vContainerSize,       ContainerSize),
      BillNo              = coalesce(@vBillNo,              BillNo),
      ETACountry          = coalesce(@vETACountry,          ETACountry),
      ETACity             = coalesce(@vETACity,             ETACity),
      ETAWarehouse        = coalesce(@vETAWarehouse,        ETAWarehouse),
      AppointmentDateTime = coalesce(@vAppointmentDateTime, AppointmentDateTime)
  from ReceiptHeaders RH
    join @ttReceipts ttR on (RH.ReceiptId = ttR.EntityId);

  set @vRecordsUpdated = @@rowcount;

  /* Build Note to log AT */
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Vessel',                @vVessel);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Container No',          @vContainerNo);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Container Size',        @vContainerSize);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Bill No',               @vBillNo);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'ETA Country',           @vETACountry);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'ETA City',              @vETACity);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'ETA Warehouse',         @vETAWarehouse);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Appointment Date/Time', @vAppointmentDateTime);
  select @vNote1 = '(' + @vNote1 + ')';

  /* Audit Trail */
  exec pr_AuditTrail_Insert @vAction, @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit = @BusinessUnit, @Note1 = @vNote1, @AuditRecordId = @vAuditRecordId output;;

  if (@vAuditRecordId is not null)
    exec pr_AuditTrail_InsertEntities @vAuditRecordId, @vEntity, @ttReceipts, @BusinessUnit;

BuildMessage:
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Receipts_Action_ChangeArrivalInfo */

Go
