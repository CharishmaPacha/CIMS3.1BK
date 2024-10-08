/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/30  RIA     pr_AMF_Inventory_TransferInventory: Changes to retain information (OB2-1970)
  2020/04/29  RIA     pr_AMF_Inventory_TransferInventory: Changes to transfer inventory in case level (CIMSV3-873)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_TransferInventory') is not null
  drop Procedure pr_AMF_Inventory_TransferInventory;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_TransferInventory: Will transfer qty from FromLocation/LPN
  to ToLocation/LPN
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_TransferInventory
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TDescription,
          @vMessage                  TMessage,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML,
          @vLocationInfoXML          TXML,
          @vLocationDetailsXML       TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vFromEntity               TEntity,
          @vToEntity                 TEntity,
          @vScannedSKU               TSKU,
          @vNewInnerPacks            TInnerPacks,
          @vUnits                    TQuantity,
          @vUnits1                   TQuantity,
          @vLPNOperation             TOperation,
          @vLocationOperation        TOperation,
          @vOperation                TOperation,
          @vAction                   TAction;
          /* Functional variables */
  declare @vLPN                      TLPN,
          @vLPNId                    TRecordId,
          @vSKU                      TSKU,
          @vSKUId                    TRecordId,
          @vLPNSKUId                 TRecordId,
          @vEntityType               TTypeCode,
          @vLPNType                  TTypeCode,
          @vLocationSKU              TSKU,
          @vLPNSKU                   TSKU,
          @vCurrSKU                  TSKU,
          @vDestinationLocationOrLPN TEntity,
          @vNewQuantity              TQuantity,
          @vLPNQty                   TQuantity,
          @vLPNStatus                TStatus,
          @vNumLPNs                  TCount,
          @vSource                   TEntity,
          @vDestination              TEntity,
          @vReasonCode               TReasonCode,
          /* From variables */
          @vFromLocationId           TRecordId,
          @vFromLocation             TLocation,
          @vFromLPNId                TRecordId,
          @vFromLPN                  TLPN,
          @vRFFormAction             TMessageName,
          /* To variabe */
          @vToLocationId             TRecordId,
          @vToLocation               TLocation,
          @vToLPNId                  TRecordId,
          @vToLPN                    TLPN;
