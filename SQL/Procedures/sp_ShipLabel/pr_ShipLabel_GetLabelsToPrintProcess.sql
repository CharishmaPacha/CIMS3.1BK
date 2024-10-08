/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/14  VM      pr_ShipLabel_GetLabelsToPrintForEntity, pr_ShipLabel_GetLabelsToPrintProcess - renamed to obsolete (HA-2510)
  2019/05/02  YJ      pr_ShipLabel_GetLabelsToPrintProcess: Migrated from Prod (S2GCA-98)
  pr_ShipLabel_GetLabelsToPrintProcess:  changes to get pallet tag records for pallet and load.
  pr_ShipLabel_GetLabelsToPrintProcess: Changed CarrierInterface domain name (S2GCA-434)
  pr_ShipLabel_GetLabelsToPrintProcess: Made changes to get the shipment type (S2GCA-249)
  2018/06/04  YJ      pr_ShipLabel_GetLabelsToPrintProcess: Changed Amazon SoldTo '165099': Migrated from staging (S2G-727)
  2018/06/01  RV      pr_ShipLabel_GetLabelsToPrintProcess: Made changes to print all the pallet ship labels against the PickTicket
  2018/05/10  RV      pr_ShipLabel_GetLabelFormat, pr_ShipLabel_GetLabelsToPrintProcess: Added Pallet Ship Label type to print
  2018/04/27  RV      pr_ShipLabel_GetLabelsToPrintProcess: Made changes to return ZPL to print from Shipping Docs page
  2018/04/26  RV      pr_ShipLabel_GetLabelsToPrintProcess: Made changes to print the pallet ship label (S2G-686)
  2017/07/12  VM      pr_ShipLabel_GetLabelsToPrintProcess: Send order OrderCategory1 to process CreateShipment Rules (SRI-798)
  2016/11/28  KN      pr_ShipLabel_GetLabelsToPrintProcess : Reverted unnecessary changes done for (HPI-740)
  2016/11/17  KN      pr_ShipLabel_GetLabelsToPrintProcess : Changed order of nodes for printing SL-1 , CL-2 (FB-810).
  2016/10/18  KN      pr_ShipLabel_GetLabelsToPrintProcess: Additionally passing Shipvia to evalutate rules (HPI-882)
  2016/09/22  KN      pr_ShipLabel_GetLabelsToPrintProcess : Added  condition to consider LPN also (HPI-740)
  2016/08/11  RV      pr_ShipLabel_GetLabelsToPrintProcess: Made changes to handle the multi packages while printing
  2016/05/05  AY      pr_ShipLabel_GetLabelsToPrintProcess: Print appropriate packing lists when user enters
  2016/05/04  TD      pr_ShipLabel_GetLabelsToPrintProcess:Changes to sendentikey value if the labeltype is
  2016/05/04  RV      pr_ShipLabel_GetLabelsToPrintProcess: Clean up the temp table to avoid the Unique violations (NBD-385)
  2016/05/03  RV      pr_ShipLabel_GetLabelsToPrintProcess: Label display format changed as LPN information is first (NBD-385)
  2016/03/16  DK      pr_ShipLabel_GetLabelsToPrintProcess: Enhanced to generate UCCBarcode (NBD-282).
  2016/03/08  TK      pr_ShipLabel_GetLabelFormat & pr_ShipLabel_GetLabelsToPrintProcess:
  pr_ShipLabel_GetLabelsToPrintProcess: Consider DocumentType & EntityType which will be helpful to evaluate rules
  2016/01/08  KN      pr_ShipLabel_GetLabelsToPrintProcess: Added condition for return label (FB-509)
  2015/11/15  AY      pr_ShipLabel_GetLabelsToPrintProcess: Allow re-printing with UCCBarcode
  2015/10/16  AY      pr_ShipLabel_GetLabelsToPrintProcess: Show proper message with ShipVia Description (ACME-340)
  2015/09/14  AY      pr_ShipLabel_GetLabelsToPrintProcess: Enhancement to reprint labels or not.
  2015/09/06  AY      pr_ShipLabel_GetLabelsToPrintProcess: Consider SortOrder of BPL as default (CIMS-617)
  2015/04/02  RV      pr_ShipLabel_GetLabelsToPrintProcess,pr_ShipLabel_GetLabelsToPrint: Resquence LPNs for the order before print
  pr_ShipLabel_GetLabelsToPrint, pr_ShipLabel_GetLabelsToPrintProcess :
  2012/11/28  AA      pr_ShipLabel_GetLabelsToPrintProcess: Added parameter LPN Status
  2012/11/10  AA      pr_ShipLabel_GetLabelsToPrintProcess: new procedure to return labels
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetLabelsToPrintProcess') is not null
  drop Procedure pr_ShipLabel_GetLabelsToPrintProcess;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GetLabelsToPrintProcess: Returns all the info associated with the
    label formats to be printed for an LPN.

LabelTypes

<LabelTypes>
  <LabelType>SL</LabelType>
  <LabelType>CL</LabelType>
  <LabelType>RL</LabelType>
  <LabelType>PS</LabelType>
  <LabelType>PTag</LabelType>
  <LabelType>VI</LabelType>
