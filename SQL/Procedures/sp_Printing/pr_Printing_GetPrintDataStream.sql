/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/29  RV      pr_Printing_GetPrintDataStream, pr_Printing_ProcessPrintList: Added markers (HA-1476)
  2020/09/23  RV      pr_Printing_GetPrintDataStream: Added new parameter num copies to accept user given input (CIMSV3-1079)
  2020/09/10  MS      pr_Printing_GetPrintDataStream: Changes to print multiple copies of label (JL-238)
  2020/06/08  MS      pr_Printing_GetPrintDataStream: Changes to update empty for null strings (HA-579)
  2020/04/17  AY      pr_Printing_GetPrintDataStream: Add PrintWidth and LabelLength to ZPL
  2020/04/07  KBB     Change the data type  pr_Printing_BuildPrintDataSet/pr_Printing_GetPrintDataStream(HA-50)
  2020/02/12  AY      pr_Printing_GetPrintDataStream: Add Currenttimestamp to nodes to print on labels (JL-39)
  2020/01/22  AY      pr_Printing_BuildPrintDataSet, pr_Printing_GetPrintDataStream: Enh. for V3 ZPL Printing
  2019/12/13  MS      pr_Printing_GetPrintDataStream: Changes to Print other labels as next set if we have morethan NumLabelsPerRow labels (CID-1220)
                      pr_Printing_GetPrintDataStream: Change to print multiple labels in a row (CID-933)
                      pr_Printing_GetPrintDataStream: Print multiple records per entity (CID-1179)
  2019/08/14  AY      pr_Printing_GetPrintDataStream: new proc to generate ZPL stream
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Printing_GetPrintDataStream') is not null
  drop Procedure pr_Printing_GetPrintDataStream;
Go
/*------------------------------------------------------------------------------
  Proc pr_Printing_GetPrintDataStream: Executes the given procedure, captures the
   result data set, transforms into xml and prepares the ZPL data stream.

  Most often we have a result set with one record and we print one label for it.
  But in some cases we could have a result set with multiple records and we have
  to print a label for each of them.
------------------------------------------------------------------------------*/
Create Procedure pr_Printing_GetPrintDataStream
  (@EntityType         TEntity,
   @EntityId           TRecordId,
   @EntityKey          TEntityKey,
   @LabelFormatName    TName,
   @LabelSQLStatement  TSQL,
   @Operation          TOperation,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @PrintDataStream    TVarchar output,
   @NumCopiesOfLabel   TInteger = null)
as
  declare @ttXMLNodes             TXMLNodes,
          @ttMarkers              TMarkers;

  declare @vPrintDataStream       TVarChar,
          @vSQL                   TVarchar,
          @vPrintDataXML          XML,
          @vProcName              TName,
          @vLabelSQLStmt          TSQL,
          @vLabelStream           TVarChar,
          @vRecordId              TRecordId,
          @vLabelSize             TDescription,
          @vLabelWidth            TInteger,
          @vLabelHeight           TInteger,
          @vPrintWidth            TInteger,
          @vLabelLength           TInteger,
          @vPrinterDPI            TInteger,

          @xmlAdditionalInfo      xml,
          @vPrintOptions          xml,
          @vNumCopiesofLabel      TInteger,
          @vNumLabelsPerRow       TInteger,
          @vColPositionStart      TInteger,
          @vColPositionIncrement  TInteger,
          @vColumnOffset          TInteger,
          @vTotalRecords          TInteger,

          @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vUserId                TUserId,
          @vDebug                 TControlValue = 'N';
