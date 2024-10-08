/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2022/09/06  RV      pr_Shipping_GetCommercialInvoiceInfo: Corrected the export purpose (BK-911)
  2017/10/01  OK      pr_Shipping_GetShipmentData: Enhanced to return the CN22 details and required shipping docs in xml
                      pr_Shipping_GetCN22Info: Added tp return the CN22 details (OB-577)
              VM      pr_Shipping_GetCommercialInvoiceInfo: Added and called from pr_Shipping_GetShipmentData (OB-576)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Shipping_GetCommercialInvoiceInfo') is not null
  drop Procedure pr_Shipping_GetCommercialInvoiceInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_Shipping_GetCommercialInvoiceInfo: Commercial Invoice Info, which is used for International shipemnts
------------------------------------------------------------------------------*/
Create Procedure pr_Shipping_GetCommercialInvoiceInfo
  (@LPNId          TRecordId,
   @SaveCIFormInDB TControlValue,
   @CIInfoXML      Txml output)
as
  declare @vReturnCode        TInteger,
          @vMessageName       TMessageName,
          @vxmlRulesData      Txml;

  /* Temp table to capture Commercial Invoice data */
  declare @ttCIInfo table
          (OrderId        TRecordId,
           Purpose        TUDF,  /* CommercialInvoicePurpose - 'Sold', 'Gift', 'Return', 'Repair', 'Sample' etc */
           Terms          TUDF,  /* CommercialInvoiceTerms   - 'Cost and Freight', 'Delivery Duty Paid', 'Free Carrier' etc */
           Date           TUDF,
           Number         TLPN,  /* We decided to send LPN as value for this field */
           FreightCharge  TUDF,  /* Get from host? per Brandon (OB) */
           Insurance      TUDF,  /* Get from host? per Brandon (OB) */
           Comments       TVarchar,
           /* Settings */
           SaveCIFormInDB TControlValue);

  declare  @vOrderId        TRecordId,
           @vPurpose        TUDF,  /* CommercialInvoicePurpose - 'Sold', 'Gift', 'Return', 'Repair', 'Sample' etc */
           @vTerms          TUDF,  /* CommercialInvoiceTerms   - 'Cost and Freight', 'Delivery Duty Paid', 'Free Carrier' etc */
           @vNumber         TLPN,  /* We decided to send LPN as value for this field */
           @vFreightCharge  TUDF,  /* Get from host? per Brandon (OB) */
           @vInsurance      TUDF,  /* Get from host? per Brandon (OB) */
           @vComments       TVarchar,
           @vOtherCharges   TUDF;
begin
  SET NOCOUNT ON;

  select @vReturnCode  = 0,
         @vMessageName = null;

  select * into #CIInfo from @ttCIInfo;

  /* Gather info for Commercial Invoice */
    select @vOrderId       = OH.OrderId,
           @vPurpose       = 'SOLD',
           @vTerms         = null /* We get Terms from the rules */,
           @vNumber        = L.LPN,
           @vFreightCharge = cast(cast(coalesce(OH.TotalShippingCost, 0) as numeric(10, 2)) as varchar),
           @vInsurance     = '0.00', /* Use if host sent */
           @vOtherCharges  = '0.00', /* Other is for any other charges placed onthe shipment by the shipper (e.g.,handling charge). */
           @vComments      = coalesce(null /* Comments - Use if host sent */, '')
    from LPNs L
    join OrderHeaders OH on (L.OrderId       = OH.OrderId)
    where (L.LPNId = @LPNId);

  insert into #CIInfo (OrderId, Purpose, Terms, Number, Date, FreightCharge, Insurance, Comments, SaveCIFormInDB)
    select @vOrderId, @vPurpose, @vTerms, @vNumber, convert(varchar, current_timestamp,   112 /* YYYYMMDD */), @vFreightCharge, @vInsurance, @vComments, @SaveCIFormInDB;

  /* Rules to get the Commercial Invoice Info */
  select @vxmlRulesData =  dbo.fn_XMLNode('RootNode',
                             dbo.fn_XMLNode('LPNId',   @LPNId) +
                             dbo.fn_XMLNode('OrderId', @vOrderId));

  /* update the dataset with the cust specific details */
  exec pr_RuleSets_ExecuteRules 'CommercialInvoiceInfo' /* RuleSetType */, @vxmlRulesData;

  select @CIInfoXML = (select *
                       from #CIInfo
                       for xml raw('CIINFO'), elements);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Shipping_GetCommercialInvoiceInfo */

Go
