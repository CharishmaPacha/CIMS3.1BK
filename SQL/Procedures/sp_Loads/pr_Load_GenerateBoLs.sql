/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/06/17  AY      pr_Load_GenerateBoLs: Set freight terms on Master BoL (HA-2888)
  2021/04/27  VS      pr_Load_GenerateBoLs: Get the Load.ShipTo for MasterBOL of Transfer Loads (HA-2591)
  2021/04/21  SK/AY   pr_Load_Modify, pr_Load_GenerateBoLs: Option for user to choose group by for the report (HA-2676)
                      pr_Load_GenerateBoLs: Update Load.BoLStatus when BoLs are generated (HA-2467)
  2021/03/31  AY      pr_Load_GenerateBoLs: Generate Master BoL when shipping to consolidator (HA GoLive)
  2021/03/23  PHK     pr_Load_GenerateBoLs: Account added to evaluate group criteria (HA-2390)
  2021/03/18  MS      pr_Load_GenerateBoLs: Bug fix to regenerate MasterBol OrderDetails (HA-2334)
  2021/03/16  PK      pr_Load_GenerateBoLs: Ported changes done by Pavan (HA-2287)
  2021/03/04  RKC/VM  pr_Load_GenerateBoLs: If user trying to Regenerate the BOL then delete and regenerate Master BOL and
  2021/02/23  AY      pr_Load_GenerateBoLs: Setup Load.ConsolidatorAddresss (HA-2054)
                      pr_Load_GenerateBoLs: Use Master BoL consolidator address
  2021/02/04  RT      pr_Load_GenerateBoLs and pr_Load_Modify: Changes to use BoLLPNs to compute the BoLOrderDEtails and BoLCarrierDetails (FB-2225)
  2021/01/31  AY      pr_Load_GenerateBoLs: Generate BoLs for Master BoL as well (HA-1954)
  2021/01/20  PK      pr_Load_GenerateBoLs, pr_Loads_Action_ModifyBoLInfo, pr_Load_Recount: Ported back changes are done by Pavan (HA-1749) (Ported from Prod)
  2019/12/23  AY      pr_Load_GenerateBoLs: Performance fixes (CID-1234)
  2018/05/11  YJ      pr_Load_GenerateBoLs: Changes to update FreightTerms on UnderlyingBoL and on Master BoLs (S2G-806)
  2016/07/26  SV      pr_Load_GenerateBoLs: Restricting to create BoL for the Orders having ShipVia other than ShipVia over the Load (TDAX-374)
  2016/07/22  NY      pr_Load_GenerateBoLs: Recount the Load (OB-431)
  2016/05/03  SV      pr_Load_GenerateBoLs: Changes to show the UserId over the AT Log in UI (CIMS-730)
  2016/05/01  AY      pr_Load_GenerateBoLs: AT and validations added (CIMS-730).
  2016/04/09  AY      pr_Load_GenerateBoLs: Do not copy Pro/Seal/Trailer numbers from Load to BoL.
  2103/10/21  TD      pr_Load_GenerateBoLs: Added contctreftype in join to get valid data.
  2013/01/29  YA      pr_Load_GenerateBoLs: Modified to update VICSBoLNumber on Loads when BoL is generated.
  2013/01/28  TD      pr_Load_GenerateBoLs: ShipFrom specific to BoLS.
  2013/01/25  YA/TD   pr_Load_GenerateBoLs: Hide ship from address for master bols(temp fix, need to discuss)
  2013/01/22  TD/NB   Added pr_Load_GenerateBoLs procedure
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Load_GenerateBoLs') is not null
  drop Procedure pr_Load_GenerateBoLs;
Go
/*------------------------------------------------------------------------------
  Proc pr_Load_GenerateBoLs: This procedure will takes LoadId as Input and generate
          BoL info for the each load and also update the MasterBoL if exists.
------------------------------------------------------------------------------*/
Create Procedure pr_Load_GenerateBoLs
  (@LoadId            TLoadId,
   @Regenerate        TFlag = 'N' /* No */,
   @UserId            TUserId,
   @BOD_GroupCriteria TLookUpCode = null)
