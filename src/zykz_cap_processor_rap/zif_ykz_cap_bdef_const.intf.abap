INTERFACE zif_ykz_cap_bdef_const
  PUBLIC .

  TYPES: BEGIN OF header,
           create         TYPE TABLE FOR CREATE ZYKZR_ThreadHeaderTP,
           read_import    TYPE TABLE FOR READ IMPORT ZYKZR_ThreadHeaderTP,
           read_result    TYPE TABLE FOR READ RESULT ZYKZR_ThreadHeaderTP,
           update         TYPE TABLE FOR UPDATE ZYKZR_ThreadHeaderTP,
           abandon_import TYPE TABLE FOR ACTION IMPORT ZYKZR_ThreadHeaderTP~Abandon,

           failed         TYPE RESPONSE FOR FAILED EARLY ZYKZR_ThreadHeaderTP,
           reported       TYPE RESPONSE FOR REPORTED EARLY ZYKZR_ThreadHeaderTP,
           mapped         TYPE RESPONSE FOR MAPPED EARLY ZYKZR_ThreadHeaderTP,

           statuses       TYPE TABLE OF zykz_cap_status WITH DEFAULT KEY,

         END OF header,
         BEGIN OF item,
           create_by TYPE TABLE FOR CREATE ZYKZR_ThreadHeaderTP\_ThreadItemTP,
         END OF item.

ENDINTERFACE.
