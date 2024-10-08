/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/07/14  RIA     pr_AMF_Inventory_AdjustQty, pr_AMF_Inventory_ValidateEntity: Changes to build data (HA-2938)
  2020/12/16  RIA     pr_AMF_Inventory_AdjustQty: Changes to consider LPNDetailId (CIMSV3-1236)
  2020/04/16  RIA     pr_AMF_Inventory_AdjustQty: Changes to consider InnerPack/Each quantity (CIMSV3-802)
  2019/07/02  RIA     pr_AMF_Inventory_AdjustQty: Changes to show message with appropriate info (CID-593)
  2019/06/25  RIA     Added pr_AMF_Inventory_AdjustQty (CID-593)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inventory_AdjustQty') is not null
  drop Procedure pr_AMF_Inventory_AdjustQty;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inventory_AdjustQty: Adjusts the qty of a LPN or Location. In V3
    user does not just select a SKU to adjust, but selects a specific detail within
    the Location or LPN and hence we rely on the LPNDetailId passed in.
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inventory_AdjustQty
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
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId,
          @vEntity                   TEntity,
          @vLPNOperation             TOperation,
          @vLocationOperation        TOperation,
          @vNewInnerPacks            TInnerPacks,
          @vNewUnits                 TQuantity,
          @vNewUnits1                TQuantity,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vReasonCodeCategory       TCategory,
          @vReasonCodesXML           TXML,
          @vxmlReasonCodes           xml,
          @vLookUpCategory           TCategory,
          @vEntityType               TTypeCode,
          @vReservedQty              TQuantity,
          @vReasonCode               TReasonCode = null,
          @vNewQuantity              TQuantity,
          /* LPN */
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vLPNDetailId              TRecordId,
          @vLPNSKUId                 TRecordId,
          @vLPNType                  TTypeCode,
          @vLPNQuantity              TQuantity,
          @vLPNSKU                   TSKU,
          @vNumLPNSKUs               TCount,
          @vLPNInfoXML               TXML,
          @vLPNDetailsXML            TXML,
          @vxmlLPNInfo               xml,
          /* SKU */
          @vSKUId                    TRecordId,
          @vSKU                      TSKU,
          @vScannedSKU               TSKU,
          @vCurrSKU                  TSKU,
          /* Location */
          @vLocation                 TLocation,
          @vLocationId               TRecordId,
          @vLocationType             TTypeCode,
          @vLocationSKU              TSKU,
          @vNumLocSKUs               TCount,
          @vLocationInfoXML          TXML,
          @vLocationDetailsXML       TXML,
          @vEntityId                 TRecordId;
