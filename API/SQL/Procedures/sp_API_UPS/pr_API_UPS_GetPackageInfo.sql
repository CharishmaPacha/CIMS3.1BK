/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2024/10/01  RV      Delete the null or empty references from temp table to not build in JSON without reference values (CIMSV3-3835)
  2024/05/17  VS      pr_API_UPS_GetPackageInfo: For UPS Sure Post Less Than 1LB Service Weight Should be in OZS instead of LBS (CIDV3-817)
  2024/05/06  VIB     Replaced fn_ConvertStringToDataSet with string_split function (CIMSV3-3606)
  2023/04/27  RV      pr_API_UPS_GetPackageInfo: Made changes to convert to Ounces for Mail services (JLFL-321)
  2023/04/12  RV      pr_API_UPS_GetPackageInfo: Made changes to send the Package SKU description as Mexican shipment requires package description (BK-1042)
  2021/06/18  TK      pr_API_UPS_GetPackageInfo: Use substring only if there is a colon':' in the value (BK-369)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.pr_API_UPS_GetPackageInfo') is not null
  drop Procedure pr_API_UPS_GetPackageInfo;
Go
/*------------------------------------------------------------------------------
  Proc pr_API_UPS_GetPackageInfo:
   This proc returns multiple packages with references in json format. We may have multiple
     packages in a shipment and each package may have multiple references, So we should build the
     array of references and array of packages.
   Sample output:
   [
   {
      "Description":"NORD",
      "Packaging":{
         "Code":"02"
      },
      "PackageWeight":{
         "UnitOfMeasurement":{
            "Code":"LBS"
         },
         "Weight":"7.5"
      },
      "ReferenceNumber":[
         {
            "BarCodeIndicator":"",
            "Code":"SE",
            "Value":"S000005775-0000053694"
         },
         {
            "Code":" PO",
            "Value":"3688285-6203360"
         }
      ]
   },
   {
      "Description":"NORD",
      "Packaging":{
         "Code":"02"
      },
      "PackageWeight":{
         "UnitOfMeasurement":{
            "Code":"LBS"
         },
         "Weight":"7.5"
      },
      "ReferenceNumber":[
         {
            "BarCodeIndicator":"",
            "Code":"SE",
            "Value":"S000005776-0000053695"
         },
         {
            "Code":" PO",
            "Value":"3688285-6203360"
         }
      ]
   }
]
------------------------------------------------------------------------------*/
Create Procedure pr_API_UPS_GetPackageInfo
  (@InputXML        xml,
   @BusinessUnit    TBusinessUnit,
   @UserId          TUserId,
   @PackageInfoJSON TNVarchar output)
as
  declare @vReturnCode             TInteger,
          @vMessageName            TMessageName,
          @vRecordId               TRecordId,

          @vServiceCode            TTypeCode,
          @vDimensionUoM           TUoM,
          @vWeightUoM              TUoM,
          @vReference1             TReference,
          @vReference2             TReference,
          @vReference3             TReference,
          @vReference4             TReference,
          @vReference5             TReference,

          @vReferencesJSON         TNVarChar,

          @vBusinessUnit           TBusinessUnit,
          @vUserId                 TUserId;

  declare @ttPackageInfo table(RecordId        TRecordId identity(1,1),
                               LPN             TLPN,
                               SKUDescription  TDescription,
                               CartonTypeDesc  TDescription,
                               PackageType     TDescription,
                               PackageLength   TLength,
                               PackageWidth    TWidth,
                               PackageHeight   THeight,
                               PackageWeight   TWeight,
                               PackageWeightOz TWeight,
                               Reference1      TReference,
                               Reference2      TReference,
                               Reference3      TReference,
                               Reference4      TReference,
                               Reference5      TReference,
                               ReferenceJSON   TNVarchar);

  declare @ttReferences       table (BarCodeIndicator TReference,
                                     Code             TReference,
                                     Value            TReference);