</LabelTypes>
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetLabelsToPrintProcess
  (@LoadNumber           TLoadNumber  = null,
   @BatchNo              TPickBatchNo = null,
   @PickTicket           TPickTicket  = null,
   @Pallet               TPallet      = null,
   @LPN                  TLPN         = null,
   @LPNStatus            TStatus,
   @LabelTypes           XML,
   @Operation            TOperation   = null,
   @PrinterName          TDeviceId,
   @LabelPrintSortOrder  TLookUpCode,
   @ReprintOptions       TPrintFlags = 'Y',
   @UserId               TUserId,
   @BusinessUnit         TBusinessUnit)
as
  declare @vReturnCode          TInteger,
          @vMessageName         TMessageName,
          @vMessage             TDescription,

          @vLPNId               TRecordId,
          @vLPN                 TLPN,
          @vNumLPNs             TCount,
          @vLPNOrderId          TRecordId,
          @vLoadId              TRecordId,
          @vOrderId             TRecordId,
          @vPickTicket          TPickTicket,
          @vOrderStatus         TStatus,
          @vOrderType           TTypeCode,
          @vOrderTypeDesc       TDescription,
          @vOrderCategory1      TCategory,
          @vCarrier             TCarrier,
          @vCarrierType         TCarrier,
          @vShipVia             TShipVia,
          @vIsSmallPackageCarrier
                                TFlag,
          @vCarrierInterface    TCarrierInterface,
          @vSoldToId            TContactRefId,
          @vLPNsAssigned        TCount,
          @vPackageSeqNo        TCount,
          @vShiplabelFormat     TName,
          @vLabelType           TLookUpCode,
          @vLabelTypes          TCount,
          @vValidLPNTypes       TControlValue,
          @vIsPalletShipLabel   TControlCode,
          @vCreateShipmentxml   TXML,
          @vIsCreateShipmentReq TFlag,
          @vRecordId            TRecordId,
          @vUCCBarcode          TBarcode,
          @vGenerateUCCBarcode  TFlag,
          @vLTRecordId          TRecordId,
          @ttLPNs               TEntityKeysTable,
          @vEntity              TEntity,
          @vLPNsWithTrackingNos TCount,
          @vLPNTrackingNo       TTrackingNo;

  declare @ttLabelTypes                  TEntityKeysTable;
  declare @ttLabelsToPrintWithoutFormat  TLabelsToPrint;
  declare @ttLabelsToPrint               TLabelsToPrint;
  declare @ttPickTicketsToCreateShipment TEntityKeysTable;
  declare @xmlRulesData                  TXML;

  declare @ttLabelsToPrintProcess table
          (RecordId         Integer Identity(1,1),
           ParentRecordId   Integer,
           LoadNumber       TLoadNumber,
           BatchNo          TPickBatchNo,
           PickTicket       TPickTicket,
           Pallet           TPallet,
           LPN              TLPN,
           Entity           TEntity,
           EntityKey        TEntityKey,
           Description      TDescription,
           LabelFormatName  TName,
           LabelType        TTypeCode,
           IsCreateShipmentReq
                            TFlag,
           IsPrintable      TFlag,
           Data             TXML,
           ZPLLabel         TXML);

  declare @ttOrderIds table (RecordId TRecordId identity(1,1),
                             OrderId  TRecordId);

