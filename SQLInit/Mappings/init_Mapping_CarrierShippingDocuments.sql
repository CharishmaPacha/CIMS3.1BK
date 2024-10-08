/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  This file defines the mapping between cims shipping document codes and Shipping Interface shipping document Codes
  This mapping will define the values expected by Shipping Interface implementation

  Revision History:

  Date        Person  Comments

  2024/02/24  RV      Initial Revision (CIMSV3-3434)
------------------------------------------------------------------------------*/

declare @Mapping       TMapping,
        @SourceSystem  TName,
        @TargetSystem  TName,
        @EntityType    TName,
        @Operation     TOperation;

select  @SourceSystem = 'CIMS',
        @TargetSystem = 'CIMSFedEx2',
        @EntityType   = 'CarrierShippingDocumentType',
        @Operation    = null;

delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem)  and (EntityType = @EntityType );

/*------------------------------------------------------------------------------
 -----------------------------------------------------------------------------*/
insert into @Mapping
             (SourceValue,               TargetValue)
      select  'COO',                     'CERTIFICATE_OF_ORIGIN'
union select  'CI',                      'COMMERCIAL_INVOICE'
union select  'DGSD',                    'DANGEROUS_GOODS_SHIPPERS_DECLARATION'
union select  'OP900',                   'OP_900'
union select  'PFI',                     'PRO_FORMA_INVOICE'
union select  'RI',                      'RETURN_INSTRUCTIONS'

exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
