/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/26  RKC     pr_AMF_Picking_InitiatePalletDrop: Build the drop pallet as the operation (HA-2115)
  2021/03/17  RKC     pr_AMF_Picking_InitiatePalletDrop: Build the drop pallet as the operation (HA-2115)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_InitiatePalletDrop') is not null
  drop Procedure pr_AMF_Picking_InitiatePalletDrop;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_InitiatePalletDrop:

------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_InitiatePalletDrop
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
  declare @vInputXML             xml,
          @vrfcProcInputxml      xml,
          @vrfcProcOutputxml     xml,
          @vPalletDetails        xml,
          @vOutstandingPicksxml  xml,
          @vTaskInfoxml          TXML,
          @vPalletInfoXML        TXML,
          @vOutstandingPicks     TXML,
          @vPalletId             TRecordId,
          @vPallet               TPallet,
          @vQuantity             TQuantity,
          @vRFFormAction         TMessageName,
          @vBusinessUnit         TBusinessUnit,
          @vTaskId               TRecordid,
          @vTransactionFailed    TBoolean;
begin /* pr_AMF_Picking_InitiatePalletDrop */
  select @vInputXML = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vInputXML.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vInputXML.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Get the pallet & RFfromaction info */
  select @vPallet        = Record.Col.value('(Data/Pallet)[1]',          'TPallet'   ),
         @vRFFormAction  = Record.Col.value('(Data/RFFormAction)[1]',    'TOperation')
  from @vInputXML.nodes('/Root') as Record(Col)

  /* Get pallet Qunatiy and validate below */
  select @vQuantity = Quantity
  from pallets
  where pallet = @vPallet

  /* If the user does not scan the pallet or nothing has been picked against to pallet. But click the
     complete or pause reservation, navigate to the first screen */
  if (((coalesce(@vPallet, '') = '') or  (coalesce(@vQuantity, 0) = 0)) and (@vRFFormAction = 'CompleteReservation'))
    begin
      /* Build the data xml */
      select @DataXML = (select 'Pause' Resolution
                         for Xml Raw(''), elements, Root('Data'));

      return;
    end

  /* Build the input for V2 procedure */
  select @vrfcProcInputxml = (select Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'    ) as DeviceId,
                                     Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'      ) as UserId,
                                     Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit') as BusinessUnit,
                                     Record.Col.value('(Data/Pallet)[1]',                     'TPallet'      ) as Pallet,
                                     'DropPallet'                                                              as Operation
                              from @vInputXML.nodes('/Root') as Record(Col)
                              for xml raw('DropPalletInfo'), elements);

  /* Build the xml in the format expected by the ValidatePallet procedure */
  select @vrfcProcInputxml = convert(xml, dbo.fn_XMLNode('ValidateDropPallet', convert(varchar(max), @vrfcProcInputxml)));

  /* Execute V2 procedure */
  exec pr_RFC_Picking_ValidatePallet @vrfcProcInputxml, @vrfcProcOutputxml output;

  exec pr_AMF_EvaluateExecResult @vrfcProcOutputxml, @vTransactionFailed output,
                                 @ErrorXML output, @DataXML output;

  /* If there is error raised simply return */
  if (@vTransactionFailed > 0) return;

  /* Read Pallet Id etc from output XML */
  select @vPalletId     = Record.Col.value('(PalletId)[1]',      'TRecordId'),
         @vPallet       = Record.Col.value('(Pallet)[1]',        'TPallet'),
         @vTaskId       = nullif(Record.Col.value('(TaskId)[1]', 'TRecordId'), ''),
         @vBusinessUnit = Record.Col.value('(BusinessUnit)[1]',  'TBusinessUnit')
  from @vrfcProcOutputxml.nodes('ValidateDropPallet/DropPalletResponse') as Record(Col);

  /* Pallet may be associated with Task or not, if associated with task, then get
     TaskInfo and outstanding picks */
  if (@vTaskId is not null)
    begin
      /* Get Task info to fill the form */
      exec pr_AMF_Info_GetTaskInfoXML @vTaskId, 'ValidatePallet', @vTaskInfoXML output;
      exec pr_AMF_Info_GetOutstandingPicks @vTaskId, @vOutstandingPicks output, @vOutstandingPicksxml output;
    end

  select @DataXML = '';
  with ResponseDetails as
  (
    select dbo.fn_XMLNode('DROPPALLETRESPONSE' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
    from @vrfcProcOutputxml.nodes('/ValidateDropPallet/DropPalletResponse/*') as t(c)
  )
  select @DataXML = @DataXML + ResponseDetail from ResponseDetails;

  if (@vTaskId is null) -- like when dropping after LPNReservations
    exec pr_AMF_Info_GetPalletInfoXML @vPalletId, 'N' /* No Details */,
                                      'DropPallet' /* Operation */, @vPalletInfoXML output;

  select @DataXml = dbo.fn_XmlNode('Data', @DataXML + coalesce(@vTaskInfoxml, '') +
                                           coalesce(@vOutstandingPicks, '') +
                                           coalesce(@vPalletInfoXML, ''));
end /* pr_AMF_Picking_InitiatePalletDrop */

Go

