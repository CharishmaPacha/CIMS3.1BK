/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_FedEx_GetLabelSpecifications') is not null
  drop Procedure pr_API_FedEx_GetLabelSpecifications;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_FedEx_GetLabelSpecifications:
    This procedure returns the label specifications in XML format.
    LabelImageFromat : Valid values are EPL, ZPL, SPL, PNG and GIF
    LabelStockSize: Valid combinations are 4x6 and 4x8
------------------------------------------------------------------------------*/
Create Procedure pr_API_FedEx_GetLabelSpecifications
  (@InputXML               xml,
   @BusinessUnit           TBusinessUnit,
   @UserId                 TUserId,
   @LabelSpecification     TVarchar output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vLabelFormatType        TTypeCode,
          @vImageType              TTypeCode;

begin /* pr_API_FedEx_GetLabelSpecifications */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

    select @vLabelFormatType = Record.Col.value('LabelFormat[1]', 'TTypeCode'),
           @vImageType       = Record.Col.value('ImageType[1]',   'TTypeCode')
    from @InputXML.nodes('/SHIPPINGINFO/REQUEST/LABELATTRIBUTES') Record(Col);

  /* Build the XML for FEDEX Label */
  select @LabelSpecification = dbo.fn_XMLNode('LabelSpecification',
                                                     dbo.fn_XMLNode('LabelFormatType', @vLabelFormatType) +
                                                     dbo.fn_XMLNode('ImageType',       @vImageType) +
                                                     dbo.fn_XMLNode('LabelStockType',  @vLabelFormatType)); --'<LabelStockType>STOCK_4X6</LabelStockType>'

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_FedEx_GetLabelSpecifications */

Go
