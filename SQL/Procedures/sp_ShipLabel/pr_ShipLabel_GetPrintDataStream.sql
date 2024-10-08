/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/06/06  PK      Remaned pr_ShipLabel_SetLPNData as pr_ShipLabel_GetPrintDataStream and changed the parameters and added a output parameter to send
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetPrintDataStream') is not null
  drop Procedure pr_ShipLabel_GetPrintDataStream;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GetPrintDataStream:
  This procedure will generate Shiplabel meta data and returns in output parameter.
  The main motive behind this is, to provide an best alternative solution for
  PandAScheduler process or to stuff some additional information on the ZPL format
  labels.
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetPrintDataStream
  (@LPNId           TRecordId,
   @LabelFormatName TName,
   @BusinessUnit    TBusinessUnit,
   @PrintDataStream TVarchar output)
as
  declare @ttLPNData        TLPNShipLabelData;
  declare @ttXMLNodes       TXMLNodes;

  declare @vPrintDataStream TVarChar,
          @vNodeCount       TCount,
          @vLPNDataXML      XML,
          @vNodeName        TVarChar,
          @vNodeValue       TVarChar,
          @vFormattedNode   TVarChar,
          @vModifier        TFlag,
          @vModifierValue   TInteger,
          @vSearchIndex     TInteger,
          @vSearchString    TVarChar,
          @vStartPos        TInteger,
          @vEndPos          TInteger,

          @vReturnCode      TInteger,
          @vMessageName     TMessageName,
          @vUserId          TUserId;

begin
  select @vReturnCode   = 0,
         @vMessageName  = null;

   /* Create temp table of #XML Nodes */
   select * into #XMLNodes from @ttXMLNodes;

  /* Get ship label data for the LPN that would be required for the Label */
  insert into @ttLPNData
    exec pr_ShipLabel_GetLPNData null /* LPN */, @LPNId, null /* Operation */, @BusinessUnit, @LabelFormatName;

  /* Note: We can't build xml with image data, so exclude the label field and build xml */
  select * into #ttLPNData from @ttLPNData;

  alter table #ttLPNData drop column Label;

  /* convert ShipLabel LPNData into XML */
  set @vLPNDataXML = (select *
                      from #ttLPNData
                      for xml raw('LPNData'), elements);

  /* Retrieve all XML nodes for easy substitution later */
  insert into #XMLNodes (NodeName, NodeValue)
    select Node.value('local-name(.)', 'varchar(50)'),
           Node.value('(.)[1]',        'varchar(1000)')
    from @vLPNDataXML.nodes('/LPNData/*') as T(Node);

  exec pr_Content_BuildDataStream @ttXMLNodes, @LabelFormatName, @BusinessUnit, @vUserId,
                                  @ResultDataStream = @PrintDataStream output;

  /* Removing orphan tags from DataStream */
  exec pr_RemoveOrphanTags @PrintDataStream, '<%', '%>', @PrintDataStream output;

end /* pr_ShipLabel_GetPrintDataStream */

Go