begin /* pr_API_UPS_GetPackageInfo */
  SET NOCOUNT ON;

  /* Initialize */
  select @vReturnCode   = 0,
         @vMessageName  = null,
         @vRecordId     = 0,
         @vWeightUoM    = 'LBS',
         @vDimensionUoM = 'IN';

  /* Extract the Packages information */
  insert into @ttPackageInfo(SKUDescription, CartonTypeDesc, PackageType, PackageLength, PackageWidth, PackageHeight, PackageWeight, PackageWeightOz,
                             Reference1, Reference2, Reference3, Reference4, Reference5)
    select Record.Col.value('(CONTAINERHEADER/SKUDescription)[1]',  'TDescription'),
           Record.Col.value('(CARTONDETAILS/Description)[1]',       'TDescription'),
           dbo.fn_GetMappedValue('CIMS', Record.Col.value('(CARTONDETAILS/CarrierPackagingType)[1]', 'TDescription'), 'UPSAPI', 'PackagingType', null, @BusinessUnit),
           Record.Col.value('(CARTONDETAILS/InnerLength)[1]',       'TLength'),
           Record.Col.value('(CARTONDETAILS/InnerWidth)[1]',        'TWidth'),
           Record.Col.value('(CARTONDETAILS/InnerHeight)[1]',       'THeight'),
           Record.Col.value('(CONTAINERHEADER/PackageWeight)[1]',   'TWeight'),
           Record.Col.value('(CONTAINERHEADER/PackageWeightOz)[1]', 'TWeight'),
           Record.Col.value('(REFERENCE/REFERENCE1)[1]',            'TREFERENCE'),
           Record.Col.value('(REFERENCE/REFERENCE2)[1]',            'TREFERENCE'),
           Record.Col.value('(REFERENCE/REFERENCE3)[1]',            'TREFERENCE'),
           Record.Col.value('(REFERENCE/REFERENCE4)[1]',            'TREFERENCE'),
           Record.Col.value('(REFERENCE/REFERENCE5)[1]',            'TREFERENCE')
    from @InputXML.nodes('/SHIPPINGINFO/REQUEST/PACKAGES/PACKAGE') Record(Col)
    OPTION (OPTIMIZE FOR ( @InputXML = null));

  select @vServiceCode = dbo.fn_GetMappedValue('CIMS', Record.Col.value('CARRIERSERVICECODE[1]', 'TDescription'), 'UPSAPI', 'ShipVia', null, @BusinessUnit)
  from @InputXML.nodes('/SHIPPINGINFO/REQUEST/SHIPVIA') Record(Col);

  /* Unit of Measurement "OZS" is the only valid UOM for some of the Mail Innovations Forward Shipments and Sure post less than 1 LB
     UPS API Document Page No:84 */
  if (@vServiceCode in ('M2', /* UPS First-Class Mail */ '92' /* UPS Sure Post Less Than 1LB */))
    select @vWeightUoM = 'OZS';

  /* Update Package's reference json for all Packages */
  while (exists(select * from @ttPackageInfo where RecordId > @vRecordId))
    begin
      select top 1 @vReference1 = Reference1,
                   @vReference2 = Reference2,
                   @vReference3 = Reference3,
                   @vReference4 = Reference4,
                   @vReference5 = Reference5,
                   @vRecordId   = RecordId
      from @ttPackageInfo
      where (RecordId > @vRecordId)
      order by RecordId;

      /* Parse the references, as each reference separed with semi colon and code and value separated with colon */
      /* BarCodeIndicator: If the indicator is present then the reference numbers value will be bar coded on the label */
      insert into @ttReferences (BarCodeIndicator, Code, Value)
        select null, case when charindex(':', @vReference1) > 0 then substring(Value, 1, charindex(':', Value)-1) else @vReference1 end,
                     case when charindex(':', @vReference1) > 0 then substring(Value, charindex(':', Value) +1, len(Value)- charindex(':', Value) +1) else @vReference1 end
        from string_split(@vReference1, ';')
        union all
        select null, case when charindex(':', @vReference2) > 0 then substring(Value, 1, charindex(':', Value)-1) else @vReference2 end,
                     case when charindex(':', @vReference2) > 0 then substring(Value, charindex(':', Value) +1, len(Value)- charindex(':', Value) +1)  else @vReference2 end
        from string_split(@vReference2, ';')
        union all
        select null, case when charindex(':', @vReference3) > 0 then substring(Value, 1, charindex(':', Value)-1) else @vReference3 end,
                     case when charindex(':', @vReference3) > 0 then substring(Value, charindex(':', Value) +1, len(Value)- charindex(':', Value) +1) else @vReference3 end
        from string_split(@vReference3, ';')
        union all
        select null, case when charindex(':', @vReference4) > 0 then substring(Value, 1, charindex(':', Value)-1) else @vReference4 end,
                     case when charindex(':', @vReference4) > 0 then substring(Value, charindex(':', Value) +1, len(Value)- charindex(':', Value) +1) else @vReference4 end
        from string_split(@vReference4, ';')
        union all
        select null, case when charindex(':', @vReference5) > 0 then substring(Value, 1, charindex(':', Value)-1) else @vReference5 end,
                     case when charindex(':', @vReference5) > 0 then substring(Value, charindex(':', Value) +1, len(Value)- charindex(':', Value) +1) else @vReference5 end
        from string_split(@vReference5, ';')

      /* Delete the empty or null references to prevent errors with the carrier when building the JSON */
      delete from @ttReferences where (coalesce(Code, '') = '') or (coalesce(Value, '') = '');

      /* Build reference json
         Note: If the BarCodeIndicator is present then the reference numbers value will be bar coded on the label.. */
      select @vReferencesJSON = (select BarCodeIndicator, Code, Value
                                 from @ttReferences
                                 FOR JSON PATH);

      /* Update the Refernces json on the respective package */
      update ttPI
      set ttPI.ReferenceJSON = @vReferencesJSON
      from @ttPackageInfo ttPI
      where RecordId = @vRecordId

      delete from @ttReferences;
    end

  /* Build packages json */
  select @PackageInfoJSON = (select [Description]                          = SKUDescription,
                                    [Packaging.Code]                       = PackageType,
                                    [Packaging.Description]                = LPN,
                                    [Dimensions.UnitOfMeasurement.Code]    = @vDimensionUoM,
                                    [Dimensions.Length]                    = cast(PackageLength as varchar(max)),
                                    [Dimensions.Width]                     = cast(PackageWidth as varchar(max)),
                                    [Dimensions.Height]                    = cast(PackageHeight as varchar(max)),
                                    [PackageWeight.UnitOfMeasurement.Code] = @vWeightUoM,
                                    [PackageWeight.Weight]                 = cast(iif (@vWeightUoM = 'OZS', PackageWeightOz, PackageWeight) as varchar(max)),
                                    [ReferenceNumber]                      = JSON_QUERY(ReferenceJSON)
                             from @ttPackageInfo
                             FOR JSON PATH);

ExitHandler:
  return(coalesce(@vReturnCode, 0));
end /* pr_API_UPS_GetPackageInfo */

Go
