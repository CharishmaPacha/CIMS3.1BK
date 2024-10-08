/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/01/05  RV      pr_Shipping_BuildReferences: corrected input parameter syntax (HA-1772)
  2018/09/07  RV      pr_Shipping_BuildReferences: Made changes to send empty if there are no references, in ADSI splitting with respect to the
                        the colon (:) if references are not empty (S2GCA-250)
  2018/08/28  DK      pr_Shipping_BuildReferences: Enhanced to use rules to get the Reference formats along with setup mapping to get Venue code (HPI-2010)
  2018/03/14  OK      pr_Shipping_BuildReferences: Changes to get the default reference formats if client specific controls are not setup (S2G-410)
  2017/04/11  NB      Modified pr_Shipping_BuildReferences (CIMS-1259)
                        for reading ADSI specific reference controls
  2015/06/01  SV      pr_Shipping_BuildReferences: Migrated this procedure from OB
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_BuildReferences') is not null
  drop Procedure pr_Shipping_BuildReferences;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_BuildReferences:
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_BuildReferences
  (@Carrier          TCarrier,
   @SoldToId         TCustomerId,
   @LPN              TLPN,
   @SalesOrder       TSalesOrder,
   @PickTicket       TPickTicket,
   @UCCBarcode       TBarcode,
   @CustPO           TCustPO,
   @PurchaseOrder    TReceiptNumber,
   @DesiredShipDate  TDateTime,
   @CarrierInterface TDescription,
   @BusinessUnit     TBusinessUnit,
  ------------------------------
   @Referencexml     TXML output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vMessage           TDescription,

          @vOrderId           TRecordId,
          @vAccount           TAccount,
          @vOwnership         TOwnership,
          @vWarehouse         TWarehouse,
          @vXmlRulesData      TXML,

          /* Other */
          @vReference1        TDescription,
          @vReference2        TDescription,
          @vReference3        TDescription;

begin /* pr_Shipping_BuildReferences */
  select @vReturnCode  = 0,
         @vMessageName = null;

  /* Get account value */
  select @vAccount    = Account,
         @vOrderId    = OrderId,
         @vOwnership  = Ownership,
         @vWarehouse  = Warehouse,
         @CustPO      = coalesce(nullif(CustPO, ''), '-'),
         @SoldToId    = SoldToId,
         @SalesOrder  = SalesOrder
  from OrderHeaders OH
  where (OH.PickTicket = @PickTicket) and (BusinessUnit = @BusinessUnit);

  if (@LPN is not null)
    select @LPN        = LPN,
           @UCCBarcode = right(UCCBarcode, 10)
    from LPNs
    where (LPN = @LPN) and (BusinessUnit = @BusinessUnit);

  select @UCCBarcode = coalesce(@UCCBarcode, '');

  /* Prepare XML for rules */
  select @vXmlRulesData = dbo.fn_XMLNode('RootNode',
                            dbo.fn_XMLNode('OrderId',          @vOrderId)         +
                            dbo.fn_XMLNode('PickTicket',       @PickTicket)       +
                            dbo.fn_XMLNode('SalesOrder',       @SalesOrder)       +
                            dbo.fn_XMLNode('CustPO',           @CustPO)           +
                            dbo.fn_XMLNode('SoldToId',         @SoldToId)         +
                            dbo.fn_XMLNode('Carrier',          @Carrier)          +
                            dbo.fn_XMLNode('CarrierInterface', @CarrierInterface) +
                            dbo.fn_XMLNode('Account',          @vAccount)         +
                            dbo.fn_XMLNode('LPN',              @LPN)              +
                            dbo.fn_XMLNode('UCCBarcode',       @UCCBarcode)       +
                            dbo.fn_XMLNode('BusinessUnit',     @BusinessUnit));

  /* Apply Rules to get Ref1, Ref2 & Ref3 values */
  exec pr_RuleSets_Evaluate 'ShippingReference1', @vXmlRulesData, @vReference1 output;
  exec pr_RuleSets_Evaluate 'ShippingReference2', @vXmlRulesData, @vReference2 output;
  exec pr_RuleSets_Evaluate 'ShippingReference3', @vXmlRulesData, @vReference3 output;

  if (coalesce(@vReference1, '') + coalesce(@vReference2, '') + coalesce(@vReference3, '') <> '')
    begin
      /* References cannot be blank, either we give it or we don't, but we cannot give blank */
      set @Referencexml = '<REFERENCE>' +
                            '<REFERENCE1>' + coalesce(nullif(@vReference1, ''), '-') + '</REFERENCE1>' +
                            '<REFERENCE2>' + coalesce(nullif(@vReference2, ''), '-') + '</REFERENCE2>' +
                            '<REFERENCE3>' + coalesce(nullif(@vReference3, ''), '-') + '</REFERENCE3>' +
                            '<REFERENCE4></REFERENCE4>'                     +
                            '<REFERENCE5></REFERENCE5>'                     +
                          '</REFERENCE>';
    end

ErrorHandler:
  /* On Error, return Error Code/Error Message */
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_BuildReferences */

Go
