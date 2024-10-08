/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/29  RV      pr_ContentLabel_GetPrintDataStream, pr_ShipLabel_GetLPNData: Added markers (HA-1476)
  2020/06/09  AY      pr_ContentLabel_GetPrintDataStream: Change to use #XMLNodes (HA-579)
  2020/05/26  RV      pr_ContentLabel_GetPrintDataStream: Removed code to drop the Label column from temp table as we already removed in domain
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ContentLabel_GetPrintDataStream') is not null
  drop Procedure pr_ContentLabel_GetPrintDataStream;
Go
/*------------------------------------------------------------------------------
  Proc pr_ContentLabel_GetPrintDataStream:
  This procedure will generate Shiplabel meta data and returns in output parameter.
  The main motive behind this is, to provide an best alternative solution for
  PandAScheduler process or to stuff some additional information on the ZPL format
  labels.
------------------------------------------------------------------------------*/
Create Procedure pr_ContentLabel_GetPrintDataStream
  (@LPNId           TRecordId,
   @LabelFormatName TName,
   @BusinessUnit    TBusinessUnit,
   @PrintDataStream TVarchar output)
as
  declare @ttLPNData              TLPNShipLabelData;
  declare @ttXMLNodes             TXMLNodes;
  declare @ttMarkers              TMarkers;

  declare @vLPNDataXML            xml,
          @vLPNContentDataXML     xml,
          @xmlAdditionalInfo      xml,
          @vRowNo                 TInteger,
          @vNumRows               TCount,
          @vRowPositionStart      TInteger,
          @vRowPosition           TInteger,
          @vRowPositionIncrement  TInteger,
          @vFooterNumRows         TInteger,
          @vMaxRowsPerLabel       TInteger,
          @vTemplateName          TName,
          @vHeaderStream          TVarchar,
          @vDetailStream          TVarchar,
          @vFooterStream          TVarchar,

          @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vUserId                TUserId,
          @vDebug                 TControlValue = 'N';

