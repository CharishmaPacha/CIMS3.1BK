/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/06/13  VS      pr_Load_ManifestClose: Migrated from S2GCA (HA-838)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_ManifestClose') is not null
  drop Procedure pr_Load_ManifestClose;
Go
/*------------------------------------------------------------------------------
  pr_Load_ManifestClose : This procedure processes all Shiplabels of a Load and
   by updating their ManifestExportStatus and creating batches to be exported
------------------------------------------------------------------------------*/
Create Procedure pr_Load_ManifestClose
  (@LoadId       TLoadId,
   @BusinessUnit TBusinessUnit,
   @UserId       TUserId,
   @Message      TMessage output)
as
  declare @vReturnCode     TInteger,
          @vMessageName    TMessageName,
          @vRecordId       TRecordId,

          @vCarrierInterface        TCarrierInterface,
          @vCarrier                 TCarrier,
          @vShipperAccountName      TName,
          @vShipDate                TDate,
          @vNextManifestExportBatch TBatch,
          @vManifestAction          varchar(max),

          @vMaxRecordsPerBatch      TCount, /* Must be integer as we will use in it update top statement below */

          @xmlRulesData             TXML;

  /* Declare temp tables */
  declare @ttShipLabelsToManifestClose Table
           (RecordId                    TRecordId Identity(1,1),
            EntityId                    TRecordId,
            EntityKey                   TEntityKey,
            OrderId                     TRecordId,
            CarrierInterface            TCarrierInterface,
            Carrier                     TCarrier,
            ShipperAccountName          TName,
            IsManifestCloseReq          TFlag,
            ManifestExportBatch         TBatch
            Unique (OrderId, RecordId),
            Unique (IsManifestCloseReq, RecordId));

  declare @ttGroupingOfManifestExport Table
           (RecordId           TRecordId Identity(1,1),
            CarrierInterface   TDescription,
            Carrier            TCarrier,
            ShipperAccountName TName);

begin /* pr_Load_ManifestClose */
begin try
  SET NOCOUNT ON;

  select @vReturnCode    = 0,
         @vMessageName   = null,
         @vRecordId      = 0;

  /* Get control vars */
  select @vMaxRecordsPerBatch = dbo.fn_Controls_GetAsInteger('ManifestExportBatch', 'RecordsPerBatch', '1000',
                                                             @BusinessUnit, @UserId);

  /* Get all the labels, which are associated to Load */
  insert into @ttShipLabelsToManifestClose (EntityId, EntityKey, OrderId, CarrierInterface, Carrier)
    select distinct SL.EntityId, SL.EntityKey, L.OrderId, SL.CarrierInterface, S.Carrier
    from ShipLabels SL
      left outer join LPNs     L  on (L.LPN               = SL.EntityKey) and (SL.EntityType = 'L')
      left outer join Pallets  P  on (P.Pallet            = SL.EntityKey) and (SL.EntityType = 'P')
      left outer join LPNs     PL on (PL.PalletId         = P.PalletId)
                 join ShipVias S  on (SL.RequestedShipVia = S.ShipVia)
    where ((L.LoadId               = @LoadId) or
           (PL.LoadId              = @LoadId)) and
          (SL.ManifestExportStatus = 'N') and
          (SL.Label          is not null) and
          (SL.Status               = 'A');

  /* If not small package load, there wouldn't be any Shiplables, so just exit */
  if (@@rowcount = 0) return;

  /* Update the respective ShipperAccountName for the ship labels */
  update ttSLTMC
  set ttSLTMC.ShipperAccountName = OH.ShipperAccountName
  from @ttShipLabelsToManifestClose ttSLTMC
    join OrderHeaders OH on (OH.OrderId = ttSLTMC.OrderId);

  /* Build the data for rule evaluation */
  select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                             dbo.fn_XMLNode('Carrier',    ''));

  /* Check if manifest close is required for each carrier */
  while exists (select * from @ttShipLabelsToManifestClose where IsManifestCloseReq is null)
    begin
      select top 1 @vCarrier = Carrier
      from @ttShipLabelsToManifestClose
      where (IsManifestCloseReq is null)
      order by RecordId;

      /* Stuff with Carrier */
      select @xmlRulesData = dbo.fn_XMLStuffValue (@xmlRulesData, 'Carrier', @vCarrier);

      /* Get ManifestAction */
      exec pr_RuleSets_Evaluate 'ManifestAction', @xmlRulesData, @vManifestAction output;

      /* If Manifest action is HOLD then the shipment is hold then it needs to be clsoed now,
          otherwise released at the time of shipment creation */
      update @ttShipLabelsToManifestClose
      set IsManifestCloseReq = case when (@vManifestAction = 'RELEASE') then 'NR' /* Not Required */
                                    else 'R' /* Required */ end
      where (Carrier = @vCarrier) and
            (IsManifestCloseReq is null);
    end /* End of while */

  /* delete the labels, wheich are not required to Manifest close */
  delete from @ttShipLabelsToManifestClose where (IsManifestCloseReq = 'NR' /* Not Required */);

  /* Need to send TrackingNos with comma separated along with Carrier, ShipperName to the service. Also
     We are processing the Manifest close by Carrier and CarrierInterface */
  insert into @ttGroupingOfManifestExport (Carrier, ShipperAccountName, CarrierInterface)
    select Carrier, ShipperAccountName, CarrierInterface
    from @ttShipLabelsToManifestClose
    group by Carrier, ShipperAccountName, CarrierInterface;

  /* Update the ManifestExportBatch for each group */
  while exists (select * from @ttGroupingOfManifestExport where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId                = RecordId,
                   @vCarrierInterface        = CarrierInterface,
                   @vCarrier                 = Carrier,
                   @vShipperAccountName      = ShipperAccountName,
                   @vNextManifestExportBatch = null
      from @ttGroupingOfManifestExport
      where (RecordId > @vRecordId)
      order by RecordId;

      /* - Create export records as per RecordsPerBatch control var
         - We will break the loop once the updated record count (below) is lesser than RecordsPerBatch control var
           considering the each group of records are done when it reaches less than ReocrdsPerBatch */
      while (1=1)
        begin
          /* Get the next label export batch no */
          exec pr_Controls_GetNextSeqNo 'ManifestExportBatch', 1, @UserId, @BusinessUnit,
                                         @vNextManifestExportBatch output;

          /* Update batch as per control var */
          update top (@vMaxRecordsPerBatch) @ttShipLabelsToManifestClose
          set ManifestExportBatch = @vNextManifestExportBatch
          where   (coalesce(CarrierInterface,   '') = coalesce(CarrierInterface,     '')) and
                  (coalesce(ShipperAccountName, '') = coalesce(@vShipperAccountName, '')) and
                  (Carrier                          = @vCarrier) and
                  (coalesce(ManifestExportBatch, 0) = 0);

          /* If @@rowcount is less than RecordsPerBatch means, for the above group, all records are updated with batch */
          if (@@rowcount < @vMaxRecordsPerBatch) break;
        end
    end

  /* Update Manifest status to send manifest close out information to carrier */
  update SL
  set SL.ManifestExportStatus = 'XR' /* Export Required */,
      SL.ManifestExportBatch  = ttSLMC.ManifestExportBatch
  from ShipLabels SL
    join @ttShipLabelsToManifestClose ttSLMC on (SL.EntityKey = ttSLMC.EntityKey)
  where (SL.ManifestExportStatus = 'N') and
        (SL.Status = 'A');

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

end try
begin catch
   exec @vReturnCode = pr_ReRaiseError;
end catch;
ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Load_ManifestClose */

Go
