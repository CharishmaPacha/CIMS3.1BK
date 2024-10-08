/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/24  VM      pr_ShipLabel_GetLPNDataAndContents: Cannot use nested insert exec, so handled it (HA-1013)
  2020/06/23  AY      pr_ShipLabel_GetLPNDataAndContents: Bug fixes (HA-1013)
  2019/04/03  MS      pr_ShipLabel_GetLPNDataAndContents: Made changes get details from procedure (CID-221)
  2016/07/05  TK      pr_ShipLabel_GetLPNDataAndContents: We don't need all the fields returned from Shippig GetLPNData, SKU1 - SKU5 needs to be considered which is returned from Function
  2016/06/28  DK      Added new procedure pr_ShipLabel_GetLPNDataAndContentsXML
  2016/06/23  TK      pr_ShipLabel_GetLPNDataAndContents: Changed input xml structure (HPI-176)
  2016/06/17  DK      pr_ShipLabel_GetLPNDataAndContents: Added  additional XML input parameter
  2015/10/26  AY      pr_ShipLabel_GetLPNDataAndContents: New procedure to print Shipping and contents combo label.
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetLPNDataAndContents') is not null
  drop Procedure pr_ShipLabel_GetLPNDataAndContents;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GetLPNDataAndContents: Returns the data set to be used to print a UCC Label.

  This procedure is called from Bartender labels.

  @LPNs xml structure:
  <Root>
    <LPNs>
      <LPN> </LPN>
      <LPN> </LPN>
    </LPNs>
  </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetLPNDataAndContents
  (@LPN              TLPN          = null,
   @LPNId            TRecordId     = null,
   @Operation        TOperation    = null,
   @BusinessUnit     TBusinessUnit = null,
   @LabelFormatName  TName         = null,
   @LPNs             XML           = null)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vUserId              TUserId,

          @vLPNId               TRecordId,
          @vLPN                 TLPN,
          @vRecordId            TRecordId,

          /* Label Info */
          @vPrintOptionsXml     xml,
          @xmlData              TXML,
          @vLabelType           TEntity,
          @vGetAdditionalInfo   TFlag,
          @vAdditionalInfo      varchar(max),
          @vPrintFlags          TPrintFlags,
          @vContentsInfo        TFlag,
          @vContentLinesPerLabel
                                TCount,
          @vMaxLabelsToPrint    TCount;

  declare @ttLPNs                  TEntityKeysTable;
  declare @ttLPNShipLabelData      TLPNShipLabelData;
  declare @ttLPNContents           TLPNContents;

begin
  set NOCOUNT ON;
  select @vReturnCode   = 0,
         @vMessagename  = null,
         @vUserId       = System_User,
         @vRecordId     = 0;

  if (@LPNs is not null)
    insert into @ttLPNs (EntityKey)
      select Record.Col.value('.', 'varchar(50)')
      from @LPNs.nodes('/Root/LPNs/LPN') as Record(Col);
  else
  /* Use LPN */
  if (@LPN is not null)
    insert into @ttLPNs (EntityId, EntityKey)
      select LPNId, LPN
      from LPNs
      where (LPN = @LPN) and (BusinessUnit = @BusinessUnit);
  else
    insert into @ttLPNs (EntityId, EntityKey)
      select LPNId, LPN
      from LPNs
      where (LPNId = @LPNId);

  /* Validations */
  if (@@rowcount = 0)
    set @vMessageName = 'LPNDoesNotExist';

  if (@vMessageName is not null)
    goto ErrorHandler;

  /* select to create table structure for #LPNContents */
  if object_id('tempdb..#LPNContents') is null
    select * into #LPNContents from @ttLPNContents;

  if object_id('tempdb..#LPNShipLabelData') is null
    select * into #LPNShipLabelData from @ttLPNShipLabelData;

  /* Get additional info from labelformat to determine how many lines per label
     and how many labels to generate */
  select @vPrintOptionsXml = PrintOptions,
         @vLabelType       = EntityType
  from LabelFormats
  where (LabelFormatName = @LabelFormatName) and (BusinessUnit = @BusinessUnit);

  if (@vPrintOptionsXML is not null)
    select @vContentsInfo         = Record.Col.value('ContentsInfo[1]',         'TFlag'),
           @vContentLinesPerLabel = Record.Col.value('ContentsLinesPerLabel[1]','TCount'),
           @vMaxLabelsToPrint     = Record.Col.value('MaxLabelsToPrint[1]',     'TCount'),
           @vGetAdditionalInfo    = Record.Col.value('GetAdditionalInfo[1]',    'TFlag')
    from @vPrintOptionsXml.nodes('printoptions') as Record(Col);

  /* If no label format is given, then we have to assume that it is a shipping label only
     and ignore the contents part of it */
  if (@LabelFormatName is null) or (coalesce(@vContentsInfo, 'N') = 'N')
    select @vMaxLabelsToPrint = -1;

  while (exists (select * from @ttLPNs where RecordId > @vRecordId))
    begin
      select top 1
             @vLPNId    = EntityId,
             @vLPN      = EntityKey,
             @vRecordId = RecordId
      from @ttLPNs
      where (RecordId > @vRecordId);

      /* Insert results into #LPNShipLabelData */
      exec pr_ShipLabel_GetLPNData @vLPN, @vLPNId, @Operation, @BusinessUnit, @LabelFormatName, 'N';

      /* Inserts the results into #LPNContents */
      exec pr_ShipLabel_GetLPNContents @vLPN, @vLPNId, @BusinessUnit, @vContentLinesPerLabel, @vMaxLabelsToPrint, 'N';
    end

  /* Return all the info collected */
  select *
  from #LPNShipLabelData LD join #LPNContents LC on LD.LPN = LC.LC_LPN;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ShipLabel_GetLPNDataAndContents */

Go
