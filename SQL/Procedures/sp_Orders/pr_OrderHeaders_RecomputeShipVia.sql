/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/10  VS      pr_OrderHeaders_RecomputeShipVia: Pass the default value for RegenerateLabel parameter (BK-126)
                      pr_OrderHeaders_RecomputeShipVia: Void the ShipLabel (BK-126)
  2017/04/25  SV      pr_OrderHeaders_ChangeAddress, pr_OrderHeaders_Modify, pr_OrderHeaders_RecomputeShipVia:
  2016/12/01  SV      pr_OrderHeaders_ChangeAddress, pr_OrderHeaders_Modify, pr_OrderHeaders_RecomputeShipVia:
  2016/10/26  TK/AY   pr_OrderHeaders_RecomputeShipVia: New procedure to change ShipVia for delayed orders (HPI-Golive)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_OrderHeaders_RecomputeShipVia') is not null
  drop Procedure pr_OrderHeaders_RecomputeShipVia;
Go
/*------------------------------------------------------------------------------
  Proc pr_OrderHeaders_RecomputeShipVia:
    Options: V - Void existing labels
------------------------------------------------------------------------------*/
Create Procedure pr_OrderHeaders_RecomputeShipVia
  (@OrderId         TRecordId,
   @ttOrders        TEntityKeysTable readonly,
   @Operation       TOperation,
   @Options         TFlags = null,
   @UserId          TUserId,
   @BusinessUnit    TBusinessUnit)
as
  declare @vReturnCode       TInteger,
          @vMessageName      TMessageName,
          @ttOrdersToUpdate  TEntityKeysTable,
          @vRecordId         TRecordId,
          @vOrderId          TRecordId,
          @vAccount          TAccount,
          @vOrderType        TTypeCode,
          @vOrderCategory1   TCategory,
          @vOrderCategory2   TCategory,
          @vCreatedDate      TDateTime,
          @vOldShipVia       TShipVia,
          @vOldCarrier       TCarrier,
          @vIsOldCarrierSmallPackage
                             TFlag,
          @vShipViaByRule    TShipVia,
          @vRulesXML         TXML,

          @vRowCount         TCount,
          @vMessage          TMessage,
          @vNote1            TDescription,
          @vNote2            TDescription,
          @vAuditRecordId    TRecordId;
begin
  select @vRecordId = 0;

  if (@OrderId is not null)
    insert into @ttOrdersToUpdate(EntityId) select @OrderId;
  else
    insert into @ttOrdersToUpdate(EntityId) select EntityId from @ttOrders

  /* Loop thru each order on the Wave and evaluate ShipVia */
  while exists (select * from @ttOrdersToUpdate where RecordId > @vRecordId)
    begin
      select top 1 @vRecordId       = OTU.RecordId,
                   @vOrderId        = OTU.EntityId,
                   @vAccount        = OH.Account,
                   @vOrderCategory1 = OH.OrderCategory1,
                   @vOrderCategory2 = OH.OrderCategory2,
                   @vOrderType      = OH.OrderType,
                   @vCreatedDate    = OH.CreatedDate,
                   @vShipViaByRule  = null,
                   @vOldShipVia     = nullif(OH.ShipVia, ''),
                   @vOldCarrier     = SV.Carrier,
                   @vIsOldCarrierSmallPackage
                                    = SV.IsSmallPackageCarrier
      from @ttOrdersToUpdate OTU
        join            OrderHeaders OH on (OTU.EntityId = OH.OrderId)
        left outer join ShipVias     SV on (OH.ShipVia   = SV.ShipVia)
      where (OTU.RecordId > @vRecordId) and (OH.Status not in ('S', 'X'))
      order by OTU.RecordId;

      /* Build Rules xml */
      select @vRulesXML = dbo.fn_XMLNode('RootNode',
                          dbo.fn_XMLNode('Operation',       @Operation) +
                          dbo.fn_XMLNode('OrderId',         @vOrderId) +
                          dbo.fn_XMLNode('Account',         @vAccount) +
                          dbo.fn_XMLNode('OrderType',       @vOrderType) +
                          dbo.fn_XMLNode('OrderCategory1',  @vOrderCategory1) +
                          dbo.fn_XMLNode('OrderCategory2',  @vOrderCategory2) +
                          dbo.fn_XMLNode('CreatedDate',     @vCreatedDate));

      /* Get the Shipvia */
      exec pr_RuleSets_Evaluate 'ShipVia' /* RuleSetType */, @vRulesXML, @vShipViaByRule output;

      if (coalesce(nullif(@vShipViaByRule, ''), '') = '') or
         (coalesce(@vShipViaByRule, '') = @vOldShipVia)
        continue;

      /* Update Ship Via on Order if there is a change */
      update OrderHeaders
      set ShipVia = @vShipViaByRule
      where (OrderId = @vOrderId);

      select @vRowCount = @@rowcount,
             @vNote1    = coalesce(@vOldShipVia, 'None'),
             @vNote2    = @vShipViaByRule;

      if (@vRowCount > 0)
        begin
          /* Later, we need to implement void shiplabels after we refactor the code */
          /* If shipvia is changed and old carrier is a small pacakge carrier then void ShipLabels */
          if (@vIsOldCarrierSmallPackage = 'Y' /* Yes */) and (coalesce(@Options, 'V') = 'V' /* Void Labels */)
            exec pr_Shipping_VoidShipLabels @vOrderId,
                                            null /* LPNId */,
                                            default,
                                            @BusinessUnit,
                                            default /* RegenerateLabel - No */,
                                            @vMessage output

          /* Log AT */
          exec pr_AuditTrail_Insert 'OrderShipViaModified', @UserId, null /* ActivityTimestamp */,
                                    @OrderId       = @vOrderId,
                                    @Note1         = @vNote1,
                                    @Note2         = @vNote2,
                                    @BusinessUnit  = @BusinessUnit,
                                    @AuditRecordId = @vAuditRecordId output;
        end
    end

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_OrderHeaders_RecomputeShipVia */

Go
