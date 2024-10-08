/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/02/28  AY      pr_Setup_Shipvias: Setup ShipVia.SCAC (HA-2693)
  2021/04/07  TK      pr_Setup_Shipvias: Set up SCAC code as well (HA-2469)
  2021/01/07  RV      pr_Setup_Shipvias: Made changes to update carrier in standard attributes if not exists (CIMS-3218)
  2021/01/04  RV      pr_Setup_Shipvias: Made changes to set up with all Business Units (HA-1775)
  2018/09/14  RV      pr_Setup_Shipvias: Made changest to add CARRIERSERVICECODE node to the standard attributes if not exists
                        from the CarrierServiceCode column (S2GCA-260)
  2018/09/09  AY      pr_Setup_Shipvias: Expanded to setup IsSmallPackageCarrierField
  2018/08/08  AY      pr_Setup_Shipvias: Added BU parameter
  2017/10/16  YJ      pr_Setup_Shipvias: pr_Setup_Shipvias: Enhanced to handle multiple BusinessUnits (CIMS-1346)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_Setup_Shipvias') is not null
  drop Procedure pr_Setup_Shipvias;
Go
/*------------------------------------------------------------------------------
  pr_Setup_Shipvias: Setup the ShipVias from the temp table for the given Carrier
------------------------------------------------------------------------------*/
Create Procedure pr_Setup_Shipvias
  (@Carrier                TCarrier,
   @ShipVias               TShipViasTable ReadOnly,
   @Action                 TAction,
   @BusinessUnit           TBusinessUnit = null,
   @UserId                 TUserId       = null,
   @IsSmallPackageCarrier  TFlags        = null,
   @SCAC                   TShipVia      = null)
as
  declare @vReturnCode   TInteger,
          @vMessageName  TMessageName;
