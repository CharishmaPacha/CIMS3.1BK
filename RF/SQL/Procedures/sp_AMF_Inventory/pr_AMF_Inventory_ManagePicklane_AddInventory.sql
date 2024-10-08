/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/14  RIA     pr_AMF_Inventory_ManagePicklane_AddInventory: Changes to fetch LPNId and successful message (HA-1688)
  2021/05/16  RIA     pr_AMF_Inventory_ManagePicklane_AddInventory: Changes to update/add inventory (HA-1688)
  2020/01/07  RIA     Added pr_AMF_Inventory_ManagePicklane_AddInventory, pr_AMF_Inventory_ManagePicklane_SetupPicklane,
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_ManagePicklane_AddInventory') is not null
  drop Procedure pr_AMF_Inventory_ManagePicklane_AddInventory;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_ManagePicklane_AddInventory:
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_ManagePicklane_AddInventory
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
          @vMessage                  TMessage,
          @vxmlInput                 xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vLocationId               TRecordId,
          @vLocation                 TLocation,
          @vLPNId                    TRecordId,
          @vSKUId                    TRecordId,
          @vSKU                      TSKU,
          @vSKUDescription           TDescription,
          @vQuantity                 TQuantity,
          @vReplenishUoM             TUoM,
          @vReasonCode               TReasonCode,
          @vInventoryClasses         TInventoryClass,
          @vInvClass1                TInventoryClass,  /* User given input in AddSKUWith InvClass form */
          @vInvClass2                TInventoryClass,
          @vInvClass3                TInventoryClass,
          @vCurrInvClass1            TInventoryClass,  /* Values retained from existing LPNs */
          @vCurrInvClass2            TInventoryClass,
          @vCurrInvClass3            TInventoryClass,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vInnerPacks               TInnerPacks,
          @vInventoryClass1          TInventoryClass,
          @vInventoryClass2          TInventoryClass,
          @vInventoryClass3          TInventoryClass,
          @vDisplayOptions           TXML,
          @vLocationInfoXML          TXML,
          @vLocationDetailsXML       TXML,
          @vCurrResponseXML          TXML,
          @vxmlCurrResponse          xml;
begin /* pr_AMF_Inventory_ManagePicklane_AddInventory */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit     = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'  ),
         @vUserId           = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'        ),
         @vDeviceId         = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'      ),
         @vLocationId       = Record.Col.value('(Data/m_LocationInfo_LocationId)[1]',  'TRecordId'      ),
         @vLocation         = Record.Col.value('(Data/m_LocationInfo_Location)[1]',    'TLocation'      ),
         @vQuantity         = Record.Col.value('(Data/Quantity)[1]',                   'TQuantity'      ),
         @vReplenishUoM     = Record.Col.value('(Data/UoM)[1]',                        'TUoM'           ),
         @vReasonCode       = Record.Col.value('(Data/ReasonCode)[1]',                 'TReasonCode'    ),
         @vSKUId            = Record.Col.value('(Data/SKUId)[1]',                      'TRecordId'      ),
         @vLPNId            = nullif(Record.Col.value('(Data/LPNId)[1]',               'TRecordId'), '' ),
         @vSKU              = Record.Col.value('(Data/m_SKU)[1]',                      'TSKU'           ),
         @vSKUDescription   = Record.Col.value('(Data/m_SKUDescription)[1]',           'TDescription'   ),
         @vInventoryClasses = Record.Col.value('(Data/m_InventoryClasses)[1]',         'TInventoryClass'),
         @vCurrInvClass1    = Record.Col.value('(Data/CurrInvClass1)[1]',              'TInventoryClass'),
         @vCurrInvClass2    = Record.Col.value('(Data/CurrInvClass2)[1]',              'TInventoryClass'),
         @vCurrInvClass3    = Record.Col.value('(Data/CurrInvClass3)[1]',              'TInventoryClass'),
         @vOperation        = Record.Col.value('(Data/Operation)[1]',                  'TOperation'     )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Doing this as for dynamic picklane SKU cannot be added with 0 qty, so we will
     not get the InventoryClass values, so we are fetching the values which are given
     by user in AddSKU and Invclass form which is saved in Devices table */
  select @vCurrResponseXML = CurrentPickingResponse
  from Devices
  where (DeviceId = @vDeviceId + '@' + @vUserId);

  select @vxmlCurrResponse = convert(xml, @vCurrResponseXML);

  select @vInvClass1        = Record.Col.value('InventoryClass1[1]',       'TInventoryClass'),
         @vInvClass2        = Record.Col.value('InventoryClass2[1]',       'TInventoryClass'),
         @vInvClass3        = Record.Col.value('InventoryClass3[1]',       'TInventoryClass')
  from @vxmlCurrResponse.nodes('/Data') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlCurrResponse = null));

  /* If user given/selected InvClass while adding SKU then we will consider that, if not we will take
     the value present on the LPN */
  select @vInventoryClass1 = coalesce(nullif(@vInvClass1,''), @vCurrInvClass1),
         @vInventoryClass2 = coalesce(nullif(@vInvClass2,''), @vCurrInvClass2),
         @vInventoryClass3 = coalesce(nullif(@vInvClass3,''), @vCurrInvClass3);

  /* If the SKU exists in the Location, then we would have an LPNId in which case
     we adjust the LPN, else we add SKU to the Location.
     As it is adding up inventory we are calling this proc, also it helps in overcoming the
     challenge we have with dynamic picklanes, as we cannot add 0 qty SKUs */
  if (@vLPNId is null)
    exec pr_RFC_AddSKUToLocation @vLocationId, @vLocation, @vSKUId, @vSKU,
                                 @vInnerPacks, @vQuantity, @vReasonCode, @vOperation,
                                 @vInventoryClass1, @vInventoryClass2, @vInventoryClass3,
                                 @vBusinessUnit, @vUserId, @vLPNId output;
  else
  /* Call the V2 proc to add/adjust the inventory for the given SKU */
  if (@vLPNId is not null)
    exec pr_RFC_AdjustLPN @vLPNId, null /* LPN */, null /* LPNDetailId */, @vSKUId, @vSKU,
                          @vInnerPacks, @vQuantity, @vReasonCode,
                          @vBusinessUnit, @vUserId;

  /* Get the success message, AT to be shown to user as success message */
  select top 1 @vMessage = Comment
  from vwATEntity
  where (EntityType = 'LPN') and (EntityId = @vLPNId)
  order by AuditId desc

  /* Build the success message */
  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  /* Get the location related info */
  exec pr_AMF_Info_GetLocationInfoXML @vLocationId, 'LPNList', @vOperation, @vLocationInfoXML output, @vLocationDetailsXML output;

  /* Call the proc to validate and get all possible options */
  exec pr_Inventory_ManagePicklane_GetValidOptions @vLocationId, @vBusinessUnit, @vDisplayOptions output;

  /* Build the DataXML */
  select @DataXml = dbo.fn_XMLNode('Data', @vLocationInfoXML + @vLocationDetailsXML +
                                           dbo.fn_XMLNode('InventoryClasses', @vInventoryClasses) +
                                           @vDisplayOptions);
end /* pr_AMF_Inventory_ManagePicklane_AddInventory */

Go