as
  declare @ReturnCode                  TInteger,
          @Message                     TMessage,
          @MessageName                 TMessageName,
          @vBoLId                      TBoLId,
          @vBoLNumber                  TBoLNumber,
          @vVICSBoLNumber              TVICSBoLNumber,
          @vBusinessunit               TBusinessUnit,
          @vShipmentId                 TShipmentId,
          @vBoLDataRecordId            TRecordId,
          @vLoadBoLsRecordId           TRecordId,
          @vRegenerateBoLDtls          TFlag,
          @VICSBoLNumber               TBoLNumber,
          @vLoadId                     TLoadId,
          @vLoadType                   TTypeCode,
          @vLoadStatus                 TStatus,
          @vLoadBoLNumber              TBoLNumber,
          @vMasterBoLCount             TCount,
          @vTrailerNumber              TTrailerNumber,
          @vSealNumber                 TSealNumber,
          @vProNumber                  TProNumber,
          @vShipVia                    TShipVia,
          @vLoadShipVia                TShipVia,
          @vShipViaIsConsolidator      TFlags,
          @vShipFromAddressId          TRecordId,
          @vShipToAddressId            TRecordId,
          @vBillToAddressId            TRecordId,
          @vConsolidatorAddressId      TContactRefId,
          @vMasterShipToId             TRecordId,
          @vMasterBoL                  TBoLNumber,
          @vFreightTerms               TLookUpCode,
          @vFreightTermsCount          TCount,
          @vFreighTermOnBoL            TLookUpCode,
          @vBoLFreightTerms            TLookUpCode,
          @vShipFrom                   TShipFrom,
          @vBoLType                    TTypeCode,
          @vLoadShipToId               TShipToId,
          @vAccount                    TAccount,
          @vAccountName                TName,
          @vPalletized                 TFlags,
          @vPalletTareWeight           TInteger = 0,
          @vPalletTareVolume           TFloat   = 0.0,
          @vxmlRulesData               TXML;

  declare @ttBoLData table
          (ShipmentId         TShipmentId,
           TrailerNumber      TTrailerNumber,
           SealNumber         TSealNumber,
           ProNumber          TProNumber,
           ShipVia            TShipVia,
           ShipFrom           TShipFrom,
           ShipFromAddressId  TRecordId,
           ShipToAddressId    TRecordId,
           BillToAddressId    TQuantity,
           FreightTerms       TLookUpCode,
           BusinessUnit       TBusinessUnit,
           RecordId           Integer Identity(1,1));

  declare @ttBoLLPNs          TBoLLPNs;

  declare @ttLoadBoLs table (ShipmentId   TShipmentId,
                             BoLId        TRecordId,
                             BoLType      TTypeCode,
                             Regenerate   TFlag,
                             BusinessUnit TBusinessUnit,
                             RecordId    Integer Identity(1,1));
