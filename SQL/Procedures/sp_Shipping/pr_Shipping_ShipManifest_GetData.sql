/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/06  RV      pr_Shipping_ShipManifest_GetDetails: Added new parameter xml input to get the action and
                        based upon the action summarize the details
                      pr_Shipping_ShipManifest_GetHeader: Added new parameter for future purpose
                      pr_Shipping_ShipManifest_GetData: Changed callers to include the xml input (HA-2401)
  2020/01/05  RT      pr_Shipping_ShipManifest_GetDetails,pr_Shipping_ShipManifest_GetData: Included LoT and CoO and joined the Loads (HA-1849)
  2020/12/29  PK      pr_Shipping_ShipManifest_GetData: Added new output parameter to return string (HA-1843).
  2020/10/22  SJ/AY   pr_Shipping_ShipManifest_GetData: Revised to print from UI as well (HA-1593)
  2020/10/12  RBV     Re-Named pr_Shipping_GetShippingManifestData to pr_Shipping_ShipManifest_GetData (HA-1548)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_ShipManifest_GetData') is not null
  drop Procedure pr_Shipping_ShipManifest_GetData;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_ShipManifest_GetData: Returns all the info associated with the
    Load and it's Cartons to print a shipping manifest.
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_ShipManifest_GetData
  (@xmlInput          xml,
   @BusinessUnit      TBusinessUnit,
   @UserId            TUserId,
   @xmlResult         xml         output,
   @vxmlResult        TXML = null output)
as
  declare @vReturnCode    TInteger,
          @vMessageName   TMessageName,
          @Message        TDescription,
          @vDebug         TControlValue = 'N',

          @SMHeaderxml    TXML,
          @SMDetailsxml   TXML,
          @Reportsxml     TXML,
          @vReportName    TName,

          @vLoadId        TLoadId,
          @vLoadNumber    TLoadNumber,
          @vShipmentId    TShipmentId,
          @vShipFrom      TShipFrom,

          @vEntity        TXML,
          @vReport        TResult,
          @Resultxml      TXML,
          @xmlRulesData   TXML,

          @vRequestInfo   TDescription,
          @vLogo          TXML,
          @vLogoRecordId  TRecordId,
          @vLoadRecordId  TRecordId,
          @vShipmentRecId TRecordId;

  declare @Loads          TEntityKeysTable,
          @ttMarkers      TMarkers;

  declare @SMToPrint  table
          (RecordId            TRecordId identity (1,1),
           LoadId              TLoadId,
           LoadNumber          TLoadNumber,
           ShipmentId          TShipmentId,
           ShipFrom            TShipFrom);

begin /* pr_Shipping_ShipManifest_GetData */
  select @vReturnCode    = 0,
         @vMessagename   = null,
         @vLoadRecordId  = 0,
         @vShipmentRecId = 0,
         @vRequestInfo   = 'Logo';

  /* Prep for debug */
  if (object_id('tempdb..#Markers') is null) select * into #Markers from @ttMarkers;
  exec pr_Debug_GetOptions @@ProcId, null /* @Operation */, @BusinessUnit, @vDebug output;
  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Start', @@ProcId;

  /* If invoked from UI, we would get the selected Loads in #SelectedEntities,
     If invoked from PrintList, we would get the specific Load from input xml */
  if (object_id('tempdb..#ttSelectedEntities') is not null) and
     (exists (select * from #ttSelectedEntities where EntityType = 'Load'))
    insert into @Loads(EntityId, EntityKey)
      select EntityId, EntityKey from #ttSelectedEntities where EntityType = 'Load'
  else
  if (@xmlInput is not null)
    insert into @Loads (EntityId, EntityKey)
      select Record.Col.value('LoadId[1]', 'TRecordId'), Record.Col.value('LoadNumber[1]', 'TLoadNumber')
      from @xmlInput.nodes('/LoadNumbers') as Record(Col);

  /* Get all the shipments on the selected Loads */
  insert into @SMToPrint (LoadId, LoadNumber, ShipmentId, ShipFrom)
     select S.LoadId, S.LoadNumber, S.ShipmentId, S.ShipFrom
     from Shipments S join @Loads L on (S.LoadId = L.EntityId) and (S.BusinessUnit = @BusinessUnit)
     order by S.LoadId, S.ShipmentId;

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'Loop_Start', @@ProcId;

  /* Look thru each shipment and generate the manifest */
  while exists (select * from @SMToPrint where RecordId > @vShipmentRecId)
    begin
      select top 1
              @vLoadId        = LoadId,
              @vLoadNumber    = LoadNumber,
              @vShipmentId    = ShipmentId,
              @vShipmentRecId = RecordId,
              @vShipFrom      = ShipFrom
      from @SMToPrint
      where (RecordId > @vShipmentRecId)
      order by RecordId;

      /* Rules to get the Shipping Manifest Name */
      select @xmlRulesData =  dbo.fn_XMLNode('RootNode',
                                dbo.fn_XMLNode('LoadId',           @vLoadId     ) +
                                dbo.fn_XMLNode('ShipFrom',         @vShipFrom   ) +
                                dbo.fn_XMLNode('DocumentType',     'SM' /* Ship Manifest */) +
                                dbo.fn_XMLNode('BusinessUnit',     @BusinessUnit));

      exec pr_RuleSets_Evaluate 'ShippingManifest', @xmlRulesData, @vReportName output;

      /* Shipping Manifest Header for the Load+Shipment */
      exec pr_Shipping_ShipManifest_GetHeader @xmlInput, @vLoadId, @vShipmentId, @BusinessUnit, @UserId, @SMHeaderxml output;

      /* Shipping Manifest Details for the Load+Shipment */
      exec pr_Shipping_ShipManifest_GetDetails @xmlInput, @vLoadId, @vShipmentId, @vReportName, @BusinessUnit, @UserId, @SMDetailsxml output;

      /* Get logo from the ContentImages with respect to the ShipFrom and load dynamically with the Logo data.*/
      if charindex('Logo', @vRequestInfo) > 0
        begin
          exec pr_RuleSets_Evaluate 'PackingListLogo', @xmlRulesData, @vLogoRecordId output;

          /* Get logo to print on the PL */
          select @vLogo = (select top 1 Image Logo
                           from ContentImages
                           where (RecordId = @vLogoRecordId)
                           for xml path (''));
        end

      /* Build report xml */
      select @Reportsxml = dbo.fn_XMLNode('REPORTS',
                             dbo.fn_XMLNode('Report', @vReportName) +
                             coalesce(@vLogo, ''));

      select @Resultxml = coalesce(@Resultxml,'') +
                            dbo.fn_XMLNode('SHIPPINGMANIFESTS',
                              dbo.fn_XMLNode('SHIPPINGMANIFEST',
                                coalesce(@SMHeaderxml,  '') +
                                coalesce(@SMDetailsxml, '') +
                                coalesce(@Reportsxml,   '')) )

    end /* while .. shipment */

  /* Shipping Manifest output xml and string */
  select @xmlResult = @Resultxml;

  select @vxmlResult = cast(@xmlResult as varchar(max));

  if (charindex('M', @vDebug) > 0) exec pr_Markers_Save 'End', @@ProcId;
  if (charindex('L', @vDebug) > 0) exec pr_Markers_Log @ttMarkers, null, null, null, null, @@ProcId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_ShipManifest_GetData */

Go
