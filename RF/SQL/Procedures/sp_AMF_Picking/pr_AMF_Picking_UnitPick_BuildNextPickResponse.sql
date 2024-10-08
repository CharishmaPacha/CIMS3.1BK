/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/05/15  RIA     pr_AMF_Picking_UnitPick_BuildNextPickResponse: Get the last 5 char of PickToLPN (HA-556)
  2019/12/16  RIA     Added : pr_AMF_Picking_UnitPick_BuildNextPickResponse (CID-1214)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Picking_UnitPick_BuildNextPickResponse') is not null
  drop Procedure pr_AMF_Picking_UnitPick_BuildNextPickResponse;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Picking_UnitPick_BuildNextPickResponse: When there is another pick to be
   done, this procedure is called to build the response in V3 desired format
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Picking_UnitPick_BuildNextPickResponse
  (@xmlInput     xml,
   @OutputXML    TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessage                  TMessage,
          @vMessageName              TMessageName,
          @vSuccessMessage           TMessage,
          @vxmlInput                 xml,
          @vxmlOutput                xml,
          @vxmlRFCProcInput          xml,
          @vxmlRFCProcOutput         xml,
          @vrfcProcInputxml          TXML,
          @vrfcProcOutputxml         TXML,
          @vTransactionFailed        TBoolean,
          /* Input variables */
          @vBusinessUnit             TBusinessUnit,
          @vUserId                   TUserId,
          @vDeviceId                 TDeviceId;
          /* Functional variables */
  declare @vDataXML                  TXML,
          @vLPNId                    TRecordId,
          @vLPN                      TLPN,
          @vAutoInitializeToLPN      TFlags,
          @vPickToLPN                TLPN,
          @vActivityLogId            TRecordId;
begin /* pr_AMF_Picking_UnitPick_BuildNextPickResponse */

  /* Get LPN */
  select @vLPN = Record.Col.value('(BATCHPICKINFO/LPN)[1]', 'TLPN')
  from @xmlInput.nodes('/BATCHPICKDETAILS') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlInput = null));

  /* below statement with read all the nodes within the response and merge them into one single xml
     AMF format expects all information under <Data> */
  select @vDataXML = '';
  with ResponseDetails as
  (
    select dbo.fn_XMLNode('BATCHPICKINFO' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
    from @xmlInput.nodes('/BATCHPICKDETAILS/BATCHPICKINFO/*') as t(c)
    union
    select dbo.fn_XMLNode('OPTIONS' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) ResponseDetail
    from @xmlInput.nodes('/BATCHPICKDETAILS/OPTIONS/BATCHPICKING/*') as t(c)
  )
  select @vDataXML = @vDataXML + ResponseDetail from ResponseDetails;

  select @vAutoInitializeToLPN = Record.Col.value('AutoInitializeToLPN[1]',    'TFlags')
  from @xmlInput.nodes('/BATCHPICKDETAILS/OPTIONS/BATCHPICKING') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlInput = null));

  /* AutoInitializeToLPN is for different reason. We are using this in V2 RF to initialize and disable ToLPN control for perticular wave types.
     However we shouldn't depend on AutoInitializeToLPN to display ToLPN suggession. Hence removing the condition */
  select @vPickToLPN = Record.Col.value('PickToLPN[1]',    'TLPN')
  from @xmlInput.nodes('/BATCHPICKDETAILS/BATCHPICKINFO') as Record(Col)
  OPTION (OPTIMIZE FOR (@xmlInput = null));

  if (@vAutoInitializeToLPN = 'Y')
    select @vDataXML =  @vDataXML + dbo.fn_XMLNode('DefaultPickToLPN', coalesce(@vPickToLPN, ''));

  /*  read the pick list from the response and add it to data node list */
  select @vDataXML = @vDataXML + dbo.fn_XMLNode('LPNRight10', right(@vLPN, 10)) +
                                 dbo.fn_XMLNode('PickToLPNRight5', right(@vPickToLPN, 5)) +
                                 coalesce(convert(varchar(max), @xmlInput.query('BATCHPICKDETAILS/PICKLIST')), '');
  select @OutputXML = dbo.fn_XMLNode('Data', @vDataXML);

end /* pr_AMF_Picking_UnitPick_BuildNextPickResponse */

Go