begin  /* pr_Load_GenerateBoLs */
  select @ReturnCode  = 0,
         @MessageName = null;

  /* Create temp tables */
  select * into #BoLLPNs from @ttBoLLPNs;

  select @vLoadId                = LoadId,
         @vLoadType              = LoadType,
         @vLoadStatus            = Status,
         @vBusinessUnit          = BusinessUnit,
         @vPalletized            = Palletized,
         @vConsolidatorAddressId = ConsolidatorAddressId,
         @vAccount               = Account,
         @vAccountName           = AccountName,
         @vLoadShipVia           = ShipVia
  from Loads
  where (LoadId = @LoadId);

  /* get BoLId based on the load */
  select @vBoLId = BoLId
  from BoLs
  where (LoadId = @LoadId);

  select @vShipViaIsConsolidator = case when ServiceClass = 'CON' then 'Y' else 'N' end
  from ShipVias
  where (ShipVia = @vLoadShipVia) and (BusinessUnit = @vBusinessUnit);

  if (coalesce(@LoadId, 0) = 0)
    set @MessageName = 'InputIsRequired';
  else
  if (coalesce(@LoadId, 0) = 0)
    set @MessageName = 'LoadIsInvalid';
  else
  if (@vLoadStatus = 'N' /* New */)
    set @MessageName = 'GenerateBoLs_NoOrdersToGenerateBoL';
  else
  if (@vLoadStatus in ('S', 'X' /* Shipped, Cancelled */))
    set @MessageName = 'GenerateBoLs_LoadShippedOrCancelled';
  else
  if ((select count(distinct(shipvia)) from Shipments where (LoadId = @LoadId)) > 1)
    set @MessageName = 'ShipmentsWithMultipleShipVias';

  if (@MessageName is not null)
    exec @ReturnCode = pr_Messages_ErrorHandler @MessageName;

  /* Get the PalletTareWeight and Volume and update accordingly */
  select @vPalletTareWeight = dbo.fn_Controls_GetAsInteger('BoL', 'PalletTareWeight', '35' /* lbs */, @vBusinessUnit, null),
         @vPalletTareVolume = dbo.fn_Controls_GetAsInteger('BoL', 'PalletVolume', '7680' /* cu.in. */, @vBusinessUnit, null);

  /* Build data for Rules evaluation */
  select @vxmlRulesData = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('BoLId',              @vBoLId) +
                            dbo.fn_XMLNode('LoadId',             @vLoadId) +
                            dbo.fn_XMLNode('LoadType',           @vLoadType) +
                            dbo.fn_XMLNode('PalletTareWeight',   @vPalletTareWeight) +
                            dbo.fn_XMLNode('PalletTareVolume',   @vPalletTareVolume) +
                            dbo.fn_XMLNode('Palletized',         @vPalletized) +
                            dbo.fn_XMLNode('Account',            @vAccount) +
                            dbo.fn_XMLNode('AccountName',        @vAccountName) +
                            dbo.fn_XMLNode('BOD_GroupCriteria',  @BOD_GroupCriteria) +
                            dbo.fn_XMLNode('BusinessUnit',       @vBusinessUnit) +
                            dbo.fn_XMLNode('UserId',             @UserId));

  /* Verify if BoLs are already created for the Shipments in the given Load
     If no BoLs are found for any of the Shipments of the Load, then create new ones
     If BoLs are already created, then regenerate BoL details, if need be */
  insert into @ttLoadBoLs (ShipmentId, BoLId, Regenerate, BusinessUnit)
    select ShipmentId, BoLId,
           case when (BoLId is null) then 'Y' else @Regenerate end, /* regenerate */
           BusinessUnit
    from Shipments
    where (LoadId = @LoadId);

  /* If user trying to remove the orders from load, and there is no more orders on the Load then
     we need to clear all the BoL details.
     We are sending Regenerate as yes so it will regenerate all the details if exists. */
  if ((@@rowcount = 0) and (@Regenerate = 'Y' /* Yes */) and (coalesce(@vBoLId, 0) <> 0))
    begin
      exec pr_BoL_GenerateCarrierDetails @vBoLId, @vxmlRulesData, @Regenerate;
      exec pr_BoL_GenerateOrderDetails @vBoLId, @vxmlRulesData, @Regenerate;

      /*  Nothing to process, because there is no data in this block */
      goto ExitHandler;
    end

  /* If no BoLs are found for any of the Shipments of the Load, then create new ones */
  if (exists (select ShipmentId from @ttLoadBoLs where BoLId is null))
    begin
      insert into @ttBoLData(ShipmentId, TrailerNumber, SealNumber, ProNumber, ShipVia, ShipFrom,
                             ShipFromAddressId, ShipToAddressId, BillToAddressId, FreightTerms,
                             BusinessUnit)
        select S.ShipmentId, L.TrailerNumber, L.SealNumber, L.ProNumber, L.ShipVia, S.ShipFrom,
               SF.ContactId, ST.ContactId, BT.ContactId, S.FreightTerms,
               L.BusinessUnit
        from Loads L
                   join Shipments S  on (S.LoadId        = L.LoadId)
        left outer join Contacts  SF on (S.ShipFrom      = SF.ContactRefId ) and
                                        (SF.Contacttype  = 'F' /* Ship From */) and
                                        (SF.BusinessUnit = L.BusinessUnit)
        left outer join Contacts  ST on (S.ShipTo        = ST.ContactRefId ) and
                                        (ST.Contacttype  = 'S' /* ShipTo */) and
                                        (ST.BusinessUnit = L.BusinessUnit)
        left outer join Contacts  BT on (S.BillTo        = BT.ContactRefId ) and
                                        (BT.Contacttype  = 'B' /* BillTo */) and
                                        (BT.BusinessUnit = L.BusinessUnit)
        where (L.LoadId = @LoadId) and (S.BoLId is null);

      /* TODO TODO Generation of Master BoL is to be done here
         This is subject to the condition that the Load has single of Multiple Shipments
         This MasterBoL value should be updated to the BoLs created in the below while loop */

      /* Loop through all the shipments and create individual BoL for each shipments */
      while exists(select * from @ttBoLData)
        begin
          select top 1
                 @vBoLDataRecordId   = RecordId,
                 @vShipmentId        = ShipmentId,
                 @vBusinessUnit      = BusinessUnit,
                 @vTrailerNumber     = TrailerNumber,
                 @vSealNumber        = SealNumber,
                 @vProNumber         = ProNumber,
                 @vShipVia           = ShipVia,
                 @vShipFrom          = ShipFrom,
                 @vShipFromAddressId = ShipFromAddressId,
                 @vShipToAddressId   = ShipToAddressId ,
                 @vBillToAddressId   = BillToAddressId,
                 @vFreightTerms      = FreightTerms,
                 @vBoLId             = 0
          from @ttBoLData
          order by RecordId;

          /* Sometimes the From address to be printed on the BoL is not the regular ShipFrom address
             in that case, get the corresponding BoL addresss for the ShipFrom. The ContactRefIf would
             be ShipFrom + 'B' for an overriding address. If there is no overriding address, then the
             below statement is ineffective and regular ShipFrom address id would be used */
          select @vShipFromAddressId = ContactId
          from Contacts
          where (ContactRefId = @vShipFrom + 'B');

          /* Get the count of different FrieghtTerms from Shipment Orders to decide on showing FreightTerms on UnderlyingBoL */
          select @vFreightTermsCount = count (distinct OH.FreightTerms),
                 @vFreighTermOnBoL   = min(OH.FreightTerms)
          from OrderHeaders OH
            join OrderShipments OS on (OH.OrderId = OS.OrderId)
          where (OS.ShipmentId = @vShipmentId);

          /* Set Underlying BoL FreightTerms based on FreightTersm count on shipment */
          select @vBoLFreightTerms = case when @vFreightTermsCount = 1 then @vFreighTermOnBoL else '' end;

          /* Call proc to create new BoL. ProNumber, SealNo and TrailerNo on the Load are sufficient, we
             don't need to copy from Load to Bol. If none is specified on BoL the one on Load would be printed.
             If we setup on BoL, then any changes have to be made on all BoLs again instead of just udpating Load */
          exec pr_BoL_CreateNew @LoadId, 'U' /* Underlying BoL */, @vBusinessUnit, null /* TrailerNo */, null /* Seal No */,
                                null /* Pro Number */, @vShipVia, @vShipFromAddressId, @vShipToAddressId,
                                @vBillToAddressId, null /* Master Bol */, @vBoLFreightTerms, @vBoLId output,
                                @vBoLNumber output, @vVICSBoLNumber output;

          /* Update Shipments with BoLId and BoLNumber */
          update Shipments
          set BoLId     = @vBoLId,
              BoLNumber = @vBoLNumber
          where(ShipmentId = @vShipmentId);

          update @ttLoadBoLs
          set BoLId   = @vBoLId,
              BoLType = 'U' /* Underlying */
          where(ShipmentId = @vShipmentId);

          /* Delete record from the temp table  */
          delete @ttBoLData
          where (RecordId = @vBoLDataRecordId);

          /* Carrier and Customer Order Details have to be generated as new BoLs are inserted */
          set @Regenerate = 'Y' /* Yes*/;

          /* Audit Trail */
          exec pr_AuditTrail_Insert 'Load_UnderlyingBoLGenerated', @UserId, null /* ActivityTimestamp */,
                                    @LoadId = @vLoadId, @Note1 = @vVICSBoLNumber, @Note2 = @vBoLNumber;

          select @vBoLId = 0, @vBoLNumber = null, @vVICSBoLNumber = null;
        end /* End while */
    end /* End if */

  /*------------------------------------------------------------------------*/
  /* Generate Master Bill Of lading if needed */

  if (((select count(*) from BoLs where LoadId = @LoadId) > 1) or
       (@vShipViaIsConsolidator = 'Y'))
     and
     ((select count(*) from BoLs where LoadId = @LoadId and BoLType = 'M' /* Master */) = 0)
    begin
      select @vBoLId = 0;

      /* Get the count of different FrieghtTerms from Shipment Orders to decide on showing FreightTerms on UnderlyingBoL */
      select @vFreightTermsCount = count (distinct OH.FreightTerms),
             @vFreighTermOnBoL   = min(OH.FreightTerms)
      from OrderHeaders OH
        join OrderShipments OS on (OH.OrderId = OS.OrderId)
        join Shipments S on (OS.ShipmentId = S.ShipmentId)
      where (S.LoadId = @LoadId);

      /* Set Underlying BoL FreightTerms based on FreightTersm count on shipment */
      select @vBoLFreightTerms = case when @vFreightTermsCount = 1 then @vFreighTermOnBoL else '' end;

      /* If Load has consolidator address, that would become the MasterBoL.ShipTo */
      if (@vConsolidatorAddressId is not null)
        select @vMasterShipToId = ContactId
        from Contacts
        where (ContactType = 'FC') and (ContactRefId = @vConsolidatorAddressId) and (BusinessUnit = @vBusinessUnit);

      /* If Load is Transfer Load then get the Load.ShipTo */
      if (@vLoadType = 'Transfer')
        select @vMasterShipToId = ContactId
        from Contacts
        where (ContactType = 'S') and (ContactRefId = @vLoadShipToId) and (BusinessUnit = @vBusinessUnit);

      /* Call proc to create new BoL - Do not need to show FreightTerms on MasterBoL (ref: S2G-806) */
      exec pr_BoL_CreateNew @LoadId, 'M'/* Master BoL */, @vBusinessUnit, @vTrailerNumber, @vSealNumber,
                            @vProNumber, @vShipVia, @vShipFromAddressId, @vMasterShipToId,
                            @vBillToAddressId, null /* Master Bol */, @vBoLFreightTerms, @vBoLId output,
                            @vBoLNumber output, @vVICSBoLNumber output;

      /* Update Master BoL number to BoL Table Here */
      update BoLs
      set MasterBoL = @vVICSBoLNumber
      where ((LoadId =  @LoadId) and
            (VICSBoLNumber <> @vVICSBoLNumber));

      /* Audit Trail */
      exec pr_AuditTrail_Insert 'Load_MasterBoLGenerated', @UserId, null /* ActivityTimestamp */,
                                @LoadId = @vLoadId, @Note1 = @vVICSBoLNumber, @Note2 = @vBoLNumber;
    end

  /* Add the Master BoL to the Load BoLs so that we can generate the details for it as well */
  insert into @ttLoadBoLs (BoLId, BoLType, Regenerate)
    select BoLId, BoLType, 'Y' from BoLs where (LoadId = @LoadId) and (BoLType = 'M' /* Master */);

  /*------------------------------------------------------------------------*/
  /* Generate BoL Details */

  select @vLoadBoLsRecordId = 0;
  while exists(select * from @ttLoadBoLs where RecordId > @vLoadBoLsRecordId)
    begin
      select top 1
             @vLoadBoLsRecordId  = RecordId,
             @vBoLId             = BoLId,
             @vBoLType           = BoLType,
             @vRegenerateBoLDtls = Regenerate
      from @ttLoadBoLs
      where (RecordId > @vLoadBoLsRecordId)
      order by RecordId;

      /* get BoLId based on the BoLs  */
      select @vBoLType  = BoLType
      from BoLs
      where (BoLId = @vBoLId);

      if (@vRegenerateBoLDtls = 'Y' /* Yes */)
        begin
          /* Get list of LPNs to consider for BoL */
          exec pr_BoLs_GenerateLPNs @vBoLId, @vBoLType, @vLoadId, @vxmlRulesData, 'BoL_Generate', @vBusinessUnit, @UserId;

          exec pr_BoL_GenerateCarrierDetails @vBoLId, @vxmlRulesData, @vRegenerateBoLDtls;
          exec pr_BoL_GenerateOrderDetails @vBoLId, @vxmlRulesData, @vRegenerateBoLDtls;
        end
    end /* End while .. generate BoL details */

  /* Verify if MasterBoL exists or not, If yes update the Load with the master BoL else with the underlying BoL */
  select @vMasterBoLCount = count(*),
         @vMasterBoL      = min(VICSBoLNumber)
  from BoLs
  where (LoadID  = @LoadId) and
        (BoLType = 'M'/* MasterBoL */);

  /* What is this for? AY 2021/01/31 */
  select @vLoadBoLNumber = case
                             when @vMasterBoLCount > 0 then
                               @vMasterBoL
                             else
                               (select min(VICSBoLNumber) from BoLs where LoadId = @LoadId)
                             end;

  /* Setup the consolidator address for the Load */
  update Loads
  set MasterBoL = @vMasterBoL,
      BoLStatus = 'Generated'
  where (LoadId = @LoadId);

  /* Recount will calculate the counts afresh */
  exec pr_Load_Recount @vLoadId;

ExitHandler:
  return(coalesce(@ReturnCode, 0));
end /* pr_Load_GenerateBoLs */

Go
