/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/03/10  RT      fn_Shipping_GetCartonDetails:  Get the Pallet and save it in the LPN to pass the CartonDetails (S2GCA-1446)
  2019/12/05  TK      pr_Shipping_GetShipmentData, pr_Shipping_SaveShipmentData & fn_Shipping_GetCartonDetails:
                        Changes to get proper carton dimensions (S2GCA-1068)
  2018/05/18  TK/RV    pr_Shipping_GetShipmentData: Use function to get carton details xml
                      fn_Shipping_GetCartonDetails: Initial revision (S2G-800)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Shipping_GetCartonDetails') is not null
  drop Function fn_Shipping_GetCartonDetails;
Go
/*------------------------------------------------------------------------------
  fn_Shipping_GetCartonDetails: This function returns the Carton Details xml required for the carrier
------------------------------------------------------------------------------*/
Create Function fn_Shipping_GetCartonDetails
  (@LPNId              TRecordId,
   @CartonType         TCartonType,
   @PackagingType      TDescription,
   @BusinessUnit       TBusinessUnit)
  -----------------------------------
   returns             TXML
as
begin
  /* declarations */
  declare @vLPN                        TLPN,
          @vCartonType                 TCartonType,
          @vCartonStatus               TStatus,
          @vCartonTypeDesc             TDescription,
          @vCartonInnerLength          TFloat,
          @vCartonInnerWidth           TFloat,
          @vCartonInnerHeight          TFloat,
          @vCartonOuterLength          TFloat,
          @vCartonOuterWidth           TFloat,
          @vCartonOuterHeight          TFloat,

          @vSKUId                      TRecordId,
          @vNumCases                   TInnerpacks,
          @vCartonDetailsXml           TXML,
          @vBusinessUnit               TBusinessUnit;

  /* Initialize */
  set @vCartonDetailsXml = '';

  /* If caller doesn't pass in Cartontype then get the one from LPN */
  if (@LPNId is not null)
    select @vLPN        = LPN,
           @vCartonType = coalesce(@CartonType, CartonType)
    from LPNs
    where (LPNId = @LPNId);
  else
    set @vCartonType = @CartonType;

  /* Return if there is no cartontype */
  if (@vCartonType is null)
    return(@vCartonDetailsXml);

  /* Get Carton info */
  select @vCartonStatus      = Status,
         @vCartonTypeDesc    = Description,
         @vCartonInnerLength = InnerLength,
         @vCartonInnerWidth  = InnerWidth,
         @vCartonInnerHeight = InnerHeight,
         @vCartonOuterLength = OuterLength,
         @vCartonOuterWidth  = OuterWidth,
         @vCartonOuterHeight = OuterHeight,
         @vBusinessUnit      = BusinessUnit
  from CartonTypes
  where (CartonType   = @vCartonType ) and
        (BusinessUnit = @BusinessUnit);

  /* If Carton type is a Standard box or LDP then try to get the dimensions from SKUs */
  if (@vCartonType in ('STD_BOX', 'STD_UNIT')) and (@LPNId is not null)
    begin
      /* Get the LPN info */
      select @vSKUId    = SKUId,
             @vNumCases = Innerpacks
      from LPNs
      where (LPNId = @LPNId);

      /* If it not a multi SKU LPN get the innerpack dimensions from SKU */
      if (@vSKUId is not null)
        begin
          select @vCartonInnerLength = case when @vCartonType = 'STD_BOX'  then coalesce(nullif(InnerpackLength, 0), nullif(UnitLength, 0), @vCartonInnerLength)
                                            when @vCartonType = 'STD_UNIT' then coalesce(nullif(UnitLength, 0), @vCartonInnerLength)
                                       end,
                 @vCartonInnerWidth  = case when @vCartonType = 'STD_BOX'  then coalesce(nullif(InnerpackWidth,  0), nullif(UnitWidth,  0), @vCartonInnerWidth)
                                            when @vCartonType = 'STD_UNIT' then coalesce(nullif(UnitWidth,  0), @vCartonInnerWidth)
                                       end,
                 @vCartonInnerHeight = case when @vCartonType = 'STD_BOX'  then coalesce(nullif(InnerpackHeight, 0), nullif(UnitHeight, 0), @vCartonInnerHeight)
                                            when @vCartonType = 'STD_UNIT' then coalesce(nullif(UnitHeight, 0), @vCartonInnerHeight)
                                       end,
                 @vCartonOuterLength = case when @vCartonType = 'STD_BOX'  then coalesce(nullif(InnerpackLength, 0), nullif(UnitLength, 0), @vCartonOuterLength)
                                            when @vCartonType = 'STD_UNIT' then coalesce(nullif(UnitLength, 0), @vCartonOuterLength)
                                       end,
                 @vCartonOuterWidth  = case when @vCartonType = 'STD_BOX'  then coalesce(nullif(InnerpackWidth,  0), nullif(UnitWidth,  0), @vCartonOuterWidth)
                                            when @vCartonType = 'STD_UNIT' then coalesce(nullif(UnitWidth,  0), @vCartonOuterWidth)
                                       end,
                 @vCartonOuterHeight = case when @vCartonType = 'STD_BOX'  then coalesce(nullif(InnerpackHeight, 0), nullif(UnitHeight, 0), @vCartonOuterHeight)
                                            when @vCartonType = 'STD_UNIT' then coalesce(nullif(UnitHeight, 0), @vCartonOuterHeight)
                                       end
          from SKUs
          where (SKUId = @vSKUId);
        end
    end

  /* Build Carton Details XML */
  select @vCartonDetailsXml = (select @vLPN               as LPN,
                                      @vCartonType        as CartonType,
                                      @PackagingType      as CarrierPackagingType,
                                      @vCartonTypeDesc    as Description,
                                      @vCartonInnerLength as InnerLength,
                                      @vCartonInnerWidth  as InnerWidth,
                                      @vCartonInnerHeight as InnerHeight,
                                      @vCartonOuterLength as OuterLength,
                                      @vCartonOuterWidth  as OuterWidth,
                                      @vCartonOuterHeight as OuterHeight,
                                      @vCartonStatus      as Status,
                                      @vBusinessUnit      as BusinessUnit
                               for xml raw('CARTONDETAILS'), elements );

  return (@vCartonDetailsXml);
end  /* fn_Shipping_GetCartonDetails */

Go
