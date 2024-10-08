/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2019/01/21  RT      pr_ShipLabel_GetEntityInfo: Made changes to get the EntityInfo when given input is Load
  2018/09/12  NB      Modified pr_ShipLabel_GetEntityInfo : to consider V3 entity type names (CIMSV3-221)
  2016/10/03  KL      pr_ShipLabel_GetEntityInfo: Changed the entity type to "Pickbatch" as we are sending Entity as "PickBatch" to get the wave information (FB-763)
  2016/09/22  MV      pr_ShipLabel_GetEntityInfo: Added the LPNStatus and PT Status columns (HPI-743)
  2016/08/09  AY      pr_ShipLabel_GetEntityInfo: Show estimated weights
  2016/05/16  RV      pr_ShipLabel_GetEntityInfo: Added ShipVia Description in entity information (NBD-523)
  2016/01/02  RV      pr_ShipLabel_GetEntityInfo: Added procedure to get the entity information as html (NBD-53)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_ShipLabel_GetEntityInfo') is not null
  drop Procedure pr_ShipLabel_GetEntityInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_ShipLabel_GetEntityInfo: This proc is used in ShippingDocs page to
   get all information presented to the user for the scanned/entered entity.
   The entity is first evaluated for what it is and this procedure is used to
   retrieve it all info and show in HTML format.

  @EntityXML format should be like below:

  <Root>
    <Entity>LPN</Entity>
    <EntityKey>S000003081</EntityKey>
  </Root>
------------------------------------------------------------------------------*/
Create Procedure pr_ShipLabel_GetEntityInfo
  (@EntityXML     TXML,
   @UserId        TUserId,
   @BusinessUnit  TBusinessUnit,
   @htmlResult    TXML           = null output)
as
  declare @vEntity             TEntity,
          @vEntityKey          TEntityKey,
          @vxmlData            xml,

          @vLPN                TLPN,
          @vLPNStatusDesc      TDescription,
          @vUCCBarcode         TBarcode,
          @vTrackingNo         TTrackingNo,
          @vPackageSeqNo       TInteger,
          @vOrderId            TRecordId,
          @vPickTicket         TPickTicket,
          @vSalesOrder         TSalesOrder,
          @vOrderStatusDesc    TDescription,
          @vWave               TPickBatchNo,
          @vCustPO             TCustPO,
          @vShipVia            TShipVia,
          @vShipViaDesc        TDescription,
          @vWeight             TWeight,
          @vCartonTypeDesc     TDescription,
          @vBatchTypeDesc      TDescription,
          @vNumOrders          TCount,
          @vNumLPNs            TCount,
          @vNumUnits           TCount,
          @vNumPallets         TCount,
          @vLoadNumber         TLoadNumber,
          @vPallet             TPallet,
          @vPalletTypeDesc     TDescription,

          @vContactRefId       TContactRefId,
          @vSoldToId           TCustomerId,
          @vShipToName         TName,
          @vShipToAddressLine1 TAddressLine,
          @vShipToAddressLine2 TAddressLine,
          @vCityStateZip       TCityStateZip,

          @vXML                TVarchar;

  declare @ttEntityInfo table (Caption TName, DataValue TDescription, RecordId TRecordId identity(1,1));

