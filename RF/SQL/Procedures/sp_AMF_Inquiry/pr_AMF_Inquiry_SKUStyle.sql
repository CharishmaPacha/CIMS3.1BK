/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/12/17  RIA     pr_AMF_Inquiry_SKUStyle: Changes to consider InventoryClass1 while fetching the inventory (HA-1766)
  2020/10/15  RIA     pr_AMF_Inquiry_SKUStyle: Changes to consider inventory from user logged in WH and Sort SKU by sizes (HA-1569)
  2020/10/13  RIA     Added: pr_AMF_Inquiry_SKUStyle (HA-1569)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_AMF_Inquiry_SKUStyle') is not null
  drop Procedure pr_AMF_Inquiry_SKUStyle;
Go
/*------------------------------------------------------------------------------
  Procedure pr_AMF_Inquiry_SKUStyle: This proc is for style inquiry where user keys
    in the SKU and based on the SKU Style and Sizes we will get all LPNs and locations
    having the SKUs and display the info
------------------------------------------------------------------------------*/
Create Procedure pr_AMF_Inquiry_SKUStyle
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
          @vRecordId                 TRecordId,

          @vDataXML                  TXML,
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
          @SKU                       TSKU,
          @vInventoryClass1          TInventoryClass,
          @vOperation                TOperation;
          /* Functional variables */
  declare @vxmlSKUInfo               xml,
          @vxmlSKUDetails            xml,
          @vSKUInfoXML               TXML,
          @vSKUDetailsXML            TXML,
          @vSKUId                    TRecordId,
          @vSKU                      TSKU,
          @vSKU1                     TSKU,
          @vSKU2                     TSKU,
          @vSKU3                     TSKU,
          @vStatus                   TStatus,
          @vWarehouse                TWarehouse,
          @GrandTotalCol             TNote,
          @GrandTotalRow             TNote,
          @vReportSizes              TNote,
          @vPivotQuery               TNote,
          @vxmlSizeHeader            xml,
          @vSizeHeader               TXML,
          @vSizeHeaderXML            TXML,
          @vStyleDetails             TVarChar;

  declare @ttSKUs                    TEntityKeysTable;
  declare @ttSizes                   TEntityKeysTable;
  declare @ttMapping                 TMapping;

  if object_id('tempdb..#SKUsByStyle ') is not null
    drop table #SKUsByStyle;

  create table #SKUsByStyle (SKUId            int,
                             SKU              varchar(50),
                             SKU1             varchar(50),
                             SKU2             varchar(50),
                             SKU3             varchar(50),
                             Quantity         int,
                             LPN              varchar(50),
                             Location         varchar(50),
                             SKUSortSeq       varchar(50));

