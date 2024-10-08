/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/07/29  RKC     pr_BoLs_Action_BoLCarrierDetailsModify:Changed the XML field name to get the values from XML (HA-1051)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_BoLs_Action_BoLCarrierDetailsModify') is not null
  drop Procedure pr_BoLs_Action_BoLCarrierDetailsModify;
Go
/*------------------------------------------------------------------------------
  Proc pr_BoLs_Action_BoLCarrierDetailsModify:
------------------------------------------------------------------------------*/
Create Procedure pr_BoLs_Action_BoLCarrierDetailsModify
  (@xmlData       xml,
   @BusinessUnit  TBusinessUnit,
   @UserId        TUserId,
   @ResultXML     TXML           = null output)
as
  /* Declare local variables */
  declare @vReturnCode                TInteger,
          @vMessageName               TMessageName,
          @vRecordId                  TRecordId,
          @vEntity                    TEntity,
          @vAction                    TAction,

          @vBoLCarrierDetailId        TRecordId,
          @vBoLNumber                 TBoLNumber,
          @vHandlingUnitQty           TQuantity,
          @vHandlingUnitType          TTypeCode,
          @vPackageQty                TQuantity,
          @vPackageType               TTypeCode,
          @vHazardous                 TFlag,
          @vNMFCDescription           TDescription,
          @vNMFCCode                  TLookUpCode,
          @vNMFCClass                 TCategory,
          @vWeight                    TWeight,
          @vVolume                    TVolume,

          @vRecordsUpdated            TCount,
          @vTotalRecords              TCount,
          @vMessage                   TXML;
begin /* pr_BoLs_Action_BoLCarrierDetailsModify */
  SET NOCOUNT ON;

  select @vReturnCode = 0,
         @vMessage    = null,
         @vRecordId   = 0;

  select @vEntity             = Record.Col.value('Entity[1]',             'TEntity'),
         @vAction             = Record.Col.value('Action[1]',             'TAction'),
         @vBoLCarrierDetailId = Record.Col.value('BoLCarrierDetailId[1]', 'TRecordId'),
         @vBoLNumber          = Record.Col.value('BoLNumber[1]',          'TBoLNumber'),
         @vHandlingUnitQty    = Record.Col.value('HandlingUnitQty[1]',    'TQuantity'),
         @vHandlingUnitType   = Record.Col.value('HandlingUnitType[1]',   'TTypeCode'),
         @vPackageQty         = Record.Col.value('PackageQty[1]',         'TQuantity'),
         @vPackageType        = Record.Col.value('PackageType[1]',        'TTypeCode'),
         @vVolume             = Record.Col.value('Volume[1]',             'TVolume'),
         @vWeight             = Record.Col.value('Weight[1]',             'TWeight'),
         @vHazardous          = Record.Col.value('Hazardous[1]',          'TFlag'),
         @vNMFCDescription    = Record.Col.value('CommDescription[1]',    'TDescription'),
         @vNMFCCode           = Record.Col.value('NMFCCode[1]',           'TLookUpCode'),
         @vNMFCClass          = Record.Col.value('NMFCClass[1]',          'TCategory')
  from @xmlData.nodes('/Root/Data') as Record(Col)
  OPTION ( OPTIMIZE FOR ( @xmlData = null ) );

  /*  Call the Proc to do the updates */
  exec pr_BoLCarrierDetails_Update @vBoLCarrierDetailId, @vBoLNumber, @vHandlingUnitQty, @vHandlingUnitType, @vPackageQty, @vPackageType,
                                   @vVolume, @vWeight, @vHazardous, @vNMFCDescription, @vNMFCCode, @vNMFCClass, @vMessage output;

  /* Return Result Message */
  insert into #ResultMessages (MessageType, MessageName) select 'I', @vMessage;

  return(coalesce(@vReturnCode, 0));
end /* pr_BoLs_Action_BoLCarrierDetailsModify */

Go
