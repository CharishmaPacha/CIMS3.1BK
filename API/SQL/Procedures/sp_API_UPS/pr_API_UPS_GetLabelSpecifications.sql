/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_GetLabelSpecifications') is not null
  drop Procedure pr_API_UPS_GetLabelSpecifications;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_GetLabelSpecifications:
    This procedure returns the label specifications json.
    LabelImageFromat : Valid values are EPL, ZPL, SPL, PNG and GIF
    LabelStockSize: Valid combinations are 4x6 and 4x8
  Sample output:
  {
   "LabelImageFormat":{
      "Code":"ZPL"
   },
   "LabelStockSize":{
      "Width":"4",
      "Height":"6"
   }
  }
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_GetLabelSpecifications
  (@InputXML               xml,
   @BusinessUnit           TBusinessUnit,
   @UserId                 TUserId,
   @LabelSpecificationJSON TNVarchar output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName;
begin /* pr_API_UPS_GetLabelSpecifications */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode        = 0,
         @vMessageName       = null;

  /* Build LabelImageFormat json */
  select @LabelSpecificationJSON = (select [LabelImageFormat.Code] = Record.Col.value('LabelImageType[1]', 'TTypeCode'),
                                           [LabelStockSize.Width]  = '4',
                                           [LabelStockSize.Height] = '6'
                                    from @InputXML.nodes('/SHIPPINGINFO/REQUEST/LABELATTRIBUTES') Record(Col)
                                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
                                    OPTION (OPTIMIZE FOR ( @InputXML = null ));
ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_GetLabelSpecifications */

Go
