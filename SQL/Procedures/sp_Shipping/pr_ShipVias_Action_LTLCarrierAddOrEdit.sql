/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/17  PK/AY   pr_ShipVias_Action_LTLCarrierAddOrEdit: Update date time and user on add/edit (HA-Support)
  2021/04/23  SJ      pr_ShipVias_Action_LTLCarrierAddOrEdit: Made changes to get SCAC for LTL Carrier (HA-2618)
  2020/11/23  KBB     pr_ShipVias_Action_LTLCarrierAddOrEdit: Added new Action procedure for LTL Carrier add or Update (HA-1670)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipVias_Action_LTLCarrierAddOrEdit') is not null
  drop Procedure pr_ShipVias_Action_LTLCarrierAddOrEdit;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipVias_Action_LTLCarrierAddOrEdit: This procedure is used for
  Create new ShipVias & Update existing Shipvias
------------------------------------------------------------------------------*/
Create Procedure pr_ShipVias_Action_LTLCarrierAddOrEdit
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                 TInteger,
          @vMessageName                TMessageName,
          @vRecordId                   TRecordId,
          /* Response */
          @vRecordsUpdated             TCount,
          @vTotalRecords               TCount,
          /* Input variables */
          @vEntity                     TEntity,
          @vAction                     TAction,
          @vShipVia                    TShipvia,
          @vCarrier                    TCarrier,
          @vDescription                TDescription,
          @vCarrierServiceCode         TCarrier,
          @vIsSmallPackageCarrier      TFlags,
          @vStatus                     TStatus,
          @vSCAC                       TStatus,
          @vServiceClass               TDescription,
          @vServiceClassDesc           TDescription;

begin /* pr_ShipVias_Action_LTLCarrierAddOrEdit */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @vRecordId    = 0;

  /* Extract form inputs */
  select @vEntity                = Record.Col.value('Entity[1]',                       'TEntity'),
         @vAction                = Record.Col.value('Action[1]',                       'TAction'),
         @vRecordId              = Record.Col.value('(Data/RecordId) [1]',             'TRecordId'),
         @vShipVia               = Record.Col.value('(Data/ShipVia)[1]',               'TShipvia'),
         @vCarrier               = Record.Col.value('(Data/Carrier)[1]',               'TCarrier'),
         @vDescription           = Record.Col.value('(Data/Description)[1]',           'TDescription'),
         @vCarrierServiceCode    = Record.Col.value('(Data/CarrierServiceCode)[1]',    'TCarrier'),
         @vIsSmallPackageCarrier = Record.Col.value('(Data/IsSmallPackageCarrier)[1]', 'TFlags'),
         @vServiceClass          = Record.Col.value('(Data/ServiceClass)[1]',          'TDescription'),
         @vServiceClassDesc      = Record.Col.value('(Data/ServiceClassDesc)[1]',      'TDescription'),
         @vSCAC                  = Record.Col.value('(Data/SCAC)[1]',                  'TShipvia'),
         @vStatus                = Record.Col.value('(Data/Status)[1]',                'TStatus')
  from @xmlData.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlData = null));

  /* Get RecordId of selected Shipvia */
  select @vRecordId = RecordId
  from ShipVias
  where (ShipVia = @vShipVia) and (BusinessUnit = @BusinessUnit);

  /* Validations */
  if (@vAction = 'ShipVias_LTLCarrierAdd') and (@vRecordId <> 0)
    set @vMessageName = 'ShipViaAlreadyExists';
  else
  if (@vAction in ('ShipVias_LTLCarrierAdd', 'ShipVias_LTLCarrierEdit')) and (coalesce(@vCarrier, '') = '')
    set @vMessageName = 'CarrierIsRequired';
  else
  if (@vAction in ('ShipVias_LTLCarrierAdd', 'ShipVias_LTLCarrierEdit')) and (@vCarrier not in ('LTL', 'Generic'))
    set @vMessageName = 'ShipVia_LTLCarrierIsInvalid';
  else
  if (@vAction in ('ShipVias_LTLCarrierAdd', 'ShipVias_LTLCarrierEdit')) and (@vDescription is null)
    set @vMessageName = 'ShipViaDescIsrequired';
  else
  if (@vAction = 'ShipVias_LTLCarrierEdit') and (@vRecordId = 0)
    set @vMessageName = 'ShipViaDoesNotExist';

  /* If Error, then return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  select @vTotalRecords = count(*) from #ttSelectedEntities;

  /* Insert the Records into Shipvias Table */
  if (@vAction = 'ShipVias_LTLCarrierAdd')
    begin
      /* #ttSelectedEntities is not populated with entries during addition of a new Shipvias
         Right now we will be adding 1 record at a time */
      select @vTotalRecords = 1;

      insert into ShipVias
        (ShipVia, Carrier, Description, CarrierServiceCode, IsSmallPackageCarrier, SCAC,
         ServiceClass, ServiceClassDesc, Status, CreatedBy, BusinessUnit)
        select @vShipVia, @vCarrier, @vDescription, @vCarrierServiceCode, @vIsSmallPackageCarrier, @vSCAC,
               @vServiceClass, @vServiceClassDesc, @vStatus, @UserId, @BusinessUnit
     end
  /* Update the details of selected ShipVias */
  else
  if (@vAction = 'ShipVias_LTLCarrierEdit')
    update ShipVias
    set ShipVia               = coalesce(@vShipVia,               ShipVia),
        Carrier               = coalesce(@vCarrier,               Carrier),
        Description           = coalesce(@vDescription,           Description),
        CarrierServiceCode    = coalesce(@vCarrierServiceCode,    CarrierServiceCode),
        IsSmallPackageCarrier = coalesce(@vIsSmallPackageCarrier, IsSmallPackageCarrier),
        SCAC                  = coalesce(@vSCAC,                  SCAC),
        ServiceClass          = coalesce(@vServiceClass,          ServiceClass),
        ServiceClassDesc      = coalesce(@vServiceClassDesc,      ServiceClassDesc),
        Status                = coalesce(@vStatus,                Status),
        ModifiedDate          = current_timestamp,
        ModifiedBy            = @UserId
    from ShipVias S
      join #ttSelectedEntities ttSE on (S.RecordId = ttSE.EntityId);

  select @vRecordsUpdated = @@rowcount

  /* Build response for user */
  exec pr_Messages_BuildActionResponse @vEntity, @vAction, @vRecordsUpdated, @vTotalRecords;

  return(coalesce(@vReturnCode, 0));
end /* pr_ShipVias_Action_LTLCarrierAddOrEdit */

Go