begin /* pr_ShipLabel_GetLabelsToPrintProcess */
  select @vReturnCode   = 0,
         @vMessagename  = null,
         @vRecordId     = 0,
         @vLTRecordId   = 0,
         @vLPNId        = null;

  /* Get the label types to be processed */
  insert into @ttLabelTypes (EntityKey)
    select Record.Col.value('(./text())[1]', 'varchar(50)')
    from @LabelTypes.nodes('/LabelTypes/LabelType') as Record(Col)

  /* Fetch the valid control values for which the labels needed to be printed */
  select @vValidLPNTypes = dbo.fn_Controls_GetAsString('ShipLabels', 'ValidLabelTypesToPrintLabels', 'CS' /* Carton, ShipCarton */, @BusinessUnit, @UserId);

  /* If the LPN is palletized then we may have to print a Pallet ShipLabel for it instead of
     LPN Shiplabels for each LPN on the Pallet. Get control var to determine that */
  select @vIsPalletShipLabel = dbo.fn_Controls_GetAsString('Shipping', 'PalletShipLabel', 'Y' /* Yes */, @BusinessUnit, @UserId);

  /* If LPN is not null then we retrieve the LPNId and fill temp table with orderids to package resequence */
  if (@LPN is not null)
    begin
      select @vLPNId         = LPNId,
             @vLPN           = LPN,  /* @vLPN is being passed @vCreateShipmentxml to evaluate rules */
             @vLPNOrderId    = OrderId,
             @vLPNTrackingNo = TrackingNo
      from LPNs
      where (LPN = @LPN) and (BusinessUnit = @BusinessUnit);

      /* If LPNId is null, then try UCC Barcode */
      if (@vLPNId is null)
        select @vLPNId      = LPNId,
               @vLPN        = LPN, /* @vLPN is being passed @vCreateShipmentxml to evaluate rules */
               @vLPNOrderId = OrderId
        from LPNs
        where (UCCBarcode = @LPN) and (BusinessUnit = @BusinessUnit);

      /* set entity here */
      set @vEntity = 'LPN';

      /* Get OrderId */
      insert into @ttOrderIds(OrderId)
        select @vLPNOrderId
    end
  else
  /* If PicketTicket is not null then we retrieve the OrderIds against the PicketTicket and fill the Temp table */
  if (@PickTicket is not null)
    begin
      set @vEntity = 'PickTicket';

      /* Get the OrderIds for PickTicket */
      insert into @ttOrderIds(OrderId)
        select OH.OrderId
        from OrderHeaders OH
        where (OH.PickTicket = @PickTicket) and (BusinessUnit = @BusinessUnit);
    end
  else
  /* If BatchNo is not null then we retrieve the OrderIds against the BatchNo and fill the Temp table */
  if (@BatchNo is not null)
    begin
      set @vEntity = 'PickBatchNo';

      /* Get the OrderIds for BatchNo */
      insert into @ttOrderIds(OrderId)
        select distinct OrderId
        from OrderHeaders
        where (PickBatchNo = @BatchNo) and (BusinessUnit = @BusinessUnit);
    end
  else
  if (@LoadNumber is not null)
    begin
      set @vEntity = 'Load';

      /* Get the LoadId */
      select @vLoadId = LoadId
      from Loads
      where (LoadNumber = @LoadNumber);

      /* Get the OrderIds for Load */
      insert into @ttOrderIds(OrderId)
        select distinct OrderId
        from vwLoadOrders
        where (LoadId = @vLoadId);
    end
  else
  /* If Pallet is not null then we retrieve the OrderIds against the Pallet and fill the Temp table */
  if (@Pallet is not null)
    begin
      set @vEntity = 'Pallet';

      /* Get the OrderIds for Pallet */
      insert into @ttOrderIds(OrderId)
        select distinct OrderId
        from LPNs
        where (Pallet = @Pallet) and (BusinessUnit = @BusinessUnit);

      /* Temp fix for CRP to print Amazon labels for Amazon orders. Also assuming that one order is associated wih one Pallet */
      select top 1 @vOrderId = OrderId
      from @ttOrderIds

      select @vSoldToId = SoldToId
      from OrderHeaders
      where (OrderId = @vOrderId)

      if (@vSoldToId = '165099' /* Amazon SoldTo */)
        select @vIsPalletShipLabel = 'N';
    end

  /* Loop For Every OrderId to Re order */
  while (exists (select * from @ttOrderIds where RecordId > @vRecordId and OrderId is not null))
    begin
      select top 1 @vRecordId   = RecordId,
                   @vOrderId    = OrderId
      from @ttOrderIds
      where (RecordId > @vRecordId) and OrderId is not null
      order by RecordId;

      /* Re order the Package Sequence Number */
      exec pr_LPNs_PackageNoResequence @vOrderId, @vLPNId;
    end;

  while (exists (select * from @ttLabelTypes where RecordId > @vLTRecordId))
    begin
      /* Fetch the selected label need to be print one by one to process*/
      select top 1 @vLabelType  = EntityKey,
                   @vLTRecordId = RecordId
      from @ttLabelTypes
      where (RecordId > @vLTRecordId)
      order by RecordId;

      /* Clean up temp table */
      delete from @ttLabelsToPrintWithoutFormat;

      /* Insert required records for selected label into temp table for process */
      /* If the vIsPalletShipLabel control variable is No then only we will insert the data into tables */
      if (@vLabelType = 'SPL' /* Small Package Label */) or
         ((@vLabelType = 'PL' /* Packing List */) and (@LPN is not null)) or
         (@vLabelType = 'CL' /* Contents label */) or
         (@vLabelType = 'RL' /* Return label */) or
         (@vLabelType = 'SL' /* Shipping Label */)  --and (@vIsPalletShipLabel = 'N' /* No */) /* and (coalesce(@Pallet, '') = '') */ )
        begin
          insert into @ttLabelsToPrintWithoutFormat (BatchNo, PickTicket, Pallet, LPNId, LPN, OrderId,
                                                     CustPO, SoldToId, ShipToId, ShipVia, ShipToStore,
                                                     WaveType, LabelType, DocumentType, LPNPrintFlags, EntityType, Operation, IsPrintable)
            select OH.PickBatchNo, OH.PickTicket, P.Pallet, L.LPNId, L.LPN, OH.OrderId,
                   OH.CustPO, OH.SoldToId, OH.ShipToId, OH.ShipVia, OH.ShipToStore,
                   PB.BatchType, @vLabelType, @vLabelType, L.PrintFlags,
                   case when (@BatchNo is not null) or (@PickTicket is not null) then 'PickTicket'
                        else 'LPN' end,
                   @Operation /* Operation to evaluate the rules of PackingListType */,
                   case when (@vLabelType = 'RL' /* Return label */) and (OH.ReturnLabelRequired = 'Y') then 'Y'
                        when (@vLabelType = 'RL') then 'N'
                        when (@ReprintOptions = 'Y') then 'Y'
                        when charindex(',' +@vLabelType + ',', ',' + coalesce(L.PrintFlags, '') + ',') = 0 then 'Y'
                        else 'N' end
            from LPNs L
              left join Pallets P on L.PalletId = P.PalletId
              inner join OrderHeaders OH on L.OrderId = OH.OrderId
              left join PickBatches PB on PB.BatchNo = OH.PickBatchNo
            where (@BatchNo is null    or L.PickBatchNo  = @BatchNo   ) and
                  (@PickTicket is null or OH.PickTicket  = @PickTicket) and
                  (@Pallet is null     or P.Pallet       = @Pallet    ) and
                  (@LPN    is null     or L.LPN          = @LPN       or L.UCCBarcode = @LPN or L.AlternateLPN = @LPN) and
                  (@LPNStatus is null  or L.Status       = @LPNStatus ) and
                  (charindex(L.LPNType, @vValidLPNTypes) <> 0);
        end
      else
      if (@vLabelType = 'PL') and ((@PickTicket is not null) or (@BatchNo is not null))
        begin
          insert into @ttLabelsToPrintWithoutFormat (BatchNo, PickTicket, OrderId,
                                                     CustPO, SoldToId, ShipToId, ShipVia, ShipToStore,
                                                     WaveType, LabelType, DocumentType, EntityType, Operation, IsPrintable)
            select OH.PickBatchNo, OH.PickTicket, OH.OrderId,
                   OH.CustPO, OH.SoldToId, OH.ShipToId, OH.ShipVia, OH.ShipToStore,
                   PB.BatchType, @vLabelType, @vLabelType, 'PickTicket', @Operation /* Operation to evaluate the PackingListType */, 'Y'
            from OrderHeaders OH
                 left join PickBatches PB on PB.BatchNo = OH.PickBatchNo
            where (@BatchNo is null    or OH.PickBatchNo = @BatchNo   ) and
                  (@PickTicket is null or OH.PickTicket  = @PickTicket);
        end
      else
      if (@vLabelType = 'PS' /* Price Stickers */)
        begin
          insert into @ttLabelsToPrint (BatchNo, PickTicket, OrderId, CustPO, SoldToId, ShipToId,
                                        ShipVia, ShipToStore, WaveType, LabelType, LabelFormatName, IsPrintable) -- table of records with Label format
            select OH.PickBatchNo, OH.PickTicket, TT.OrderId, OH.CustPO, OH.SoldToId, OH.ShipToId,
                   OH.ShipVia, OH.ShipToStore, PB.BatchType, @vLabelType, OH.PriceStickerFormat, 'Y'
            from @ttOrderIds TT
              join OrderHeaders OH on TT.OrderId = OH.OrderId
              join PickBatches  PB on OH.PickBatchId = PB.RecordId
            where OH.PriceStickerFormat <> '';
        end
      else /* Print Pallet ship label based on input Pallet or PickTicket */
      if (@vLabelType = 'PSL' /* Pallet Ship Label */)
        begin
          if (@Pallet is not null)
            /* If user enters Pallet then print for the given Pallet */
            insert into @ttLabelsToPrintWithoutFormat (BatchNo, PickTicket, Pallet, LPNId, LPN, OrderId,
                                                       CustPO, SoldToId, ShipToId, ShipVia, ShipToStore,
                                                       WaveType, LabelType, DocumentType, LPNPrintFlags, EntityType, IsPrintable)
              select OH.PickBatchNo, OH.PickTicket, P.Pallet, null /* LPNId */, null /* LPN */, OH.OrderId,
                     OH.CustPO, OH.SoldToId, OH.ShipToId, OH.ShipVia, OH.ShipToStore,
                     OH.WaveType, @vLabelType, @vLabelType, P.PrintFlags, 'Pallet', 'Y'
              from Pallets P
                join vwOrderHeaders OH on (OH.OrderId = P.OrderId)
              where (P.Pallet = @Pallet);
          else
          if (@PickTicket is not null)
            /* If user enters PickTicket then print for all pallets of the given PickTicket */
            insert into @ttLabelsToPrintWithoutFormat (BatchNo, PickTicket, Pallet, LPNId, LPN, OrderId,
                                                       CustPO, SoldToId, ShipToId, ShipVia, ShipToStore,
                                                       WaveType, LabelType, DocumentType, LPNPrintFlags, EntityType, IsPrintable)
              select OH.PickBatchNo, OH.PickTicket, P.Pallet, null /* LPNId */, null /* LPN */, OH.OrderId,
                     OH.CustPO, OH.SoldToId, OH.ShipToId, OH.ShipVia, OH.ShipToStore,
                     OH.WaveType, @vLabelType, @vLabelType, P.PrintFlags, 'Pallet', 'Y'
              from Pallets P
                join vwOrderHeaders OH on (OH.OrderId = P.OrderId)
              where (OH.PickTicket = @PickTicket);
        end
      else
      /* Insert Records when the Entity is pallet or load tto print Pallet tag */
      if (@vLabelType = 'PTag' /* Pallet Tag */) and (@vEntity in ('Pallet', 'Load') /* Pallet, Load */)
        begin
          if (@Pallet is not null)
            /* If user enters Pallet then print for the given Pallet */
            insert into @ttLabelsToPrintWithoutFormat (LoadNumber, BatchNo, PickTicket, Pallet, LPNId, LPN, OrderId,
                                                       CustPO, SoldToId, ShipToId, ShipVia, ShipToStore,
                                                       WaveType, LabelType, DocumentType, LPNPrintFlags, EntityType, IsPrintable)
              select L.LoadNumber, P.PickBatchNo, OH.PickTicket, P.Pallet, null /* LPNId */, null /* LPN */, OH.OrderId,
                     OH.CustPO, OH.SoldToId, P.ShipToId, OH.ShipVia, OH.ShipToStore,
                     PB.BatchType, @vLabelType, @vLabelType, P.PrintFlags, 'Pallet', 'Y'
              from Pallets P
                left outer join OrderHeaders OH on (OH.OrderId = P.OrderId)
                left outer join PickBatches  PB on (PB.RecordId = P.PickBatchId)
                left outer join Loads        L  on (L.LoadId = P.LoadId)
              where (P.Pallet = @Pallet);
          else
          if (@PickTicket is not null)
            /* If user enters PickTicket then print for all pallets of the given PickTicket */
            insert into @ttLabelsToPrintWithoutFormat (BatchNo, PickTicket, Pallet, LPNId, LPN, OrderId,
                                                       CustPO, SoldToId, ShipToId, ShipVia, ShipToStore,
                                                       WaveType, LabelType, DocumentType, LPNPrintFlags, EntityType, IsPrintable)
              select OH.PickBatchNo, OH.PickTicket, P.Pallet, null /* LPNId */, null /* LPN */, OH.OrderId,
                     OH.CustPO, OH.SoldToId, OH.ShipToId, OH.ShipVia, OH.ShipToStore,
                     OH.WaveType, @vLabelType, @vLabelType, P.PrintFlags, 'Pallet', 'Y'
              from Pallets P
                join vwOrderHeaders OH on (OH.OrderId = P.OrderId)
              where (OH.PickTicket = @PickTicket);
          else
          if (@LoadNumber is not null)
            /* If user enters Load then print for the Pallets on that LoadNumber */
            insert into @ttLabelsToPrintWithoutFormat (LoadNumber, BatchNo, PickTicket, Pallet, LPNId, LPN, OrderId,
                                                       CustPO, SoldToId, ShipToId, ShipVia, ShipToStore,
                                                       WaveType, LabelType, DocumentType, LPNPrintFlags, EntityType, IsPrintable)
              select distinct @LoadNumber, P.PickBatchNo, OH.PickTicket, P.Pallet, null /* LPNId */, null /* LPN */, P.OrderId,
                     OH.CustPO, OH.SoldToId, P.ShipToId, OH.ShipVia, OH.ShipToStore,
                     PB.BatchType, @vLabelType, @vLabelType, null, 'Pallet', 'Y'
              from Pallets P
                left outer join OrderHeaders OH on (OH.OrderId = P.OrderId)
                left outer join PickBatches  PB on (PB.RecordId = P.PickBatchId)
              where (P.LoadId = @vLoadId);
        end

      if (exists (select * from @ttLabelsToPrintWithoutFormat))
        insert into @ttLabelsToPrint (LoadNumber, BatchNo, PickTicket, Pallet, LPNId, LPN, TaskId, OrderId, CustPO, SoldToId, ShipToId,
                                      Carrier, ShipVia, ShipToStore, WaveType, LabelType, LabelFormatName, IsPrintable) -- table of records with Label format
          exec pr_ShipLabel_GetLabelFormat @ttLabelsToPrintWithoutFormat; -- table of records without Label format

      select @xmlRulesData = dbo.fn_XMLNode('RootNode',
                               dbo.fn_XMLNode('LabelType', @vLabelType) +
                               dbo.fn_XMLNode('Operation', 'PrintShipLabels'));

      /* Clean up temp table */
      delete from @ttLPNs;

      insert into @ttLPNs (EntityId, EntityKey)
        select distinct LP.LPNId, LP.LPN
        from @ttLabelsToPrint LP join LPNs L on (LP.LPNId = L.LPNId)
        where (L.UCCBarcode is null);

      /* Generate UCC Barcodes for LPNs that require it */
      exec pr_LPNs_SetUCCBarcode null /* LPNId */, @ttLPNs, null /* Order Id */, @xmlRulesData,
                                 @BusinessUnit, @UserId;
    end /* process of each LabelType */

    /* Consider BPL as the default, so if default, change to BPL */
    if @LabelPrintSortOrder = 'D'
      select @LabelPrintSortOrder = 'BPL';

    --Batch,PickTicket,LPN
    if (@LabelPrintSortOrder = 'BPL')
      begin
        -- ToDo: Refactor below using new stored procedure as

        /* Insert Load records to process the Pallets of the considered Load Below when the DocType is Pallet tag */
        insert into @ttLabelsToPrintProcess (LoadNumber, Entity, EntityKey, Description, LabelFormatName, IsPrintable)
          select distinct LoadNumber, 'Load', LoadNumber, 'Load ' + LoadNumber, LabelFormatName, 'N'
          from @ttLabelsToPrint
          where LoadNumber is not null;

        -- insert into @ttLabelsToPrintProcess exec pr_ShipLabel_GetWaveNodes @ttLabelsToPrint;
        with Batches(BatchNo, LabelFormatName)
        as
        (
          select BatchNo,
                 max(case when LabelType = 'BL' then LabelFormatName
                          else null end)
          from @ttLabelsToPrint
          group by BatchNo
        )

        -- insert wave header
        insert into @ttLabelsToPrintProcess (BatchNo, Entity, EntityKey, Description, LabelFormatName)
          select BatchNo, 'Wave', BatchNo, 'Wave ' + BatchNo, LabelFormatName
          from Batches
          where BatchNo is not null;

        -- ToDo: Refactor below using new stored procedure as
        -- insert into @ttLabelsToPrintProcess exec pr_ShipLabel_GetPTNodes @ttLabelsToPrint, @ttLabelsToPrintProcess
        -- This procedure should return PT Nodes and create shipment nodes if applicable.

        /* Insert PickTicket records, with BatchNo being the parent */
        with PickTickets(BatchNo, PickTicket, LabelformatName, LabelType)
        as
        (
          select BatchNo,
                 /* Consider the entity to get the LabelFormatName, since if LabelFormatName is null the IsPrintable would be 'N' */
                 PickTicket,
                 max(case when (@vEntity = 'PickTicket') and (LabelType not in ('SL', 'SPL', 'CL')) then LabelformatName
                          else null
                     end),
                 case when @vEntity = 'PickTicket' then LabelType
                          else null
                     end
          from @ttLabelsToPrint
          /* Consider group by with respect to the entity for LabelType, when the Entity is other than the PickTicket,
             that is if in case of LPN then we are evaluating LPN with respect to each LabelType on the PickTicket record (refer CID-193 for more details) */
          group by BatchNo, PickTicket, case when @vEntity = 'PickTicket' then LabelType else null end
        )
        insert into @ttLabelsToPrintProcess (ParentRecordId, BatchNo, PickTicket, Entity, EntityKey, Description, LabelFormatName, LabelType)
          select LPP.RecordId,
                 PT.BatchNo,
                 PT.PickTicket,
                 'PickTicket',
                 PT.PickTicket,
                 case when PT.LabelType = 'PL' then 'PickTicket ' + PT.PickTicket + ', ' + 'Packing list'
                      when PT.LabelType = 'PM' then 'PickTicket ' + PT.PickTicket + ', ' + 'Packing Manifest'
                      when PT.LabelType = 'OM' then 'PickTicket ' + PT.PickTicket + ', ' + 'Order Manifest'
                      else 'PickTicket ' + PT.PickTicket
                 end,
                 PT.LabelFormatName,
                 PT.LabelType
          from PickTickets PT
            inner join @ttLabelsToPrintProcess LPP on LPP.BatchNo = PT.BatchNo
          where PT.PickTicket is not null;

        /* Insert Create Shipment records for each PT here - it is important to insert here
           because Create shipment node should be prior to the LPNs which trigger label printing.
           these nodes will be deleted later if not required */
        with CreateShipmentPickTickets(BatchNo, PickTicket, LabelFormatName, LabelType)
        as
        (
          select BatchNo,
                 PickTicket,
                 null,
                 LabelType
          from @ttLabelsToPrint
          group by BatchNo, PickTicket, LabelType
          having PickTicket is not null
        )
        insert into @ttLabelsToPrintProcess (ParentRecordId, BatchNo, PickTicket, Entity, EntityKey, Description, LabelFormatName, LabelType, IsCreateShipmentReq)
        /* Consider the top 1 record since we are getting multiple records, we are grouping with respect to LabelType
           that is if in case of LPN then we are evaluating LPN with respect to each LabelType on the PickTicket record, we are Creating Shipment for each PickTicket, when selected multiple LabelTypes */
        select top 1 LPP.RecordId,
          CPT.BatchNo,
          CPT.PickTicket,
          'PickTicket',
          CPT.PickTicket,
          'Create Shipment for Pick Ticket ' + CPT.PickTicket,
          CPT.LabelFormatName,
          CPT.LabelType,
          'N' /* No */
        from CreateShipmentPickTickets CPT
          inner join @ttLabelsToPrintProcess LPP on (LPP.BatchNo = CPT.BatchNo) and (LPP.PickTicket = CPT.PickTicket)
        where CPT.PickTicket is not null;

        /* Insert Pallets on the Load or Pallet record, when the entity is Pallet aor Load */
        if (@vLabelType = 'PTag') and (@vEntity in ('Pallet', 'Load'))
          begin
            /* Insert Pallets with the PT being the parent */
            insert into @ttLabelsToPrintProcess (ParentRecordId, LoadNumber, BatchNo, PickTicket, Pallet, Entity, EntityKey, Description,
                                                 LabelFormatName, LabelType, IsPrintable)
              select LPP.RecordId,
              Plts.LoadNumber,
              Plts.BatchNo,
              Plts.PickTicket,
              Plts.Pallet,
              'Pallet',
              Plts.Pallet,
              'Pallet ' + Plts.Pallet + ', Pallet tag' /* Description */,
              Plts.LabelFormatName,
              Plts.LabelType,
              Plts.IsPrintable
              from @ttLabelsToPrint Plts
                left outer join @ttLabelsToPrintProcess LPP on (LPP.LoadNumber = Plts.LoadNumber)
                left outer join ShipVias SV on Plts.ShipVia = SV.ShipVia
              where ((Plts.Pallet is not null) or
                     (Plts.LabelType = 'PTag')) and
                    ((Plts.LoadNumber = @LoadNumber) or
                     (Plts.Pallet = @Pallet))
              order by Plts.Pallet, Plts.LabelType;
          end
        else
        /* Insert LPNs with the PT being the parent. There will be two PT nodes so, insert under the one which has
           Create Shipment is null i.e. master node of the PickTicket */
        insert into @ttLabelsToPrintProcess (ParentRecordId, BatchNo, PickTicket, LPN, Entity, EntityKey, Description,
                                             LabelFormatName, LabelType, IsPrintable, ZPLLabel)
          select LPP.RecordId,
                 LPNs.BatchNo,
                 LPNs.PickTicket,
                 LPNs.LPN,
                 case when (LPNs.LPN is not null) then 'LPN'
                      when (LPNs.Pallet is not null) then 'Pallet' end ,
                 case when (LPNs.LPN is not null) then LPNs.LPN
                      when (LPNs.Pallet is not null) then LPNs.Pallet end ,
                 case when LPNs.LabelType = 'SL'  then 'LPN ' + coalesce(LPNs.LPN, LPNs.Pallet) + ', Shipping Label'
                      when LPNs.LabelType = 'SPL' then 'LPN ' + coalesce(LPNs.LPN, LPNs.Pallet) + ', ' + 'Small Package Label'
                      when LPNs.LabelType = 'PSL' then 'Pallet ' + coalesce(LPNs.LPN, LPNs.Pallet) + ', ' + 'Pallet Label'
                      when LPNs.LabelType = 'CL'  then 'LPN ' + coalesce(LPNs.LPN, LPNs.Pallet) + ', Contents Label'
                      when LPNs.LabelType = 'PL'  then 'LPN ' + coalesce(LPNs.LPN, LPNs.Pallet) + ', Packing list'
                      when LPNs.LabelType = 'RL'  then 'LPN ' + coalesce(LPNs.LPN, LPNs.Pallet) +', return label'
                      when LPNs.LabelType = 'PS'  then 'Price Stickers ' + @vEntity + ' ' + coalesce(@BatchNo, @PickTicket, @LPN)
                      else 'LPN ' + LPNs.LPN
                 end /* Description */,
                 LPNs.LabelFormatName,
                 LPNs.LabelType,
                 LPNs.IsPrintable,
                 SL.ZPLLabel
          from @ttLabelsToPrint LPNs
            inner join @ttLabelsToPrintProcess LPP on LPP.BatchNo = LPNs.BatchNo and LPP.PickTicket = LPNs.PickTicket
            left outer join ShipVias SV on LPNs.ShipVia = SV.ShipVia
            left outer join ShipLabels SL on (SL.EntityKey = LPNs.LPN)
          where (IsCreateShipmentReq is null) and ((LPNs.LPN is not null) or (LPNs.Pallet is not null) or
                (LPNs.Labeltype = 'PS'))
          order by LPNs.LPN,
          case   when  LPNs.LabelType = 'SL'  then  1
                 when  LPNs.LabelType = 'CL'  then  2
          end,
          LPNs.LabelType;
      end
  else
  if (@LabelPrintSortOrder = 'D' /* Default */)
    begin
      insert into @ttLabelsToPrintProcess (BatchNo, Pallet, EntityKey, Description, LabelFormatName, LabelType)
      select BatchNo, Pallet, Pallet, 'Pallet ' + Pallet, LabelFormatName, LabelType
      from @ttLabelsToPrint;
    end

  /* Change description to reflect the LPNs not being reprinted */
  update @ttLabelsToPrintProcess
  set Description = 'Not reprinting ' + Description
  where (IsPrintable = 'N') and (LPN is not null);

  /* Get the LabelType counts */
  select @vLabelTypes = Count(distinct EntityKey)
  from @ttLabelTypes;

  /* If printing for LPN, then we may have to do some updates like changing status,
     so invoke the method to does that */
  if (@vLPNId is not null) and (exists(select * from @ttLabelTypes where EntityKey not in ('PS'/* PriceStickers */)) and (@vLabelTypes >= 1))
    exec pr_ShipLabel_OnPrintingDocsForLPN @vLPNId, @Operation, @BusinessUnit, @UserId;

  insert into @ttPickTicketsToCreateShipment(EntityKey)
    select distinct PickTicket
    from @ttLabelsToPrintProcess
    where IsCreateShipmentReq = 'N'; /* No */

  select @vRecordId = 0;

  /* Check whether we need to create multiple shipment or not */
  while (exists (select EntityKey from @ttPickTicketsToCreateShipment where RecordId > @vRecordId))
    begin
      select @vIsCreateShipmentReq = null;

      select top 1
             @vPickTicket = EntityKey,
             @vRecordId   = RecordId
      from @ttPickTicketsToCreateShipment
      where (RecordId > @vRecordId);

      select @vOrderId               = OH.OrderId,
             @vOrderStatus           = OH.Status,
             @vOrderCategory1        = OH.OrderCategory1,
             @vLPNsAssigned          = OH.LPNsAssigned,
             @vCarrier               = S.Carrier,
             @vCarrierType           = S.CarrierType, /* SPG - Small Package  or LTL */
             @vShipVia               = S.ShipVia,
             @vIsSmallPackageCarrier = S.IsSmallPackageCarrier
      from OrderHeaders OH
        left join vwShipVias S on (OH.ShipVia = S.ShipVia)
      where (OH.PickTicket   = @vPickTicket)

      /* Determine how many of the LPNs have tracking nos */
      select @vLPNsWithTrackingNos = count(*)
      from ShipLabels S
           join LPNs L on (L.LPN = S.EntityKey) and (L.BusinessUnit = S.BusinessUnit)
      where (S.OrderId = @vOrderId) and
            (S.IsValidTrackingNo = 'Y');

      select @vCreateShipmentxml = '<RootNode>' +
                                     dbo.fn_XMLNode('OrderId',               @vOrderId)      +
                                     dbo.fn_XMLNode('OrderCategory1',        coalesce(@vOrderCategory1, '')) +
                                     dbo.fn_XMLNode('LPNId',                 @vLPNId)        +
                                     dbo.fn_XMLNode('LPN',                   @vLPN)          +
                                     dbo.fn_XMLNode('Carrier',               @vCarrier)      + /* Consider the source of request to determine whichpacking list to print using the rules */
                                     dbo.fn_XMLNode('CarrierType',           @vCarrierType)  +
                                     dbo.fn_XMLNode('ShipVia',               @vShipVia)      +
                                     dbo.fn_XMLNode('IsSmallPackageCarrier', @vIsSmallPackageCarrier) +
                                     dbo.fn_XMLNode('CarrierInterface',      '')             +
                                     dbo.fn_XMLNode('Entity',                @vEntity)       +
                                     dbo.fn_XMLNode('PackageSeqNo',          @vPackageSeqNo) +
                                     dbo.fn_XMLNode('LPNsAssigned',          @vLPNsAssigned) +
                                     dbo.fn_XMLNode('OrderStatus',           @vOrderStatus)  +
                                     dbo.fn_XMLNode('TrackingNoCount',       isnull(@vLPNsWithTrackingNos,0)) +
                                     dbo.fn_XMLNode('LPNTrackingNo',         @vLPNTrackingNo) +
                                   '</RootNode>'

      /* Get Carrier Interface */
      exec pr_RuleSets_Evaluate 'CarrierInterface', @vCreateShipmentxml, @vCarrierInterface output;

      select @vCreateShipmentxml = dbo.fn_XMLStuffValue (@vCreateShipmentxml, 'CarrierInterface', @vCarrierInterface);

      /* Get the CreateShipment Flag */
      exec pr_RuleSets_Evaluate 'CreateSPGShipment', @vCreateShipmentxml, @vIsCreateShipmentReq output;

      update @ttLabelsToPrintProcess
      set IsCreateShipmentReq = coalesce(@vIsCreateShipmentReq, 'N')
      where (IsCreateShipmentReq = 'N') and
            (Entity = 'PickTicket') and
            (EntityKey = @vPickTicket);

      /* In case of USPS, we don't have multishipment functionality.
         So, LPN alone will be provided to generate the label from ShippingDocs page. */
      if (@vCarrier = 'USPS')
        update #ttLabelsToPrintProcess
        set IsCreateShipmentReq = coalesce(@vIsCreateShipmentReq, 'N')
        where (Entity = 'LPN') and
              (EntityKey = @vLPN);
    end

  /* To: We should update CreateShipment of LPNs to Yes or No based upon that of the PT */

  select RecordId KeyFieldName,
         ParentRecordId ParentFieldName,
         case when LabelFormatName like 'Price%' then coalesce(EntityKey,  @LPN, @PickTicket, @PickTicket)
              else EntityKey
         end EntityKey,
         Description,
         IsCreateShipmentReq,
         coalesce(IsPrintable,
                  case when LabelFormatName is not null then 'Y'else 'N' end) as IsPrintable,
         coalesce(Data, dbo.fn_XMLNode('Root', dbo.fn_XMLNode('LabelFormatName', LabelFormatName))) as Data,
         Entity,
         LabelType as LabelType,
         ''  as ZPLLabel -- this is no longer used and is being saved to session, so to avoid that we are disabling it
  from @ttLabelsToPrintProcess
  where (IsCreateShipmentReq is null) or (IsCreateShipmentReq in ('M' /* Multiple shipment */,'Y' /* Yes to Single shipment */))
  order by RecordId;

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName, @vOrderTypeDesc;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_ShipLabel_GetLabelsToPrintProcess */

Go

/* V2 proc - not required in V3. Will remove after certain time (HA-2510) */
exec sp_Rename 'pr_ShipLabel_GetLabelsToPrintProcess', 'pr_ShipLabel_GetLabelsToPrintProcess_Obsolete'

Go
