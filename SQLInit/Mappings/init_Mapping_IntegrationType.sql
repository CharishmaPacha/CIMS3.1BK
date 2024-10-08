/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/12/05  DA      pr_Mapping_Setup rename as pr_Setup_Mapping (CIMS-2219)
  2016/03/22  NB      Added Vionics-InventoryChange to EDI Export set(NBD-286)
                      Script corrections to properly clear/insert mapping data
  2016/02/19  TK      Mapping set up for OnHand Inventory (NBD-132)
  2016/02/10  NB      Ownercode corrected KUIU->KUU(NBD-108)
  2016/02/05  NB      Minor Syntax correction
  2016/01/27  TK      Initial Revision (FB-310).
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  IntegrationType -> Ownership, TransType
------------------------------------------------------------------------------*/
declare @Mapping       TMapping,
        @SourceSystem  TName      = 'CIMS',
        @TargetSystem  TName      = 'HOST',
        @EntityType    TEntity    = 'Ownership',
        @Operation     TOperation = 'Integration';

delete from Mapping where (SourceSystem = @SourceSystem) and (TargetSystem = @TargetSystem) and
                          (EntityType = @EntityType) and (Operation = @Operation);

insert into @Mapping
       (SourceValue,         TargetValue     )
values ('ExportTrans_CSV',   'KUU,Recv'      ),
       ('ExportTrans_CSV',   'KUU,InvCh'     ),
       ('ExportTrans_EDI',   'KUU,Ship'      ),
       ('ExportTrans_EDI',   'CHR,Recv'      ),
       ('ExportTrans_EDI',   'CHR,Ship'      ),
       ('ExportTrans_EDI',   'VSL,InvCh'     ),
       ('ExportINVOH_CSV',   'KUU'           );

--exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go

/*------------------------------------------------------------------------------
  IntegrationType -> Ownership for IOH Export
------------------------------------------------------------------------------*/
declare @Mapping       TMapping,
        @SourceSystem  TName      = 'CIMS',
        @TargetSystem  TName      = 'HOST',
        @EntityType    TEntity    = 'Ownership',
        @Operation     TOperation = 'Integration';

delete from Mapping where EntityType = @EntityType;

insert into @Mapping
       (SourceValue,            TargetValue     )
values ('ExportINVOH_CSV',      'KUU'      );

--exec pr_Setup_Mapping @Mapping, @SourceSystem, @TargetSystem, @EntityType, @Operation;

Go
