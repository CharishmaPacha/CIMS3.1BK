/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/16  RIA     pr_AMF_CC_ConfirmReserveLoc_Pallet: Changes to clear data nodes that are not needed (HA-1984)
  2020/11/17  SK      pr_AMF_CC_ConfirmReserveLoc_PalletD3: Modified to pr_AMF_CC_ConfirmReserveLoc_Pallet (HA-1567)
  2020/09/10  SK      pr_AMF_CC_ConfirmReserveLoc_PalletD3: Upgraded to match up LD2 count changes
  Added pr_AMF_CC_ConfirmReserveLoc_PalletD3 (HA-1077)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_CC_ConfirmReserveLoc_Pallet') is not null
  drop Procedure pr_AMF_CC_ConfirmReserveLoc_Pallet;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_CC_ConfirmReserveLoc_Pallet:
    Confirm Location - Pallet Depth 3 and 4
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_CC_ConfirmReserveLoc_Pallet
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  /* Standard variables */
  declare @vReturnCode              TInteger,
          @vMessageName             TMessageName,
          @vMessage                 TMessage,
          @vxmlInput                xml,
          @vxmlOutput               xml,
          @vxmlRFCProcInput         xml,
          @vxmlRFCProcOutput        xml,
          @vrfcProcInputxml         TXML,
          @vrfcProcOutputxml        TXML,
          @vTransactionFailed       TBoolean,
          /* Input variables */
          @vBusinessUnit            TBusinessUnit,
          @vUserId                  TUserId,
          @vDeviceId                TDeviceId,
          @vLPN                     TLPN,
          @vTaskSubType             TFlag,
          @vTaskId                  TRecordId,
          @vTaskDetailId            TRecordId,
          @vOperation               TOperation;
          /* Functional variables */
  declare @vDeviceName              TName,
          @vBatchNo                 TTaskBatchNo,
          @vPickZone                TZoneId,
          @vLocationId              TRecordId,
          @vLocation                TLocation,
          @vLocNumLPNs              TQuantity,
          @vRFFormAction            TDescription,
          @vxmlData                 xml,
          @vLocCCInfoXML            TXML,
          @vTempXML                 TXML;
          /* Temporary table */
  declare @CCConfirmedDetails       TCycleCountTable;
begin /* pr_AMF_CC_ConfirmReserveLoc_Pallet */

  /* Convert input into xml var */
  select @vxmlInput = convert(xml, @InputXML);

  /* Build temporary table */
  select * into #CCConfirmedDetails from @CCConfirmedDetails;

  /* Initialize */
  select @DataXML       = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML     = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML      = null,
         @InfoXML       = null,
         @vMessageName  = null;

  /* Read inputs from InputXML */
  select @vBusinessUnit   = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'),
         @vUserId         = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ),
         @vDeviceId       = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ),
         @vTaskSubType    = Record.Col.value('(Data/m_TaskSubType)[1]',              'TFlag'        ),
         @vTaskId         = Record.Col.value('(Data/m_TaskId)[1]',                   'TRecordId'    ),
         @vTaskDetailId   = Record.Col.value('(Data/m_TaskDetailId)[1]',             'TRecordId'    ),
         @vBatchNo        = Record.Col.value('(Data/m_BatchNo)[1]',                  'TTaskBatchNo' ),
         @vLocationId     = Record.Col.value('(Data/m_LocationInfo_LocationId)[1]',  'TRecordId'    ),
         @vLocation       = Record.Col.value('(Data/m_LocationInfo_Location)[1]',    'TLocation'    ),
         @vOperation      = Record.Col.value('(Data/Operation)[1]',                  'TOperation'   ),
         @vRFFormAction   = Record.Col.value('(Data/RFFormAction)[1]',               'TDescription' )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* set value for DeviceName to replace current data set to Devices table */
  select @vDeviceName = @vDeviceId + '@' + @vUserId;

  /* Build the Location Header Info */
  select @vLocCCInfoXML = dbo.fn_XMLNode('CONFIRMCYCLECOUNTDETAILS',
                            dbo.fn_XMLNode('Location',      @vLocation) +
                            dbo.fn_XMLNode('SubTaskType',   @vTaskSubType) +
                            dbo.fn_XMLNode('TaskId',        @vTaskId) +
                            dbo.fn_XMLNode('TaskDetailId',  @vTaskDetailId) +
                            dbo.fn_XMLNode('BatchNo',       @vBatchNo) +
                            dbo.fn_XMLNode('BusinessUnit',  @vBusinessUnit) +
                            dbo.fn_XMLNode('UserId',        @vUserId) +
                            dbo.fn_XMLNode('DeviceId',      @vDeviceId));

  /* Build the Locations Pallet Details */
  insert into #CCConfirmedDetails(EntityType, EntityKey, Pallet, LPN, SKU, NewInnerPacks, NewQuantity)
    select 'Pallet',
           Record.Col.value('(Pallet)[1]',        'TPallet'),
           Record.Col.value('(Pallet)[1]',        'TPallet'),
           Record.Col.value('(LPN)[1]',           'TLPN'),
           Record.Col.value('(SKU)[1]',           'TSKU'),
           Record.Col.value('(NewInnerPacks)[1]', 'TInnerPacks'),
           Record.Col.value('(NewUnits)[1]',      'TQuantity')
    from @vxmlInput.nodes('/Root/Data/CCData/CCTable') as Record(Col);

  select @vTempXML = (select Pallet        as Pallet,
                             LPN           as LPN,
                             SKU           as SKU,
                             NewInnerPacks as InnerPacks,
                             NewQuantity   as Quantity
                      from #CCConfirmedDetails
                      for xml path('LOCATIONINFO'), root('CCLOCDETAILS'));

  select @vxmlRFCProcInput = convert(xml, dbo.fn_XMLAddNode(@vLocCCInfoXML, 'CONFIRMCYCLECOUNTDETAILS', @vTempXML));

  /* Delete the below nodes as it is causing issues in data binding when there is an error */
  /* Future: Removing m_ nodes will be removed in future version where a flag will be set in the form to not to send these in the first place */
  select @vxmlData = convert(xml, @DataXML);
  set @vxmlData.modify('delete /Data/LPN');
  set @vxmlData.modify('delete /Data/m_LPN');
  set @vxmlData.modify('delete /Data/m_CCData');
  select @DataXML = convert(varchar(max), @vxmlData);

  update Devices
  set DataXML = @DataXML
  where (DeviceId = @vDeviceName);

  /* Complete CC for Reserve Location for Pallet */
  exec pr_RFC_CC_CompleteLocationCC @vxmlRFCProcInput, @vxmlRFCProcOutput output;

  /* Evaluate the result returned */
  exec pr_AMF_EvaluateExecResult @vxmlRFCProcOutput, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output, @InfoXML output;

  /* If an error occurs while completing cc, exit */
  if (coalesce(@vTransactionFailed, 0) <> 0)
    return @vTransactionFailed;

  /* CC is completed on Location, now prepare the response: If directed, suggest the
     next location or else it is done */
  exec pr_CycleCount_CompleteResponse @vxmlRFCProcOutput, @vLocation, @DataXml output, @InfoXML output;

end /* pr_AMF_CC_ConfirmReserveLoc_Pallet */

Go

