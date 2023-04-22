CLASS zcl_ykz_cap_cleaner DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ykz_cap_cleaner IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DELETE FROM zykz_cap_thread.
    DELETE FROM zykz_cap_item.
    COMMIT WORK.
  ENDMETHOD.
ENDCLASS.