begin
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vRecordId     = 0,
         @vPrinterDPI   = 203,
         @vSQL          = '';

  /* Create required hash tables if they does not exist */
  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;

  /* Check if in debug mode */
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Start', @@ProcId;

  /* create temp table for capturing result set with a single identify column */
  create table #PrintDataSet
    (PDSRecordId int Identity(1, 1) not null);

  /* Create temp table of #XML Nodes */
  select * into #XMLNodes from @ttXMLNodes;

  /* Get additional info of the template */
  select top 1 @xmlAdditionalInfo = AdditionalData
  from ContentTemplates
  where (TemplateName like @LabelFormatName + '%') and
        (BusinessUnit = @BusinessUnit);

  /* Assume the printer is 203 dpi as all our labels are designed for 203 dpi printers
     Get NumCopies of selected label from print options if user not given */
  select @vLabelSize        = LabelSize,
         @vLabelWidth       = cast(substring(LabelSize, 1, charindex('x', LabelSize) - 1) as integer),
         @vLabelHeight      = cast(substring(LabelSize, charindex('x', LabelSize) + 1, len(LabelSize))  as integer),
         @vPrintOptions     = PrintOptions,
         @vNumCopiesofLabel = coalesce(nullif(@NumCopiesOfLabel, 0), nullif(NumCopies, 0), 1)
  from vwLabelFormats
  where (LabelFormatName = @LabelFormatName) and
        (BusinessUnit    = @BusinessUnit);

  select @vColPositionStart     = Node.value('ColPositionStart[1]', 'int'),     /* Starting position of first label */
         @vColPositionIncrement = Node.value('ColPositionIncrement[1]','int'),  /* Incrementing the column position of next label */
         @vNumLabelsPerRow      = Node.value('NumLabelsPerRow[1]','int')        /* Number of labels in each row on the label */
  from @xmlAdditionalInfo.nodes('AdditionalInfo') as T(node);

  select @vNumLabelsPerRow = coalesce(nullif(@vNumLabelsPerRow, 0), 1);

  /* Build the #PrintDataset for the given entity. Unlike contents labels, where multiple
     records print on each label, here we print a label for each record in the dataset */
  exec pr_Printing_BuildPrintDataSet @EntityType, @EntityId, @EntityKey, @LabelFormatName, @LabelSQLStatement, @Operation, @BusinessUnit;

  select @vTotalRecords = count(*) from #PrintDataSet;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Build Data set', @@ProcId;

  /* Generate datastream for each record */
  while exists (select * from #PrintDataSet where PDSRecordId > @vRecordId)
    begin
      /* Get the next data record - clear variables */
      select top 1
             @vRecordId     = PDSRecordId,
             @vLabelStream  = null,
             @vPrintDataXML = null
      from #PrintDataSet
      where (PDSRecordId > @vRecordId)
      order by PDSRecordId;

      /* convert Data set of the current recordid into XML */
      set @vPrintDataXML = (select *
                            from #PrintDataSet
                            where (PDSRecordId = @vRecordId)
                            for xml raw('PrintData'), elements XSINIL, BINARY BASE64);

      /* Retrieve all XML nodes for easy substitution later */
      delete from #XMLNodes;
      insert into #XMLNodes (NodeName, NodeValue)
        select Node.value('local-name(.)', 'varchar(50)'),
               Node.value('(.)[1]',        'varchar(1000)')
        from @vPrintDataXML.nodes('/PrintData/*') as T(Node);

      update #XMLNodes set TagName = '<%' + NodeName + '%>';

      /* If there are multiple labels in a row, then each label could be offset
         as per the label definition */
      if (@vNumLabelsPerRow > 1)
        begin
          select @vColumnOffset = @vColPositionStart + ((@vRecordId - 1) % @vNumLabelsPerRow) * @vColPositionIncrement;
          insert into #XMLNodes (NodeName, NodeValue) select 'LabelHomeX', @vColumnOffset;
        end
      else
        insert into #XMLNodes (NodeName, NodeValue) select 'LabelHomeX', 0;

      /* Add CurrentDateTime for substitution later */
      insert into #XMLNodes (NodeName, NodeValue) select 'CurrentDateTime', current_timestamp;

      /* Generate the ZPL for the current PrintDataXML */
      exec pr_Content_BuildDataStream @ttXMLNodes, @LabelFormatName, @BusinessUnit, @vUserId,
                                      @ResultDataStream = @vLabelStream output;

      /* If there are multiple labels in a row, then, except for first label in the row,
         remove the XA and except for the label label in the row, remove XZ */
      if (@vNumLabelsPerRow > 1)
        begin
          /* Except for first label, remove XA, start of label command */
          if (@vRecordId % @vNumLabelsPerRow <> 1)
            select @vLabelStream = replace(@vLabelStream, '^XA', '');
          else
          /* Except for last label in row, remove XZ, end of Label comamnd */
          if (@vRecordId % @vNumLabelsPerRow <> 0) and (@vRecordId < @vTotalRecords)
            select @vLabelStream = replace(@vLabelStream, '^XZ', '');
        end

      select @PrintDataStream = coalesce(@PrintDataStream, '') + coalesce(@vLabelStream, '');
    end

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Loop end', @@ProcId;

  /* Add the PrintWidth and LabelLength at the beginning of the ZPL - this
     ensures that any previous prints of diff sizes do not limit the current label
     being printed */
  select @vPrintWidth     = @vLabelWidth * @vNumLabelsPerRow * @vPrinterDPI;
  select @vLabelLength    = @vLabelHeight * @vPrinterDPI;
  select @PrintDataStream = replace(@PrintDataStream, '^XA', '^XA' +
                                                              '^PW' + cast(@vPrintWidth as varchar) +
                                                              '^LL' + cast(@vLabelLength as varchar) +
                                                              '^SS,,,,,'); --+ cast(@vLabelLength as varchar));
  /* Setup NumCopies for the Label to print
    ^PQN: N Represents number of copies to print */
  select @PrintDataStream = replace(@PrintDataStream, '^XZ', '^PQ' + cast(@vNumCopiesofLabel as varchar) + '^XZ');

  /* Removing orphan tags from DataStream */
  exec pr_RemoveOrphanTags @PrintDataStream, '<%', '%>', @PrintDataStream output;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'End', @@ProcId;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log @ttMarkers, @EntityType, @EntityId, @EntityKey, 'Printing_GetPrintDataStream', @@ProcId, 'Markers_GetPrintDataStream';
end /* pr_Printing_GetPrintDataStream */

Go
