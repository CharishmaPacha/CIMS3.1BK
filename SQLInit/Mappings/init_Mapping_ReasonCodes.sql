/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2018/03/09  RT      Mapping set up for Reason codes (S2G-319)
  2016/03/29  NB      Replaced Target value 07 with 06. See comments(NBD-43)
  2016/01/15  NB      Mapping entries for reason codes(NBD-43)
  2015/09/01  OK      Initial Revision (CIMS-607).
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
ReasonCodes ->
 -----------------------------------------------------------------------------*/

declare @Mapping       TMapping,
        @SourceSystem  TName,
        @TargetSystem  TName,
        @EntityType    TName,
        @Operation     TOperation;

select  @SourceSystem = 'CIMS',
        @TargetSystem = 'HOST',
        @EntityType   = 'ReasonCode',
        @Operation    = null;

delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem)  and (EntityType = @EntityType );

/*------------------------------------------------------------------------------
 -----------------------------------------------------------------------------*/
insert into @Mapping
            (SourceValue, TargetValue)
/* 06   DEBIT Transaction */
      select LookUpCode, '06' from LookUps
             where LookUpCategory in ('RC_ShortPick', 'RC_LPNAdjust-', 'RC_LPNVoid')
union select LookUpCode, '06' from LookUps
             where LookUpCode in ('101' /* Cycle Count - Lost LPN */, '202' /* Cannot find Units */ )

/* 56   CREDIT Transaction */
union select LookUpCode, '56' from LookUps
             where LookUpCategory in ('RC_ShortPick', 'RC_LPNAdjust+', 'RC_LPNCreateInv', 'RC_ExplodePrepack', 'RC_Returns', 'RC_Disposition_BackToInv')
union select LookUpCode, '56' from LookUps
             where LookUpCode in ('203' /* Found Inventory */,  '204' /* New Inventory in Picklane */)

/* 07   Destroyed
   Vionics will not be using 07. Instead using 06
   */
union select LookUpCode, '06' from LookUps
             where LookUpCategory in ('RC_Disposition_Scrap')
union select LookUpCode, '06' from LookUps
             where LookUpCode in ('200' /* Product Damaged */)
/* 54   Receipt Greater than originally received */

/* AT   Pre-pack components */
union select LookUpCode, 'AT' from LookUps
             where LookUpCategory in ('RC_ExplodePrepack')

--exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
