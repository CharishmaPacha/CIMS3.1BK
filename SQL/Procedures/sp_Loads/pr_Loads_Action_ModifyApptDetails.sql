/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/27  AY      pr_Loads_Action_ModifyApptDetails: Allow to setup Dock Location (HA-2835)
  2021/05/24  AY      pr_Loads_Action_ModifyApptDetails: Abilty to clear CheckIn/Out times (HA Support)
  2021/03/05  SJ      pr_Loads_Action_ModifyApptDetails: Giving provision to change CarrierCheckIn, CarrierCheckOut (HA-2137)
  2020/09/21  SAK     pr_Loads_Action_ModifyApptDetails: Does not allow to update the App Details on the Shipped and canceled loads (HA-1366)
  2020/07/19  OK      Added pr_Loads_Action_ModifyApptDetails and pr_Loads_Action_ModifyBoLInfo (HA-1146, HA-1147)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Loads_Action_ModifyApptDetails') is not null
  drop Procedure pr_Loads_Action_ModifyApptDetails;
Go
/*------------------------------------------------------------------------------
  Proc pr_Loads_Action_ModifyApptDetails: This proc will modify the appointment
    details of the load with user inputs
------------------------------------------------------------------------------*/
Create Procedure pr_Loads_Action_ModifyApptDetails
  (@EntityXML       xml,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @ResultXML       TXML = null output)
as
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vMessage                   TMessage,

          @vAppointmentConfirmation   TDescription,
          @vAppointmentDateTime       TDateTime,
          @vDeliveryRequestType       TLookupCode,
          @vLoadDeliveryDate          TVarchar,
          @vLoadAppointmentDateTime   TVarchar,
          @vDeliveryDate              TDateTime,
          @vTransitDays               TCount,
          @vDockLocation              TLocation,
          @vCarrierCheckIn            TTime,
          @vCarrierCheckOut           TTime,

          @vEntity                    TEntity,
          @vAction                    TAction,
          @vRecordsUpdated            TCount,
          @vTotalRecords              TCount,
          @vActivityType              TActivityType,
          @vAuditRecordId             TRecordId,
          @vNote1                     TDescription;

  declare @ttLoadsUpdated             TEntityKeysTable;
begin
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vNote1       = '';

  /* Get the Action from the xml */
  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @EntityXML.nodes('/Root') as Record(Col)
  OPTION ( OPTIMIZE FOR (@EntityXML = null ) );

  /* Read inputs from XML */
  select @vAppointmentConfirmation = nullif(Record.Col.value('AppointmentConfirmation[1]', 'TDescription'), ''),
         @vAppointmentDateTime     = nullif(Record.Col.value('AppointmentDateTime[1]',     'TDateTime'),    ''),
         @vDeliveryRequestType     = nullif(Record.Col.value('DeliveryRequestType[1]',     'TLookupCode'),  ''),
         @vDeliveryDate            = nullif(Record.Col.value('DeliveryDate[1]',            'TDateTime'),    ''),
         @vTransitDays             = nullif(Record.Col.value('TransitDays[1]',             'TInteger'),     ''),
         @vDockLocation            = nullif(Record.Col.value('DockLocation[1]',            'TLocation'),    ''),
         @vCarrierCheckIn          = Record.Col.value('CarrierCheckIn[1]',                 'TTime'),
         @vCarrierCheckOut         = Record.Col.value('CarrierCheckOut[1]',                'TTime')
  from @EntityXML.nodes('/Root/Data') as Record(Col);

  /* Get the total no. of Loads */
  select @vTotalRecords = count(*) from #ttSelectedEntities;

  select @vLoadDeliveryDate        = convert(varchar, @vDeliveryDate, 101),
         @vLoadAppointmentDateTime = convert(varchar, @vAppointmentDateTime, 101),
         @vActivityType            = @vAction;

  /* If any of the Loads have already Shipped or Cancelled, delete them as there is no point in updating
     appointment details now */
  delete ttSE
  output 'E', 'Loads_ModifyApptDetails_InvalidStatus', L.LoadNumber, L.Status
  into #ResultMessages (MessageType, MessageName, Value1, Value2)
  from #ttSelectedEntities ttSE join Loads L on (ttSE.EntityId = L.LoadId)
  where (L.Status in ('X' /* Cancelled */, 'S' /* Shipped */));

  update #ResultMessages
  set Value2 = dbo.fn_Status_GetDescription ('Load', Value2, @BusinessUnit)
  where (MessageName = 'Loads_ModifyApptDetails_InvalidStatus');

  /* Update the required details on the selected Loads */
  update L
  set AppointmentConfirmation = coalesce(@vAppointmentConfirmation, AppointmentConfirmation),
      AppointmentDateTime     = coalesce(@vAppointmentDateTime,     AppointmentDateTime),
      DeliveryRequestType     = coalesce(@vDeliveryRequestType,     DeliveryRequestType),
      DeliveryDate            = coalesce(@vDeliveryDate,            DeliveryDate),
      TransitDays             = coalesce(@vTransitDays,             TransitDays),
      DockLocation            = coalesce(@vDockLocation,            DockLocation),
      CarrierCheckIn          = case when @vCarrierCheckIn = '00:00:00' then null
                                     else coalesce(@vCarrierCheckIn, CarrierCheckIn)
                                end,
      CarrierCheckOut         = case when @vCarrierCheckOut = '00:00:00' then null
                                     else coalesce(@vCarrierCheckOut, CarrierCheckOut)
                                end
  output Inserted.LoadId, Inserted.LoadNumber into @ttLoadsUpdated (EntityId, EntityKey)
  from Loads L
    join #ttSelectedEntities ttSE on (L.LoadId = ttSE.EntityId);

  /* Get the updated Loads count */
  select @vRecordsUpdated = @@rowcount;

  /* Build Note to log AT */
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Appt Confirmation', @vAppointmentConfirmation);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Appt DateTime',     @vLoadAppointmentDateTime);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Delivery Request Type', @vDeliveryRequestType);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Delivery Date',    @vLoadDeliveryDate);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Transit Days',     @vTransitDays);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Dock Location',    @vDockLocation);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Carrier CheckIn',  @vCarrierCheckIn);
  select @vNote1 = dbo.fn_AppendCSV(@vNote1, 'Carrier CheckOut', @vCarrierCheckOut);
  select @vNote1 = '(' + @vNote1 + ')';

  /* Audit Trail */
  exec pr_AuditTrail_Insert @vActivityType, @UserId, null /* ActivityTimestamp */,
                            @BusinessUnit  = @BusinessUnit,
                            @Note1         = @vNote1,
                            @AuditRecordId = @vAuditRecordId output;

  exec pr_AuditTrail_InsertEntities @vAuditRecordId, @vEntity, @ttLoadsUpdated, @BusinessUnit;

  /* Based upon the number of Loads that have been Updated, give an appropriate message */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Loads_Action_ModifyApptDetails */

Go
