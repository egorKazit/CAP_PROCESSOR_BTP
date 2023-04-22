@AbapCatalog.sqlViewName: 'ZYKZCAPITEM'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Thread item'
define view ZYKZR_ThreadItem
  as select from zykz_cap_item

  association [1] to ZYKZR_ThreadHeader as _ThreadHeader on $projection.ThreadUUID = _ThreadHeader.UUID

{
  key uuid          as UUID,
      threaduuid    as ThreadUUID,
      item          as Item,
      type          as Type,
      nameorcontent as NameOrContent,

      _ThreadHeader
}
