/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx_GetPackageInfo') is not null
  drop Procedure pr_API_FedEx_GetPackageInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx_GetPackageInfo: Extract data from get shipment data xml and
   build payment info XML

------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx_GetPackageInfo
  (@ShipmentInfoXML    XML,
   @BusinessUnit       TBusinessUnit,
   @UserId             TUserId,
   @PackageInfo        TVarchar output)
as
  declare @vReturnCode            TInteger,
          @vMessageName           TMessageName,
          @vSequenceNumber        TInteger,
          @vLength                TLength,
          @vWidth                 TWidth,
          @vHeight                THeight,
          @vUnits                 TUoM,
          @vValue                 TQuantity,
          @vReference1            TReference,
          @vWeight                TVarchar,
          @vDimensions            TVarchar;

begin /* pr_API_FedEx_GetPackageInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  /* Get the CartonInfo */
  select @vSequenceNumber = Record.Col.value('(CONTAINERHEADER/PackageSeqNo)[1]',  'TInteger'),
         @vLength         = Record.Col.value('(CARTONDETAILS/InnerLength)[1]',     'TLength'),
         @vWidth          = Record.Col.value('(CARTONDETAILS/InnerWidth)[1]',      'TWidth'),
         @vHeight         = Record.Col.value('(CARTONDETAILS/InnerHeight)[1]',     'THeight'),
         @vUnits          = Record.Col.value('(Commodities/Weight/WeightUoM)[1]',  'TUoM'),
         @vValue          = Record.Col.value('(Commodities/Weight/Value)[1]',      'TQuantity'),
         @vREFERENCE1     = Record.Col.value('(REFERENCE/REFERENCE1)[1]',          'TReference')
  from @ShipmentInfoXML.nodes('/SHIPPINGINFO/REQUEST/PACKAGES/PACKAGE') Record(Col);

  select @vWeight =  dbo.fn_XMLNode('Weight',
                                      dbo.fn_XMLNode('Units', @vUnits) +
                                      dbo.fn_XMLNode('Value', @vValue));

  select @vDimensions =  dbo.fn_XMLNode('Dimensions',
                                      dbo.fn_XMLNode('Length', @vLength) +
                                      dbo.fn_XMLNode('Width',  @vWidth) +
                                      dbo.fn_XMLNode('Height', @vHeight)+
                                      dbo.fn_XMLNode('Units',  'IN'));

  /* Build the XML for FEDEX PackageInfo */
  select @PackageInfo = '<RequestedPackageLineItems>' +
                          '<SequenceNumber>' + cast(@vSequenceNumber as varchar(4)) + '</SequenceNumber>' +
                           @vWeight +
                           @vDimensions +
                          '<CustomerReferences>
                            <CustomerReferenceType>CUSTOMER_REFERENCE</CustomerReferenceType>
                            <Value>TC001_01_PT1_ST01_PK01_SNDUS_RCPCA_POS</Value>
                           </CustomerReferences>' +
                        '</RequestedPackageLineItems>';

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx_GetPackageInfo */

Go