begin /* pr_AMF_Inventory_AdjustQty */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /*  Read inputs from InputXML */
  select @vBusinessUnit      = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId            = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vEntity            = Record.Col.value('(Data/Entity)[1]',                     'TEntity'      ),
         @vEntityType        = Record.Col.value('(Data/m_EntityType)[1]',               'TTypeCode'    ),
         @vLPNId             = Record.Col.value('(Data/m_LPNInfo_LPNId)[1]',            'TRecordId'    ),
         @vLPN               = Record.Col.value('(Data/m_LPNInfo_LPN)[1]',              'TLPN'         ),
         @vLPNDetailId       = nullif(Record.Col.value('(Data/LPNDetailId)[1]',         'TRecordId'    ), ''),
         @vLocationId        = Record.Col.value('(Data/m_LocationInfo_LocationId)[1]',  'TRecordId'    ),
         @vLocation          = Record.Col.value('(Data/m_LocationInfo_Location)[1]',    'TLocation'    ),
         @vNumLocSKUs        = Record.Col.value('(Data/m_LocationInfo_NumSKUs)[1]',     'TCount'       ),
         @vNumLPNSKUs        = Record.Col.value('(Data/m_LPNInfo_NumLines)[1]',         'TCount'       ),
         --@vSKUId           = Record.Col.value('(Data/m_LPNInfo_SKUId)[1]',            'TRecordId'    ),
         @vScannedSKU        = Record.Col.value('(Data/SKU)[1]',                        'TSKU'         ),
         @vLPNSKU            = Record.Col.value('(Data/m_LPNInfo_SKU)[1]',              'TSKU'         ),
         @vLocationSKU       = Record.Col.value('(Data/m_LocationInfo_SKU)[1]',         'TSKU'         ),
         @vNewInnerPacks     = Record.Col.value('(Data/NewInnerPacks)[1]',              'TInnerPacks'  ),
         @vNewUnits          = nullif(Record.Col.value('(Data/NewUnits)[1]',            'TQuantity'    ), ''),
         @vNewUnits1         = nullif(Record.Col.value('(Data/NewUnits1)[1]',           'TQuantity'    ), ''),
         @vReasonCode        = Record.Col.value('(Data/ReasonCode)[1]',                 'TReasonCode'  ),
         @vLookUpCategory    = Record.Col.value('(Data/LookUpCategory)[1]',             'TCategory'    ),
         @vLPNOperation      = Record.Col.value('(Data/LPNOperation)[1]',               'TOperation'   ),
         @vLocationOperation = Record.Col.value('(Data/LocationOperation)[1]',          'TOperation'   ),
         @vOperation         = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* If it is a multi SKU LPN/Location, user would be required to scan the SKU, so
     use the current SKU */
  select @vCurrSKU     = coalesce(nullif(@vScannedSKU, ''), @vLPNSKU, @vLocationSKU, ''),
         @vEntityId    = coalesce(nullif(@vLPNId,''), @vLocationId),
         @vNewQuantity = coalesce(@vNewUnits, @vNewUnits1);

  /* Get the SKU from the selected LPN detail */
  select @vSKUId = SKUId
  from LPNDetails
  where (LPNDetailId = @vLPNDetailId);

  if (@vLPNDetailId is null)
    set @vMessageName = 'AdjustQty_SelectValidLine';

  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

  /* If the LPN is logical LPN */
  if (@vEntityType = 'LOC' /* Location */)
    exec pr_RFC_AdjustLocation @vLocationId, @vLocation, @vLPNDetailId /* SKUId */, 'LPNDETAIL' /* CurrSKU */,
                               @vNewInnerPacks, @vNewQuantity, @vReasonCode,
                               @vBusinessUnit, @vUserId;
  else
    exec pr_RFC_AdjustLPN @vLPNId, @vLPN, @vLPNDetailId, @vSKUId, null /* SKU */,
                          @vNewInnerPacks, @vNewQuantity, @vReasonCode,
                          @vBusinessUnit, @vUserId;

  /* Above V2 procedures raise an exception or finish successfull */

  /* Adjust procedures do not return any confirmation, so get the latest AT for the scanned entity */
  select top 1 @vMessage = Comment
  from vwATEntity
  where (EntityId     = @vEntityId) and
        (ActivityType in ('LPNAdjustQty', 'LocationAdjustQty'))
  order by AuditId desc;

  select @InfoXML = dbo.fn_AMF_BuildSuccessXML(@vMessage);

  /* If successfully updated and the Location/LPN has only one item then we are done
     and we would revert to prior screen, or else give the LPN/Location info */
  if ((@vEntityType = 'LOC') and (@vNumLocSKUs = 1)) or
     ((@vEntityType = 'LPN') and (@vNumLPNSKUs = 1))
    begin
      select @DataXML = (select 'Done' Resolution
                         for Xml Raw(''), elements, Root('Data'));

      return;
    end

  /* If location/LPN has more than 1 SKU build the respective info */
  if (@vEntityType = 'LOC')
    begin
      exec pr_AMF_Info_GetLocationInfoXML @vLocationId, null, @vLocationOperation,
                                          @vLocationInfoXML output, @vLocationDetailsXML output;
     end
  else
  if (@vEntityType = 'LPN')
    begin
      exec pr_AMF_Info_GetLPNInfoXML @vLPNId, null /* LPNDETAILS */, @vLPNOperation,
                                     @vLPNInfoXML output, @vLPNDetailsXML output;
    end

  /* get the Reason codes for as we need them for AdjustLPN/Location */
  select @vReasonCodeCategory = 'RC_' + @vEntityType + 'Adjust';
  exec pr_AMF_BuildLookUpList @vReasonCodeCategory, 'ReasonCodes', 'select a reason', @vBusinessunit, @vReasonCodesXML output;

  /* build the data xml */
  select @DataXML = dbo.fn_XMLNode('Data', coalesce(@vLPNInfoXML, @vLocationInfoXML, '') +
                                           coalesce(@vLPNDetailsXML, @vLocationDetailsXML, '') +
                                           coalesce(@vReasonCodesXML, '') +
                                           dbo.fn_XMLNode('EntityType', @vEntityType));

end /* pr_AMF_Inventory_AdjustQty */

Go

