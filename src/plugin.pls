-- Kanban Board region plug-in (TechRevX, www.techrevx.com)
-- render: writes the board container and a JSON block with the settings and the cards, then calls
--         techrevx.kanban.init (kanban.js).
-- ajax:   x01 = LIST  returns the cards again (refresh)
--         x01 = MOVE  runs the Move Code with :ID (x02), :STATUS (x03), :POSITION (x04) and :ORDER (x05);
--                     the card must be a row of the region's source.
-- Cards: id, t (title), s (status), d (description), a (assignee), due (YYYY-MM-DD), l (label), c (color).

c_column_attrs constant apex_t_varchar2 := apex_t_varchar2(
    'ID_COLUMN', 'TITLE_COLUMN', 'STATUS_COLUMN', 'DESCRIPTION_COLUMN', 'ASSIGNEE_COLUMN', 'DUE_COLUMN', 'LABEL_COLUMN', 'COLOR_COLUMN' );
c_column_keys constant apex_t_varchar2 := apex_t_varchar2( 'id', 't', 's', 'd', 'a', 'due', 'l', 'c' );

-- writes "cards" to the current apex_json output; returns whether p_find_id is one of them
function write_cards( p_region in apex_plugin.t_region, p_find_id in varchar2 default null, p_write in boolean default true ) return boolean is
    l_names   apex_t_varchar2 := apex_t_varchar2();
    l_pos     apex_t_number   := apex_t_number();
    l_types   apex_t_number   := apex_t_number();
    l_columns apex_exec.t_columns;
    l_context apex_exec.t_context;
    l_added   boolean;
    l_found   boolean := false;
begin
    l_names.extend( c_column_attrs.count );
    l_pos.extend( c_column_attrs.count );
    l_types.extend( c_column_attrs.count );
    for i in 1 .. c_column_attrs.count loop
        l_names( i ) := p_region.attributes.get_varchar2( c_column_attrs( i ) );
        if l_names( i ) is not null then
            l_added := false;
            for j in 1 .. i - 1 loop
                l_added := l_added or nvl( l_names( j ) = l_names( i ), false );
            end loop;
            if not l_added then
                apex_exec.add_column( p_columns => l_columns, p_column_name => l_names( i ) );
            end if;
        end if;
    end loop;

    l_context := apex_exec.open_query_context( p_columns => l_columns, p_max_rows => 5000 );
    for i in 1 .. c_column_attrs.count loop
        if l_names( i ) is not null then
            l_pos( i ) := apex_exec.get_column_position( l_context, l_names( i ) );
            if l_pos( i ) is null then
                raise_application_error( -20001, 'Kanban Board: column ' || l_names( i ) || ' is not in the region source of "' || p_region.name || '".' );
            end if;
            l_types( i ) := apex_exec.get_column( l_context, l_pos( i ) ).data_type;
        end if;
    end loop;

    if p_write then
        apex_json.open_array( 'cards' );
    end if;
    while apex_exec.next_row( l_context ) loop
        if p_find_id is not null and apex_exec.get_varchar2( l_context, l_pos( 1 ) ) = p_find_id then
            l_found := true;
        end if;
        if p_write then
            apex_json.open_object;
            for i in 1 .. c_column_attrs.count loop
                if l_pos( i ) is not null then
                    if l_types( i ) = apex_exec.c_data_type_date then
                        apex_json.write( c_column_keys( i ), to_char( apex_exec.get_date( l_context, l_pos( i ) ), 'YYYY-MM-DD' ) );
                    elsif l_types( i ) in ( apex_exec.c_data_type_timestamp, apex_exec.c_data_type_timestamp_tz, apex_exec.c_data_type_timestamp_ltz ) then
                        apex_json.write( c_column_keys( i ), to_char( apex_exec.get_timestamp( l_context, l_pos( i ) ), 'YYYY-MM-DD' ) );
                    else
                        apex_json.write( c_column_keys( i ), apex_exec.get_varchar2( l_context, l_pos( i ) ) );
                    end if;
                end if;
            end loop;
            apex_json.close_object;
        end if;
    end loop;
    if p_write then
        apex_json.close_array;
    end if;
    apex_exec.close( l_context );
    return l_found;
exception
    when others then
        apex_exec.close( l_context );
        raise;
end write_cards;

procedure render (
    p_plugin in            apex_plugin.t_plugin,
    p_region in            apex_plugin.t_region,
    p_param  in            apex_plugin.t_region_render_param,
    p_result in out nocopy apex_plugin.t_region_render_result )
is
    l_json  clob;
    l_dummy boolean;
