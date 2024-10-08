/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/29  RIA     pr_AMF_Packing_BuildPackInfo, pr_AMF_Packing_OrderPacking_ScanComplete: Did clean-up (CIMSV3)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Packing_OrderPacking_ScanComplete') is not null
  drop Procedure pr_AMF_Packing_OrderPacking_ScanComplete;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Packing_OrderPacking_ScanComplete:

  Once after user confirms the pack quantity, this proc will be called to compute
  the volume, weight of the packed items and also to determine the carton type
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Packing_OrderPacking_ScanComplete
  (@InputXML     TXML,
   @DataXML      TXML output,
   @UIInfoXML    TXML output,
   @InfoXML      TXML output,
   @ErrorXML     TXML output)
as
          /* Standard variables */
  declare @vReturnCode               TInteger,
          @vMessageName              TMessageName,
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
          @vDeviceId                 TDeviceId,
          @vOrderId                  TRecordId,
          @vRFFormAction             TMessageName,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vPackInfoXML              TXML,
          @vDataXML                  TXML,
          @vPackDetailsXML           TXML,
          @vxmlPackDetails           xml,
          @vxmlData                  xml,
          @vCustomer                 TName,
          @vShipTo                   TShipToId,
          @vShipToName               TName,
          @vShipToCSZ                TName,
          @vShipVia                  TShipVia,
          @vPackedQty                TInteger,
          @vSKUsPacked               TInteger,
          @vEstimatedWeight          TFloat,
          @vXmlDocHandle             TInteger,
          @vActivityLogId            TRecordId,
          @vSuccessMessage           TMessage;
begin /* pr_AMF_Packing_OrderPacking_ScanComplete */

  select @vxmlInput = convert(xml, @InputXML); /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Prepare xml doc from xml input */
  exec sp_xml_preparedocument @vXmlDocHandle output, @vxmlInput;

  if (@vXmlDocHandle is not null)
    begin
      select * into #PackingDetails
      from OPENXML(@vXmlDocHandle, '//Data/PackingCarton/CartonDetails', 2)
      with (SKU            TSKU,
            LPN            TLPN,
            UnitsPacked    TQuantity,
            SKUId          TRecordId,
            UnitWeight     TWeight,
            OrderId        TRecordId,
            OrderDetailId  TRecordId,
            LPNId          TRecordId,
            LPNDetailId    TRecordId)
      where (UnitsPacked > 0);
    end

  --select @vxmlSKUDetails = @vxmlInput.query('/Data/PackInfoTable');

  /* Get the total packed quantity and no of SKUs */
  select @vSKUsPacked      = count(*),
         @vPackedQty       = sum(UnitsPacked),
         @vEstimatedWeight = sum(UnitsPacked * UnitWeight)
  from #PackingDetails

  /* Read inputs from InputXML */
  select @vBusinessUnit     = Record.Col.value('(SessionInfo/BusinessUnit)[1]',     'TBusinessUnit'),
         @vUserId           = Record.Col.value('(SessionInfo/UserName)[1]',         'TUserId'      ),
         @vDeviceId         = Record.Col.value('(SessionInfo/DeviceId)[1]',         'TDeviceId'    ),
         @vOrderId          = Record.Col.value('(Data/m_OrderId)[1]',               'TRecordId'    )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Get ShipTo, ShipVia and Customer details based on the PickTicket */
  select @vCustomer   = OH.CustomerName,
         @vShipTo     = OH.ShipToId,
         @vShipToName = OH.ShipToName,
         @vShipToCSZ  = OH.ShipToCityStateZip,
         @vShipVia    = OH.ShipVia
  from vwOrderHeaders OH
  where (OrderId = @vOrderId);

  /* Compute the volume, weight of the packed items to determine the carton type */

  /* Build xml to evaluate Rules */
  select @vPackInfoXML = dbo.fn_XMLNode('UnitsPacked',     @vPackedQty) +
                         dbo.fn_XMLNode('SKUsPacked',      @vSKUsPacked) +
                         dbo.fn_XMLNode('EstimatedWeight', @vEstimatedWeight) +
                         dbo.fn_XMLNode('Customer',        @vCustomer) +
                         dbo.fn_XMLNode('ShipTo',          @vShipTo) +
                         dbo.fn_XMLNode('ShipToName',      @vShipToName) +
                         dbo.fn_XMLNode('ShipToCSZ',       @vShipToCSZ) +
                         dbo.fn_XMLNode('ShipVia',         @vShipVia);

  /* Convert into xml */
  select @vxmlData = cast(@DataXML as xml);

  /* Delete the xml nodes for which we need the new set  */
  set @vxmlData.modify('delete /Data /PackingCarton');

  select @vDataXML = coalesce(convert(varchar(max), @vxmlData), '');

  /* This is user scanned/packed qty for particular SKUs in previous screen and we
     need that in the close carton/package operation */
  select @vxmlPackDetails = (select * from #PackingDetails
                             for Xml Raw('CartonDetails'), elements XSINIL, Root('PackingCarton'));

  --select @vPackDetailsXML = coalesce(convert(varchar(max), @vxmlPackDetails), '');

  /* Build necessary info */
  select @DataXml = dbo.fn_XMLAddNode(@vDataXML, 'Data', coalesce(@vPackInfoXML, '') +
                                                 coalesce(convert(varchar(max), @vxmlPackDetails), ''));

end /* pr_AMF_Packing_OrderPacking_ScanComplete */

Go