begin /* pr_ShipLabel_GetEntityInfo */

  /* Extracting data elements from XML. */
  set @vxmlData = convert(xml, @EntityXML);

  select @vEntity    = Record.Col.value('Entity[1]', 'TEntity'),
         @vEntityKey = Record.Col.value('EntityKey[1]', 'TEntityKey')
  from @vxmlData.nodes('/Root') as Record(Col);

  insert into @ttEntityInfo
    select 'Entity', FieldCaption
    from vwFieldCaptions
    where (ContextName = 'ShipLabels.Page') and (FieldName = @vEntity);

  if (@vEntity = 'LPN')
    begin
      select @vLPN                = LPN,
             @vLPNStatusDesc      = LS.StatusDescription,
             @vOrderId            = L.OrderId,
             @vWeight             = coalesce(nullif(L.ActualWeight, 0), L.EstimatedWeight),
             @vCartonTypeDesc     = CT.Description,
             @vUCCBarcode         = UCCBarcode,
             @vTrackingNo         = TrackingNo,
             @vPackageSeqNo       = PackageSeqNo
      from LPNs L
        left outer join CartonTypes  CT on (CT.CartonType = L.CartonType)
        left outer join Statuses     LS on (LS.StatusCode = L.Status   and LS.Entity = @vEntity)
      where (L.LPN = @vEntityKey) and
            (L.BusinessUnit = @BusinessUnit);

      select @vNumLPNs = LPNsAssigned from OrderHeaders where OrderId = @vOrderId;

      insert into @ttEntityInfo select 'LPN',           @vLPN
      insert into @ttEntityInfo select 'LPN Status',    @vLPNStatusDesc
      insert into @ttEntityInfo select 'Carton Type',   @vCartonTypeDesc
      insert into @ttEntityInfo select 'Carton Weight', @vWeight
      insert into @ttEntityInfo select 'UCC Barcode',   @vUCCBarcode
      insert into @ttEntityInfo select 'Tracking No',   @vTrackingNo
      insert into @ttEntityInfo select 'Carton #',      cast(@vPackageSeqNo as varchar) + ' of ' + cast(@vNumLPNs as varchar)
    end

  /* Get OrderId if PT is given */
  if (@vEntity = 'PickTicket')
    select @vOrderId = OH.OrderId
    from OrderHeaders OH
    where (OH.PickTicket = @vEntityKey) and
          (OH.BusinessUnit = @BusinessUnit);

  /* If LPN or PickTicket give PT Details */
  if (@vEntity in ('LPN', 'PickTicket')) and (@vOrderId is not null)
    begin
      select @vPickTicket         = OH.PickTicket,
             @vSalesOrder         = OH.SalesOrder,
             @vOrderStatusDesc    = OS.StatusDescription,
             @vWave               = OH.PickBatchNo,
             @vSoldToId           = OH.SoldToId,
             @vCustPO             = OH.CustPO,
             @vShipVia            = OH.ShipVia,
             @vShipViaDesc        = SV.Description,
             @vWeight             = OH.TotalWeight,
             @vNumLPNs            = OH.LPNsAssigned
      from OrderHeaders OH
        left outer join ShipVias SV on (OH.ShipVia = SV.ShipVia)
        left outer join Statuses OS on (OS.StatusCode = OH.Status and OS.Entity = 'Order')
      where (OH.OrderId = @vOrderId);

      select @vShipToName         = Name,
             @vShipToAddressLine1 = AddressLine1,
             @vShipToAddressLine2 = AddressLine2,
             @vCityStateZip       = CityStateZip
      from dbo.fn_Contacts_GetShipToAddress(@vOrderId, null /* ContactRefId */);

      insert into @ttEntityInfo select 'Pick Ticket', @vPickTicket
      insert into @ttEntityInfo select 'Sales Order', @vSalesOrder
      insert into @ttEntityInfo select 'Order Status',@vOrderStatusDesc
      insert into @ttEntityInfo select 'Wave',        @vWave
      insert into @ttEntityInfo select 'Cust PO',     @vCustPO
      insert into @ttEntityInfo select 'Ship Via',    @vShipVia + ', ' + @vShipViaDesc
      insert into @ttEntityInfo select 'Total Weight',@vWeight
      insert into @ttEntityInfo select 'Sold To',     @vSoldToId
      insert into @ttEntityInfo select 'Ship To',     @vShipToName
      insert into @ttEntityInfo select ' ',           @vShipToAddressLine1
      insert into @ttEntityInfo select ' ',           @vShipToAddressLine2
      insert into @ttEntityInfo select ' ',           @vCityStateZip

    end
  else
  if (@vEntity in ('PickBatch', 'Wave'))
    begin
      select @vContactRefId       = PB.ShipToId,
             @vBatchTypeDesc      = PB.BatchTypeDesc,
             @vNumOrders          = PB.NumOrders,
             @vNumLPNs            = PB.NumLPNs,
             @vNumUnits           = PB.NumUnits,
             @vShipVia            = PB.ShipVia,
             @vShipViaDesc        = PB.ShipViaDesc
      from vwPickBatches PB
      where (PB.BatchNo = @vEntityKey) and
            (PB.BusinessUnit = @BusinessUnit);

      select @vShipToName         = Name,
             @vShipToAddressLine1 = AddressLine1,
             @vShipToAddressLine2 = AddressLine2,
             @vCityStateZip       = CityStateZip
      from dbo.fn_Contacts_GetShipToAddress(null /* OrderId */, @vContactRefId);

      insert into @ttEntityInfo select 'Wave Type',        @vBatchTypeDesc
      insert into @ttEntityInfo select 'Number of Orders', @vNumOrders
      insert into @ttEntityInfo select 'Number of LPNs',   @vNumLPNs
      insert into @ttEntityInfo select 'Number of Units',  @vNumUnits
    end
  else
  if (@vEntity = 'Load')
    begin
      select @vContactRefId       = L.ShipToId,
             @vLoadNumber         = L.LoadNumber,
             @vNumPallets         = L.NumPallets,
             @vNumOrders          = L.NumOrders,
             @vNumLPNs            = L.NumLPNs,
             @vNumUnits           = L.NumUnits,
             @vShipVia            = L.ShipVia,
             @vShipViaDesc        = L.ShipViaDescription
      from vwLoads L
      where (L.LoadNumber    = @vEntityKey) and
            (L.BusinessUnit = @BusinessUnit);

      /*  to display in the preview if required */
      select @vShipToName         = Name,
             @vShipToAddressLine1 = AddressLine1,
             @vShipToAddressLine2 = AddressLine2,
             @vCityStateZip       = CityStateZip
      from dbo.fn_Contacts_GetShipToAddress(null /* OrderId */, @vContactRefId);

      insert into @ttEntityInfo select 'Load',             @vLoadNumber
      insert into @ttEntityInfo select 'ShipVia',          @vShipViaDesc
      insert into @ttEntityInfo select 'Number of Pallets',@vNumPallets
      insert into @ttEntityInfo select 'Number of Orders', @vNumOrders
      insert into @ttEntityInfo select 'Number of LPNs',   @vNumLPNs
      insert into @ttEntityInfo select 'Number of Units',  @vNumUnits
    end
  else
  if (@vEntity = 'Pallet')
    begin
      select @vPallet         = P.Pallet,
             @vNumLPNs        = P.NumLPNs,
             @vNumUnits       = P.Quantity,
             @vPalletTypeDesc = P.PalletTypeDesc
      from vwPallets P
      where (P.Pallet = @vEntityKey) and
            (P.BusinessUnit = @BusinessUnit);

      insert into @ttEntityInfo select 'Pallet',           @vPallet
      insert into @ttEntityInfo select 'Pallet Type',      @vPalletTypeDesc
      insert into @ttEntityInfo select 'Number of LPNs',   @vNumLPNs
      insert into @ttEntityInfo select 'Number of Units',  @vNumUnits
    end

  /* Build the output html */
  select @vXML = cast((select 'font-size:small' as [td/@style],
                              Caption +
                              case when (coalesce(Caption, '')='') then '' else ':' end as 'td',
                              '',
                              DataValue as 'td',
                              ''
                       from @ttEntityInfo
                       order by RecordId
                       FOR XML PATH('tr'), ELEMENTS ) AS nvarchar(max));

  /* Format it as a table */
  select @htmlResult = dbo.fn_HTML_PrepareTable(null /* Captions */, @vXML, 'border="0"')
end /* pr_ShipLabel_GetEntityInfo */

Go