begin
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write( 'ajaxIdentifier', apex_plugin.get_ajax_identifier );
    apex_json.write( 'itemsToSubmit', apex_plugin_util.page_item_names_to_jquery( p_region.ajax_items_to_submit ) );
    apex_json.write( 'noDataFound', apex_plugin_util.replace_substitutions( p_region.no_data_found_message, false ) );
    apex_json.write( 'columns', apex_plugin_util.replace_substitutions( p_region.attributes.get_varchar2( 'COLUMNS' ), false ) );
    apex_json.write( 'features', p_region.attributes.get_varchar2( 'FEATURES' ) );
    apex_json.write( 'clickItem', p_region.attributes.get_varchar2( 'CLICK_ITEM' ) );
    apex_json.write( 'columnWidth', p_region.attributes.get_number( 'COLUMN_WIDTH' ) );
    apex_json.write( 'height', p_region.attributes.get_number( 'HEIGHT' ) );
    apex_json.write( 'canSave', p_region.attributes.get_varchar2( 'MOVE_CODE' ) is not null );
    l_dummy := write_cards( p_region );
    apex_json.close_object;
    l_json := apex_json.get_clob_output;
    apex_json.free_output;

    sys.htp.p( '<div id="' || apex_escape.html_attribute( p_region.static_id ) || '_kanban" class="tx-Kanban" style="--tx-kb-height:'
               || nvl( p_region.attributes.get_number( 'HEIGHT' ), 600 ) || 'px;--tx-kb-lane:' || nvl( p_region.attributes.get_number( 'COLUMN_WIDTH' ), 290 ) || 'px"></div>' );
    sys.htp.p( '<script type="application/json" id="' || apex_escape.html_attribute( p_region.static_id ) || '_cards">' );
    apex_util.prn( p_clob => replace( l_json, '</', '<\/' ), p_escape => false );
    sys.htp.p( '</script>' );
    dbms_lob.freetemporary( l_json );

    apex_javascript.add_onload_code(
        p_code => 'techrevx.kanban.init(' || apex_javascript.add_value( p_region.static_id, false ) || ');' );
end render;

procedure ajax (
    p_plugin in            apex_plugin.t_plugin,
    p_region in            apex_plugin.t_region,
    p_param  in            apex_plugin.t_region_ajax_param,
    p_result in out nocopy apex_plugin.t_region_ajax_result )
is
    l_code   varchar2( 32767 ) := p_region.attributes.get_varchar2( 'MOVE_CODE' );
    l_params apex_exec.t_parameters;
    l_dummy  boolean;

    -- apex_exec refuses binds the code does not use, so only pass the ones it mentions
    function uses( p_name in varchar2 ) return boolean is
    begin
        return regexp_like( l_code, ':' || p_name || '([^A-Za-z0-9_$#]|$)', 'i' );
    end uses;
begin
    if apex_application.g_x01 = 'MOVE' then
        if l_code is null then
            raise_application_error( -20002, 'Kanban Board: no Move Code.' );
        end if;
        if not write_cards( p_region, apex_application.g_x02, false ) then
            raise_application_error( -20003, 'Kanban Board: unknown card.' );
        end if;
        savepoint tx_kanban_move;
        if uses( 'ID' ) then
            apex_exec.add_parameter( l_params, 'ID', apex_application.g_x02 );
        end if;
        if uses( 'STATUS' ) then
            apex_exec.add_parameter( l_params, 'STATUS', apex_application.g_x03 );
        end if;
        if uses( 'POSITION' ) then
            apex_exec.add_parameter( l_params, 'POSITION', to_number( apex_application.g_x04 ) );
        end if;
        if uses( 'ORDER' ) then
            apex_exec.add_parameter( l_params, 'ORDER', apex_application.g_x05 );
        end if;
        begin
            apex_exec.execute_plsql( p_plsql_code => l_code, p_sql_parameters => l_params );
            apex_json.open_object;
            apex_json.write( 'moved', true );
            apex_json.close_object;
        exception
            when others then
                -- undo what the Move Code changed; its raise_application_error text is shown to the user
                rollback to tx_kanban_move;
                if sqlcode between -20999 and -20000 then
                    apex_debug.info( 'Kanban Board: Move Code refused card %s: %s', apex_application.g_x02, sqlerrm );
                else
                    apex_debug.error( 'Kanban Board: Move Code failed for card %s: %s', apex_application.g_x02, sqlerrm );
                end if;
                apex_json.open_object;
                apex_json.write( 'moved', false );
                apex_json.write( 'message', case when sqlcode between -20999 and -20000
                                                 then regexp_substr( sqlerrm, '^ORA-\d{5}: ([^' || chr( 10 ) || ']+)', 1, 1, null, 1 ) end );
                apex_json.close_object;
        end;
    else
        apex_json.open_object;
        l_dummy := write_cards( p_region );
        apex_json.close_object;
    end if;
end ajax;