begin /* pr_AMF_Inquiry_SKUStyle */

  select @vxmlInput = convert(xml, @InputXML);  /* Convert input into xml var */

  /* Initialize */
  select @DataXML   = convert(varchar(max), @vxmlInput.query('Root/Data')),
         @UIInfoXML = convert(varchar(max), @vxmlInput.query('Root/UIInfo')),
         @ErrorXML  = null,
         @InfoXML   = null,
         @vRecordId = 0;

  /*  Read inputs from InputXML */
  select @vBusinessUnit    = Record.Col.value('(SessionInfo/BusinessUnit)[1]',        'TBusinessUnit'  ),
         @vUserId          = Record.Col.value('(SessionInfo/UserName)[1]',            'TUserId'        ),
         @vDeviceId        = Record.Col.value('(SessionInfo/DeviceId)[1]',            'TDeviceId'      ),
         @SKU              = Record.Col.value('(Data/SKU)[1]',                        'TSKU'           ),
         @vInventoryClass1 = Record.Col.value('(Data/InventoryClass1)[1]',            'TInventoryClass'),
         @vOperation       = Record.Col.value('(Data/Operation)[1]',                  'TOperation'     )
  from @vxmlInput.nodes('/Root') as Record(Col)
  OPTION (OPTIMIZE FOR (@vxmlInput = null));

  /* Fetch the SKUId and SKU */
  select top 1 @vSKUId  = SKUId,
               @vSKU    = SKU,
               @vSKU1   = SKU1,
               @vSKU2   = SKU2,
               @vStatus = Status
  from dbo.fn_SKUs_GetScannedSKUs(@SKU, @vBusinessUnit);

  if (@vSKUId is null)
    set @vMessageName = 'SKUIsInvalid';
  else
  if (@vStatus = 'I' /* Inactive */)
    set @vMessageName = 'SKUIsInactive';

  /* This will raise an exception, and the caller ExecuteAction procedure would capture and return error to UI */
  if (@vMessageName is not null)
    exec pr_Messages_ErrorHandler @vMessageName;

  /* Get the SKU Info */
  exec pr_AMF_Info_GetSKUInfoXML @vSKUId, 'N' /* No Details */, @vOperation,
                                 @vSKUInfoXML output;

  /* Fetch the user logged in Warehouse */
  select @vWarehouse = Warehouse
  from Devices
  where DeviceId = @vDeviceId + '@' + @vUserId+ '@' + 'Inquiry';

  /* Get all the SKUs for the same style and/or color */
  insert into @ttSKUs (EntityId, EntityKey)
    select SKUId, SKU
    from SKUs
    where ((SKU1 = @vSKU1) and (SKU2 = @vSKU2)) and (Status <> 'I' /* Inactive */)
    order by SKUId;

  /* Get the available inventory for the selected SKUs and inventoryclass if given */
  if (@vInventoryClass1 = '')
    insert into #SKUsByStyle(SKUId, SKU, SKU1, SKU2, SKU3, Quantity, LPN, Location, SKUSortSeq)
      select EOI.SKUId, EOI.SKU, EOI.SKU1, EOI.SKU2, EOI.SKU3, --EOI.SKU4, EOI.SKU5,
             EOI.AvailableQty, EOI.LPN, EOI.Location, EOI.SKUSortOrder
      from vwExportsOnhandInventory EOI
        join @ttSKUs TTS on (TTS.EntityId = EOI.SKUId)
        where (AvailableQty > 0) and
              (Warehouse = @vWarehouse);
  else
    insert into #SKUsByStyle(SKUId, SKU, SKU1, SKU2, SKU3, Quantity, LPN, Location, SKUSortSeq)
      select EOI.SKUId, EOI.SKU, EOI.SKU1, EOI.SKU2, EOI.SKU3, --EOI.SKU4, EOI.SKU5,
             EOI.AvailableQty, EOI.LPN, EOI.Location, EOI.SKUSortOrder
      from vwExportsOnhandInventory EOI
        join @ttSKUs TTS on (TTS.EntityId = EOI.SKUId)
        where (AvailableQty > 0) and
              (InventoryClass1 = @vInventoryClass1) and
              (Warehouse = @vWarehouse);

  /* Set SKU sort order to a high number for Mixed, so that it shows up in the last */
  update #SKUsByStyle
  set SKUSortSeq = 10000
  where SKU3 = 'Mixed';

  /* Update SKUSortSeq as null to check size exists in mapping table */
  update #SKUsByStyle
  set SKUSortSeq = null
  where SKU3 <> 'Mixed';

  /* Set SKUSortSeq for Mixed color SKUs from Mapping table */
  update SBS
  set SBS.SKUSortSeq = dbo.fn_GetMappedValue('CIMS', SBS.SKU3,'CIMS', 'Sizes', '', @vBusinessUnit)
  from  #SKUsByStyle SBS
  where SKU2 = 'Mixed' and SKUSortSeq is null and SKU3 <> 'Mixed'

  /* Update SKUSortSeq with mapping table target value */
  update SBS
  set SBS.SKUSortSeq = M.TargetValue
  from #SKUsByStyle SBS
   join Mapping M on M.SourceValue = SBS.SKU3
  where (M.EntityType = 'Sizes')

  /* Load all sizes into temp table */
  insert into @ttSizes(EntityId, EntityKey)
    select distinct SKUSortSeq, SKU3
    from #SKUsByStyle
    order by SKUSortSeq;

  /* Get the all sizes with the counts */
  exec pr_SKUs_SizeScale @ttSizes, @vReportSizes out, @GrandTotalCol out, @GrandTotalRow out;

  select @vSizeHeader = (select * from (select 'Size' + cast(RecordId as varchar) as SizeNo, EntityKey from @ttSizes) A Pivot (min(EntityKey) for
    SizeNo in ([Size1], [Size2], [Size3], [Size4], [Size5], [Size6], [Size7], [Size8], [Size9], [Size10], [Size11], [Size12])) Sizes for xml AUTO, elements);

  select @vxmlSizeHeader = convert(xml, @vSizeHeader);

  select @vSizeHeaderXML = '';
  with FlatXML as
  (
    select dbo.fn_XMLNode('Sizes_' + c.value('(local-name(.))[1]', 'nvarchar(max)'), replace(c.value('(.)[1]', 'nvarchar(max)'), '''', '''''')) DetailNode
    from @vxmlSizeHeader.nodes('/Sizes/*') as t(c)
  )
  select @vSizeHeaderXML = @vSizeHeaderXML + DetailNode from FlatXML;

  /* Generate the sizes with count by using Dynamic Query */
  set @vPivotQuery = 'select SKU1, SKU2, Location, ('+ @GrandTotalCol + ') as [GrandTotal], ' + @vReportSizes + ' into #temp_SKUDetails
                      from
                         (select SKU1, SKU2, Location, SKU3, Quantity
                          from #SKUsByStyle
                          ) A
                          PIVOT
                          (
                           sum (Quantity)
                           for SKU3 in ('+ @vReportSizes +')
                          ) B;

  set @xmlSKUDetails = (select CQ.* from
                         (select * from #temp_SKUDetails
                          union All
                          select ''Grand Total'','''','''', IsNull (sum([GrandTotal]),0), '+ @GrandTotalRow +
                          ' from #temp_SKUDetails) CQ
                        FOR XML AUTO, ELEMENTS XSINIL, ROOT(''SKUDETAILS''))';

  exec sp_executesql @vPivotQuery, N'@xmlSKUDetails xml output', @xmlSKUDetails = @vxmlSKUDetails out;

  select @vSKUDetailsxml = coalesce(convert(varchar(max), @vxmlSKUDetails), '');

  /* Build the DataXML */
  select @DataXML = dbo.fn_XmlNode('Data', coalesce(@vSKUInfoXML, '') + coalesce(@vSKUDetailsXML, '') +
                                           coalesce(@vSizeHeaderXML, '') +
                                           dbo.fn_XMLNode('InventoryClass1', @vInventoryClass1));

end /* pr_AMF_Inquiry_SKUStyle */

Go

