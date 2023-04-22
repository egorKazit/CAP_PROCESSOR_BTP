CLASS zcl_ykz_complete_entry_job DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ts_content_type.
        INCLUDE TYPE ZYKZR_ThreadHeaderTP.
    TYPES: items TYPE STANDARD TABLE OF ZYKZR_ThreadItemTP WITH DEFAULT KEY,
      END OF ts_content_type.

    CONSTANTS p_thread_id TYPE c LENGTH 8 VALUE 'P_THR_ID'.

    INTERFACES if_apj_dt_exec_object .
    INTERFACES if_apj_rt_exec_object .

  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS zcl_ykz_complete_entry_job IMPLEMENTATION.


  METHOD if_apj_dt_exec_object~get_parameters.

    " Return the supported selection parameters here
    et_parameter_def = VALUE #(
     ( selname        = p_thread_id
       kind           = if_apj_dt_exec_object=>parameter
       datatype       = 'C'
       length         =  32
       param_text     = 'Thread Id'
       changeable_ind = abap_true
       mandatory_ind  = abap_true
       )
    ).

    " Return the default parameters values here
    et_parameter_val = VALUE #(
      ( selname = p_thread_id
        kind    = if_apj_dt_exec_object=>parameter
        sign    = 'I'
        option  = 'EQ'
        low     = 1 ) ).

  ENDMETHOD.


  METHOD if_apj_rt_exec_object~execute.

    ASSERT lines( it_parameters ) > 0.
    ASSERT line_exists( it_parameters[ selname = p_thread_id ] ).
    ASSERT it_parameters[ selname = p_thread_id ]-low IS NOT INITIAL.

    DATA(thread_uuid) = it_parameters[ selname = p_thread_id ]-low.

    READ ENTITIES OF ZYKZR_ThreadHeaderTP
      ENTITY ThreadHeader
      ALL FIELDS WITH VALUE #( ( uuid = CONV #( thread_uuid ) ) )
      RESULT DATA(header)
      ENTITY ThreadHeader BY \_ThreadItemTP
      ALL FIELDS WITH VALUE #( ( uuid = CONV #( thread_uuid ) ) )
      RESULT DATA(items).

    ASSERT header IS NOT INITIAL.

    DATA(content) = NEW ts_content_type( ).
    content->* = CORRESPONDING #( header[ 1 ] ).
    content->items = CORRESPONDING #( items ).

    DATA(content_in_json) = /ui2/cl_json=>serialize( content->* ).
    DATA(content_in_raw) = /ui2/cl_json=>string_to_raw( content_in_json ).

    SELECT COUNT( * )
      FROM zykz_cap_thd_arh
      WHERE uuid = @thread_uuid
      INTO @DATA(lines).

    IF lines = 0.
      " create new
      DATA(zykz_cap_thd_arh_struct) = NEW zykz_cap_thd_arh( client  = sy-mandt
                                                            uuid    = thread_uuid
                                                            content = content_in_raw ).
      INSERT zykz_cap_thd_arh FROM @zykz_cap_thd_arh_struct->*.
    ELSE.
      " update existing
      UPDATE zykz_cap_thd_arh
        SET content = @content_in_raw
        WHERE uuid  = @thread_uuid.
    ENDIF.
    COMMIT WORK.
  ENDMETHOD.
ENDCLASS.
