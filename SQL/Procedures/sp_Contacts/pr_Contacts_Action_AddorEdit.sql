/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/22  NB      pr_Contacts_Action_AddorEdit: changes to consider OrderHeaders_Addresses action call as Contacts_Edit (HA-2309)
  2021/04/12  AJM     pr_Contacts_Action_AddorEdit: Added Contacts_Add block (HA-2583)
  2021/03/18  OK      pr_Contacts_Action_AddorEdit: Added new proc to edit contacts (HA-2317)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Contacts_Action_AddorEdit') is not null
  drop Procedure pr_Contacts_Action_AddorEdit;
Go
/*------------------------------------------------------------------------------
  Proc pr_Contacts_Action_AddorEdit: Action to add/edit a contact
------------------------------------------------------------------------------*/
Create Procedure pr_Contacts_Action_AddorEdit
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
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vContactId                  TRecordId,
          @vContactRefId               TContactRefId,
          @vContactType                TContactType,
          @vName                       TName,
          @vAddressLine1               TAddressLine,
          @vAddressLine2               TAddressLine,
          @vAddressLine3               TAddressLine,
          @vCity                       TCity,
          @vState                      TState,
          @vZip                        TZip,
          @vCountry                    TCountry,
          @vPhoneNo                    TPhoneNo,
          @vEmail                      TEmailAddress,
          @vContactPerson              TName,
          @vAddressRegion              TAddressRegion;

begin /* pr_Contacts_Action_AddorEdit */
  SET NOCOUNT ON;

  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vRecordId     = 0,
         @vTotalRecords = count(*) from #ttSelectedEntities;

  select @vEntity = Record.Col.value('Entity[1]', 'TEntity'),
         @vAction = Record.Col.value('Action[1]', 'TAction')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  select @vContactId     = nullif(Record.Col.value('ContactId[1]',      'TRecordId'),     ''),
         @vContactRefId  = nullif(Record.Col.value('ContactRefId[1]',   'TContactRefId'), ''),
         @vContactType   = nullif(Record.Col.value('ContactType [1]',   'TContactType'),  ''),
         @vName          = nullif(Record.Col.value('Name[1]',           'TName'),         ''),
         @vAddressLine1  = nullif(Record.Col.value('AddressLine1[1]',   'TAddressLine'),  ''),
         @vAddressLine2  = nullif(Record.Col.value('AddressLine2[1]',   'TAddressLine'),  ''),
         @vAddressLine3  = nullif(Record.Col.value('AddressLine3[1]',   'TAddressLine'),  ''),
         @vCity          = nullif(Record.Col.value('City[1]',           'TCity'),         ''),
         @vState         = nullif(Record.Col.value('State[1]',          'TState'),        ''),
         @vZip           = nullif(Record.Col.value('Zip[1]',            'TZip'),          ''),
         @vCountry       = nullif(Record.Col.value('Country[1]',        'TCountry'),      ''),
         @vPhoneNo       = nullif(Record.Col.value('PhoneNo[1]',        'TPhoneNo'),      ''),
         @vEmail         = nullif(Record.Col.value('Email[1]',          'TEmailAddress'), ''),
         @vContactPerson = nullif(Record.Col.value('ContactPerson[1]',  'TName'),         '')
  from @xmlData.nodes('/Root/Data') as Record(Col);

  /* If it is a valid contact id, then assume it is an edit */
  if (exists (select * from Contacts where ContactId = @vContactId))
    select @vAction = 'Contacts_Edit';

  /* If user is trying to add, then verify if it already exists */
  if (@vAction = 'Contacts_Add')
    select @vContactId = ContactId
    from Contacts
    where (ContactType  = @vContactType ) and
          (ContactRefId = @vContactRefId) and
          (BusinessUnit = @BusinessUnit );

  /* Validations */
  if (@vName is null)
    set @vMessageName = 'ContactNameIsRequired';
  else
  if (@vContactType is null)
    set @vMessageName = 'ContactTypeIsRequired';
  else
  if (@vAction = 'Contacts_Add') and (@vContactRefId is null)
    set @vMessageName = 'ContactIdIsRequired';
  else
  if (@vAction = 'Contacts_Add') and (@vContactId is not null)
    set @vMessageName = 'ContactAlreadyExists';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* Clean up & Initialize */
  select @vName          = dbo.fn_RemoveSpecialChars(@vName),
         @vAddressLine1  = dbo.fn_RemoveSpecialChars(@vAddressLine1),
         @vAddressLine2  = dbo.fn_RemoveSpecialChars(@vAddressLine2),
         @vAddressLine3  = dbo.fn_RemoveSpecialChars(@vAddressLine3),
         @vAddressRegion = dbo.fn_Contacts_GetAddressRegion(@vCountry),
         @UserId         = coalesce(@UserId, System_User);

  /* Add contact */
  if (@vAction = 'Contacts_Add')
    begin
      /* #ttSelectedEntities is not populated with entries during addition of a new Contact
         Right now we will be adding 1 record at a time */
      select @vTotalRecords = 1;

      /* Add all Contacts */
      insert into Contacts (ContactRefId, Name, ContactType, AddressLine1, AddressLine2, AddressLine3,
                            City, State, Zip, Country, PhoneNo, Email, ContactPerson, AddressRegion,
                            BusinessUnit, CreatedBy)
        select @vContactRefId, @vName, @vContactType, @vAddressLine1, @vAddressLine2, @vAddressLine3,
               @vCity, @vState, @vZip, @vCountry, @vPhoneNo, @vEmail, @vContactPerson, @vAddressRegion,
               @BusinessUnit, @UserId;
    end
  else
  /* Edit contact */
  if (@vAction = 'Contacts_Edit') and (coalesce(@vContactId, 0) <> 0)
    begin
      update Contacts
      set
        Name          = dbo.fn_RemoveSpecialChars(@vName),
        ContactType   = @vContactType,
        AddressLine1  = dbo.fn_RemoveSpecialChars(@vAddressLine1),
        AddressLine2  = dbo.fn_RemoveSpecialChars(@vAddressLine2),
        AddressLine3  = dbo.fn_RemoveSpecialChars(@vAddressLine3),
        City          = @vCity,
        State         = @vState,
        Zip           = @vZip,
        Country       = @vCountry,
        PhoneNo       = @vPhoneNo,
        Email         = @vEmail,
        ContactPerson = @vContactPerson,
        AddressRegion = @vAddressRegion,
        ModifiedDate  = current_timestamp,
        ModifiedBy    = coalesce(@UserId, system_user)
      where (ContactId = @vContactId);
    end

  /* Get record count */
  select @vRecordsUpdated = @@rowcount;

  /* Build response */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_Contacts_Action_AddorEdit */

Go
