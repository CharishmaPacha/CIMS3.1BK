/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/05/11  RIA     pr_AMF_Inquiry_SKU: Changes to build total quantity (OB2-1792)
  2021/04/25  RIA     pr_AMF_Inquiry_SKU: Changes to build SKU info and details (OB2-1769)
  2020/12/17  RIA     pr_AMF_Inquiry_SKUStyle: Changes to consider InventoryClass1 while fetching the inventory (HA-1766)
  2020/10/15  RIA     pr_AMF_Inquiry_SKUStyle: Changes to consider inventory from user logged in WH and Sort SKU by sizes (HA-1569)
  2020/10/13  RIA     Added: pr_AMF_Inquiry_SKUStyle (HA-1569)
  2019/06/09  RIA     pr_AMF_Inquiry_SKU: Changes to show primary location (CID-500)
  2019/05/16  AY      pr_AMF_Inquiry_SKU: WIP
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inquiry_SKU') is not null
  drop Procedure pr_AMF_Inquiry_SKU;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inquiry_SKU

  Processes the requests for SKU Inquiry for SKU Inquiry work flow
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inquiry_SKU
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
          @vRFFormAction             TMessageName,
          @SKU                       TSKU,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vSKUId                    TRecordId,
          @vSKU                      TSKU,
          @vTotalQuantity            TQuantity,
          @vTotalReservedQty         TQuantity,
          @vSKUInfoXML               TXML,
          @vSKUDetailsXML            TXML,
          @vxmlSKUDetails            xml;
begin /* pr_AMF_Inquiry_SKU */

  select @vxmlInput = convert(xml, @InputXML);   /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null;

  /* Read inputs from InputXML */
  select @vUserId       = Record.Col.value('(SessionInfo/UserName)[1]',     'TUserId'      ),
         @vBusinessUnit = Record.Col.value('(SessionInfo/BusinessUnit)[1]', 'TBusinessUnit'),
         @SKU           = Record.Col.value('(Data/SKU)[1]',                 'TSKU'         )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Insert exec fails when the SKU is invalid for SKU Inquiry
     This is because of the rollback statement which gets executed for invalid SKUs
     Therefore, validations for SKU from SKU inquiry procedure are performed here, to avoid db error and show proper error */
  select top 1 @vSKUId = SKUId,
               @vSKU   = SKU
  from dbo.fn_SKUs_GetScannedSKUs(@SKU, @vBusinessUnit);

  if (@vSKUId is null)
    set @vMessageName = 'SKUDoesNotExist';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec pr_Messages_ErrorHandler @vMessageName;

  /* Get the SKU Info */
  exec pr_AMF_Info_GetSKUInfoXML @vSKUId, 'N' /* No Details */, @vOperation,
                                 @vSKUInfoXML output;

  /* Get the Inventory for the SKU. Show Picklane even if it is empty */
  select L.DestWarehouse, L.LocationId, L.Location, L.PalletId, L.Pallet, L.LPN, L.Status LPNStatus,
         cast('' as varchar(50)) LPNStatusDesc, '' as PAZone, '' as PickZone,
        sum(LD.Quantity) Quantity, sum(LD.ReservedQty) ReservedQty
  into #SKUDetails
  from LPNDetails LD
    join LPNs L on LD.LPNId = L.LPNId
  where (LD.SKUId = @vSKUId) and
        (L.Archived = 'N') and
        ((LD.Quantity     > 0) or (L.LPNType = 'L')) and
        ((LD.OnhandStatus in ('A', 'R' /* Available, Reserved */)) or
         (LD.OnhandStatus ='U' and L.Status = 'R' /* Received */))
  group by L.DestWarehouse, L.LPN, L.LocationId, L.Location, L.Palletid, L.Pallet, L.Status;

  update #SKUDetails
  set LPNStatusDesc = dbo.fn_Status_GetDescription('LPN', LPNStatus, @vBusinessUnit);

  /* get the totals */
  select @vTotalQuantity    = sum(Quantity),
         @vTotalReservedQty = sum(ReservedQty)
  from #SKUDetails;

  /* Process output into XML */
  select @vxmlSKUDetails = (select Location, LPN, LPNStatusDesc, Quantity, ReservedQty,
                                   Pallet, DestWarehouse
                            from #SKUDetails
                            for Xml Raw('SKUDetail'), elements XSINIL, Root('SKUDETAILS'));

  select @DataXml = dbo.fn_XmlNode('Data', coalesce(@vSKUInfoXML, '') +
                                   coalesce(convert(varchar(max), @vxmlSKUDetails), '') +
                                   dbo.fn_XMLNode('TotalQuantity', @vTotalQuantity) +
                                   dbo.fn_XMLNode('TotalReservedQty', @vTotalReservedQty));

end /* pr_AMF_Inquiry_SKU */

Go

