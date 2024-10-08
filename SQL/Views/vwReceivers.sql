/*------------------------------------------------------------------------------
  Copyright (c) Supply Chain Technologies.  All rights reserved.

  Revision History:

  Date        Person  Comments

  2020/06/25  NB      Receivers: Added Warehouse field(CIMSV3-987)
  2020/03/15  AY      Receiver: Removed UserId field
  2020/03/12  MS      Added ReceiverStatus & ReceiverStatusDesc (CIMSV3-750)
  2017/05/04  LRA     Changes to resolve the truncate issue with data (CIMS-1326)
  2016/08/09  PSK     Changed the vwUDF's to use cast(' ' as varchar(50)).(CIMS-1027).
  2014/04/23  SV      Added Archived field
  2014/04/14  VM      Added Container & Reference fields
  2014/03/01  PKS     Initial revision.
------------------------------------------------------------------------------*/

Go

/*------------------------------------------------------------------------------
  Table: vwReceivers
------------------------------------------------------------------------------*/
Go

if object_id('dbo.vwReceivers') is not null
  drop View dbo.vwReceivers;
Go

Create View vwReceivers (
  ReceiverId,
  ReceiverNumber,
  ReceiverDate,
  ReceiverStatus,
  ReceiverStatusDesc,
  Status,  -- deprecated

  BoLNumber,
  Container,
  Warehouse,
  /* Below are deprecated, use ReceiverRef fields */
  Reference1,
  Reference2,
  Reference3,
  Reference4,
  Reference5,

  ReceiverRef1,
  ReceiverRef2,
  ReceiverRef3,
  ReceiverRef4,
  ReceiverRef5,

  /* Below are deprecated, use custom UDF fields */
  UDF1,
  UDF2,
  UDF3,
  UDF4,
  UDF5,

  vwUDF1,
  vwUDF2,
  vwUDF3,
  vwUDF4,
  vwUDF5,

  RCV_UDF1,
  RCV_UDF2,
  RCV_UDF3,
  RCV_UDF4,
  RCV_UDF5,

  vwRCV_UDF1,
  vwRCV_UDF2,
  vwRCV_UDF3,
  vwRCV_UDF4,
  vwRCV_UDF5,

  Archived,
  BusinessUnit,
  CreatedDate,
  CreatedBy,
  ModifiedDate,
  ModifiedBy
)
as
select
  R.ReceiverId,
  R.ReceiverNumber,
  R.ReceiverDate,
  R.Status,
  S.StatusDescription,
  R.Status,   -- Status, deprecated

  R.BoLNumber,
  R.Container,
  R.Warehouse,

  R.Reference1,
  R.Reference2,
  R.Reference3,
  R.Reference4,
  R.Reference5,

  R.Reference1,
  R.Reference2,
  R.Reference3,
  R.Reference4,
  R.Reference5,

  R.UDF1,
  R.UDF2,
  R.UDF3,
  R.UDF4,
  R.UDF5,

  cast(' ' as varchar(50)), /* vwUDF1 */
  cast(' ' as varchar(50)), /* vwUDF2 */
  cast(' ' as varchar(50)), /* vwUDF3 */
  cast(' ' as varchar(50)), /* vwUDF4 */
  cast(' ' as varchar(50)), /* vwUDF5 */

  R.UDF1,
  R.UDF2,
  R.UDF3,
  R.UDF4,
  R.UDF5,

  cast(' ' as varchar(50)), /* vwRCV_UDF1 */
  cast(' ' as varchar(50)), /* vwRCV_UDF2 */
  cast(' ' as varchar(50)), /* vwRCV_UDF3 */
  cast(' ' as varchar(50)), /* vwRCV_UDF4 */
  cast(' ' as varchar(50)), /* vwRCV_UDF5 */

  R.Archived,
  R.BusinessUnit,
  R.CreatedDate,
  R.CreatedBy,
  R.ModifiedDate,
  R.ModifiedBy
from Receivers R
  left outer join Statuses S on (R.Status       = S.StatusCode  ) and
                                (S.Entity       = 'Receiver'    ) and
                                (S.BusinessUnit = R.BusinessUnit)

Go
