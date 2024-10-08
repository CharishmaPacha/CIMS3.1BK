/*------------------------------------------------------------------------------
  Copyright (c) Foxfire Technologies (India) Ltd.  All rights reserved

  Revision History:

  Date        Person  Comments

  2018/02/13  TK      fn_Tasks_EvaluateDependencies: Initial Revision (S2G-179)
------------------------------------------------------------------------------*/

Go

if object_id('dbo.fn_Tasks_EvaluateDependencies') is not null
  drop Function dbo.fn_Tasks_EvaluateDependencies;
Go
/*------------------------------------------------------------------------------
  Function fn_Tasks_EvaluateDependencies: Function evaluates dependencies from given table
    and decides dependency
------------------------------------------------------------------------------*/
Create Function fn_Tasks_EvaluateDependencies
  (@Dependencies    TDependencies ReadOnly)
  -----------------------------------------
   returns TFlags
as
begin
  declare @vDependencyFlags  TFlags;

  /* If any one task detail is short then whole task would be short */
  if exists(select * from @Dependencies where DependencyFlags = 'S'/* Short */)
    set @vDependencyFlags = 'S'/* Short */;
  else
  /* If any one task detail is Waiting on Replenishment then whole task would be Waiting on Replenishment */
  if exists(select * from @Dependencies where DependencyFlags = 'R'/* Waiting on Repl. */)
    set @vDependencyFlags = 'R'/* Waiting on Replenishment */;
  else
  /* If any one task detail is May be Available then whole task would be May be Available */
  if exists(select * from @Dependencies where DependencyFlags = 'M'/* May be Available */)
    set @vDependencyFlags = 'M'/* May be Available */;
  else
    set @vDependencyFlags = 'N'/* No Dependency */;

  return(@vDependencyFlags);
end /* fn_Tasks_EvaluateDependencies */

Go
