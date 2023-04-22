@AbapCatalog.sqlViewName: 'ZYKZCAPTHREAD'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Thread header'
define view ZYKZR_ThreadHeader
  as select from zykz_cap_thread

  association [0..*] to ZYKZR_ThreadItem as _ThreadItem on $projection.UUID = _ThreadItem.ThreadUUID

{
  key uuid          as UUID,
      thread        as Thread,
      name          as Name,
      status        as Status,
      sourceuuid    as SourceUUID,
      processedflag as ProcessedFlag,

      _ThreadItem
}
