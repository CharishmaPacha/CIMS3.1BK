/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2020/09/29  RIA     Clean-up (CIMSV3-622)
  2019/12/22  RIA     Changes to form methods (CIMSV3-622)
  2019/12/20  RIA     Changes to workflow (CIMSV3-622)
  2019/09/06  RIA     Initial Revision(CID-996)
------------------------------------------------------------------------------*/

declare @vWorkFlowName TName;

select @vWorkFlowName = 'Packing_OrderPacking';

delete from AMF_WorkFlowDetails where WorkFlowName = @vWorkFlowName;
insert into AMF_WorkFlowDetails
            (FormSequence, FormCondition,                             FormName,                      FormMethod,                                    WorkFlowName,   BusinessUnit)
      select 1,            null,                                      'Packing_ScanOrder',           'pr_AMF_Packing_OrderPacking_Start',           @vWorkFlowName, BusinessUnit from vwBusinessUnits
union select 2,            '~ShipTo~ <> ''''',                        'Packing_ClosePackage',        'pr_AMF_Packing_OrderPacking_ClosePackage',    @vWorkFlowName, BusinessUnit from vwBusinessUnits
union select 3,            '~OrderId~ > ''0''',                       'Packing_ScanPackOrder',       'pr_AMF_Packing_OrderPacking_ScanComplete',    @vWorkFlowName, BusinessUnit from vwBusinessUnits
union select 4,            '~OrderId~ = ''''',                        'Packing_ScanOrder',           'pr_AMF_Packing_OrderPacking_ScanComplete',    @vWorkFlowName, BusinessUnit from vwBusinessUnits

Go

 -- Remove BusinessUnits from here

 -- Temp Table for AMFWorkFlowDetails
 -- New Procedure to insert Data