begin
  select @vReturnCode     = 0,
         @vMessageName    = null,
         @PrintDataStream = '';

  /* Create required hash tables if they does not exist */
  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'pr_ContentLabel_GetPrintDataStream_Start', @@ProcId;

   /* Create temp table of #XML Nodes */
   select * into #XMLNodes from @ttXMLNodes;

  /* Get additional info of the template */
  select top 1 @xmlAdditionalInfo = AdditionalData
  from ContentTemplates
  where (TemplateName like @LabelFormatName + '%') and
        (BusinessUnit = @BusinessUnit);

  select @vRowPositionStart     = Node.value('RowPositionStart[1]', 'int'),          /* Starting position of first row */
         @vRowPositionIncrement = Node.value('RowPositionIncrement[1]','int'),  /* Incrementing the position of next row to print on PackingList */
         @vFooterNumRows        = Node.value('FooterNumRows[1]','int'),         /* Number of rows in the footer */
         @vMaxRowsPerLabel      = Node.value('MaxRowsPerLabel[1]','int')        /* Max Number of detail Row in the defail section */
  from @xmlAdditionalInfo.nodes('AdditionalInfo') as T(node)

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Start', @@ProcId;

  /* Get ship label data for the LPN that would be required for the Label */
  insert into @ttLPNData
    exec pr_ShipLabel_GetLPNData null /* LPN */, @LPNId, null /* Operation */, @BusinessUnit, @LabelFormatName;

  /* Note: We can't build xml with image data, so exclude the label field and build xml */
  select * into #ttLPNData from @ttLPNData;

  /* convert ShipLabel LPNData into XML */
  set @vLPNDataXML = (select *
                      from #ttLPNData
                      for xml raw('LPNData'), elements);

  /* Retrieve all XML nodes for easy substitution later */
  insert into #XMLNodes (NodeName, NodeValue)
    select Node.value('local-name(.)', 'varchar(50)'),
           Node.value('(.)[1]',        'varchar(1000)')
    from @vLPNDataXML.nodes('/LPNData/*') as T(Node)

  update #XMLNodes set TagName = '<%' + NodeName + '%>';

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Build XML Nodes', @@ProcId;

  /* Get the Header Data stream */
  select @vTemplateName = @LabelFormatName + '_Header';
  exec pr_Content_BuildDataStream @ttXMLNodes, @vTemplateName, @BusinessUnit, @vUserId,
                                  @ResultDataStream = @vHeaderStream output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Build Header', @@ProcId;

  /* Get the Footer Data stream */
  select @vTemplateName = @LabelFormatName + '_Footer';
  exec pr_Content_BuildDataStream @ttXMLNodes, @vTemplateName, @BusinessUnit, @vUserId,
                                  @ResultDataStream = @vFooterStream output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Build Footer', @@ProcId;

  /* Inserting the details returned from the proc pr_Shipping_GetLPNContentLabelData into temp table */
  select LPN, LPNLine, SKU, Quantity, CustSKU, SKUDescription, UPC,
         SKU1, SKU2, SKU3, SKU4, SKU5, UnitsAuthorizedToShip, row_number() over(order by HostOrderLine, SKU) as RecordId
  into #ttLPNContentData
  from vwLPNPackingListDetails
  where LPNId = @LPNId
  order by LPNDetailId;

  select @vNumRows      = @@rowcount,
         @vRowNo        = 1,
         @vTemplateName = @LabelFormatName + '_Detail';

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Loop Start', @@ProcId;

  /* Iterate thru the LPNContents Details */
  while (@vRowNo <= @vNumRows)
    begin
      /* Initialize */
      delete from #XMLNodes;
      select @vDetailStream = null;

      /* if first row of label, start with header */
      if (@vRowNo % @vMaxRowsPerLabel = 1)
        begin
          select @PrintDataStream += @vHeaderStream,
                 @vRowPosition     = @vRowPositionStart;
        end

      /* Get each Record node from the xml */
      set @vLPNContentDataXML = (select *
                                 from #ttLPNContentData
                                 where RecordId = @vRowNo
                                 for xml raw('LPNContents'), elements);

      /* Get the next Contents nodes and values */
      insert into #XMLNodes (NodeName, NodeValue)
        select Node.value('local-name(.)', 'varchar(50)'),
               Node.value('(.)[1]',        'varchar(1000)')
        from @vLPNContentDataXML.nodes('/LPNContents/*') as T(Node)

      update #XMLNodes set TagName = '<%' + NodeName + '%>';

      /* Get the ZPL for the current detail */
      exec pr_Content_BuildDataStream @ttXMLNodes, @vTemplateName, @BusinessUnit, @vUserId,
                                      @ResultDataStream = @vDetailStream output;

      /* Setup the Position of the Detail */
      select @vDetailStream = replace (@vDetailStream, '<%DetailRowPosition%>', @vRowPosition);

      /* Append the Content Detail ZPL */
      select @PrintDataStream += coalesce(@vDetailStream, '');

      /* If we have reached the maximum number of rows per label, then add footer
         or if we got to the last row, then add footer */
      if (@vRowNo % @vMaxRowsPerLabel = 0) or (@vRowNo = @vNumRows)
        select @PrintDataStream += @vFooterStream;

      select @vRowNo       += 1,
             @vRowPosition += @vRowPositionIncrement;
    end /* while Row < NumRows */

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Loop end', @@ProcId;

  /* Removing orphan tags from DataStream */
  exec pr_RemoveOrphanTags @PrintDataStream, '<%', '%>', @PrintDataStream output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'End', @@ProcId;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log @ttMarkers, 'LPN', @LPNId, null, 'GetPrintDataStream', @@ProcId, 'Markers_ContentLabel_GetPrintDataStream';

end /* pr_ContentLabel_GetPrintDataStream */

Go