begin /* pr_AMF_Inventory_TransferInventory */

  select @vxmlInput   = convert(xml, @InputXML),  /* Convert input into xml var */
         @vReasonCode = '132'; /* TransferInventory */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit      = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId            = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId          = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vFromEntity        = Record.Col.value('(Data/Entity)[1]',                     'TEntity'      ),
         @vEntityType        = Record.Col.value('(Data/m_EntityType)[1]',               'TTypeCode'    ),
         @vLPNSKU            = Record.Col.value('(Data/m_LPNInfo_SKU)[1]',              'TSKU'         ),
         @vLocationSKU       = Record.Col.value('(Data/m_LocationInfo_SKU)[1]',         'TSKU'         ),
         @vToEntity          = Record.Col.value('(Data/ToEntity)[1]',                   'TEntity'      ),
         @vScannedSKU        = Record.Col.value('(Data/SKU)[1]',                        'TSKU'         ),
         @vNewInnerPacks     = Record.Col.value('(Data/NewInnerPacks)[1]',              'TInnerPacks'  ),
         @vUnits             = nullif(Record.Col.value('(Data/NewUnits)[1]',            'TQuantity'    ), ''),
         @vUnits1            = nullif(Record.Col.value('(Data/NewUnits1)[1]',           'TQuantity'    ), ''),
         @vLPNOperation      = Record.Col.value('(Data/LPNOperation)[1]',               'TOperation'   ),
         @vLocationOperation = Record.Col.value('(Data/LocationOperation)[1]',          'TOperation'   ),
         @vOperation         = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   ),
         @vRFFormAction      = Record.Col.value('(Data/RFFormAction)[1]',               'TMessageName' ),
         @vAction            = Record.Col.value('(Data/Action)[1]',                     'TAction'      )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Identify the From Entity */
  exec pr_LPNs_IdentifyLPNOrLocation @vFromEntity, @vBusinessUnit, @vUserId,
                                     @vSource out, @vFromLPNId out, @vFromLPN out,
                                     @vFromLocationId out, @vFromLocation out;

  /* Identify the To Entity */
  exec pr_LPNs_IdentifyLPNOrLocation @vToEntity, @vBusinessUnit, @vUserId,
                                     @vDestination out, @vToLPNId out, @vToLPN out,
                                     @vToLocationId out, @vToLocation out;

  /* If it is a multi SKU LPN/Location, user would be required to scan the SKU, so
     use the current SKU */
  select @vCurrSKU      = coalesce(nullif(@vScannedSKU, ''), @vLPNSKU, @vLocationSKU, ''),
         @vNewQuantity  = coalesce(@vUnits, @vUnits1);

  /* Build the input to setup location min/max level */
  select @vxmlRFCProcInput = (select @vFromLocationId                               as FromLocationId,
                                     @vFromLocation                                 as FromLocation,
                                     @vFromLPNId                                    as FromLPNId,
                                     @vFromLPN                                      as FromLPN,
                                     @vToLocationId                                 as ToLocationId,
                                     @vToLocation                                   as ToLocation,
                                     @vToLPNId                                      as ToLPNId,
                                     @vToLPN                                        as ToLPN,
                                     coalesce(@vToLocation, @vToLPN)                as DestinationLocationOrLPN,
                                     @vCurrSKU                                      as CurrentSKU,
                                     @vNewInnerPacks                                as NewInnerPacks,
                                     @vNewQuantity                                  as TransferQuantity,
                                     @vReasonCode                                   as ReasonCode,
                                     @vOperation                                    as Operation,
                                     @vBusinessUnit                                 as BusinessUnit,
                                     @vUserId                                       as UserId
                              for xml raw('TransferInventory'), elements);

  /* Call the V2 proc to transfer inventory ToLPN/Location */
  exec pr_RFC_TransferInventory @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  /* As Transfer Inventory raises errors considering we come here only after success */
  select @vMessage   = Record.Col.value('(SUCCESSDETAILS/SUCCESSINFO/Message)[1]',       'TMessage' )
         --@vLPNId     = Record.Col.value('(vwLPNDetailDto/vwLPNDetails/LPNId)[1]',        'TRecordId')
  from @vxmlRFCProcOutput.nodes('/TransferInventoryInfo') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlRFCProcOutput = null));

  /* Build the success message */
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  /* Get the quantity of the LPN/Location */
  if (@vEntityType = 'LOC')
    select @vLPNQty = sum(Quantity) from LPNs where (LocationId = @vFromLocationId);
  else
  if (@vEntityType = 'LPN')
    select @vLPNQty = sum(Quantity) from LPNs where (LPNId = @vFromLPNId);

  /* When user clicked on confirm/continue then build the data again */
  if (@vRFFormAction = 'ConfirmAndContinue') and (@vLPNQty > 0)
    begin
      if (@vEntityType = 'LOC') /* Get Location Info */
        exec pr_AMF_Info_GetLocationInfoXML @vFromLocationId, null, @vLocationOperation,
                                            @vLocationInfoXML output, @vLocationDetailsXML output;
      else
      if (@vEntityType = 'LPN') /* Get LPN Info */
        exec pr_AMF_Info_GetLPNInfoXML @vFromLPNId, null /* LPNDetails */, @vLPNOperation,
                                       @vLPNInfoXML output, @vLPNDetailsXML output;
      /* Build the DataXML */
      select @DataXml = dbo.fn_XMLNode('Data', coalesce(@vLPNInfoXML, @vLocationInfoXML) +
                                               coalesce(@vLPNDetailsXML, @vLocationDetailsXML) +
                                               dbo.fn_XMLNode('XferInventory', 'Y') +
                                               dbo.fn_XMLNode('ToEntity', @vToEntity) +
                                               dbo.fn_XMLNode('EntityType', @vEntityType));
    end
  else
    select @DataXML = (select 'Done' Transfer for xml Raw(''), elements, Root('Data'));

end /* pr_AMF_Inventory_TransferInventory */

Go