begin
  /* Initialize */
  select @vReturnCode  = 0,
         @vMessageName = null,
         @UserId       = coalesce(@UserId, 'cimsdba');

  /* Execute the delete action */
  if (charindex('D', @Action) > 0)
    delete S2
    from @ShipVias S1 cross join vwBusinessUnits BU
      join ShipVias S2 on (S1.ShipVia = S2.ShipVia)
    where (S2.Carrier      = @Carrier) and
          (S2.BusinessUnit = coalesce(@BusinessUnit, S1.BusinessUnit, BU.BusinessUnit));

  /* Perform the inserts if the Carrier + Shipvia doesn't exist */
  if (charindex('I', @Action) > 0)
    insert into ShipVias (Carrier, ShipVia, Description, CarrierServiceCode, Status,
                          SortSeq, BusinessUnit, StandardAttributes, ServiceClass, ServiceClassDesc, SCAC,
                          SpecialServices, IsSmallPackageCarrier, CreatedBy)
      select coalesce(S1.Carrier, @Carrier), S1.ShipVia, S1.Description, coalesce(S1.CarrierServiceCode, 'S'), S1.Status,
             coalesce(S1.SortSeq, S1.RecordId), coalesce(S1.BusinessUnit, BU.BusinessUnit), coalesce(S1.StandardAttributes, ''),
             cast(S1.StandardAttributes as xml).value('(/SERVICECLASS/node())[1]',      'TVarchar'),
             cast(S1.StandardAttributes as xml).value('(/SERVICECLASSDESC/node())[1]',  'TVarchar'),
             coalesce(S1.SCAC, @SCAC, cast(S1.StandardAttributes as xml).value('SCAC[1]', 'TTypeCode')),
             S1.SpecialServices, @IsSmallPackageCarrier, @UserId
      from @ShipVias S1 cross join vwBusinessUnits BU
        left outer join ShipVias S2 on (S2.Carrier      = coalesce(S1.Carrier, @Carrier)) and
                                       (S2.ShipVia      = S1.ShipVia) and
                                       (S2.BusinessUnit = coalesce(@BusinessUnit, S1.BusinessUnit, BU.BusinessUnit))
      where (S2.RecordId is null);

  /* Update existing records */
  if (charindex('U', @Action) > 0)
    update S1
    set Description           = coalesce(S2.Description,         S1.Description),
        ShipVia               = coalesce(S2.ShipVia,             S1.ShipVia),
        CarrierServiceCode    = coalesce(S2.CarrierServiceCode,  S1.CarrierServiceCode ),
        Status                = coalesce(S2.Status,              S1.Status),
        SortSeq               = coalesce(S2.SortSeq,             S1.SortSeq),
        ServiceClass          = coalesce(cast(S2.StandardAttributes as xml).value('(/SERVICECLASS/node())[1]',      'TVarchar'), S1.ServiceClass),
        ServiceClassDesc      = coalesce(cast(S2.StandardAttributes as xml).value('(/SERVICECLASSDESC/node())[1]',  'TVarchar'), S1.ServiceClassDesc),
        SCAC                  = coalesce(S2.SCAC,@SCAC, cast(S1.StandardAttributes as xml).value('SCAC[1]', 'TTypeCode')),
        StandardAttributes    = coalesce(S2.StandardAttributes,  S1.StandardAttributes, ''),
        SpecialServices       = coalesce(S2.SpecialServices,     S1.SpecialServices),
        IsSmallPackageCarrier = coalesce(@IsSmallPackageCarrier, IsSmallPackageCarrier),
        ModifiedBy            = @UserId,
        ModifiedDate          = current_timestamp
    from ShipVias S1 cross join vwBusinessUnits BU
      join @ShipVias S2 on (S1.Carrier      = coalesce(S2.Carrier, @Carrier)) and
                           (S1.ShipVia      = S2.ShipVia) and
                           (S1.BusinessUnit = coalesce(@BusinessUnit, S2.BusinessUnit, BU.BusinessUnit));

  /* Add Carrier to Standard Attibutes if it doesn't already exist */
  update S1
  set StandardAttributes  = S1.StandardAttributes + case when @Carrier is not null then dbo.fn_XMLNode('CARRIER', @Carrier)
                                                         else dbo.fn_XMLNode('CARRIER', S1.Carrier)
                                                    end
  from ShipVias S1 cross join vwBusinessUnits BU
    join @ShipVias S2 on (S1.Carrier      = coalesce(S2.Carrier, @Carrier)) and
                         (S1.ShipVia      = S2.ShipVia) and
                         (S1.BusinessUnit = coalesce(@BusinessUnit, S2.BusinessUnit, BU.BusinessUnit))
  where (charindex('<CARRIER>', S1.StandardAttributes) = 0);

  /* Add SCAC to Standard Attibutes if it doesn't already exist */
  update S1
  set StandardAttributes  = S1.StandardAttributes + case when @SCAC is not null  then dbo.fn_XMLNode('SCAC', @SCAC)
                                                         when S1.Carrier = 'LTL' then dbo.fn_XMLNode('SCAC', S1.ShipVia)
                                                         else                         dbo.fn_XMLNode('SCAC', S1.Carrier)
                                                    end
  from ShipVias S1 cross join vwBusinessUnits BU
    join @ShipVias S2 on (S1.Carrier      = coalesce(S2.Carrier, @Carrier)) and
                         (S1.ShipVia      = S2.ShipVia) and
                         (S1.BusinessUnit = coalesce(@BusinessUnit, S2.BusinessUnit, BU.BusinessUnit))
  where (charindex('<SCAC>', S1.StandardAttributes) = 0);

  /* Add CarrierServiceCode to Standard Attibutes if it doesn't already exist */
  update S1
  set StandardAttributes  = S1.StandardAttributes + dbo.fn_XMLNode('CARRIERSERVICECODE', S1.CarrierServiceCode)
  from ShipVias S1 cross join vwBusinessUnits BU
    join @ShipVias S2 on (S1.Carrier      = coalesce(S2.Carrier, @Carrier)) and
                         (S1.ShipVia      = S2.ShipVia) and
                         (S1.BusinessUnit = coalesce(@BusinessUnit, S2.BusinessUnit, BU.BusinessUnit))
  where (S1.CarrierServiceCode is not null) and
        (charindex('<CARRIERSERVICECODE>', S1.StandardAttributes) = 0);

  /* Add ServiceLevel to Standard Attibutes if it doesn't already exist */
  update S1
  set StandardAttributes  = S1.StandardAttributes + dbo.fn_XMLNode('ServiceLevel', S1.Description)
  from ShipVias S1 cross join vwBusinessUnits BU
    join @ShipVias S2 on (S1.Carrier      = coalesce(S2.Carrier, @Carrier)) and
                         (S1.ShipVia      = S2.ShipVia) and
                         (S1.BusinessUnit = coalesce(@BusinessUnit, S2.BusinessUnit, BU.BusinessUnit))
  where (charindex('<SERVICELEVEL>', S1.StandardAttributes) = 0);

ErrorHandler:
  if (@vMessageName is not null)
    exec @vReturnCode = pr_Messages_ErrorHandler @vMessageName;

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_Setup_Shipvias */

Go
