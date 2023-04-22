@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Thread header BO'
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZYKZR_ThreadHeaderTP
  as select from ZYKZR_ThreadHeader
  composition [*] of ZYKZR_ThreadItemTP as _ThreadItemTP
{
  key UUID,
      SourceUUID,
      Thread,
      Name,
      Status,
      ProcessedFlag,
      /* Associations */
      _ThreadItemTP
}
