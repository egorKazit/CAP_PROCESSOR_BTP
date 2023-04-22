@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Thread item BO'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZYKZR_ThreadItemTP
  as select from ZYKZR_ThreadItem

  association to parent ZYKZR_ThreadHeaderTP as _ThreadHeaderTP on $projection.ThreadUUID = _ThreadHeaderTP.UUID

{
  key UUID,
      ThreadUUID,
      Item,
      Type,
      NameOrContent,
      /* Associations */
      _ThreadHeaderTP
}
