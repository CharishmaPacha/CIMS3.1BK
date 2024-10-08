/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2021/04/12  TK      fn_API_6River_PickWave_BuildArrayOfContainerInfo: Initial Revision (CID-1778)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_API_6River_PickWave_BuildArrayOfContainerInfo') is not null
  drop Function fn_API_6River_PickWave_BuildArrayOfContainerInfo;
Go
/*------------------------------------------------------------------------------
  fn_API_6River_PickWave_BuildArrayOfContainerInfo: Returns the customized array of Container info for 6River

  Function will return identifiers in the following format

  when CartonType = 'BAG-14x19'
    { "containerID": "S000713065", "containerType": [ "T4", "T2" ] }

  when Carton Type is other than Bag then
    { "containerID": "S000713065", "containerType": "BAG-14x19" }

------------------------------------------------------------------------------*/
Create Function fn_API_6River_PickWave_BuildArrayOfContainerInfo
  (@TaskDetailId  TRecordId)
  --------------------------
   returns        TVarChar
as
begin
  declare @vContainerInfoArray    TVarchar;

  /* Build Container Info Array */
  select @vContainerInfoArray = (select case when CartonType = 'BAG-14x19' then '{"containerID":"' + TempLabel + '","containerType":["T4","T2"]}'
                                             else '{"containerID":"' + TempLabel +'","containerType":"' + CartonType +'"}'
                                        end
                                 from vwUIPickTaskDetails
                                 where (TaskDetailId = @TaskDetailId));

  return (@vContainerInfoArray);
end /* fn_API_6River_PickWave_BuildArrayOfContainerInfo */

Go
