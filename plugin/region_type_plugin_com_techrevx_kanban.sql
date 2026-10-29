prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- Oracle APEX export file
--
-- You should run this script using a SQL client connected to the database as
-- the owner (parsing schema) of the application or as a database user with the
-- APEX_ADMINISTRATOR_ROLE role.
--
-- This export file has been automatically generated. Modifying this file is not
-- supported by Oracle and can lead to unexpected application and/or instance
-- behavior now or in the future.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2026.04.07'
,p_release=>'26.2.0'
,p_default_workspace_id=>6202419497391597
,p_default_application_id=>100
,p_default_id_offset=>0
,p_default_owner=>'AAMIRKHANZ'
);
end;
/
 
prompt APPLICATION 100 - Apex Plug-ins
--
-- Application Export:
--   Application:     100
--   Name:            Apex Plug-ins
--   Date and Time:   09:17 Thursday October 29, 2026
--   Exported By:     AAMIRKHANZ
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 6120805635550131
--   Manifest End
--   Version:         26.2.0
--   Instance ID:     2400160207269871
--

begin
  -- replace components
  wwv_flow_imp.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/region_type/com_techrevx_kanban
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(6120805635550131)
,p_plugin_type=>'REGION TYPE'
,p_name=>'COM.TECHREVX.KANBAN'
,p_display_name=>'Kanban Board'
,p_apexlang_name=>'kanban'
,p_javascript_file_urls=>wwv_flow_string.join(wwv_flow_t_varchar2(
'#PLUGIN_FILES#Sortable.min.js',
'#PLUGIN_FILES#kanban.js'))
,p_css_file_urls=>'#PLUGIN_FILES#kanban.css'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- Kanban Board region plug-in (TechRevX, www.techrevx.com)',
'-- render: writes the board container and a JSON block with the settings and the cards, then calls',
'--         techrevx.kanban.init (kanban.js).',
'-- ajax:   x01 = LIST  returns the cards again (refresh)',
'--         x01 = MOVE  runs the Move Code with :ID (x02), :STATUS (x03), :POSITION (x04) and :ORDER (x05);',
'--                     the card must be a row of the region''s source.',
'-- Cards: id, t (title), s (status), d (description), a (assignee), due (YYYY-MM-DD), l (label), c (color).',
'',
'c_column_attrs constant apex_t_varchar2 := apex_t_varchar2(',
'    ''ID_COLUMN'', ''TITLE_COLUMN'', ''STATUS_COLUMN'', ''DESCRIPTION_COLUMN'', ''ASSIGNEE_COLUMN'', ''DUE_COLUMN'', ''LABEL_COLUMN'', ''COLOR_COLUMN'' );',
'c_column_keys constant apex_t_varchar2 := apex_t_varchar2( ''id'', ''t'', ''s'', ''d'', ''a'', ''due'', ''l'', ''c'' );',
'',
'-- writes "cards" to the current apex_json output; returns whether p_find_id is one of them',
'function write_cards( p_region in apex_plugin.t_region, p_find_id in varchar2 default null, p_write in boolean default true ) return boolean is',
'    l_names   apex_t_varchar2 := apex_t_varchar2();',
'    l_pos     apex_t_number   := apex_t_number();',
'    l_types   apex_t_number   := apex_t_number();',
'    l_columns apex_exec.t_columns;',
'    l_context apex_exec.t_context;',
'    l_added   boolean;',
'    l_found   boolean := false;',
'begin',
'    l_names.extend( c_column_attrs.count );',
'    l_pos.extend( c_column_attrs.count );',
'    l_types.extend( c_column_attrs.count );',
'    for i in 1 .. c_column_attrs.count loop',
'        l_names( i ) := p_region.attributes.get_varchar2( c_column_attrs( i ) );',
'        if l_names( i ) is not null then',
'            l_added := false;',
'            for j in 1 .. i - 1 loop',
'                l_added := l_added or nvl( l_names( j ) = l_names( i ), false );',
'            end loop;',
'            if not l_added then',
'                apex_exec.add_column( p_columns => l_columns, p_column_name => l_names( i ) );',
'            end if;',
'        end if;',
'    end loop;',
'',
'    l_context := apex_exec.open_query_context( p_columns => l_columns, p_max_rows => 5000 );',
'    for i in 1 .. c_column_attrs.count loop',
'        if l_names( i ) is not null then',
'            l_pos( i ) := apex_exec.get_column_position( l_context, l_names( i ) );',
'            if l_pos( i ) is null then',
'                raise_application_error( -20001, ''Kanban Board: column '' || l_names( i ) || '' is not in the region source of "'' || p_region.name || ''".'' );',
'            end if;',
'            l_types( i ) := apex_exec.get_column( l_context, l_pos( i ) ).data_type;',
'        end if;',
'    end loop;',
'',
'    if p_write then',
'        apex_json.open_array( ''cards'' );',
'    end if;',
'    while apex_exec.next_row( l_context ) loop',
'        if p_find_id is not null and apex_exec.get_varchar2( l_context, l_pos( 1 ) ) = p_find_id then',
'            l_found := true;',
'        end if;',
'        if p_write then',
'            apex_json.open_object;',
'            for i in 1 .. c_column_attrs.count loop',
'                if l_pos( i ) is not null then',
'                    if l_types( i ) = apex_exec.c_data_type_date then',
'                        apex_json.write( c_column_keys( i ), to_char( apex_exec.get_date( l_context, l_pos( i ) ), ''YYYY-MM-DD'' ) );',
'                    elsif l_types( i ) in ( apex_exec.c_data_type_timestamp, apex_exec.c_data_type_timestamp_tz, apex_exec.c_data_type_timestamp_ltz ) then',
'                        apex_json.write( c_column_keys( i ), to_char( apex_exec.get_timestamp( l_context, l_pos( i ) ), ''YYYY-MM-DD'' ) );',
'                    else',
'                        apex_json.write( c_column_keys( i ), apex_exec.get_varchar2( l_context, l_pos( i ) ) );',
'                    end if;',
'                end if;',
'            end loop;',
'            apex_json.close_object;',
'        end if;',
'    end loop;',
'    if p_write then',
'        apex_json.close_array;',
'    end if;',
'    apex_exec.close( l_context );',
'    return l_found;',
'exception',
'    when others then',
'        apex_exec.close( l_context );',
'        raise;',
'end write_cards;',
'',
'procedure render (',
'    p_plugin in            apex_plugin.t_plugin,',
'    p_region in            apex_plugin.t_region,',
'    p_param  in            apex_plugin.t_region_render_param,',
'    p_result in out nocopy apex_plugin.t_region_render_result )',
'is',
'    l_json  clob;',
'    l_dummy boolean;',
'begin',
'    apex_json.initialize_clob_output;',
'    apex_json.open_object;',
'    apex_json.write( ''ajaxIdentifier'', apex_plugin.get_ajax_identifier );',
'    apex_json.write( ''itemsToSubmit'', apex_plugin_util.page_item_names_to_jquery( p_region.ajax_items_to_submit ) );',
'    apex_json.write( ''noDataFound'', apex_plugin_util.replace_substitutions( p_region.no_data_found_message, false ) );',
'    apex_json.write( ''columns'', apex_plugin_util.replace_substitutions( p_region.attributes.get_varchar2( ''COLUMNS'' ), false ) );',
'    apex_json.write( ''features'', p_region.attributes.get_varchar2( ''FEATURES'' ) );',
'    apex_json.write( ''clickItem'', p_region.attributes.get_varchar2( ''CLICK_ITEM'' ) );',
'    apex_json.write( ''columnWidth'', p_region.attributes.get_number( ''COLUMN_WIDTH'' ) );',
'    apex_json.write( ''height'', p_region.attributes.get_number( ''HEIGHT'' ) );',
'    apex_json.write( ''canSave'', p_region.attributes.get_varchar2( ''MOVE_CODE'' ) is not null );',
'    l_dummy := write_cards( p_region );',
'    apex_json.close_object;',
'    l_json := apex_json.get_clob_output;',
'    apex_json.free_output;',
'',
'    sys.htp.p( ''<div id="'' || apex_escape.html_attribute( p_region.static_id ) || ''_kanban" class="tx-Kanban" style="--tx-kb-height:''',
'               || nvl( p_region.attributes.get_number( ''HEIGHT'' ), 600 ) || ''px;--tx-kb-lane:'' || nvl( p_region.attributes.get_number( ''COLUMN_WIDTH'' ), 290 ) || ''px"></div>'' );',
'    sys.htp.p( ''<script type="application/json" id="'' || apex_escape.html_attribute( p_region.static_id ) || ''_cards">'' );',
'    apex_util.prn( p_clob => replace( l_json, ''</'', ''<\/'' ), p_escape => false );',
'    sys.htp.p( ''</script>'' );',
'    dbms_lob.freetemporary( l_json );',
'',
'    apex_javascript.add_onload_code(',
'        p_code => ''techrevx.kanban.init('' || apex_javascript.add_value( p_region.static_id, false ) || '');'' );',
'end render;',
'',
'procedure ajax (',
'    p_plugin in            apex_plugin.t_plugin,',
'    p_region in            apex_plugin.t_region,',
'    p_param  in            apex_plugin.t_region_ajax_param,',
'    p_result in out nocopy apex_plugin.t_region_ajax_result )',
'is',
'    l_code   varchar2( 32767 ) := p_region.attributes.get_varchar2( ''MOVE_CODE'' );',
'    l_params apex_exec.t_parameters;',
'    l_dummy  boolean;',
'',
'    -- apex_exec refuses binds the code does not use, so only pass the ones it mentions',
'    function uses( p_name in varchar2 ) return boolean is',
'    begin',
'        return regexp_like( l_code, '':'' || p_name || ''([^A-Za-z0-9_$#]|$)'', ''i'' );',
'    end uses;',
'begin',
'    if apex_application.g_x01 = ''MOVE'' then',
'        if l_code is null then',
'            raise_application_error( -20002, ''Kanban Board: no Move Code.'' );',
'        end if;',
'        if not write_cards( p_region, apex_application.g_x02, false ) then',
'            raise_application_error( -20003, ''Kanban Board: unknown card.'' );',
'        end if;',
'        savepoint tx_kanban_move;',
'        if uses( ''ID'' ) then',
'            apex_exec.add_parameter( l_params, ''ID'', apex_application.g_x02 );',
'        end if;',
'        if uses( ''STATUS'' ) then',
'            apex_exec.add_parameter( l_params, ''STATUS'', apex_application.g_x03 );',
'        end if;',
'        if uses( ''POSITION'' ) then',
'            apex_exec.add_parameter( l_params, ''POSITION'', to_number( apex_application.g_x04 ) );',
'        end if;',
'        if uses( ''ORDER'' ) then',
'            apex_exec.add_parameter( l_params, ''ORDER'', apex_application.g_x05 );',
'        end if;',
'        begin',
'            apex_exec.execute_plsql( p_plsql_code => l_code, p_sql_parameters => l_params );',
'            apex_json.open_object;',
'            apex_json.write( ''moved'', true );',
'            apex_json.close_object;',
'        exception',
'            when others then',
'                -- undo what the Move Code changed; its raise_application_error text is shown to the user',
'                rollback to tx_kanban_move;',
'                if sqlcode between -20999 and -20000 then',
'                    apex_debug.info( ''Kanban Board: Move Code refused card %s: %s'', apex_application.g_x02, sqlerrm );',
'                else',
'                    apex_debug.error( ''Kanban Board: Move Code failed for card %s: %s'', apex_application.g_x02, sqlerrm );',
'                end if;',
'                apex_json.open_object;',
'                apex_json.write( ''moved'', false );',
'                apex_json.write( ''message'', case when sqlcode between -20999 and -20000',
'                                                 then regexp_substr( sqlerrm, ''^ORA-\d{5}: ([^'' || chr( 10 ) || '']+)'', 1, 1, null, 1 ) end );',
'                apex_json.close_object;',
'        end;',
'    else',
'        apex_json.open_object;',
'        l_dummy := write_cards( p_region );',
'        apex_json.close_object;',
'    end if;',
'end ajax;'))
,p_api_version=>3
,p_render_function=>'render'
,p_ajax_function=>'ajax'
,p_standard_attributes=>'SOURCE_LOCATION:AJAX_ITEMS_TO_SUBMIT:ORDER_BY:NO_DATA_FOUND_MESSAGE:SUPPORTS_EXTERNAL_FILTERING'
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Kanban Board: Cards in status lanes that users drag to a new lane or position, saved with your own PL/SQL.',
'',
'Source: any region source with one row per card. Map ID, Title and Status; Description, Assignee, Due Date, Label and Color are optional. Cards appear in each lane in the order of the query.',
'Lanes: listed in Columns as value:Label or value:Label:limit (work-in-progress limit), or one per status found in the data.',
'Moving: drag with mouse or touch, or press Ctrl+Left / Ctrl+Right on a focused card. The Move Code gets :ID, :STATUS, :POSITION and :ORDER; if it fails the card moves back.',
'Features: search box, card counts and limits, add buttons per lane, overdue and due-soon dates, assignee initials, colored labels.',
'JavaScript: apex.region( "id" ).refresh(). Events: Kanban - Card Moved, Card Clicked and Add Card.',
'',
'SortableJS is licensed under the MIT License (sortablejs.github.io).',
'Documentation, updates and more plugins: https://www.techrevx.com'))
,p_version_identifier=>'1.0'
,p_about_url=>'https://www.techrevx.com'
,p_plugin_comment=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Drag library: SortableJS 1.15.7, included',
'Saving: your PL/SQL with :ID, :STATUS, :POSITION and :ORDER',
'License: SortableJS MIT License'))
,p_files_version=>2461343091606
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(6120964920550133)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_title=>'Board'
,p_apexlang_name=>'board'
,p_static_id=>'BOARD'
,p_display_sequence=>20
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(6121036253550133)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_title=>'Data'
,p_apexlang_name=>'data'
,p_static_id=>'DATA'
,p_display_sequence=>10
);
wwv_flow_imp_shared.create_plugin_attr_group(
 p_id=>wwv_flow_imp.id(6121140941550133)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_title=>'Saving'
,p_apexlang_name=>'saving'
,p_static_id=>'SAVING'
,p_display_sequence=>30
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6121226064550133)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_static_id=>'ASSIGNEE_COLUMN'
,p_prompt=>'Assignee Column'
,p_apexlang_name=>'assigneeColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6121036253550133)
,p_help_text=>'Optional person shown as initials in a colored circle; the full name is in the tooltip.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6121319534550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>11
,p_display_sequence=>30
,p_static_id=>'CLICK_ITEM'
,p_prompt=>'Set Item on Click'
,p_apexlang_name=>'clickItem'
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>false
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6120964920550133)
,p_help_text=>'Page item set to the card''s ID when a card is clicked (or Enter is pressed on it), before Kanban - Card Clicked fires. Use it to open a dialog for the card.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6121453070550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>8
,p_display_sequence=>80
,p_static_id=>'COLOR_COLUMN'
,p_prompt=>'Color Column'
,p_apexlang_name=>'colorColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6121036253550133)
,p_help_text=>'Optional CSS color for the label and the card''s edge. Without it, each label text gets its own color.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6121582576550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>9
,p_display_sequence=>10
,p_static_id=>'COLUMNS'
,p_prompt=>'Columns'
,p_apexlang_name=>'columns'
,p_attribute_type=>'TEXT'
,p_is_required=>false
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6120964920550133)
,p_examples=>'TODO:To do, DOING:In progress:3, REVIEW:Review:2, DONE:Done'
,p_help_text=>'The lanes in order, as value:Label or value:Label:limit, separated by commas. The limit is the work-in-progress limit; the lane header turns red above it. Leave empty to make one lane per status found in the data.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6121654546550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>12
,p_display_sequence=>40
,p_static_id=>'COLUMN_WIDTH'
,p_prompt=>'Lane Width'
,p_apexlang_name=>'columnWidth'
,p_attribute_type=>'INTEGER'
,p_is_required=>true
,p_default_value=>'290'
,p_unit=>'px'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6120964920550133)
,p_help_text=>'Minimum width of each lane. Lanes share any extra space in the region; when they do not fit, the board scrolls sideways.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6121726666550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_static_id=>'DESCRIPTION_COLUMN'
,p_prompt=>'Description Column'
,p_apexlang_name=>'descriptionColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6121036253550133)
,p_help_text=>'Optional text under the title, shortened to three lines.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6121861410550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_static_id=>'DUE_COLUMN'
,p_prompt=>'Due Date Column'
,p_apexlang_name=>'dueColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'DATE:TIMESTAMP:VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6121036253550133)
,p_help_text=>'Optional due date. Overdue cards show it in red, cards due within two days in amber.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6121949677550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>10
,p_display_sequence=>20
,p_static_id=>'FEATURES'
,p_prompt=>'Features'
,p_apexlang_name=>'features'
,p_attribute_type=>'CHECKBOXES'
,p_is_required=>false
,p_default_value=>'drag:search:counts:add'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_attribute_group_id=>wwv_flow_imp.id(6120964920550133)
,p_help_text=>'Drag and Drop: move cards with the mouse, touch, or Ctrl+Arrow keys. Search: a box that filters cards by any text. Counts: the number of cards (and the limit) in each lane header. Add Buttons: a + button per lane that fires Kanban - Add Card.'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6122316115550134)
,p_plugin_attribute_id=>wwv_flow_imp.id(6121949677550134)
,p_display_sequence=>40
,p_display_value=>'Add Buttons'
,p_return_value=>'add'
,p_apexlang_name=>'add'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6122298674550134)
,p_plugin_attribute_id=>wwv_flow_imp.id(6121949677550134)
,p_display_sequence=>30
,p_display_value=>'Counts'
,p_return_value=>'counts'
,p_apexlang_name=>'counts'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6122034444550134)
,p_plugin_attribute_id=>wwv_flow_imp.id(6121949677550134)
,p_display_sequence=>10
,p_display_value=>'Drag and Drop'
,p_return_value=>'drag'
,p_apexlang_name=>'drag'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(6122184560550134)
,p_plugin_attribute_id=>wwv_flow_imp.id(6121949677550134)
,p_display_sequence=>20
,p_display_value=>'Search'
,p_return_value=>'search'
,p_apexlang_name=>'search'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6122414839550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>13
,p_display_sequence=>50
,p_static_id=>'HEIGHT'
,p_prompt=>'Height'
,p_apexlang_name=>'height'
,p_attribute_type=>'INTEGER'
,p_is_required=>true
,p_default_value=>'600'
,p_unit=>'px'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6120964920550133)
,p_help_text=>'Height of the board; each lane scrolls on its own.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6122545527550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_static_id=>'ID_COLUMN'
,p_prompt=>'ID Column'
,p_apexlang_name=>'idColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>true
,p_column_data_types=>'VARCHAR2:NUMBER'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6121036253550133)
,p_help_text=>'Unique key of each card, available as :ID in the Move Code.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6122621284550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>70
,p_static_id=>'LABEL_COLUMN'
,p_prompt=>'Label Column'
,p_apexlang_name=>'labelColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>false
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6121036253550133)
,p_help_text=>'Optional tag on the card, such as Bug, Feature or High.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6122723560550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>14
,p_display_sequence=>10
,p_static_id=>'MOVE_CODE'
,p_prompt=>'Move Code'
,p_apexlang_name=>'moveCode'
,p_attribute_type=>'PLSQL'
,p_is_required=>false
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6121140941550133)
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'update tasks',
'   set status = :STATUS,',
'       updated_by = :APP_USER',
' where task_id = :ID;'))
,p_help_text=>'PL/SQL run when a card is dropped. :ID is the card, :STATUS the new lane, :POSITION its place in the lane (1 = top) and :ORDER the IDs of the lane''s cards in their new order, comma separated. If it fails, the card moves back. Leave empty to only fire'
||' the Kanban - Card Moved event.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6122865704550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_static_id=>'STATUS_COLUMN'
,p_prompt=>'Status Column'
,p_apexlang_name=>'statusColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>true
,p_column_data_types=>'VARCHAR2:NUMBER'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6121036253550133)
,p_help_text=>'The column (lane) a card is in, for example TODO or DONE. Cards appear in each lane in the order of the query.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(6122905005550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_static_id=>'TITLE_COLUMN'
,p_prompt=>'Title Column'
,p_apexlang_name=>'titleColumn'
,p_attribute_type=>'REGION SOURCE COLUMN'
,p_is_required=>true
,p_column_data_types=>'VARCHAR2'
,p_is_translatable=>false
,p_attribute_group_id=>wwv_flow_imp.id(6121036253550133)
,p_help_text=>'Card heading.'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(6123032542550134)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_name=>'tx-kanban-add'
,p_display_name=>'Kanban - Add Card'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(6123136910550135)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_name=>'tx-kanban-click'
,p_display_name=>'Kanban - Card Clicked'
);
wwv_flow_imp_shared.create_plugin_event(
 p_id=>wwv_flow_imp.id(6123265439550135)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_name=>'tx-kanban-move'
,p_display_name=>'Kanban - Card Moved'
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A2120536F727461626C6520312E31352E37202D204D4954207C206769743A2F2F6769746875622E636F6D2F536F727461626C654A532F536F727461626C652E676974202A2F0A2166756E6374696F6E28742C65297B226F626A656374223D3D747970';
wwv_flow_imp.g_varchar2_table(2) := '656F66206578706F727473262622756E646566696E656422213D747970656F66206D6F64756C653F6D6F64756C652E6578706F7274733D6528293A2266756E6374696F6E223D3D747970656F6620646566696E652626646566696E652E616D643F646566';
wwv_flow_imp.g_varchar2_table(3) := '696E652865293A28743D747C7C73656C66292E536F727461626C653D6528297D28746869732C66756E6374696F6E28297B2275736520737472696374223B66756E6374696F6E206F28742C65297B286E756C6C3D3D657C7C653E742E6C656E6774682926';
wwv_flow_imp.g_varchar2_table(4) := '2628653D742E6C656E677468293B666F7228766172206E3D302C6F3D41727261792865293B6E3C653B6E2B2B296F5B6E5D3D745B6E5D3B72657475726E206F7D66756E6374696F6E206928742C652C6E297B72657475726E28653D66756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(5) := '74297B743D66756E6374696F6E28742C65297B696628226F626A65637422213D747970656F6620747C7C21742972657475726E20743B766172206E3D745B53796D626F6C2E746F5072696D69746976655D3B696628766F696420303D3D3D6E2972657475';
wwv_flow_imp.g_varchar2_table(6) := '726E2822737472696E67223D3D3D653F537472696E673A4E756D626572292874293B653D6E2E63616C6C28742C657C7C2264656661756C7422293B696628226F626A65637422213D747970656F6620652972657475726E20653B7468726F77206E657720';
wwv_flow_imp.g_varchar2_table(7) := '547970654572726F7228224040746F5072696D6974697665206D7573742072657475726E2061207072696D69746976652076616C75652E22297D28742C22737472696E6722293B72657475726E2273796D626F6C223D3D747970656F6620743F743A742B';
wwv_flow_imp.g_varchar2_table(8) := '22227D28652929696E20743F4F626A6563742E646566696E6550726F706572747928742C652C7B76616C75653A6E2C656E756D657261626C653A21302C636F6E666967757261626C653A21302C7772697461626C653A21307D293A745B655D3D6E2C747D';
wwv_flow_imp.g_varchar2_table(9) := '66756E6374696F6E206128297B72657475726E28613D4F626A6563742E61737369676E3F4F626A6563742E61737369676E2E62696E6428293A66756E6374696F6E2874297B666F722876617220653D313B653C617267756D656E74732E6C656E6774683B';
wwv_flow_imp.g_varchar2_table(10) := '652B2B297B766172206E2C6F3D617267756D656E74735B655D3B666F72286E20696E206F29217B7D2E6861734F776E50726F70657274792E63616C6C286F2C6E297C7C28745B6E5D3D6F5B6E5D297D72657475726E20747D292E6170706C79286E756C6C';
wwv_flow_imp.g_varchar2_table(11) := '2C617267756D656E7473297D66756E6374696F6E207228652C74297B766172206E2C6F3D4F626A6563742E6B6579732865293B72657475726E204F626A6563742E6765744F776E50726F706572747953796D626F6C732626286E3D4F626A6563742E6765';
wwv_flow_imp.g_varchar2_table(12) := '744F776E50726F706572747953796D626F6C732865292C742626286E3D6E2E66696C7465722866756E6374696F6E2874297B72657475726E204F626A6563742E6765744F776E50726F706572747944657363726970746F7228652C74292E656E756D6572';
wwv_flow_imp.g_varchar2_table(13) := '61626C657D29292C6F2E707573682E6170706C79286F2C6E29292C6F7D66756E6374696F6E20492865297B666F722876617220743D313B743C617267756D656E74732E6C656E6774683B742B2B297B766172206E3D6E756C6C213D617267756D656E7473';
wwv_flow_imp.g_varchar2_table(14) := '5B745D3F617267756D656E74735B745D3A7B7D3B7425323F72284F626A656374286E292C2130292E666F72456163682866756E6374696F6E2874297B6928652C742C6E5B745D297D293A4F626A6563742E6765744F776E50726F70657274794465736372';
wwv_flow_imp.g_varchar2_table(15) := '6970746F72733F4F626A6563742E646566696E6550726F7065727469657328652C4F626A6563742E6765744F776E50726F706572747944657363726970746F7273286E29293A72284F626A656374286E29292E666F72456163682866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(16) := '74297B4F626A6563742E646566696E6550726F706572747928652C742C4F626A6563742E6765744F776E50726F706572747944657363726970746F72286E2C7429297D297D72657475726E20657D66756E6374696F6E206C28742C65297B6966286E756C';
wwv_flow_imp.g_varchar2_table(17) := '6C3D3D742972657475726E7B7D3B766172206E2C6F3D66756E6374696F6E28742C65297B6966286E756C6C3D3D742972657475726E7B7D3B766172206E2C6F3D7B7D3B666F72286E20696E2074296966287B7D2E6861734F776E50726F70657274792E63';
wwv_flow_imp.g_varchar2_table(18) := '616C6C28742C6E29297B6966282D31213D3D652E696E6465784F66286E2929636F6E74696E75653B6F5B6E5D3D745B6E5D7D72657475726E206F7D28742C65293B6966284F626A6563742E6765744F776E50726F706572747953796D626F6C7329666F72';
wwv_flow_imp.g_varchar2_table(19) := '2876617220693D4F626A6563742E6765744F776E50726F706572747953796D626F6C732874292C723D303B723C692E6C656E6774683B722B2B296E3D695B725D2C2D313D3D3D652E696E6465784F66286E2926267B7D2E70726F70657274794973456E75';
wwv_flow_imp.g_varchar2_table(20) := '6D657261626C652E63616C6C28742C6E292626286F5B6E5D3D745B6E5D293B72657475726E206F7D66756E6374696F6E20652874297B72657475726E2066756E6374696F6E2874297B69662841727261792E697341727261792874292972657475726E20';
wwv_flow_imp.g_varchar2_table(21) := '6F2874297D2874297C7C66756E6374696F6E2874297B69662822756E646566696E656422213D747970656F662053796D626F6C26266E756C6C213D745B53796D626F6C2E6974657261746F725D7C7C6E756C6C213D745B2240406974657261746F72225D';
wwv_flow_imp.g_varchar2_table(22) := '2972657475726E2041727261792E66726F6D2874297D2874297C7C66756E6374696F6E28742C65297B69662874297B69662822737472696E67223D3D747970656F6620742972657475726E206F28742C65293B766172206E3D7B7D2E746F537472696E67';
wwv_flow_imp.g_varchar2_table(23) := '2E63616C6C2874292E736C69636528382C2D31293B72657475726E224D6170223D3D3D286E3D224F626A656374223D3D3D6E2626742E636F6E7374727563746F723F742E636F6E7374727563746F722E6E616D653A6E297C7C22536574223D3D3D6E3F41';
wwv_flow_imp.g_varchar2_table(24) := '727261792E66726F6D2874293A22417267756D656E7473223D3D3D6E7C7C2F5E283F3A55697C49296E74283F3A387C31367C333229283F3A436C616D706564293F4172726179242F2E74657374286E293F6F28742C65293A766F696420307D7D2874297C';
wwv_flow_imp.g_varchar2_table(25) := '7C66756E6374696F6E28297B7468726F77206E657720547970654572726F722822496E76616C696420617474656D707420746F20737072656164206E6F6E2D6974657261626C6520696E7374616E63652E5C6E496E206F7264657220746F206265206974';
wwv_flow_imp.g_varchar2_table(26) := '657261626C652C206E6F6E2D6172726179206F626A65637473206D75737420686176652061205B53796D626F6C2E6974657261746F725D2829206D6574686F642E22297D28297D66756E6374696F6E20732874297B72657475726E28733D2266756E6374';
wwv_flow_imp.g_varchar2_table(27) := '696F6E223D3D747970656F662053796D626F6C26262273796D626F6C223D3D747970656F662053796D626F6C2E6974657261746F723F66756E6374696F6E2874297B72657475726E20747970656F6620747D3A66756E6374696F6E2874297B7265747572';
wwv_flow_imp.g_varchar2_table(28) := '6E207426262266756E6374696F6E223D3D747970656F662053796D626F6C2626742E636F6E7374727563746F723D3D3D53796D626F6C262674213D3D53796D626F6C2E70726F746F747970653F2273796D626F6C223A747970656F6620747D292874297D';
wwv_flow_imp.g_varchar2_table(29) := '66756E6374696F6E20742874297B69662822756E646566696E656422213D747970656F662077696E646F77262677696E646F772E6E6176696761746F722972657475726E21216E6176696761746F722E757365724167656E742E6D617463682874297D76';
wwv_flow_imp.g_varchar2_table(30) := '617220793D74282F283F3A54726964656E742E2A72765B203A5D3F31315C2E7C6D7369657C69656D6F62696C657C57696E646F77732050686F6E65292F69292C773D74282F456467652F69292C633D74282F66697265666F782F69292C753D74282F7361';
wwv_flow_imp.g_varchar2_table(31) := '666172692F692926262174282F6368726F6D652F692926262174282F616E64726F69642F69292C643D74282F69502861647C6F647C686F6E65292F69292C6E3D74282F6368726F6D652F6929262674282F616E64726F69642F69292C683D7B6361707475';
wwv_flow_imp.g_varchar2_table(32) := '72653A21312C706173736976653A21317D3B66756E6374696F6E206628742C652C6E297B742E6164644576656E744C697374656E657228652C6E2C2179262668297D66756E6374696F6E207028742C652C6E297B742E72656D6F76654576656E744C6973';
wwv_flow_imp.g_varchar2_table(33) := '74656E657228652C6E2C2179262668297D66756E6374696F6E206728742C65297B69662865262628223E223D3D3D655B305D262628653D652E737562737472696E67283129292C7429297472797B696628742E6D6174636865732972657475726E20742E';
wwv_flow_imp.g_varchar2_table(34) := '6D6174636865732865293B696628742E6D734D61746368657353656C6563746F722972657475726E20742E6D734D61746368657353656C6563746F722865293B696628742E7765626B69744D61746368657353656C6563746F722972657475726E20742E';
wwv_flow_imp.g_varchar2_table(35) := '7765626B69744D61746368657353656C6563746F722865297D63617463682874297B72657475726E7D7D66756E6374696F6E206D2874297B72657475726E20742E686F7374262674213D3D646F63756D656E742626742E686F73742E6E6F646554797065';
wwv_flow_imp.g_varchar2_table(36) := '2626742E686F7374213D3D743F742E686F73743A742E706172656E744E6F64657D66756E6374696F6E205028742C652C6E2C6F297B69662874297B6E3D6E7C7C646F63756D656E743B646F7B6966286E756C6C213D65262628223E22213D3D655B305D7C';
wwv_flow_imp.g_varchar2_table(37) := '7C742E706172656E744E6F64653D3D3D6E2926266728742C65297C7C6F2626743D3D3D6E2972657475726E20747D7768696C652874213D3D6E262628743D6D28742929297D72657475726E206E756C6C7D76617220762C623D2F5C732B2F673B66756E63';
wwv_flow_imp.g_varchar2_table(38) := '74696F6E206B28742C652C6E297B766172206F3B74262665262628742E636C6173734C6973743F742E636C6173734C6973745B6E3F22616464223A2272656D6F7665225D2865293A286F3D282220222B742E636C6173734E616D652B222022292E726570';
wwv_flow_imp.g_varchar2_table(39) := '6C61636528622C222022292E7265706C616365282220222B652B2220222C222022292C742E636C6173734E616D653D286F2B286E3F2220222B653A222229292E7265706C61636528622C2220222929297D66756E6374696F6E205228742C652C6E297B76';
wwv_flow_imp.g_varchar2_table(40) := '6172206F3D742626742E7374796C653B6966286F297B696628766F696420303D3D3D6E2972657475726E20646F63756D656E742E64656661756C74566965772626646F63756D656E742E64656661756C74566965772E676574436F6D7075746564537479';
wwv_flow_imp.g_varchar2_table(41) := '6C653F6E3D646F63756D656E742E64656661756C74566965772E676574436F6D70757465645374796C6528742C2222293A742E63757272656E745374796C652626286E3D742E63757272656E745374796C65292C766F696420303D3D3D653F6E3A6E5B65';
wwv_flow_imp.g_varchar2_table(42) := '5D3B6F5B653D21286520696E206F7C7C2D31213D3D652E696E6465784F6628227765626B69742229293F222D7765626B69742D222B653A655D3D6E2B2822737472696E67223D3D747970656F66206E3F22223A22707822297D7D66756E6374696F6E2044';
wwv_flow_imp.g_varchar2_table(43) := '28742C65297B766172206E3D22223B69662822737472696E67223D3D747970656F662074296E3D743B656C736520646F7B766172206F3D5228742C227472616E73666F726D22297D7768696C65286F2626226E6F6E6522213D3D6F2626286E3D6F2B2220';
wwv_flow_imp.g_varchar2_table(44) := '222B6E292C2165262628743D742E706172656E744E6F646529293B76617220693D77696E646F772E444F4D4D61747269787C7C77696E646F772E5765624B69744353534D61747269787C7C77696E646F772E4353534D61747269787C7C77696E646F772E';
wwv_flow_imp.g_varchar2_table(45) := '4D534353534D61747269783B72657475726E206926266E65772069286E297D66756E6374696F6E204528742C652C6E297B69662874297B766172206F3D742E676574456C656D656E747342795461674E616D652865292C693D302C723D6F2E6C656E6774';
wwv_flow_imp.g_varchar2_table(46) := '683B6966286E29666F72283B693C723B692B2B296E286F5B695D2C69293B72657475726E206F7D72657475726E5B5D7D66756E6374696F6E204F28297B76617220743D646F63756D656E742E7363726F6C6C696E67456C656D656E743B72657475726E20';
wwv_flow_imp.g_varchar2_table(47) := '747C7C646F63756D656E742E646F63756D656E74456C656D656E747D66756E6374696F6E205828742C652C6E2C6F2C69297B696628742E676574426F756E64696E67436C69656E74526563747C7C743D3D3D77696E646F77297B76617220722C612C6C2C';
wwv_flow_imp.g_varchar2_table(48) := '732C632C752C643D74213D3D77696E646F772626742E706172656E744E6F6465262674213D3D4F28293F28613D28723D742E676574426F756E64696E67436C69656E74526563742829292E746F702C6C3D722E6C6566742C733D722E626F74746F6D2C63';
wwv_flow_imp.g_varchar2_table(49) := '3D722E72696768742C753D722E6865696768742C722E7769647468293A286C3D613D302C733D77696E646F772E696E6E65724865696768742C633D77696E646F772E696E6E657257696474682C753D77696E646F772E696E6E65724865696768742C7769';
wwv_flow_imp.g_varchar2_table(50) := '6E646F772E696E6E65725769647468293B69662828657C7C6E29262674213D3D77696E646F77262628693D697C7C742E706172656E744E6F64652C21792929646F7B696628692626692E676574426F756E64696E67436C69656E7452656374262628226E';
wwv_flow_imp.g_varchar2_table(51) := '6F6E6522213D3D5228692C227472616E73666F726D22297C7C6E26262273746174696322213D3D5228692C22706F736974696F6E222929297B76617220683D692E676574426F756E64696E67436C69656E745265637428293B612D3D682E746F702B7061';
wwv_flow_imp.g_varchar2_table(52) := '727365496E74285228692C22626F726465722D746F702D77696474682229292C6C2D3D682E6C6566742B7061727365496E74285228692C22626F726465722D6C6566742D77696474682229292C733D612B722E6865696768742C633D6C2B722E77696474';
wwv_flow_imp.g_varchar2_table(53) := '683B627265616B7D7D7768696C6528693D692E706172656E744E6F6465293B72657475726E206F262674213D3D77696E646F772626286F3D28653D4428697C7C7429292626652E612C743D652626652E642C65262628733D28612F3D74292B28752F3D74';
wwv_flow_imp.g_varchar2_table(54) := '292C633D286C2F3D6F292B28642F3D6F2929292C7B746F703A612C6C6566743A6C2C626F74746F6D3A732C72696768743A632C77696474683A642C6865696768743A757D7D7D66756E6374696F6E205928742C652C6E297B666F7228766172206F3D4D28';
wwv_flow_imp.g_varchar2_table(55) := '742C2130292C693D582874295B655D3B6F3B297B76617220723D58286F295B6E5D3B696628212822746F70223D3D3D6E7C7C226C656674223D3D3D6E3F723C3D693A693C3D72292972657475726E206F3B6966286F3D3D3D4F282929627265616B3B6F3D';
wwv_flow_imp.g_varchar2_table(56) := '4D286F2C2131297D72657475726E21317D66756E6374696F6E204228742C652C6E2C6F297B666F722876617220693D302C723D302C613D742E6368696C6472656E3B723C612E6C656E6774683B297B696628226E6F6E6522213D3D615B725D2E7374796C';
wwv_flow_imp.g_varchar2_table(57) := '652E646973706C61792626615B725D213D3D48742E67686F73742626286F7C7C615B725D213D3D48742E647261676765642926265028615B725D2C6E2E647261676761626C652C742C213129297B696628693D3D3D652972657475726E20615B725D3B69';
wwv_flow_imp.g_varchar2_table(58) := '2B2B7D722B2B7D72657475726E206E756C6C7D66756E6374696F6E204628742C65297B666F7228766172206E3D742E6C617374456C656D656E744368696C643B6E2626286E3D3D3D48742E67686F73747C7C226E6F6E65223D3D3D52286E2C2264697370';
wwv_flow_imp.g_varchar2_table(59) := '6C617922297C7C6526262167286E2C6529293B296E3D6E2E70726576696F7573456C656D656E745369626C696E673B72657475726E206E7C7C6E756C6C7D66756E6374696F6E206A28742C65297B766172206E3D303B69662821747C7C21742E70617265';
wwv_flow_imp.g_varchar2_table(60) := '6E744E6F64652972657475726E2D313B666F72283B743D742E70726576696F7573456C656D656E745369626C696E673B292254454D504C415445223D3D3D742E6E6F64654E616D652E746F55707065724361736528297C7C743D3D3D48742E636C6F6E65';
wwv_flow_imp.g_varchar2_table(61) := '7C7C652626216728742C65297C7C6E2B2B3B72657475726E206E7D66756E6374696F6E20532874297B76617220653D302C6E3D302C6F3D4F28293B6966287429646F7B76617220693D442874292C723D692E612C693D692E647D7768696C6528652B3D74';
wwv_flow_imp.g_varchar2_table(62) := '2E7363726F6C6C4C6566742A722C6E2B3D742E7363726F6C6C546F702A692C74213D3D6F262628743D742E706172656E744E6F646529293B72657475726E5B652C6E5D7D66756E6374696F6E204D28742C65297B69662821747C7C21742E676574426F75';
wwv_flow_imp.g_varchar2_table(63) := '6E64696E67436C69656E74526563742972657475726E204F28293B766172206E3D742C6F3D21313B646F7B6966286E2E636C69656E7457696474683C6E2E7363726F6C6C57696474687C7C6E2E636C69656E744865696768743C6E2E7363726F6C6C4865';
wwv_flow_imp.g_varchar2_table(64) := '69676874297B76617220693D52286E293B6966286E2E636C69656E7457696474683C6E2E7363726F6C6C5769647468262628226175746F223D3D692E6F766572666C6F77587C7C227363726F6C6C223D3D692E6F766572666C6F7758297C7C6E2E636C69';
wwv_flow_imp.g_varchar2_table(65) := '656E744865696768743C6E2E7363726F6C6C486569676874262628226175746F223D3D692E6F766572666C6F77597C7C227363726F6C6C223D3D692E6F766572666C6F775929297B696628216E2E676574426F756E64696E67436C69656E74526563747C';
wwv_flow_imp.g_varchar2_table(66) := '7C6E3D3D3D646F63756D656E742E626F64792972657475726E204F28293B6966286F7C7C652972657475726E206E3B6F3D21307D7D7D7768696C65286E3D6E2E706172656E744E6F6465293B72657475726E204F28297D66756E6374696F6E205F28742C';
wwv_flow_imp.g_varchar2_table(67) := '65297B72657475726E204D6174682E726F756E6428742E746F70293D3D3D4D6174682E726F756E6428652E746F702926264D6174682E726F756E6428742E6C656674293D3D3D4D6174682E726F756E6428652E6C6566742926264D6174682E726F756E64';
wwv_flow_imp.g_varchar2_table(68) := '28742E686569676874293D3D3D4D6174682E726F756E6428652E6865696768742926264D6174682E726F756E6428742E7769647468293D3D3D4D6174682E726F756E6428652E7769647468297D66756E6374696F6E204328652C6E297B72657475726E20';
wwv_flow_imp.g_varchar2_table(69) := '66756E6374696F6E28297B76617220743B767C7C28313D3D3D28743D617267756D656E7473292E6C656E6774683F652E63616C6C28746869732C745B305D293A652E6170706C7928746869732C74292C763D73657454696D656F75742866756E6374696F';
wwv_flow_imp.g_varchar2_table(70) := '6E28297B763D766F696420307D2C6E29297D7D66756E6374696F6E204828742C652C6E297B742E7363726F6C6C4C6566742B3D652C742E7363726F6C6C546F702B3D6E7D66756E6374696F6E20542874297B76617220653D77696E646F772E506F6C796D';
wwv_flow_imp.g_varchar2_table(71) := '65722C6E3D77696E646F772E6A51756572797C7C77696E646F772E5A6570746F3B72657475726E20652626652E646F6D3F652E646F6D2874292E636C6F6E654E6F6465282130293A6E3F6E2874292E636C6F6E65282130295B305D3A742E636C6F6E654E';
wwv_flow_imp.g_varchar2_table(72) := '6F6465282130297D66756E6374696F6E207828742C65297B5228742C22706F736974696F6E222C226162736F6C75746522292C5228742C22746F70222C652E746F70292C5228742C226C656674222C652E6C656674292C5228742C227769647468222C65';
wwv_flow_imp.g_varchar2_table(73) := '2E7769647468292C5228742C22686569676874222C652E686569676874297D66756E6374696F6E20412874297B5228742C22706F736974696F6E222C2222292C5228742C22746F70222C2222292C5228742C226C656674222C2222292C5228742C227769';
wwv_flow_imp.g_varchar2_table(74) := '647468222C2222292C5228742C22686569676874222C2222297D66756E6374696F6E204C286E2C6F2C69297B76617220723D7B7D3B72657475726E2041727261792E66726F6D286E2E6368696C6472656E292E666F72456163682866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(75) := '74297B76617220653B5028742C6F2E647261676761626C652C6E2C213129262621742E616E696D61746564262674213D3D69262628653D582874292C722E6C6566743D4D6174682E6D696E286E756C6C213D3D28743D722E6C656674292626766F696420';
wwv_flow_imp.g_varchar2_table(76) := '30213D3D743F743A312F302C652E6C656674292C722E746F703D4D6174682E6D696E286E756C6C213D3D28743D722E746F70292626766F69642030213D3D743F743A312F302C652E746F70292C722E72696768743D4D6174682E6D6178286E756C6C213D';
wwv_flow_imp.g_varchar2_table(77) := '3D28743D722E7269676874292626766F69642030213D3D743F743A2D312F302C652E7269676874292C722E626F74746F6D3D4D6174682E6D6178286E756C6C213D3D28743D722E626F74746F6D292626766F69642030213D3D743F743A2D312F302C652E';
wwv_flow_imp.g_varchar2_table(78) := '626F74746F6D29297D292C722E77696474683D722E72696768742D722E6C6566742C722E6865696768743D722E626F74746F6D2D722E746F702C722E783D722E6C6566742C722E793D722E746F702C727D766172204B3D22536F727461626C65222B286E';
wwv_flow_imp.g_varchar2_table(79) := '65772044617465292E67657454696D6528293B66756E6374696F6E204E28297B76617220652C6F3D5B5D3B72657475726E7B63617074757265416E696D6174696F6E53746174653A66756E6374696F6E28297B6F3D5B5D2C746869732E6F7074696F6E73';
wwv_flow_imp.g_varchar2_table(80) := '2E616E696D6174696F6E26265B5D2E736C6963652E63616C6C28746869732E656C2E6368696C6472656E292E666F72456163682866756E6374696F6E2874297B76617220652C6E3B226E6F6E6522213D3D5228742C22646973706C61792229262674213D';
wwv_flow_imp.g_varchar2_table(81) := '3D48742E67686F73742626286F2E70757368287B7461726765743A742C726563743A582874297D292C653D49287B7D2C6F5B6F2E6C656E6774682D315D2E72656374292C21742E74686973416E696D6174696F6E4475726174696F6E7C7C286E3D442874';
wwv_flow_imp.g_varchar2_table(82) := '2C21302929262628652E746F702D3D6E2E662C652E6C6566742D3D6E2E65292C742E66726F6D526563743D65297D297D2C616464416E696D6174696F6E53746174653A66756E6374696F6E2874297B6F2E707573682874297D2C72656D6F7665416E696D';
wwv_flow_imp.g_varchar2_table(83) := '6174696F6E53746174653A66756E6374696F6E2874297B6F2E73706C6963652866756E6374696F6E28742C65297B666F7228766172206E20696E207429696628742E6861734F776E50726F7065727479286E2929666F7228766172206F20696E20652969';
wwv_flow_imp.g_varchar2_table(84) := '6628652E6861734F776E50726F7065727479286F292626655B6F5D3D3D3D745B6E5D5B6F5D2972657475726E204E756D626572286E293B72657475726E2D317D286F2C7B7461726765743A747D292C31297D2C616E696D617465416C6C3A66756E637469';
wwv_flow_imp.g_varchar2_table(85) := '6F6E2874297B76617220633D746869733B69662821746869732E6F7074696F6E732E616E696D6174696F6E2972657475726E20636C65617254696D656F75742865292C766F6964282266756E6374696F6E223D3D747970656F6620742626742829293B76';
wwv_flow_imp.g_varchar2_table(86) := '617220753D21312C643D303B6F2E666F72456163682866756E6374696F6E2874297B76617220653D302C6E3D742E7461726765742C6F3D6E2E66726F6D526563742C693D58286E292C723D6E2E7072657646726F6D526563742C613D6E2E70726576546F';
wwv_flow_imp.g_varchar2_table(87) := '526563742C6C3D742E726563742C733D44286E2C2130293B73262628692E746F702D3D732E662C692E6C6566742D3D732E65292C6E2E746F526563743D692C6E2E74686973416E696D6174696F6E4475726174696F6E26265F28722C69292626215F286F';
wwv_flow_imp.g_varchar2_table(88) := '2C69292626286C2E746F702D692E746F70292F286C2E6C6566742D692E6C656674293D3D286F2E746F702D692E746F70292F286F2E6C6566742D692E6C65667429262628743D6C2C733D722C723D612C613D632E6F7074696F6E732C653D4D6174682E73';
wwv_flow_imp.g_varchar2_table(89) := '717274284D6174682E706F7728732E746F702D742E746F702C32292B4D6174682E706F7728732E6C6566742D742E6C6566742C3229292F4D6174682E73717274284D6174682E706F7728732E746F702D722E746F702C32292B4D6174682E706F7728732E';
wwv_flow_imp.g_varchar2_table(90) := '6C6566742D722E6C6566742C3229292A612E616E696D6174696F6E292C5F28692C6F297C7C286E2E7072657646726F6D526563743D6F2C6E2E70726576546F526563743D692C653D657C7C632E6F7074696F6E732E616E696D6174696F6E2C632E616E69';
wwv_flow_imp.g_varchar2_table(91) := '6D617465286E2C6C2C692C6529292C65262628753D21302C643D4D6174682E6D617828642C65292C636C65617254696D656F7574286E2E616E696D6174696F6E526573657454696D6572292C6E2E616E696D6174696F6E526573657454696D65723D7365';
wwv_flow_imp.g_varchar2_table(92) := '7454696D656F75742866756E6374696F6E28297B6E2E616E696D6174696F6E54696D653D302C6E2E7072657646726F6D526563743D6E756C6C2C6E2E66726F6D526563743D6E756C6C2C6E2E70726576546F526563743D6E756C6C2C6E2E74686973416E';
wwv_flow_imp.g_varchar2_table(93) := '696D6174696F6E4475726174696F6E3D6E756C6C7D2C65292C6E2E74686973416E696D6174696F6E4475726174696F6E3D65297D292C636C65617254696D656F75742865292C753F653D73657454696D656F75742866756E6374696F6E28297B2266756E';
wwv_flow_imp.g_varchar2_table(94) := '6374696F6E223D3D747970656F66207426267428297D2C64293A2266756E6374696F6E223D3D747970656F66207426267428292C6F3D5B5D7D2C616E696D6174653A66756E6374696F6E28742C652C6E2C6F297B76617220692C723B6F2626285228742C';
wwv_flow_imp.g_varchar2_table(95) := '227472616E736974696F6E222C2222292C5228742C227472616E73666F726D222C2222292C693D28723D4428746869732E656C29292626722E612C723D722626722E642C693D28652E6C6566742D6E2E6C656674292F28697C7C31292C723D28652E746F';
wwv_flow_imp.g_varchar2_table(96) := '702D6E2E746F70292F28727C7C31292C742E616E696D6174696E67583D2121692C742E616E696D6174696E67593D2121722C5228742C227472616E73666F726D222C227472616E736C617465336428222B692B2270782C222B722B2270782C302922292C';
wwv_flow_imp.g_varchar2_table(97) := '746869732E666F7252657061696E7444756D6D793D742E6F666673657457696474682C5228742C227472616E736974696F6E222C227472616E73666F726D20222B6F2B226D73222B28746869732E6F7074696F6E732E656173696E673F2220222B746869';
wwv_flow_imp.g_varchar2_table(98) := '732E6F7074696F6E732E656173696E673A222229292C5228742C227472616E73666F726D222C227472616E736C617465336428302C302C302922292C226E756D626572223D3D747970656F6620742E616E696D617465642626636C65617254696D656F75';
wwv_flow_imp.g_varchar2_table(99) := '7428742E616E696D61746564292C742E616E696D617465643D73657454696D656F75742866756E6374696F6E28297B5228742C227472616E736974696F6E222C2222292C5228742C227472616E73666F726D222C2222292C742E616E696D617465643D21';
wwv_flow_imp.g_varchar2_table(100) := '312C742E616E696D6174696E67583D21312C742E616E696D6174696E67593D21317D2C6F29297D7D7D76617220573D5B5D2C7A3D7B696E697469616C697A65427944656661756C743A21307D2C473D7B6D6F756E743A66756E6374696F6E2865297B666F';
wwv_flow_imp.g_varchar2_table(101) := '7228766172207420696E207A29217A2E6861734F776E50726F70657274792874297C7C7420696E20657C7C28655B745D3D7A5B745D293B572E666F72456163682866756E6374696F6E2874297B696628742E706C7567696E4E616D653D3D3D652E706C75';
wwv_flow_imp.g_varchar2_table(102) := '67696E4E616D65297468726F7722536F727461626C653A2043616E6E6F74206D6F756E7420706C7567696E20222E636F6E63617428652E706C7567696E4E616D652C22206D6F7265207468616E206F6E636522297D292C572E707573682865297D2C706C';
wwv_flow_imp.g_varchar2_table(103) := '7567696E4576656E743A66756E6374696F6E28652C6E2C6F297B76617220743D746869733B746869732E6576656E7443616E63656C65643D21312C6F2E63616E63656C3D66756E6374696F6E28297B742E6576656E7443616E63656C65643D21307D3B76';
wwv_flow_imp.g_varchar2_table(104) := '617220693D652B22476C6F62616C223B572E666F72456163682866756E6374696F6E2874297B6E5B742E706C7567696E4E616D655D2626286E5B742E706C7567696E4E616D655D5B695D26266E5B742E706C7567696E4E616D655D5B695D2849287B736F';
wwv_flow_imp.g_varchar2_table(105) := '727461626C653A6E7D2C6F29292C6E2E6F7074696F6E735B742E706C7567696E4E616D655D26266E5B742E706C7567696E4E616D655D5B655D26266E5B742E706C7567696E4E616D655D5B655D2849287B736F727461626C653A6E7D2C6F2929297D297D';
wwv_flow_imp.g_varchar2_table(106) := '2C696E697469616C697A65506C7567696E733A66756E6374696F6E286E2C6F2C692C74297B666F7228766172206520696E20572E666F72456163682866756E6374696F6E2874297B76617220653D742E706C7567696E4E616D653B286E2E6F7074696F6E';
wwv_flow_imp.g_varchar2_table(107) := '735B655D7C7C742E696E697469616C697A65427944656661756C742926262828743D6E65772074286E2C6F2C6E2E6F7074696F6E7329292E736F727461626C653D6E2C742E6F7074696F6E733D6E2E6F7074696F6E732C6E5B655D3D742C6128692C742E';
wwv_flow_imp.g_varchar2_table(108) := '64656661756C747329297D292C6E2E6F7074696F6E73297B76617220723B6E2E6F7074696F6E732E6861734F776E50726F7065727479286529262628766F69642030213D3D28723D746869732E6D6F646966794F7074696F6E286E2C652C6E2E6F707469';
wwv_flow_imp.g_varchar2_table(109) := '6F6E735B655D29292626286E2E6F7074696F6E735B655D3D7229297D7D2C6765744576656E7450726F706572746965733A66756E6374696F6E28652C6E297B766172206F3D7B7D3B72657475726E20572E666F72456163682866756E6374696F6E287429';
wwv_flow_imp.g_varchar2_table(110) := '7B2266756E6374696F6E223D3D747970656F6620742E6576656E7450726F70657274696573262661286F2C742E6576656E7450726F706572746965732E63616C6C286E5B742E706C7567696E4E616D655D2C6529297D292C6F7D2C6D6F646966794F7074';
wwv_flow_imp.g_varchar2_table(111) := '696F6E3A66756E6374696F6E28652C6E2C6F297B76617220693B72657475726E20572E666F72456163682866756E6374696F6E2874297B655B742E706C7567696E4E616D655D2626742E6F7074696F6E4C697374656E65727326262266756E6374696F6E';
wwv_flow_imp.g_varchar2_table(112) := '223D3D747970656F6620742E6F7074696F6E4C697374656E6572735B6E5D262628693D742E6F7074696F6E4C697374656E6572735B6E5D2E63616C6C28655B742E706C7567696E4E616D655D2C6F29297D292C697D7D3B66756E6374696F6E2055287429';
wwv_flow_imp.g_varchar2_table(113) := '7B76617220653D742E736F727461626C652C6E3D742E726F6F74456C2C6F3D742E6E616D652C693D742E746172676574456C2C723D742E636C6F6E65456C2C613D742E746F456C2C6C3D742E66726F6D456C2C733D742E6F6C64496E6465782C633D742E';
wwv_flow_imp.g_varchar2_table(114) := '6E6577496E6465782C753D742E6F6C64447261676761626C65496E6465782C643D742E6E6577447261676761626C65496E6465782C683D742E6F726967696E616C4576656E742C663D742E707574536F727461626C652C703D742E65787472614576656E';
wwv_flow_imp.g_varchar2_table(115) := '7450726F706572746965733B696628653D657C7C6E26266E5B4B5D297B76617220672C6D3D652E6F7074696F6E732C743D226F6E222B6F2E6368617241742830292E746F55707065724361736528292B6F2E7375627374722831293B2177696E646F772E';
wwv_flow_imp.g_varchar2_table(116) := '437573746F6D4576656E747C7C797C7C773F28673D646F63756D656E742E6372656174654576656E7428224576656E742229292E696E69744576656E74286F2C21302C2130293A673D6E657720437573746F6D4576656E74286F2C7B627562626C65733A';
wwv_flow_imp.g_varchar2_table(117) := '21302C63616E63656C61626C653A21307D292C672E746F3D617C7C6E2C672E66726F6D3D6C7C7C6E2C672E6974656D3D697C7C6E2C672E636C6F6E653D722C672E6F6C64496E6465783D732C672E6E6577496E6465783D632C672E6F6C64447261676761';
wwv_flow_imp.g_varchar2_table(118) := '626C65496E6465783D752C672E6E6577447261676761626C65496E6465783D642C672E6F726967696E616C4576656E743D682C672E70756C6C4D6F64653D663F662E6C6173745075744D6F64653A766F696420303B76617220762C623D492849287B7D2C';
wwv_flow_imp.g_varchar2_table(119) := '70292C472E6765744576656E7450726F70657274696573286F2C6529293B666F72287620696E206229675B765D3D625B765D3B6E26266E2E64697370617463684576656E742867292C6D5B745D26266D5B745D2E63616C6C28652C67297D7D66756E6374';
wwv_flow_imp.g_varchar2_table(120) := '696F6E207128742C65297B766172206E3D286F3D323C617267756D656E74732E6C656E6774682626766F69642030213D3D617267756D656E74735B325D3F617267756D656E74735B325D3A7B7D292E6576742C6F3D6C286F2C56293B472E706C7567696E';
wwv_flow_imp.g_varchar2_table(121) := '4576656E742E62696E642848742928742C652C49287B64726167456C3A242C706172656E74456C3A512C67686F7374456C3A4A2C726F6F74456C3A74742C6E657874456C3A65742C6C617374446F776E456C3A6E742C636C6F6E65456C3A6F742C636C6F';
wwv_flow_imp.g_varchar2_table(122) := '6E6548696464656E3A69742C64726167537461727465643A76742C707574536F727461626C653A75742C616374697665536F727461626C653A48742E6163746976652C6F726967696E616C4576656E743A6E2C6F6C64496E6465783A72742C6F6C644472';
wwv_flow_imp.g_varchar2_table(123) := '61676761626C65496E6465783A6C742C6E6577496E6465783A61742C6E6577447261676761626C65496E6465783A73742C6869646547686F7374466F725461726765743A59742C756E6869646547686F7374466F725461726765743A42742C636C6F6E65';
wwv_flow_imp.g_varchar2_table(124) := '4E6F7748696464656E3A66756E6374696F6E28297B69743D21307D2C636C6F6E654E6F7753686F776E3A66756E6374696F6E28297B69743D21317D2C6469737061746368536F727461626C654576656E743A66756E6374696F6E2874297B5A287B736F72';
wwv_flow_imp.g_varchar2_table(125) := '7461626C653A652C6E616D653A742C6F726967696E616C4576656E743A6E7D297D7D2C6F29297D76617220563D5B22657674225D3B66756E6374696F6E205A2874297B552849287B707574536F727461626C653A75742C636C6F6E65456C3A6F742C7461';
wwv_flow_imp.g_varchar2_table(126) := '72676574456C3A242C726F6F74456C3A74742C6F6C64496E6465783A72742C6F6C64447261676761626C65496E6465783A6C742C6E6577496E6465783A61742C6E6577447261676761626C65496E6465783A73747D2C7429297D76617220242C512C4A2C';
wwv_flow_imp.g_varchar2_table(127) := '74742C65742C6E742C6F742C69742C72742C61742C6C742C73742C63742C75742C64742C68742C66742C70742C67742C6D742C76742C62742C79742C77742C44742C45743D21312C53743D21312C5F743D5B5D2C43743D21312C54743D21312C78743D5B';
wwv_flow_imp.g_varchar2_table(128) := '5D2C4F743D21312C4D743D5B5D2C41743D22756E646566696E656422213D747970656F6620646F63756D656E742C4E743D642C49743D777C7C793F22637373466C6F6174223A22666C6F6174222C50743D41742626216E26262164262622647261676761';
wwv_flow_imp.g_varchar2_table(129) := '626C6522696E20646F63756D656E742E637265617465456C656D656E74282264697622292C6B743D66756E6374696F6E28297B6966284174297B696628792972657475726E21313B76617220743D646F63756D656E742E637265617465456C656D656E74';
wwv_flow_imp.g_varchar2_table(130) := '28227822293B72657475726E20742E7374796C652E637373546578743D22706F696E7465722D6576656E74733A6175746F222C226175746F223D3D3D742E7374796C652E706F696E7465724576656E74737D7D28292C52743D66756E6374696F6E28742C';
wwv_flow_imp.g_varchar2_table(131) := '65297B766172206E3D522874292C6F3D7061727365496E74286E2E7769647468292D7061727365496E74286E2E70616464696E674C656674292D7061727365496E74286E2E70616464696E675269676874292D7061727365496E74286E2E626F72646572';
wwv_flow_imp.g_varchar2_table(132) := '4C6566745769647468292D7061727365496E74286E2E626F7264657252696768745769647468292C693D4228742C302C65292C723D4228742C312C65292C613D692626522869292C6C3D722626522872292C733D6126267061727365496E7428612E6D61';
wwv_flow_imp.g_varchar2_table(133) := '7267696E4C656674292B7061727365496E7428612E6D617267696E5269676874292B582869292E77696474682C743D6C26267061727365496E74286C2E6D617267696E4C656674292B7061727365496E74286C2E6D617267696E5269676874292B582872';
wwv_flow_imp.g_varchar2_table(134) := '292E77696474683B69662822666C6578223D3D3D6E2E646973706C61792972657475726E22636F6C756D6E223D3D3D6E2E666C6578446972656374696F6E7C7C22636F6C756D6E2D72657665727365223D3D3D6E2E666C6578446972656374696F6E3F22';
wwv_flow_imp.g_varchar2_table(135) := '766572746963616C223A22686F72697A6F6E74616C223B6966282267726964223D3D3D6E2E646973706C61792972657475726E206E2E6772696454656D706C617465436F6C756D6E732E73706C697428222022292E6C656E6774683C3D313F2276657274';
wwv_flow_imp.g_varchar2_table(136) := '6963616C223A22686F72697A6F6E74616C223B696628692626612E666C6F61742626226E6F6E6522213D3D612E666C6F6174297B653D226C656674223D3D3D612E666C6F61743F226C656674223A227269676874223B72657475726E21727C7C22626F74';
wwv_flow_imp.g_varchar2_table(137) := '6822213D3D6C2E636C65617226266C2E636C656172213D3D653F22686F72697A6F6E74616C223A22766572746963616C227D72657475726E206926262822626C6F636B223D3D3D612E646973706C61797C7C22666C6578223D3D3D612E646973706C6179';
wwv_flow_imp.g_varchar2_table(138) := '7C7C227461626C65223D3D3D612E646973706C61797C7C2267726964223D3D3D612E646973706C61797C7C6F3C3D732626226E6F6E65223D3D3D6E5B49745D7C7C722626226E6F6E65223D3D3D6E5B49745D26266F3C732B74293F22766572746963616C';
wwv_flow_imp.g_varchar2_table(139) := '223A22686F72697A6F6E74616C227D2C58743D66756E6374696F6E2874297B66756E6374696F6E206C28722C61297B72657475726E2066756E6374696F6E28742C652C6E2C6F297B76617220693D742E6F7074696F6E732E67726F75702E6E616D652626';
wwv_flow_imp.g_varchar2_table(140) := '652E6F7074696F6E732E67726F75702E6E616D652626742E6F7074696F6E732E67726F75702E6E616D653D3D3D652E6F7074696F6E732E67726F75702E6E616D653B6966286E756C6C3D3D72262628617C7C69292972657475726E21303B6966286E756C';
wwv_flow_imp.g_varchar2_table(141) := '6C3D3D727C7C21313D3D3D722972657475726E21313B69662861262622636C6F6E65223D3D3D722972657475726E20723B6966282266756E6374696F6E223D3D747970656F6620722972657475726E206C287228742C652C6E2C6F292C612928742C652C';
wwv_flow_imp.g_varchar2_table(142) := '6E2C6F293B653D28613F743A65292E6F7074696F6E732E67726F75702E6E616D653B72657475726E21303D3D3D727C7C22737472696E67223D3D747970656F6620722626723D3D3D657C7C722E6A6F696E26262D313C722E696E6465784F662865297D7D';
wwv_flow_imp.g_varchar2_table(143) := '76617220653D7B7D2C6E3D742E67726F75703B6E2626226F626A656374223D3D73286E297C7C286E3D7B6E616D653A6E7D292C652E6E616D653D6E2E6E616D652C652E636865636B50756C6C3D6C286E2E70756C6C2C2130292C652E636865636B507574';
wwv_flow_imp.g_varchar2_table(144) := '3D6C286E2E707574292C652E726576657274436C6F6E653D6E2E726576657274436C6F6E652C742E67726F75703D657D2C59743D66756E6374696F6E28297B216B7426264A262652284A2C22646973706C6179222C226E6F6E6522297D2C42743D66756E';
wwv_flow_imp.g_varchar2_table(145) := '6374696F6E28297B216B7426264A262652284A2C22646973706C6179222C2222297D3B41742626216E2626646F63756D656E742E6164644576656E744C697374656E65722822636C69636B222C66756E6374696F6E2874297B6966285374297265747572';
wwv_flow_imp.g_varchar2_table(146) := '6E20742E70726576656E7444656661756C7428292C742E73746F7050726F7061676174696F6E2626742E73746F7050726F7061676174696F6E28292C742E73746F70496D6D65646961746550726F7061676174696F6E2626742E73746F70496D6D656469';
wwv_flow_imp.g_varchar2_table(147) := '61746550726F7061676174696F6E28292C53743D21317D2C2130293B66756E6374696F6E2046742874297B69662824297B743D742E746F75636865733F742E746F75636865735B305D3A743B76617220653D28693D742E636C69656E74582C723D742E63';
wwv_flow_imp.g_varchar2_table(148) := '6C69656E74592C5F742E736F6D652866756E6374696F6E2874297B76617220653D745B4B5D2E6F7074696F6E732E656D707479496E736572745468726573686F6C643B6966286526262146287429297B766172206E3D582874292C6F3D693E3D6E2E6C65';
wwv_flow_imp.g_varchar2_table(149) := '66742D652626693C3D6E2E72696768742B652C653D723E3D6E2E746F702D652626723C3D6E2E626F74746F6D2B653B72657475726E206F2626653F613D743A766F696420307D7D292C61293B69662865297B766172206E2C6F3D7B7D3B666F72286E2069';
wwv_flow_imp.g_varchar2_table(150) := '6E207429742E6861734F776E50726F7065727479286E292626286F5B6E5D3D745B6E5D293B6F2E7461726765743D6F2E726F6F74456C3D652C6F2E70726576656E7444656661756C743D766F696420302C6F2E73746F7050726F7061676174696F6E3D76';
wwv_flow_imp.g_varchar2_table(151) := '6F696420302C655B4B5D2E5F6F6E447261674F766572286F297D7D76617220692C722C617D66756E6374696F6E206A742874297B242626242E706172656E744E6F64655B4B5D2E5F69734F75747369646554686973456C28742E746172676574297D6675';
wwv_flow_imp.g_varchar2_table(152) := '6E6374696F6E20487428742C65297B69662821747C7C21742E6E6F6465547970657C7C31213D3D742E6E6F646554797065297468726F7722536F727461626C653A2060656C60206D75737420626520616E2048544D4C456C656D656E742C206E6F742022';
wwv_flow_imp.g_varchar2_table(153) := '2E636F6E636174287B7D2E746F537472696E672E63616C6C287429293B746869732E656C3D742C746869732E6F7074696F6E733D653D61287B7D2C65292C745B4B5D3D746869733B766172206E2C6F2C693D7B67726F75703A6E756C6C2C736F72743A21';
wwv_flow_imp.g_varchar2_table(154) := '302C64697361626C65643A21312C73746F72653A6E756C6C2C68616E646C653A6E756C6C2C647261676761626C653A2F5E5B756F5D6C242F692E7465737428742E6E6F64654E616D65293F223E6C69223A223E2A222C737761705468726573686F6C643A';
wwv_flow_imp.g_varchar2_table(155) := '312C696E76657274537761703A21312C696E766572746564537761705468726573686F6C643A6E756C6C2C72656D6F7665436C6F6E654F6E486964653A21302C646972656374696F6E3A66756E6374696F6E28297B72657475726E20527428742C746869';
wwv_flow_imp.g_varchar2_table(156) := '732E6F7074696F6E73297D2C67686F7374436C6173733A22736F727461626C652D67686F7374222C63686F73656E436C6173733A22736F727461626C652D63686F73656E222C64726167436C6173733A22736F727461626C652D64726167222C69676E6F';
wwv_flow_imp.g_varchar2_table(157) := '72653A22612C20696D67222C66696C7465723A6E756C6C2C70726576656E744F6E46696C7465723A21302C616E696D6174696F6E3A302C656173696E673A6E756C6C2C736574446174613A66756E6374696F6E28742C65297B742E736574446174612822';
wwv_flow_imp.g_varchar2_table(158) := '54657874222C652E74657874436F6E74656E74297D2C64726F70427562626C653A21312C647261676F766572427562626C653A21312C646174614964417474723A22646174612D6964222C64656C61793A302C64656C61794F6E546F7563684F6E6C793A';
wwv_flow_imp.g_varchar2_table(159) := '21312C746F75636853746172745468726573686F6C643A284E756D6265722E7061727365496E743F4E756D6265723A77696E646F77292E7061727365496E742877696E646F772E646576696365506978656C526174696F2C3130297C7C312C666F726365';
wwv_flow_imp.g_varchar2_table(160) := '46616C6C6261636B3A21312C66616C6C6261636B436C6173733A22736F727461626C652D66616C6C6261636B222C66616C6C6261636B4F6E426F64793A21312C66616C6C6261636B546F6C6572616E63653A302C66616C6C6261636B4F66667365743A7B';
wwv_flow_imp.g_varchar2_table(161) := '783A302C793A307D2C737570706F7274506F696E7465723A2131213D3D48742E737570706F7274506F696E746572262622506F696E7465724576656E7422696E2077696E646F7726262821757C7C64292C656D707479496E736572745468726573686F6C';
wwv_flow_imp.g_varchar2_table(162) := '643A357D3B666F72286E20696E20472E696E697469616C697A65506C7567696E7328746869732C742C69292C69296E20696E20657C7C28655B6E5D3D695B6E5D293B666F72286F20696E2058742865292C7468697329225F223D3D3D6F2E636861724174';
wwv_flow_imp.g_varchar2_table(163) := '28302926262266756E6374696F6E223D3D747970656F6620746869735B6F5D262628746869735B6F5D3D746869735B6F5D2E62696E64287468697329293B746869732E6E6174697665447261676761626C653D21652E666F72636546616C6C6261636B26';
wwv_flow_imp.g_varchar2_table(164) := '2650742C746869732E6E6174697665447261676761626C65262628746869732E6F7074696F6E732E746F75636853746172745468726573686F6C643D31292C652E737570706F7274506F696E7465723F6628742C22706F696E746572646F776E222C7468';
wwv_flow_imp.g_varchar2_table(165) := '69732E5F6F6E5461705374617274293A286628742C226D6F757365646F776E222C746869732E5F6F6E5461705374617274292C6628742C22746F7563687374617274222C746869732E5F6F6E546170537461727429292C746869732E6E61746976654472';
wwv_flow_imp.g_varchar2_table(166) := '61676761626C652626286628742C22647261676F766572222C74686973292C6628742C2264726167656E746572222C7468697329292C5F742E7075736828746869732E656C292C652E73746F72652626652E73746F72652E6765742626746869732E736F';
wwv_flow_imp.g_varchar2_table(167) := '727428652E73746F72652E6765742874686973297C7C5B5D292C6128746869732C4E2829297D66756E6374696F6E204C7428742C652C6E2C6F2C692C722C612C6C297B76617220732C632C753D745B4B5D2C643D752E6F7074696F6E732E6F6E4D6F7665';
wwv_flow_imp.g_varchar2_table(168) := '3B72657475726E2177696E646F772E437573746F6D4576656E747C7C797C7C773F28733D646F63756D656E742E6372656174654576656E7428224576656E742229292E696E69744576656E7428226D6F7665222C21302C2130293A733D6E657720437573';
wwv_flow_imp.g_varchar2_table(169) := '746F6D4576656E7428226D6F7665222C7B627562626C65733A21302C63616E63656C61626C653A21307D292C732E746F3D652C732E66726F6D3D742C732E647261676765643D6E2C732E64726167676564526563743D6F2C732E72656C617465643D697C';
wwv_flow_imp.g_varchar2_table(170) := '7C652C732E72656C61746564526563743D727C7C582865292C732E77696C6C496E7365727441667465723D6C2C732E6F726967696E616C4576656E743D612C742E64697370617463684576656E742873292C633D643F642E63616C6C28752C732C61293A';
wwv_flow_imp.g_varchar2_table(171) := '637D66756E6374696F6E204B742874297B742E647261676761626C653D21317D66756E6374696F6E20577428297B4F743D21317D66756E6374696F6E207A742874297B72657475726E2073657454696D656F757428742C30297D66756E6374696F6E2047';
wwv_flow_imp.g_varchar2_table(172) := '742874297B72657475726E20636C65617254696D656F75742874297D48742E70726F746F747970653D7B636F6E7374727563746F723A48742C5F69734F75747369646554686973456C3A66756E6374696F6E2874297B746869732E656C2E636F6E746169';
wwv_flow_imp.g_varchar2_table(173) := '6E732874297C7C743D3D3D746869732E656C7C7C2862743D6E756C6C297D2C5F676574446972656374696F6E3A66756E6374696F6E28742C65297B72657475726E2266756E6374696F6E223D3D747970656F6620746869732E6F7074696F6E732E646972';
wwv_flow_imp.g_varchar2_table(174) := '656374696F6E3F746869732E6F7074696F6E732E646972656374696F6E2E63616C6C28746869732C742C652C24293A746869732E6F7074696F6E732E646972656374696F6E7D2C5F6F6E54617053746172743A66756E6374696F6E2865297B696628652E';
wwv_flow_imp.g_varchar2_table(175) := '63616E63656C61626C65297B766172206E3D746869732C6F3D746869732E656C2C743D746869732E6F7074696F6E732C693D742E70726576656E744F6E46696C7465722C723D652E747970652C613D652E746F75636865732626652E746F75636865735B';
wwv_flow_imp.g_varchar2_table(176) := '305D7C7C652E706F696E74657254797065262622746F756368223D3D3D652E706F696E746572547970652626652C6C3D28617C7C65292E7461726765742C733D652E7461726765742E736861646F77526F6F74262628652E706174682626652E70617468';
wwv_flow_imp.g_varchar2_table(177) := '5B305D7C7C652E636F6D706F736564506174682626652E636F6D706F7365645061746828295B305D297C7C6C2C633D742E66696C7465723B6966282166756E6374696F6E2874297B4D742E6C656E6774683D303B76617220653D742E676574456C656D65';
wwv_flow_imp.g_varchar2_table(178) := '6E747342795461674E616D652822696E70757422292C6E3D652E6C656E6774683B666F72283B6E2D2D3B297B766172206F3D655B6E5D3B6F2E636865636B656426264D742E70757368286F297D7D286F292C2124262621282F6D6F757365646F776E7C70';
wwv_flow_imp.g_varchar2_table(179) := '6F696E746572646F776E2F2E74657374287229262630213D3D652E627574746F6E7C7C742E64697361626C656429262621732E6973436F6E74656E744564697461626C65262628746869732E6E6174697665447261676761626C657C7C21757C7C216C7C';
wwv_flow_imp.g_varchar2_table(180) := '7C2253454C45435422213D3D6C2E7461674E616D652E746F55707065724361736528292926262128286C3D50286C2C742E647261676761626C652C6F2C2131292926266C2E616E696D617465647C7C6E743D3D3D6C29297B69662872743D6A286C292C6C';
wwv_flow_imp.g_varchar2_table(181) := '743D6A286C2C742E647261676761626C65292C2266756E6374696F6E223D3D747970656F662063297B696628632E63616C6C28746869732C652C6C2C74686973292972657475726E205A287B736F727461626C653A6E2C726F6F74456C3A732C6E616D65';
wwv_flow_imp.g_varchar2_table(182) := '3A2266696C746572222C746172676574456C3A6C2C746F456C3A6F2C66726F6D456C3A6F7D292C71282266696C746572222C6E2C7B6576743A657D292C766F696428692626652E70726576656E7444656661756C742829297D656C736520696628633D63';
wwv_flow_imp.g_varchar2_table(183) := '2626632E73706C697428222C22292E736F6D652866756E6374696F6E2874297B696628743D5028732C742E7472696D28292C6F2C2131292972657475726E205A287B736F727461626C653A6E2C726F6F74456C3A742C6E616D653A2266696C746572222C';
wwv_flow_imp.g_varchar2_table(184) := '746172676574456C3A6C2C66726F6D456C3A6F2C746F456C3A6F7D292C71282266696C746572222C6E2C7B6576743A657D292C21307D292972657475726E20766F696428692626652E70726576656E7444656661756C742829293B742E68616E646C6526';
wwv_flow_imp.g_varchar2_table(185) := '26215028732C742E68616E646C652C6F2C2131297C7C746869732E5F7072657061726544726167537461727428652C612C6C297D7D7D2C5F707265706172654472616753746172743A66756E6374696F6E28742C652C6E297B766172206F2C693D746869';
wwv_flow_imp.g_varchar2_table(186) := '732C723D692E656C2C613D692E6F7074696F6E732C6C3D722E6F776E6572446F63756D656E743B6E2626212426266E2E706172656E744E6F64653D3D3D722626286F3D58286E292C74743D722C513D28243D6E292E706172656E744E6F64652C65743D24';
wwv_flow_imp.g_varchar2_table(187) := '2E6E6578745369626C696E672C6E743D6E2C63743D612E67726F75702C64743D7B7461726765743A48742E647261676765643D242C636C69656E74583A28657C7C74292E636C69656E74582C636C69656E74593A28657C7C74292E636C69656E74597D2C';
wwv_flow_imp.g_varchar2_table(188) := '67743D64742E636C69656E74582D6F2E6C6566742C6D743D64742E636C69656E74592D6F2E746F702C746869732E5F6C617374583D28657C7C74292E636C69656E74582C746869732E5F6C617374593D28657C7C74292E636C69656E74592C242E737479';
wwv_flow_imp.g_varchar2_table(189) := '6C655B2277696C6C2D6368616E6765225D3D22616C6C222C6F3D66756E6374696F6E28297B71282264656C6179456E646564222C692C7B6576743A747D292C48742E6576656E7443616E63656C65643F692E5F6F6E44726F7028293A28692E5F64697361';
wwv_flow_imp.g_varchar2_table(190) := '626C6544656C61796564447261674576656E747328292C21632626692E6E6174697665447261676761626C65262628242E647261676761626C653D2130292C692E5F7472696767657244726167537461727428742C65292C5A287B736F727461626C653A';
wwv_flow_imp.g_varchar2_table(191) := '692C6E616D653A2263686F6F7365222C6F726967696E616C4576656E743A747D292C6B28242C612E63686F73656E436C6173732C213029297D2C612E69676E6F72652E73706C697428222C22292E666F72456163682866756E6374696F6E2874297B4528';
wwv_flow_imp.g_varchar2_table(192) := '242C742E7472696D28292C4B74297D292C66286C2C22647261676F766572222C4674292C66286C2C226D6F7573656D6F7665222C4674292C66286C2C22746F7563686D6F7665222C4674292C612E737570706F7274506F696E7465723F2866286C2C2270';
wwv_flow_imp.g_varchar2_table(193) := '6F696E7465727570222C692E5F6F6E44726F70292C746869732E6E6174697665447261676761626C657C7C66286C2C22706F696E74657263616E63656C222C692E5F6F6E44726F7029293A2866286C2C226D6F7573657570222C692E5F6F6E44726F7029';
wwv_flow_imp.g_varchar2_table(194) := '2C66286C2C22746F756368656E64222C692E5F6F6E44726F70292C66286C2C22746F75636863616E63656C222C692E5F6F6E44726F7029292C632626746869732E6E6174697665447261676761626C65262628746869732E6F7074696F6E732E746F7563';
wwv_flow_imp.g_varchar2_table(195) := '6853746172745468726573686F6C643D342C242E647261676761626C653D2130292C71282264656C61795374617274222C746869732C7B6576743A747D292C21612E64656C61797C7C612E64656C61794F6E546F7563684F6E6C79262621657C7C746869';
wwv_flow_imp.g_varchar2_table(196) := '732E6E6174697665447261676761626C65262628777C7C79293F6F28293A48742E6576656E7443616E63656C65643F746869732E5F6F6E44726F7028293A28612E737570706F7274506F696E7465723F2866286C2C22706F696E7465727570222C692E5F';
wwv_flow_imp.g_varchar2_table(197) := '64697361626C6544656C6179656444726167292C66286C2C22706F696E74657263616E63656C222C692E5F64697361626C6544656C617965644472616729293A2866286C2C226D6F7573657570222C692E5F64697361626C6544656C6179656444726167';
wwv_flow_imp.g_varchar2_table(198) := '292C66286C2C22746F756368656E64222C692E5F64697361626C6544656C6179656444726167292C66286C2C22746F75636863616E63656C222C692E5F64697361626C6544656C617965644472616729292C66286C2C226D6F7573656D6F7665222C692E';
wwv_flow_imp.g_varchar2_table(199) := '5F64656C6179656444726167546F7563684D6F766548616E646C6572292C66286C2C22746F7563686D6F7665222C692E5F64656C6179656444726167546F7563684D6F766548616E646C6572292C612E737570706F7274506F696E746572262666286C2C';
wwv_flow_imp.g_varchar2_table(200) := '22706F696E7465726D6F7665222C692E5F64656C6179656444726167546F7563684D6F766548616E646C6572292C692E5F64726167537461727454696D65723D73657454696D656F7574286F2C612E64656C61792929297D2C5F64656C61796564447261';
wwv_flow_imp.g_varchar2_table(201) := '67546F7563684D6F766548616E646C65723A66756E6374696F6E2874297B743D742E746F75636865733F742E746F75636865735B305D3A743B4D6174682E6D6178284D6174682E61627328742E636C69656E74582D746869732E5F6C61737458292C4D61';
wwv_flow_imp.g_varchar2_table(202) := '74682E61627328742E636C69656E74592D746869732E5F6C6173745929293E3D4D6174682E666C6F6F7228746869732E6F7074696F6E732E746F75636853746172745468726573686F6C642F28746869732E6E6174697665447261676761626C65262677';
wwv_flow_imp.g_varchar2_table(203) := '696E646F772E646576696365506978656C526174696F7C7C3129292626746869732E5F64697361626C6544656C617965644472616728297D2C5F64697361626C6544656C61796564447261673A66756E6374696F6E28297B2426264B742824292C636C65';
wwv_flow_imp.g_varchar2_table(204) := '617254696D656F757428746869732E5F64726167537461727454696D6572292C746869732E5F64697361626C6544656C61796564447261674576656E747328297D2C5F64697361626C6544656C61796564447261674576656E74733A66756E6374696F6E';
wwv_flow_imp.g_varchar2_table(205) := '28297B76617220743D746869732E656C2E6F776E6572446F63756D656E743B7028742C226D6F7573657570222C746869732E5F64697361626C6544656C6179656444726167292C7028742C22746F756368656E64222C746869732E5F64697361626C6544';
wwv_flow_imp.g_varchar2_table(206) := '656C6179656444726167292C7028742C22746F75636863616E63656C222C746869732E5F64697361626C6544656C6179656444726167292C7028742C22706F696E7465727570222C746869732E5F64697361626C6544656C6179656444726167292C7028';
wwv_flow_imp.g_varchar2_table(207) := '742C22706F696E74657263616E63656C222C746869732E5F64697361626C6544656C6179656444726167292C7028742C226D6F7573656D6F7665222C746869732E5F64656C6179656444726167546F7563684D6F766548616E646C6572292C7028742C22';
wwv_flow_imp.g_varchar2_table(208) := '746F7563686D6F7665222C746869732E5F64656C6179656444726167546F7563684D6F766548616E646C6572292C7028742C22706F696E7465726D6F7665222C746869732E5F64656C6179656444726167546F7563684D6F766548616E646C6572297D2C';
wwv_flow_imp.g_varchar2_table(209) := '5F747269676765724472616753746172743A66756E6374696F6E28742C65297B653D657C7C22746F756368223D3D742E706F696E746572547970652626742C21746869732E6E6174697665447261676761626C657C7C653F746869732E6F7074696F6E73';
wwv_flow_imp.g_varchar2_table(210) := '2E737570706F7274506F696E7465723F6628646F63756D656E742C22706F696E7465726D6F7665222C746869732E5F6F6E546F7563684D6F7665293A6628646F63756D656E742C653F22746F7563686D6F7665223A226D6F7573656D6F7665222C746869';
wwv_flow_imp.g_varchar2_table(211) := '732E5F6F6E546F7563684D6F7665293A286628242C2264726167656E64222C74686973292C662874742C22647261677374617274222C746869732E5F6F6E44726167537461727429293B7472797B646F63756D656E742E73656C656374696F6E3F7A7428';
wwv_flow_imp.g_varchar2_table(212) := '66756E6374696F6E28297B646F63756D656E742E73656C656374696F6E2E656D70747928297D293A77696E646F772E67657453656C656374696F6E28292E72656D6F7665416C6C52616E67657328297D63617463682874297B7D7D2C5F64726167537461';
wwv_flow_imp.g_varchar2_table(213) := '727465643A66756E6374696F6E28742C65297B766172206E3B45743D21312C74742626243F287128226472616753746172746564222C746869732C7B6576743A657D292C746869732E6E6174697665447261676761626C6526266628646F63756D656E74';
wwv_flow_imp.g_varchar2_table(214) := '2C22647261676F766572222C6A74292C6E3D746869732E6F7074696F6E732C747C7C6B28242C6E2E64726167436C6173732C2131292C6B28242C6E2E67686F7374436C6173732C2130292C48742E6163746976653D746869732C742626746869732E5F61';
wwv_flow_imp.g_varchar2_table(215) := '7070656E6447686F737428292C5A287B736F727461626C653A746869732C6E616D653A227374617274222C6F726967696E616C4576656E743A657D29293A746869732E5F6E756C6C696E6728297D2C5F656D756C617465447261674F7665723A66756E63';
wwv_flow_imp.g_varchar2_table(216) := '74696F6E28297B6966286874297B746869732E5F6C617374583D68742E636C69656E74582C746869732E5F6C617374593D68742E636C69656E74592C597428293B666F722876617220743D646F63756D656E742E656C656D656E7446726F6D506F696E74';
wwv_flow_imp.g_varchar2_table(217) := '2868742E636C69656E74582C68742E636C69656E7459292C653D743B742626742E736861646F77526F6F74262628743D742E736861646F77526F6F742E656C656D656E7446726F6D506F696E742868742E636C69656E74582C68742E636C69656E745929';
wwv_flow_imp.g_varchar2_table(218) := '29213D3D653B29653D743B696628242E706172656E744E6F64655B4B5D2E5F69734F75747369646554686973456C2874292C6529646F7B696628655B4B5D29696628655B4B5D2E5F6F6E447261674F766572287B636C69656E74583A68742E636C69656E';
wwv_flow_imp.g_varchar2_table(219) := '74582C636C69656E74593A68742E636C69656E74592C7461726765743A742C726F6F74456C3A657D29262621746869732E6F7074696F6E732E647261676F766572427562626C6529627265616B7D7768696C6528653D6D28743D6529293B427428297D7D';
wwv_flow_imp.g_varchar2_table(220) := '2C5F6F6E546F7563684D6F76653A66756E6374696F6E2874297B6966286474297B76617220653D746869732E6F7074696F6E732C6E3D652E66616C6C6261636B546F6C6572616E63652C6F3D652E66616C6C6261636B4F66667365742C693D742E746F75';
wwv_flow_imp.g_varchar2_table(221) := '636865733F742E746F75636865735B305D3A742C723D4A262644284A2C2130292C613D4A2626722626722E612C6C3D4A2626722626722E642C653D4E7426264474262653284474292C613D28692E636C69656E74582D64742E636C69656E74582B6F2E78';
wwv_flow_imp.g_varchar2_table(222) := '292F28617C7C31292B28653F655B305D2D78745B305D3A30292F28617C7C31292C6C3D28692E636C69656E74592D64742E636C69656E74592B6F2E79292F286C7C7C31292B28653F655B315D2D78745B315D3A30292F286C7C7C31293B6966282148742E';
wwv_flow_imp.g_varchar2_table(223) := '6163746976652626214574297B6966286E26264D6174682E6D6178284D6174682E61627328692E636C69656E74582D746869732E5F6C61737458292C4D6174682E61627328692E636C69656E74592D746869732E5F6C6173745929293C6E297265747572';
wwv_flow_imp.g_varchar2_table(224) := '6E3B746869732E5F6F6E44726167537461727428742C2130297D4A262628723F28722E652B3D612D2866747C7C30292C722E662B3D6C2D2870747C7C3029293A723D7B613A312C623A302C633A302C643A312C653A612C663A6C7D2C723D226D61747269';
wwv_flow_imp.g_varchar2_table(225) := '7828222E636F6E63617428722E612C222C22292E636F6E63617428722E622C222C22292E636F6E63617428722E632C222C22292E636F6E63617428722E642C222C22292E636F6E63617428722E652C222C22292E636F6E63617428722E662C222922292C';
wwv_flow_imp.g_varchar2_table(226) := '52284A2C227765626B69745472616E73666F726D222C72292C52284A2C226D6F7A5472616E73666F726D222C72292C52284A2C226D735472616E73666F726D222C72292C52284A2C227472616E73666F726D222C72292C66743D612C70743D6C2C68743D';
wwv_flow_imp.g_varchar2_table(227) := '69292C742E63616E63656C61626C652626742E70726576656E7444656661756C7428297D7D2C5F617070656E6447686F73743A66756E6374696F6E28297B696628214A297B76617220743D746869732E6F7074696F6E732E66616C6C6261636B4F6E426F';
wwv_flow_imp.g_varchar2_table(228) := '64793F646F63756D656E742E626F64793A74742C653D5828242C21302C4E742C21302C74292C6E3D746869732E6F7074696F6E733B6966284E74297B666F722844743D743B22737461746963223D3D3D522844742C22706F736974696F6E22292626226E';
wwv_flow_imp.g_varchar2_table(229) := '6F6E65223D3D3D522844742C227472616E73666F726D222926264474213D3D646F63756D656E743B2944743D44742E706172656E744E6F64653B4474213D3D646F63756D656E742E626F647926264474213D3D646F63756D656E742E646F63756D656E74';
wwv_flow_imp.g_varchar2_table(230) := '456C656D656E743F2844743D3D3D646F63756D656E7426262844743D4F2829292C652E746F702B3D44742E7363726F6C6C546F702C652E6C6566742B3D44742E7363726F6C6C4C656674293A44743D4F28292C78743D53284474297D6B284A3D242E636C';
wwv_flow_imp.g_varchar2_table(231) := '6F6E654E6F6465282130292C6E2E67686F7374436C6173732C2131292C6B284A2C6E2E66616C6C6261636B436C6173732C2130292C6B284A2C6E2E64726167436C6173732C2130292C52284A2C227472616E736974696F6E222C2222292C52284A2C2274';
wwv_flow_imp.g_varchar2_table(232) := '72616E73666F726D222C2222292C52284A2C22626F782D73697A696E67222C22626F726465722D626F7822292C52284A2C226D617267696E222C30292C52284A2C22746F70222C652E746F70292C52284A2C226C656674222C652E6C656674292C52284A';
wwv_flow_imp.g_varchar2_table(233) := '2C227769647468222C652E7769647468292C52284A2C22686569676874222C652E686569676874292C52284A2C226F706163697479222C22302E3822292C52284A2C22706F736974696F6E222C4E743F226162736F6C757465223A22666978656422292C';
wwv_flow_imp.g_varchar2_table(234) := '52284A2C227A496E646578222C2231303030303022292C52284A2C22706F696E7465724576656E7473222C226E6F6E6522292C48742E67686F73743D4A2C742E617070656E644368696C64284A292C52284A2C227472616E73666F726D2D6F726967696E';
wwv_flow_imp.g_varchar2_table(235) := '222C67742F7061727365496E74284A2E7374796C652E7769647468292A3130302B222520222B6D742F7061727365496E74284A2E7374796C652E686569676874292A3130302B222522297D7D2C5F6F6E4472616753746172743A66756E6374696F6E2874';
wwv_flow_imp.g_varchar2_table(236) := '2C65297B766172206E3D746869732C6F3D742E646174615472616E736665722C693D6E2E6F7074696F6E733B712822647261675374617274222C746869732C7B6576743A747D292C48742E6576656E7443616E63656C65643F746869732E5F6F6E44726F';
wwv_flow_imp.g_varchar2_table(237) := '7028293A287128227365747570436C6F6E65222C74686973292C48742E6576656E7443616E63656C65647C7C28286F743D54282429292E72656D6F76654174747269627574652822696422292C6F742E647261676761626C653D21312C6F742E7374796C';
wwv_flow_imp.g_varchar2_table(238) := '655B2277696C6C2D6368616E6765225D3D22222C746869732E5F68696465436C6F6E6528292C6B286F742C746869732E6F7074696F6E732E63686F73656E436C6173732C2131292C48742E636C6F6E653D6F74292C6E2E636C6F6E6549643D7A74286675';
wwv_flow_imp.g_varchar2_table(239) := '6E6374696F6E28297B712822636C6F6E65222C6E292C48742E6576656E7443616E63656C65647C7C286E2E6F7074696F6E732E72656D6F7665436C6F6E654F6E486964657C7C74742E696E736572744265666F7265286F742C24292C6E2E5F6869646543';
wwv_flow_imp.g_varchar2_table(240) := '6C6F6E6528292C5A287B736F727461626C653A6E2C6E616D653A22636C6F6E65227D29297D292C657C7C6B28242C692E64726167436C6173732C2130292C653F2853743D21302C6E2E5F6C6F6F7049643D736574496E74657276616C286E2E5F656D756C';
wwv_flow_imp.g_varchar2_table(241) := '617465447261674F7665722C353029293A287028646F63756D656E742C226D6F7573657570222C6E2E5F6F6E44726F70292C7028646F63756D656E742C22746F756368656E64222C6E2E5F6F6E44726F70292C7028646F63756D656E742C22746F756368';
wwv_flow_imp.g_varchar2_table(242) := '63616E63656C222C6E2E5F6F6E44726F70292C6F2626286F2E656666656374416C6C6F7765643D226D6F7665222C692E736574446174612626692E736574446174612E63616C6C286E2C6F2C2429292C6628646F63756D656E742C2264726F70222C6E29';
wwv_flow_imp.g_varchar2_table(243) := '2C5228242C227472616E73666F726D222C227472616E736C6174655A2830292229292C45743D21302C6E2E5F64726167537461727449643D7A74286E2E5F64726167537461727465642E62696E64286E2C652C7429292C6628646F63756D656E742C2273';
wwv_flow_imp.g_varchar2_table(244) := '656C6563747374617274222C6E292C76743D21302C77696E646F772E67657453656C656374696F6E28292E72656D6F7665416C6C52616E67657328292C7526265228646F63756D656E742E626F64792C22757365722D73656C656374222C226E6F6E6522';
wwv_flow_imp.g_varchar2_table(245) := '29297D2C5F6F6E447261674F7665723A66756E6374696F6E286E297B766172206F2C692C722C742C652C613D746869732E656C2C6C3D6E2E7461726765742C733D746869732E6F7074696F6E732C633D732E67726F75702C753D48742E6163746976652C';
wwv_flow_imp.g_varchar2_table(246) := '643D63743D3D3D632C683D732E736F72742C663D75747C7C752C703D746869732C673D21313B696628214F74297B696628766F69642030213D3D6E2E70726576656E7444656661756C7426266E2E63616E63656C61626C6526266E2E70726576656E7444';
wwv_flow_imp.g_varchar2_table(247) := '656661756C7428292C6C3D50286C2C732E647261676761626C652C612C2130292C4F2822647261674F76657222292C48742E6576656E7443616E63656C65642972657475726E20673B696628242E636F6E7461696E73286E2E746172676574297C7C6C2E';
wwv_flow_imp.g_varchar2_table(248) := '616E696D6174656426266C2E616E696D6174696E675826266C2E616E696D6174696E67597C7C702E5F69676E6F72655768696C65416E696D6174696E673D3D3D6C2972657475726E2041282131293B69662853743D21312C75262621732E64697361626C';
wwv_flow_imp.g_varchar2_table(249) := '6564262628643F687C7C28693D51213D3D7474293A75743D3D3D746869737C7C28746869732E6C6173745075744D6F64653D63742E636865636B50756C6C28746869732C752C242C6E29292626632E636865636B50757428746869732C752C242C6E2929';
wwv_flow_imp.g_varchar2_table(250) := '297B696628723D22766572746963616C223D3D3D746869732E5F676574446972656374696F6E286E2C6C292C6F3D582824292C4F2822647261674F76657256616C696422292C48742E6576656E7443616E63656C65642972657475726E20673B69662869';
wwv_flow_imp.g_varchar2_table(251) := '2972657475726E20513D74742C4D28292C746869732E5F68696465436C6F6E6528292C4F282272657665727422292C48742E6576656E7443616E63656C65647C7C2865743F74742E696E736572744265666F726528242C6574293A74742E617070656E64';
wwv_flow_imp.g_varchar2_table(252) := '4368696C64282429292C41282130293B766172206D3D4628612C732E647261676761626C65293B6966286D262628533D6E2C633D722C783D5828462828453D74686973292E656C2C452E6F7074696F6E732E647261676761626C6529292C453D4C28452E';
wwv_flow_imp.g_varchar2_table(253) := '656C2C452E6F7074696F6E732C4A292C2128633F532E636C69656E74583E452E72696768742B31307C7C532E636C69656E74593E782E626F74746F6D2626532E636C69656E74583E782E6C6566743A532E636C69656E74593E452E626F74746F6D2B3130';
wwv_flow_imp.g_varchar2_table(254) := '7C7C532E636C69656E74583E782E72696768742626532E636C69656E74593E782E746F70297C7C6D2E616E696D6174656429297B6966286D262628743D6E2C653D722C433D58284228285F3D74686973292E656C2C302C5F2E6F7074696F6E732C213029';
wwv_flow_imp.g_varchar2_table(255) := '292C5F3D4C285F2E656C2C5F2E6F7074696F6E732C4A292C653F742E636C69656E74583C5F2E6C6566742D31307C7C742E636C69656E74593C432E746F702626742E636C69656E74583C432E72696768743A742E636C69656E74593C5F2E746F702D3130';
wwv_flow_imp.g_varchar2_table(256) := '7C7C742E636C69656E74593C432E626F74746F6D2626742E636C69656E74583C432E6C65667429297B76617220763D4228612C302C732C2130293B696628763D3D3D242972657475726E2041282131293B696628443D58286C3D76292C2131213D3D4C74';
wwv_flow_imp.g_varchar2_table(257) := '2874742C612C242C6F2C6C2C442C6E2C2131292972657475726E204D28292C612E696E736572744265666F726528242C76292C513D612C4E28292C41282130297D656C7365206966286C2E706172656E744E6F64653D3D3D61297B76617220622C792C77';
wwv_flow_imp.g_varchar2_table(258) := '2C443D58286C292C453D242E706172656E744E6F6465213D3D612C533D28533D242E616E696D617465642626242E746F526563747C7C6F2C783D6C2E616E696D6174656426266C2E746F526563747C7C442C5F3D28653D72293F532E6C6566743A532E74';
wwv_flow_imp.g_varchar2_table(259) := '6F702C743D653F532E72696768743A532E626F74746F6D2C433D653F532E77696474683A532E6865696768742C763D653F782E6C6566743A782E746F702C533D653F782E72696768743A782E626F74746F6D2C783D653F782E77696474683A782E686569';
wwv_flow_imp.g_varchar2_table(260) := '6768742C21285F3D3D3D767C7C743D3D3D537C7C5F2B432F323D3D3D762B782F3229292C5F3D723F22746F70223A226C656674222C433D59286C2C22746F70222C22746F7022297C7C5928242C22746F70222C22746F7022292C763D433F432E7363726F';
wwv_flow_imp.g_varchar2_table(261) := '6C6C546F703A766F696420303B6966286274213D3D6C262628793D445B5F5D2C43743D21312C54743D21532626732E696E76657274537761707C7C45292C30213D3D28623D66756E6374696F6E28742C652C6E2C6F2C692C722C612C6C297B7661722073';
wwv_flow_imp.g_varchar2_table(262) := '3D6F3F742E636C69656E74593A742E636C69656E74582C633D6F3F6E2E6865696768743A6E2E77696474682C743D6F3F6E2E746F703A6E2E6C6566742C6F3D6F3F6E2E626F74746F6D3A6E2E72696768742C6E3D21313B6966282161296966286C262677';
wwv_flow_imp.g_varchar2_table(263) := '743C632A69297B69662843743D214374262628313D3D3D79743F742B632A722F323C733A733C6F2D632A722F32293F21303A4374296E3D21303B656C736520696628313D3D3D79743F733C742B77743A6F2D77743C732972657475726E2D79747D656C73';
wwv_flow_imp.g_varchar2_table(264) := '6520696628742B632A28312D69292F323C732626733C6F2D632A28312D69292F322972657475726E2066756E6374696F6E2874297B72657475726E206A2824293C6A2874293F313A2D317D2865293B696628286E3D6E7C7C6129262628733C742B632A72';
wwv_flow_imp.g_varchar2_table(265) := '2F327C7C6F2D632A722F323C73292972657475726E20742B632F323C733F313A2D313B72657475726E20307D286E2C6C2C442C722C533F313A732E737761705468726573686F6C642C6E756C6C3D3D732E696E766572746564537761705468726573686F';
wwv_flow_imp.g_varchar2_table(266) := '6C643F732E737761705468726573686F6C643A732E696E766572746564537761705468726573686F6C642C54742C62743D3D3D6C292929666F722876617220543D6A2824293B28773D512E6368696C6472656E5B542D3D625D29262628226E6F6E65223D';
wwv_flow_imp.g_varchar2_table(267) := '3D3D5228772C22646973706C617922297C7C773D3D3D4A293B293B696628303D3D3D627C7C773D3D3D6C2972657475726E2041282131293B79743D623B76617220783D2862743D6C292E6E657874456C656D656E745369626C696E672C453D21312C533D';
wwv_flow_imp.g_varchar2_table(268) := '4C742874742C612C242C6F2C6C2C442C6E2C453D313D3D3D62293B6966282131213D3D532972657475726E2031213D3D5326262D31213D3D537C7C28453D313D3D3D53292C4F743D21302C73657454696D656F75742857742C3330292C4D28292C452626';
wwv_flow_imp.g_varchar2_table(269) := '21783F612E617070656E644368696C642824293A6C2E706172656E744E6F64652E696E736572744265666F726528242C453F783A6C292C4326264828432C302C762D432E7363726F6C6C546F70292C513D242E706172656E744E6F64652C766F69642030';
wwv_flow_imp.g_varchar2_table(270) := '3D3D3D797C7C54747C7C2877743D4D6174682E61627328792D58286C295B5F5D29292C4E28292C41282130297D7D656C73657B6966286D3D3D3D242972657475726E2041282131293B696628286C3D6D2626613D3D3D6E2E7461726765743F6D3A6C2926';
wwv_flow_imp.g_varchar2_table(271) := '2628443D58286C29292C2131213D3D4C742874742C612C242C6F2C6C2C442C6E2C21216C292972657475726E204D28292C6D26266D2E6E6578745369626C696E673F612E696E736572744265666F726528242C6D2E6E6578745369626C696E67293A612E';
wwv_flow_imp.g_varchar2_table(272) := '617070656E644368696C642824292C513D612C4E28292C41282130297D696628612E636F6E7461696E732824292972657475726E2041282131297D72657475726E21317D66756E6374696F6E204F28742C65297B7128742C702C49287B6576743A6E2C69';
wwv_flow_imp.g_varchar2_table(273) := '734F776E65723A642C617869733A723F22766572746963616C223A22686F72697A6F6E74616C222C7265766572743A692C64726167526563743A6F2C746172676574526563743A442C63616E536F72743A682C66726F6D536F727461626C653A662C7461';
wwv_flow_imp.g_varchar2_table(274) := '726765743A6C2C636F6D706C657465643A412C6F6E4D6F76653A66756E6374696F6E28742C65297B72657475726E204C742874742C612C242C6F2C742C582874292C6E2C65297D2C6368616E6765643A4E7D2C6529297D66756E6374696F6E204D28297B';
wwv_flow_imp.g_varchar2_table(275) := '4F2822647261674F766572416E696D6174696F6E4361707475726522292C702E63617074757265416E696D6174696F6E537461746528292C70213D3D662626662E63617074757265416E696D6174696F6E537461746528297D66756E6374696F6E204128';
wwv_flow_imp.g_varchar2_table(276) := '74297B72657475726E204F2822647261674F766572436F6D706C65746564222C7B696E73657274696F6E3A747D292C74262628643F752E5F68696465436C6F6E6528293A752E5F73686F77436C6F6E652870292C70213D3D662626286B28242C2875747C';
wwv_flow_imp.g_varchar2_table(277) := '7C75292E6F7074696F6E732E67686F7374436C6173732C2131292C6B28242C732E67686F7374436C6173732C213029292C7574213D3D70262670213D3D48742E6163746976653F75743D703A703D3D3D48742E6163746976652626757426262875743D6E';
wwv_flow_imp.g_varchar2_table(278) := '756C6C292C663D3D3D70262628702E5F69676E6F72655768696C65416E696D6174696E673D6C292C702E616E696D617465416C6C2866756E6374696F6E28297B4F2822647261674F766572416E696D6174696F6E436F6D706C65746522292C702E5F6967';
wwv_flow_imp.g_varchar2_table(279) := '6E6F72655768696C65416E696D6174696E673D6E756C6C7D292C70213D3D66262628662E616E696D617465416C6C28292C662E5F69676E6F72655768696C65416E696D6174696E673D6E756C6C29292C286C3D3D3D24262621242E616E696D617465647C';
wwv_flow_imp.g_varchar2_table(280) := '7C6C3D3D3D612626216C2E616E696D617465642926262862743D6E756C6C292C732E647261676F766572427562626C657C7C6E2E726F6F74456C7C7C6C3D3D3D646F63756D656E747C7C28242E706172656E744E6F64655B4B5D2E5F69734F7574736964';
wwv_flow_imp.g_varchar2_table(281) := '6554686973456C286E2E746172676574292C747C7C4674286E29292C21732E647261676F766572427562626C6526266E2E73746F7050726F7061676174696F6E26266E2E73746F7050726F7061676174696F6E28292C673D21307D66756E6374696F6E20';
wwv_flow_imp.g_varchar2_table(282) := '4E28297B61743D6A2824292C73743D6A28242C732E647261676761626C65292C5A287B736F727461626C653A702C6E616D653A226368616E6765222C746F456C3A612C6E6577496E6465783A61742C6E6577447261676761626C65496E6465783A73742C';
wwv_flow_imp.g_varchar2_table(283) := '6F726967696E616C4576656E743A6E7D297D7D2C5F69676E6F72655768696C65416E696D6174696E673A6E756C6C2C5F6F66664D6F76654576656E74733A66756E6374696F6E28297B7028646F63756D656E742C226D6F7573656D6F7665222C74686973';
wwv_flow_imp.g_varchar2_table(284) := '2E5F6F6E546F7563684D6F7665292C7028646F63756D656E742C22746F7563686D6F7665222C746869732E5F6F6E546F7563684D6F7665292C7028646F63756D656E742C22706F696E7465726D6F7665222C746869732E5F6F6E546F7563684D6F766529';
wwv_flow_imp.g_varchar2_table(285) := '2C7028646F63756D656E742C22647261676F766572222C4674292C7028646F63756D656E742C226D6F7573656D6F7665222C4674292C7028646F63756D656E742C22746F7563686D6F7665222C4674297D2C5F6F666655704576656E74733A66756E6374';
wwv_flow_imp.g_varchar2_table(286) := '696F6E28297B76617220743D746869732E656C2E6F776E6572446F63756D656E743B7028742C226D6F7573657570222C746869732E5F6F6E44726F70292C7028742C22746F756368656E64222C746869732E5F6F6E44726F70292C7028742C22706F696E';
wwv_flow_imp.g_varchar2_table(287) := '7465727570222C746869732E5F6F6E44726F70292C7028742C22706F696E74657263616E63656C222C746869732E5F6F6E44726F70292C7028742C22746F75636863616E63656C222C746869732E5F6F6E44726F70292C7028646F63756D656E742C2273';
wwv_flow_imp.g_varchar2_table(288) := '656C6563747374617274222C74686973297D2C5F6F6E44726F703A66756E6374696F6E2874297B76617220653D746869732E656C2C6E3D746869732E6F7074696F6E733B61743D6A2824292C73743D6A28242C6E2E647261676761626C65292C71282264';
wwv_flow_imp.g_varchar2_table(289) := '726F70222C746869732C7B6576743A747D292C513D242626242E706172656E744E6F64652C61743D6A2824292C73743D6A28242C6E2E647261676761626C65292C48742E6576656E7443616E63656C65647C7C2843743D54743D45743D21312C636C6561';
wwv_flow_imp.g_varchar2_table(290) := '72496E74657276616C28746869732E5F6C6F6F704964292C636C65617254696D656F757428746869732E5F64726167537461727454696D6572292C477428746869732E636C6F6E654964292C477428746869732E5F6472616753746172744964292C7468';
wwv_flow_imp.g_varchar2_table(291) := '69732E6E6174697665447261676761626C652626287028646F63756D656E742C2264726F70222C74686973292C7028652C22647261677374617274222C746869732E5F6F6E44726167537461727429292C746869732E5F6F66664D6F76654576656E7473';
wwv_flow_imp.g_varchar2_table(292) := '28292C746869732E5F6F666655704576656E747328292C7526265228646F63756D656E742E626F64792C22757365722D73656C656374222C2222292C5228242C227472616E73666F726D222C2222292C742626287674262628742E63616E63656C61626C';
wwv_flow_imp.g_varchar2_table(293) := '652626742E70726576656E7444656661756C7428292C6E2E64726F70427562626C657C7C742E73746F7050726F7061676174696F6E2829292C4A26264A2E706172656E744E6F646526264A2E706172656E744E6F64652E72656D6F76654368696C64284A';
wwv_flow_imp.g_varchar2_table(294) := '292C2874743D3D3D517C7C7574262622636C6F6E6522213D3D75742E6C6173745075744D6F64652926266F7426266F742E706172656E744E6F646526266F742E706172656E744E6F64652E72656D6F76654368696C64286F74292C24262628746869732E';
wwv_flow_imp.g_varchar2_table(295) := '6E6174697665447261676761626C6526267028242C2264726167656E64222C74686973292C4B742824292C242E7374796C655B2277696C6C2D6368616E6765225D3D22222C7674262621457426266B28242C2875747C7C74686973292E6F7074696F6E73';
wwv_flow_imp.g_varchar2_table(296) := '2E67686F7374436C6173732C2131292C6B28242C746869732E6F7074696F6E732E63686F73656E436C6173732C2131292C5A287B736F727461626C653A746869732C6E616D653A22756E63686F6F7365222C746F456C3A512C6E6577496E6465783A6E75';
wwv_flow_imp.g_varchar2_table(297) := '6C6C2C6E6577447261676761626C65496E6465783A6E756C6C2C6F726967696E616C4576656E743A747D292C7474213D3D513F28303C3D61742626285A287B726F6F74456C3A512C6E616D653A22616464222C746F456C3A512C66726F6D456C3A74742C';
wwv_flow_imp.g_varchar2_table(298) := '6F726967696E616C4576656E743A747D292C5A287B736F727461626C653A746869732C6E616D653A2272656D6F7665222C746F456C3A512C6F726967696E616C4576656E743A747D292C5A287B726F6F74456C3A512C6E616D653A22736F7274222C746F';
wwv_flow_imp.g_varchar2_table(299) := '456C3A512C66726F6D456C3A74742C6F726967696E616C4576656E743A747D292C5A287B736F727461626C653A746869732C6E616D653A22736F7274222C746F456C3A512C6F726967696E616C4576656E743A747D29292C7574262675742E7361766528';
wwv_flow_imp.g_varchar2_table(300) := '29293A6174213D3D72742626303C3D61742626285A287B736F727461626C653A746869732C6E616D653A22757064617465222C746F456C3A512C6F726967696E616C4576656E743A747D292C5A287B736F727461626C653A746869732C6E616D653A2273';
wwv_flow_imp.g_varchar2_table(301) := '6F7274222C746F456C3A512C6F726967696E616C4576656E743A747D29292C48742E6163746976652626286E756C6C213D617426262D31213D3D61747C7C2861743D72742C73743D6C74292C5A287B736F727461626C653A746869732C6E616D653A2265';
wwv_flow_imp.g_varchar2_table(302) := '6E64222C746F456C3A512C6F726967696E616C4576656E743A747D292C746869732E736176652829292929292C746869732E5F6E756C6C696E6728297D2C5F6E756C6C696E673A66756E6374696F6E28297B7128226E756C6C696E67222C74686973292C';
wwv_flow_imp.g_varchar2_table(303) := '74743D243D513D4A3D65743D6F743D6E743D69743D64743D68743D76743D61743D73743D72743D6C743D62743D79743D75743D63743D48742E647261676765643D48742E67686F73743D48742E636C6F6E653D48742E6163746976653D6E756C6C3B7661';
wwv_flow_imp.g_varchar2_table(304) := '7220653D746869732E656C3B4D742E666F72456163682866756E6374696F6E2874297B652E636F6E7461696E73287429262628742E636865636B65643D2130297D292C4D742E6C656E6774683D66743D70743D307D2C68616E646C654576656E743A6675';
wwv_flow_imp.g_varchar2_table(305) := '6E6374696F6E2874297B73776974636828742E74797065297B636173652264726F70223A636173652264726167656E64223A746869732E5F6F6E44726F702874293B627265616B3B636173652264726167656E746572223A6361736522647261676F7665';
wwv_flow_imp.g_varchar2_table(306) := '72223A24262628746869732E5F6F6E447261674F7665722874292C66756E6374696F6E2874297B742E646174615472616E73666572262628742E646174615472616E736665722E64726F704566666563743D226D6F766522293B742E63616E63656C6162';
wwv_flow_imp.g_varchar2_table(307) := '6C652626742E70726576656E7444656661756C7428297D287429293B627265616B3B636173652273656C6563747374617274223A742E70726576656E7444656661756C7428297D7D2C746F41727261793A66756E6374696F6E28297B666F722876617220';
wwv_flow_imp.g_varchar2_table(308) := '742C653D5B5D2C6E3D746869732E656C2E6368696C6472656E2C6F3D302C693D6E2E6C656E6774682C723D746869732E6F7074696F6E733B6F3C693B6F2B2B295028743D6E5B6F5D2C722E647261676761626C652C746869732E656C2C2131292626652E';
wwv_flow_imp.g_varchar2_table(309) := '7075736828742E67657441747472696275746528722E64617461496441747472297C7C66756E6374696F6E2874297B76617220653D742E7461674E616D652B742E636C6173734E616D652B742E7372632B742E687265662B742E74657874436F6E74656E';
wwv_flow_imp.g_varchar2_table(310) := '742C6E3D652E6C656E6774682C6F3D303B666F72283B6E2D2D3B296F2B3D652E63686172436F64654174286E293B72657475726E206F2E746F537472696E67283336297D287429293B72657475726E20657D2C736F72743A66756E6374696F6E28742C65';
wwv_flow_imp.g_varchar2_table(311) := '297B766172206E3D7B7D2C6F3D746869732E656C3B746869732E746F417272617928292E666F72456163682866756E6374696F6E28742C65297B653D6F2E6368696C6472656E5B655D3B5028652C746869732E6F7074696F6E732E647261676761626C65';
wwv_flow_imp.g_varchar2_table(312) := '2C6F2C2131292626286E5B745D3D65297D2C74686973292C652626746869732E63617074757265416E696D6174696F6E537461746528292C742E666F72456163682866756E6374696F6E2874297B6E5B745D2626286F2E72656D6F76654368696C64286E';
wwv_flow_imp.g_varchar2_table(313) := '5B745D292C6F2E617070656E644368696C64286E5B745D29297D292C652626746869732E616E696D617465416C6C28297D2C736176653A66756E6374696F6E28297B76617220743D746869732E6F7074696F6E732E73746F72653B742626742E73657426';
wwv_flow_imp.g_varchar2_table(314) := '26742E7365742874686973297D2C636C6F736573743A66756E6374696F6E28742C65297B72657475726E205028742C657C7C746869732E6F7074696F6E732E647261676761626C652C746869732E656C2C2131297D2C6F7074696F6E3A66756E6374696F';
wwv_flow_imp.g_varchar2_table(315) := '6E28742C65297B766172206E3D746869732E6F7074696F6E733B696628766F696420303D3D3D652972657475726E206E5B745D3B766172206F3D472E6D6F646966794F7074696F6E28746869732C742C65293B6E5B745D3D766F69642030213D3D6F3F6F';
wwv_flow_imp.g_varchar2_table(316) := '3A652C2267726F7570223D3D3D7426265874286E297D2C64657374726F793A66756E6374696F6E28297B71282264657374726F79222C74686973293B76617220743D746869732E656C3B745B4B5D3D6E756C6C2C7028742C226D6F757365646F776E222C';
wwv_flow_imp.g_varchar2_table(317) := '746869732E5F6F6E5461705374617274292C7028742C22746F7563687374617274222C746869732E5F6F6E5461705374617274292C7028742C22706F696E746572646F776E222C746869732E5F6F6E5461705374617274292C746869732E6E6174697665';
wwv_flow_imp.g_varchar2_table(318) := '447261676761626C652626287028742C22647261676F766572222C74686973292C7028742C2264726167656E746572222C7468697329292C41727261792E70726F746F747970652E666F72456163682E63616C6C28742E717565727953656C6563746F72';
wwv_flow_imp.g_varchar2_table(319) := '416C6C28225B647261676761626C655D22292C66756E6374696F6E2874297B742E72656D6F76654174747269627574652822647261676761626C6522297D292C746869732E5F6F6E44726F7028292C746869732E5F64697361626C6544656C6179656444';
wwv_flow_imp.g_varchar2_table(320) := '7261674576656E747328292C5F742E73706C696365285F742E696E6465784F6628746869732E656C292C31292C746869732E656C3D743D6E756C6C7D2C5F68696465436C6F6E653A66756E6374696F6E28297B69747C7C2871282268696465436C6F6E65';
wwv_flow_imp.g_varchar2_table(321) := '222C74686973292C48742E6576656E7443616E63656C65647C7C2852286F742C22646973706C6179222C226E6F6E6522292C746869732E6F7074696F6E732E72656D6F7665436C6F6E654F6E4869646526266F742E706172656E744E6F646526266F742E';
wwv_flow_imp.g_varchar2_table(322) := '706172656E744E6F64652E72656D6F76654368696C64286F74292C69743D213029297D2C5F73686F77436C6F6E653A66756E6374696F6E2874297B22636C6F6E65223D3D3D742E6C6173745075744D6F64653F697426262871282273686F77436C6F6E65';
wwv_flow_imp.g_varchar2_table(323) := '222C74686973292C48742E6576656E7443616E63656C65647C7C28242E706172656E744E6F6465213D74747C7C746869732E6F7074696F6E732E67726F75702E726576657274436C6F6E653F65743F74742E696E736572744265666F7265286F742C6574';
wwv_flow_imp.g_varchar2_table(324) := '293A74742E617070656E644368696C64286F74293A74742E696E736572744265666F7265286F742C24292C746869732E6F7074696F6E732E67726F75702E726576657274436C6F6E652626746869732E616E696D61746528242C6F74292C52286F742C22';
wwv_flow_imp.g_varchar2_table(325) := '646973706C6179222C2222292C69743D213129293A746869732E5F68696465436C6F6E6528297D7D2C417426266628646F63756D656E742C22746F7563686D6F7665222C66756E6374696F6E2874297B2848742E6163746976657C7C4574292626742E63';
wwv_flow_imp.g_varchar2_table(326) := '616E63656C61626C652626742E70726576656E7444656661756C7428297D292C48742E7574696C733D7B6F6E3A662C6F66663A702C6373733A522C66696E643A452C69733A66756E6374696F6E28742C65297B72657475726E21215028742C652C742C21';
wwv_flow_imp.g_varchar2_table(327) := '31297D2C657874656E643A66756E6374696F6E28742C65297B6966287426266529666F7228766172206E20696E206529652E6861734F776E50726F7065727479286E29262628745B6E5D3D655B6E5D293B72657475726E20747D2C7468726F74746C653A';
wwv_flow_imp.g_varchar2_table(328) := '432C636C6F736573743A502C746F67676C65436C6173733A6B2C636C6F6E653A542C696E6465783A6A2C6E6578745469636B3A7A742C63616E63656C4E6578745469636B3A47742C646574656374446972656374696F6E3A52742C6765744368696C643A';
wwv_flow_imp.g_varchar2_table(329) := '422C657870616E646F3A4B7D2C48742E6765743D66756E6374696F6E2874297B72657475726E20745B4B5D7D2C48742E6D6F756E743D66756E6374696F6E28297B666F722876617220743D617267756D656E74732E6C656E6774682C653D6E6577204172';
wwv_flow_imp.g_varchar2_table(330) := '7261792874292C6E3D303B6E3C743B6E2B2B29655B6E5D3D617267756D656E74735B6E5D3B28653D655B305D2E636F6E7374727563746F723D3D3D41727261793F655B305D3A65292E666F72456163682866756E6374696F6E2874297B69662821742E70';
wwv_flow_imp.g_varchar2_table(331) := '726F746F747970657C7C21742E70726F746F747970652E636F6E7374727563746F72297468726F7722536F727461626C653A204D6F756E74656420706C7567696E206D757374206265206120636F6E7374727563746F722066756E6374696F6E2C206E6F';
wwv_flow_imp.g_varchar2_table(332) := '7420222E636F6E636174287B7D2E746F537472696E672E63616C6C287429293B742E7574696C7326262848742E7574696C733D492849287B7D2C48742E7574696C73292C742E7574696C7329292C472E6D6F756E742874297D297D2C48742E6372656174';
wwv_flow_imp.g_varchar2_table(333) := '653D66756E6374696F6E28742C65297B72657475726E206E657720487428742C65297D3B7661722055742C71742C56742C5A742C24742C51742C4A743D5B5D2C74653D212848742E76657273696F6E3D22312E31352E3722293B66756E6374696F6E2065';
wwv_flow_imp.g_varchar2_table(334) := '6528297B4A742E666F72456163682866756E6374696F6E2874297B636C656172496E74657276616C28742E706964297D292C4A743D5B5D7D66756E6374696F6E206E6528297B636C656172496E74657276616C285174297D766172206F652C69653D4328';
wwv_flow_imp.g_varchar2_table(335) := '66756E6374696F6E286E2C742C652C6F297B696628742E7363726F6C6C297B76617220692C723D286E2E746F75636865733F6E2E746F75636865735B305D3A6E292E636C69656E74582C613D286E2E746F75636865733F6E2E746F75636865735B305D3A';
wwv_flow_imp.g_varchar2_table(336) := '6E292E636C69656E74592C6C3D742E7363726F6C6C53656E73697469766974792C733D742E7363726F6C6C53706565642C633D4F28292C753D21313B7174213D3D6526262871743D652C656528292C55743D742E7363726F6C6C2C693D742E7363726F6C';
wwv_flow_imp.g_varchar2_table(337) := '6C466E2C21303D3D3D557426262855743D4D28652C21302929293B76617220643D302C683D55743B646F7B76617220663D682C703D582866292C673D702E746F702C6D3D702E626F74746F6D2C763D702E6C6566742C623D702E72696768742C793D702E';
wwv_flow_imp.g_varchar2_table(338) := '77696474682C773D702E6865696768742C443D766F696420302C453D766F696420302C533D662E7363726F6C6C57696474682C5F3D662E7363726F6C6C4865696768742C433D522866292C543D662E7363726F6C6C4C6566742C703D662E7363726F6C6C';
wwv_flow_imp.g_varchar2_table(339) := '546F702C453D663D3D3D633F28443D793C53262628226175746F223D3D3D432E6F766572666C6F77587C7C227363726F6C6C223D3D3D432E6F766572666C6F77587C7C2276697369626C65223D3D3D432E6F766572666C6F7758292C773C5F2626282261';
wwv_flow_imp.g_varchar2_table(340) := '75746F223D3D3D432E6F766572666C6F77597C7C227363726F6C6C223D3D3D432E6F766572666C6F77597C7C2276697369626C65223D3D3D432E6F766572666C6F775929293A28443D793C53262628226175746F223D3D3D432E6F766572666C6F77587C';
wwv_flow_imp.g_varchar2_table(341) := '7C227363726F6C6C223D3D3D432E6F766572666C6F7758292C773C5F262628226175746F223D3D3D432E6F766572666C6F77597C7C227363726F6C6C223D3D3D432E6F766572666C6F775929292C543D442626284D6174682E61627328622D72293C3D6C';
wwv_flow_imp.g_varchar2_table(342) := '2626542B793C53292D284D6174682E61627328762D72293C3D6C2626212154292C703D452626284D6174682E616273286D2D61293C3D6C2626702B773C5F292D284D6174682E61627328672D61293C3D6C2626212170293B696628214A745B645D29666F';
wwv_flow_imp.g_varchar2_table(343) := '722876617220783D303B783C3D643B782B2B294A745B785D7C7C284A745B785D3D7B7D293B4A745B645D2E76783D3D5426264A745B645D2E76793D3D7026264A745B645D2E656C3D3D3D667C7C284A745B645D2E656C3D662C4A745B645D2E76783D542C';
wwv_flow_imp.g_varchar2_table(344) := '4A745B645D2E76793D702C636C656172496E74657276616C284A745B645D2E706964292C303D3D542626303D3D707C7C28753D21302C4A745B645D2E7069643D736574496E74657276616C2866756E6374696F6E28297B6F2626303D3D3D746869732E6C';
wwv_flow_imp.g_varchar2_table(345) := '61796572262648742E6163746976652E5F6F6E546F7563684D6F7665282474293B76617220743D4A745B746869732E6C617965725D2E76793F4A745B746869732E6C617965725D2E76792A733A302C653D4A745B746869732E6C617965725D2E76783F4A';
wwv_flow_imp.g_varchar2_table(346) := '745B746869732E6C617965725D2E76782A733A303B2266756E6374696F6E223D3D747970656F662069262622636F6E74696E756522213D3D692E63616C6C2848742E647261676765642E706172656E744E6F64655B4B5D2C652C742C6E2C24742C4A745B';
wwv_flow_imp.g_varchar2_table(347) := '746869732E6C617965725D2E656C297C7C48284A745B746869732E6C617965725D2E656C2C652C74297D2E62696E64287B6C617965723A647D292C32342929292C642B2B7D7768696C6528742E627562626C655363726F6C6C262668213D3D6326262868';
wwv_flow_imp.g_varchar2_table(348) := '3D4D28682C21312929293B74653D757D7D2C3330292C6E3D66756E6374696F6E2874297B76617220653D742E6F726967696E616C4576656E742C6E3D742E707574536F727461626C652C6F3D742E64726167456C2C693D742E616374697665536F727461';
wwv_flow_imp.g_varchar2_table(349) := '626C652C723D742E6469737061746368536F727461626C654576656E742C613D742E6869646547686F7374466F725461726765742C743D742E756E6869646547686F7374466F725461726765743B65262628693D6E7C7C692C6128292C653D652E636861';
wwv_flow_imp.g_varchar2_table(350) := '6E676564546F75636865732626652E6368616E676564546F75636865732E6C656E6774683F652E6368616E676564546F75636865735B305D3A652C653D646F63756D656E742E656C656D656E7446726F6D506F696E7428652E636C69656E74582C652E63';
wwv_flow_imp.g_varchar2_table(351) := '6C69656E7459292C7428292C69262621692E656C2E636F6E7461696E732865292626287228227370696C6C22292C746869732E6F6E5370696C6C287B64726167456C3A6F2C707574536F727461626C653A6E7D2929297D3B66756E6374696F6E20726528';
wwv_flow_imp.g_varchar2_table(352) := '297B7D66756E6374696F6E20616528297B7D72652E70726F746F747970653D7B7374617274496E6465783A6E756C6C2C6472616753746172743A66756E6374696F6E2874297B743D742E6F6C64447261676761626C65496E6465783B746869732E737461';
wwv_flow_imp.g_varchar2_table(353) := '7274496E6465783D747D2C6F6E5370696C6C3A66756E6374696F6E2874297B76617220653D742E64726167456C2C6E3D742E707574536F727461626C653B746869732E736F727461626C652E63617074757265416E696D6174696F6E537461746528292C';
wwv_flow_imp.g_varchar2_table(354) := '6E26266E2E63617074757265416E696D6174696F6E537461746528293B743D4228746869732E736F727461626C652E656C2C746869732E7374617274496E6465782C746869732E6F7074696F6E73293B743F746869732E736F727461626C652E656C2E69';
wwv_flow_imp.g_varchar2_table(355) := '6E736572744265666F726528652C74293A746869732E736F727461626C652E656C2E617070656E644368696C642865292C746869732E736F727461626C652E616E696D617465416C6C28292C6E26266E2E616E696D617465416C6C28297D2C64726F703A';
wwv_flow_imp.g_varchar2_table(356) := '6E7D2C612872652C7B706C7567696E4E616D653A227265766572744F6E5370696C6C227D292C61652E70726F746F747970653D7B6F6E5370696C6C3A66756E6374696F6E2874297B76617220653D742E64726167456C2C743D742E707574536F72746162';
wwv_flow_imp.g_varchar2_table(357) := '6C657C7C746869732E736F727461626C653B742E63617074757265416E696D6174696F6E537461746528292C652E706172656E744E6F64652626652E706172656E744E6F64652E72656D6F76654368696C642865292C742E616E696D617465416C6C2829';
wwv_flow_imp.g_varchar2_table(358) := '7D2C64726F703A6E7D2C612861652C7B706C7567696E4E616D653A2272656D6F76654F6E5370696C6C227D293B766172206C652C73652C63652C75652C64652C68653D5B5D2C66653D5B5D2C70653D21312C67653D21312C6D653D21313B66756E637469';
wwv_flow_imp.g_varchar2_table(359) := '6F6E207665286E2C6F297B66652E666F72456163682866756E6374696F6E28742C65297B653D6F2E6368696C6472656E5B742E736F727461626C65496E6465782B286E3F4E756D6265722865293A30295D3B653F6F2E696E736572744265666F72652874';
wwv_flow_imp.g_varchar2_table(360) := '2C65293A6F2E617070656E644368696C642874297D297D66756E6374696F6E20626528297B68652E666F72456163682866756E6374696F6E2874297B74213D3D63652626742E706172656E744E6F64652626742E706172656E744E6F64652E72656D6F76';
wwv_flow_imp.g_varchar2_table(361) := '654368696C642874297D297D72657475726E2048742E6D6F756E74286E65772066756E6374696F6E28297B66756E6374696F6E207428297B666F7228766172207420696E20746869732E64656661756C74733D7B7363726F6C6C3A21302C666F72636541';
wwv_flow_imp.g_varchar2_table(362) := '75746F5363726F6C6C46616C6C6261636B3A21312C7363726F6C6C53656E73697469766974793A33302C7363726F6C6C53706565643A31302C627562626C655363726F6C6C3A21307D2C7468697329225F223D3D3D742E63686172417428302926262266';
wwv_flow_imp.g_varchar2_table(363) := '756E6374696F6E223D3D747970656F6620746869735B745D262628746869735B745D3D746869735B745D2E62696E64287468697329297D72657475726E20742E70726F746F747970653D7B64726167537461727465643A66756E6374696F6E2874297B74';
wwv_flow_imp.g_varchar2_table(364) := '3D742E6F726967696E616C4576656E743B746869732E736F727461626C652E6E6174697665447261676761626C653F6628646F63756D656E742C22647261676F766572222C746869732E5F68616E646C654175746F5363726F6C6C293A746869732E6F70';
wwv_flow_imp.g_varchar2_table(365) := '74696F6E732E737570706F7274506F696E7465723F6628646F63756D656E742C22706F696E7465726D6F7665222C746869732E5F68616E646C6546616C6C6261636B4175746F5363726F6C6C293A742E746F75636865733F6628646F63756D656E742C22';
wwv_flow_imp.g_varchar2_table(366) := '746F7563686D6F7665222C746869732E5F68616E646C6546616C6C6261636B4175746F5363726F6C6C293A6628646F63756D656E742C226D6F7573656D6F7665222C746869732E5F68616E646C6546616C6C6261636B4175746F5363726F6C6C297D2C64';
wwv_flow_imp.g_varchar2_table(367) := '7261674F766572436F6D706C657465643A66756E6374696F6E2874297B743D742E6F726967696E616C4576656E743B746869732E6F7074696F6E732E647261674F766572427562626C657C7C742E726F6F74456C7C7C746869732E5F68616E646C654175';
wwv_flow_imp.g_varchar2_table(368) := '746F5363726F6C6C2874297D2C64726F703A66756E6374696F6E28297B746869732E736F727461626C652E6E6174697665447261676761626C653F7028646F63756D656E742C22647261676F766572222C746869732E5F68616E646C654175746F536372';
wwv_flow_imp.g_varchar2_table(369) := '6F6C6C293A287028646F63756D656E742C22706F696E7465726D6F7665222C746869732E5F68616E646C6546616C6C6261636B4175746F5363726F6C6C292C7028646F63756D656E742C22746F7563686D6F7665222C746869732E5F68616E646C654661';
wwv_flow_imp.g_varchar2_table(370) := '6C6C6261636B4175746F5363726F6C6C292C7028646F63756D656E742C226D6F7573656D6F7665222C746869732E5F68616E646C6546616C6C6261636B4175746F5363726F6C6C29292C6E6528292C656528292C636C65617254696D656F75742876292C';
wwv_flow_imp.g_varchar2_table(371) := '763D766F696420307D2C6E756C6C696E673A66756E6374696F6E28297B24743D71743D55743D74653D51743D56743D5A743D6E756C6C2C4A742E6C656E6774683D307D2C5F68616E646C6546616C6C6261636B4175746F5363726F6C6C3A66756E637469';
wwv_flow_imp.g_varchar2_table(372) := '6F6E2874297B746869732E5F68616E646C654175746F5363726F6C6C28742C2130297D2C5F68616E646C654175746F5363726F6C6C3A66756E6374696F6E28652C6E297B766172206F2C693D746869732C723D28652E746F75636865733F652E746F7563';
wwv_flow_imp.g_varchar2_table(373) := '6865735B305D3A65292E636C69656E74582C613D28652E746F75636865733F652E746F75636865735B305D3A65292E636C69656E74592C743D646F63756D656E742E656C656D656E7446726F6D506F696E7428722C61293B24743D652C6E7C7C74686973';
wwv_flow_imp.g_varchar2_table(374) := '2E6F7074696F6E732E666F7263654175746F5363726F6C6C46616C6C6261636B7C7C777C7C797C7C753F28696528652C746869732E6F7074696F6E732C742C6E292C6F3D4D28742C2130292C2174657C7C51742626723D3D3D56742626613D3D3D5A747C';
wwv_flow_imp.g_varchar2_table(375) := '7C28517426266E6528292C51743D736574496E74657276616C2866756E6374696F6E28297B76617220743D4D28646F63756D656E742E656C656D656E7446726F6D506F696E7428722C61292C2130293B74213D3D6F2626286F3D742C65652829292C6965';
wwv_flow_imp.g_varchar2_table(376) := '28652C692E6F7074696F6E732C742C6E297D2C3130292C56743D722C5A743D6129293A746869732E6F7074696F6E732E627562626C655363726F6C6C26264D28742C213029213D3D4F28293F696528652C746869732E6F7074696F6E732C4D28742C2131';
wwv_flow_imp.g_varchar2_table(377) := '292C2131293A656528297D7D2C6128742C7B706C7567696E4E616D653A227363726F6C6C222C696E697469616C697A65427944656661756C743A21307D297D292C48742E6D6F756E742861652C7265292C48742E6D6F756E74286E65772066756E637469';
wwv_flow_imp.g_varchar2_table(378) := '6F6E28297B66756E6374696F6E207428297B746869732E64656661756C74733D7B73776170436C6173733A22736F727461626C652D737761702D686967686C69676874227D7D72657475726E20742E70726F746F747970653D7B6472616753746172743A';
wwv_flow_imp.g_varchar2_table(379) := '66756E6374696F6E2874297B743D742E64726167456C3B6F653D747D2C647261674F76657256616C69643A66756E6374696F6E2874297B76617220653D742E636F6D706C657465642C6E3D742E7461726765742C6F3D742E6F6E4D6F76652C693D742E61';
wwv_flow_imp.g_varchar2_table(380) := '6374697665536F727461626C652C723D742E6368616E6765642C613D742E63616E63656C3B692E6F7074696F6E732E73776170262628743D746869732E736F727461626C652E656C2C693D746869732E6F7074696F6E732C6E26266E213D3D7426262874';
wwv_flow_imp.g_varchar2_table(381) := '3D6F652C6F653D2131213D3D6F286E293F286B286E2C692E73776170436C6173732C2130292C6E293A6E756C6C2C74262674213D3D6F6526266B28742C692E73776170436C6173732C213129292C7228292C65282130292C612829297D2C64726F703A66';
wwv_flow_imp.g_varchar2_table(382) := '756E6374696F6E2874297B76617220652C6E2C6F3D742E616374697665536F727461626C652C693D742E707574536F727461626C652C723D742E64726167456C2C613D697C7C746869732E736F727461626C652C6C3D746869732E6F7074696F6E733B6F';
wwv_flow_imp.g_varchar2_table(383) := '6526266B286F652C6C2E73776170436C6173732C2131292C6F652626286C2E737761707C7C692626692E6F7074696F6E732E7377617029262672213D3D6F65262628612E63617074757265416E696D6174696F6E537461746528292C61213D3D6F26266F';
wwv_flow_imp.g_varchar2_table(384) := '2E63617074757265416E696D6174696F6E537461746528292C6E3D6F652C743D28653D72292E706172656E744E6F64652C6C3D6E2E706172656E744E6F64652C7426266C262621742E6973457175616C4E6F6465286E292626216C2E6973457175616C4E';
wwv_flow_imp.g_varchar2_table(385) := '6F6465286529262628693D6A2865292C723D6A286E292C742E6973457175616C4E6F6465286C292626693C722626722B2B2C742E696E736572744265666F7265286E2C742E6368696C6472656E5B695D292C6C2E696E736572744265666F726528652C6C';
wwv_flow_imp.g_varchar2_table(386) := '2E6368696C6472656E5B725D29292C612E616E696D617465416C6C28292C61213D3D6F26266F2E616E696D617465416C6C2829297D2C6E756C6C696E673A66756E6374696F6E28297B6F653D6E756C6C7D7D2C6128742C7B706C7567696E4E616D653A22';
wwv_flow_imp.g_varchar2_table(387) := '73776170222C6576656E7450726F706572746965733A66756E6374696F6E28297B72657475726E7B737761704974656D3A6F657D7D7D297D292C48742E6D6F756E74286E65772066756E6374696F6E28297B66756E6374696F6E2074286F297B666F7228';
wwv_flow_imp.g_varchar2_table(388) := '766172207420696E207468697329225F223D3D3D742E63686172417428302926262266756E6374696F6E223D3D747970656F6620746869735B745D262628746869735B745D3D746869735B745D2E62696E64287468697329293B6F2E6F7074696F6E732E';
wwv_flow_imp.g_varchar2_table(389) := '61766F6964496D706C69636974446573656C6563747C7C286F2E6F7074696F6E732E737570706F7274506F696E7465723F6628646F63756D656E742C22706F696E7465727570222C746869732E5F646573656C6563744D756C746944726167293A286628';
wwv_flow_imp.g_varchar2_table(390) := '646F63756D656E742C226D6F7573657570222C746869732E5F646573656C6563744D756C746944726167292C6628646F63756D656E742C22746F756368656E64222C746869732E5F646573656C6563744D756C7469447261672929292C6628646F63756D';
wwv_flow_imp.g_varchar2_table(391) := '656E742C226B6579646F776E222C746869732E5F636865636B4B6579446F776E292C6628646F63756D656E742C226B65797570222C746869732E5F636865636B4B65795570292C746869732E64656661756C74733D7B73656C6563746564436C6173733A';
wwv_flow_imp.g_varchar2_table(392) := '22736F727461626C652D73656C6563746564222C6D756C7469447261674B65793A6E756C6C2C61766F6964496D706C69636974446573656C6563743A21312C736574446174613A66756E6374696F6E28742C65297B766172206E3D22223B68652E6C656E';
wwv_flow_imp.g_varchar2_table(393) := '677468262673653D3D3D6F3F68652E666F72456163682866756E6374696F6E28742C65297B6E2B3D28653F222C20223A2222292B742E74657874436F6E74656E747D293A6E3D652E74657874436F6E74656E742C742E7365744461746128225465787422';
wwv_flow_imp.g_varchar2_table(394) := '2C6E297D7D7D72657475726E20742E70726F746F747970653D7B6D756C7469447261674B6579446F776E3A21312C69734D756C7469447261673A21312C64656C61795374617274476C6F62616C3A66756E6374696F6E2874297B743D742E64726167456C';
wwv_flow_imp.g_varchar2_table(395) := '3B63653D747D2C64656C6179456E6465643A66756E6374696F6E28297B746869732E69734D756C7469447261673D7E68652E696E6465784F66286365297D2C7365747570436C6F6E653A66756E6374696F6E2874297B76617220653D742E736F72746162';
wwv_flow_imp.g_varchar2_table(396) := '6C652C743D742E63616E63656C3B696628746869732E69734D756C746944726167297B666F7228766172206E3D303B6E3C68652E6C656E6774683B6E2B2B2966652E7075736828542868655B6E5D29292C66655B6E5D2E736F727461626C65496E646578';
wwv_flow_imp.g_varchar2_table(397) := '3D68655B6E5D2E736F727461626C65496E6465782C66655B6E5D2E647261676761626C653D21312C66655B6E5D2E7374796C655B2277696C6C2D6368616E6765225D3D22222C6B2866655B6E5D2C746869732E6F7074696F6E732E73656C656374656443';
wwv_flow_imp.g_varchar2_table(398) := '6C6173732C2131292C68655B6E5D3D3D3D636526266B2866655B6E5D2C746869732E6F7074696F6E732E63686F73656E436C6173732C2131293B652E5F68696465436C6F6E6528292C7428297D7D2C636C6F6E653A66756E6374696F6E2874297B766172';
wwv_flow_imp.g_varchar2_table(399) := '20653D742E736F727461626C652C6E3D742E726F6F74456C2C6F3D742E6469737061746368536F727461626C654576656E742C743D742E63616E63656C3B746869732E69734D756C746944726167262628746869732E6F7074696F6E732E72656D6F7665';
wwv_flow_imp.g_varchar2_table(400) := '436C6F6E654F6E486964657C7C68652E6C656E677468262673653D3D3D6526262876652821302C6E292C6F2822636C6F6E6522292C74282929297D2C73686F77436C6F6E653A66756E6374696F6E2874297B76617220653D742E636C6F6E654E6F775368';
wwv_flow_imp.g_varchar2_table(401) := '6F776E2C6E3D742E726F6F74456C2C743D742E63616E63656C3B746869732E69734D756C74694472616726262876652821312C6E292C66652E666F72456163682866756E6374696F6E2874297B5228742C22646973706C6179222C2222297D292C652829';
wwv_flow_imp.g_varchar2_table(402) := '2C64653D21312C742829297D2C68696465436C6F6E653A66756E6374696F6E2874297B76617220653D746869732C6E3D28742E736F727461626C652C742E636C6F6E654E6F7748696464656E292C743D742E63616E63656C3B746869732E69734D756C74';
wwv_flow_imp.g_varchar2_table(403) := '694472616726262866652E666F72456163682866756E6374696F6E2874297B5228742C22646973706C6179222C226E6F6E6522292C652E6F7074696F6E732E72656D6F7665436C6F6E654F6E486964652626742E706172656E744E6F64652626742E7061';
wwv_flow_imp.g_varchar2_table(404) := '72656E744E6F64652E72656D6F76654368696C642874297D292C6E28292C64653D21302C742829297D2C647261675374617274476C6F62616C3A66756E6374696F6E2874297B742E736F727461626C653B21746869732E69734D756C7469447261672626';
wwv_flow_imp.g_varchar2_table(405) := '7365262673652E6D756C7469447261672E5F646573656C6563744D756C74694472616728292C68652E666F72456163682866756E6374696F6E2874297B742E736F727461626C65496E6465783D6A2874297D292C68653D68652E736F72742866756E6374';
wwv_flow_imp.g_varchar2_table(406) := '696F6E28742C65297B72657475726E20742E736F727461626C65496E6465782D652E736F727461626C65496E6465787D292C6D653D21307D2C64726167537461727465643A66756E6374696F6E2874297B76617220652C6E3D746869732C743D742E736F';
wwv_flow_imp.g_varchar2_table(407) := '727461626C653B746869732E69734D756C746944726167262628746869732E6F7074696F6E732E736F7274262628742E63617074757265416E696D6174696F6E537461746528292C746869732E6F7074696F6E732E616E696D6174696F6E26262868652E';
wwv_flow_imp.g_varchar2_table(408) := '666F72456163682866756E6374696F6E2874297B74213D3D636526265228742C22706F736974696F6E222C226162736F6C75746522297D292C653D582863652C21312C21302C2130292C68652E666F72456163682866756E6374696F6E2874297B74213D';
wwv_flow_imp.g_varchar2_table(409) := '3D636526267828742C65297D292C70653D67653D213029292C742E616E696D617465416C6C2866756E6374696F6E28297B70653D67653D21312C6E2E6F7074696F6E732E616E696D6174696F6E262668652E666F72456163682866756E6374696F6E2874';
wwv_flow_imp.g_varchar2_table(410) := '297B412874297D292C6E2E6F7074696F6E732E736F72742626626528297D29297D2C647261674F7665723A66756E6374696F6E2874297B76617220653D742E7461726765742C6E3D742E636F6D706C657465642C743D742E63616E63656C3B676526267E';
wwv_flow_imp.g_varchar2_table(411) := '68652E696E6465784F662865292626286E282131292C742829297D2C7265766572743A66756E6374696F6E2874297B766172206E2C6F2C653D742E66726F6D536F727461626C652C693D742E726F6F74456C2C723D742E736F727461626C652C613D742E';
wwv_flow_imp.g_varchar2_table(412) := '64726167526563743B313C68652E6C656E67746826262868652E666F72456163682866756E6374696F6E2874297B722E616464416E696D6174696F6E5374617465287B7461726765743A742C726563743A67653F582874293A617D292C412874292C742E';
wwv_flow_imp.g_varchar2_table(413) := '66726F6D526563743D612C652E72656D6F7665416E696D6174696F6E53746174652874297D292C67653D21312C6E3D21746869732E6F7074696F6E732E72656D6F7665436C6F6E654F6E486964652C6F3D692C68652E666F72456163682866756E637469';
wwv_flow_imp.g_varchar2_table(414) := '6F6E28742C65297B653D6F2E6368696C6472656E5B742E736F727461626C65496E6465782B286E3F4E756D6265722865293A30295D3B653F6F2E696E736572744265666F726528742C65293A6F2E617070656E644368696C642874297D29297D2C647261';
wwv_flow_imp.g_varchar2_table(415) := '674F766572436F6D706C657465643A66756E6374696F6E2874297B76617220652C6E3D742E736F727461626C652C6F3D742E69734F776E65722C693D742E696E73657274696F6E2C723D742E616374697665536F727461626C652C613D742E706172656E';
wwv_flow_imp.g_varchar2_table(416) := '74456C2C6C3D742E707574536F727461626C652C743D746869732E6F7074696F6E733B692626286F2626722E5F68696465436C6F6E6528292C70653D21312C742E616E696D6174696F6E2626313C68652E6C656E67746826262867657C7C216F26262172';
wwv_flow_imp.g_varchar2_table(417) := '2E6F7074696F6E732E736F72742626216C29262628653D582863652C21312C21302C2130292C68652E666F72456163682866756E6374696F6E2874297B74213D3D63652626287828742C65292C612E617070656E644368696C64287429297D292C67653D';
wwv_flow_imp.g_varchar2_table(418) := '2130292C6F7C7C2867657C7C626528292C313C68652E6C656E6774683F286F3D64652C722E5F73686F77436C6F6E65286E292C722E6F7074696F6E732E616E696D6174696F6E262621646526266F262666652E666F72456163682866756E6374696F6E28';
wwv_flow_imp.g_varchar2_table(419) := '74297B722E616464416E696D6174696F6E5374617465287B7461726765743A742C726563743A75657D292C742E66726F6D526563743D75652C742E74686973416E696D6174696F6E4475726174696F6E3D6E756C6C7D29293A722E5F73686F77436C6F6E';
wwv_flow_imp.g_varchar2_table(420) := '65286E2929297D2C647261674F766572416E696D6174696F6E436170747572653A66756E6374696F6E2874297B76617220653D742E64726167526563742C6E3D742E69734F776E65722C743D742E616374697665536F727461626C653B68652E666F7245';
wwv_flow_imp.g_varchar2_table(421) := '6163682866756E6374696F6E2874297B742E74686973416E696D6174696F6E4475726174696F6E3D6E756C6C7D292C742E6F7074696F6E732E616E696D6174696F6E2626216E2626742E6D756C7469447261672E69734D756C7469447261672626287565';
wwv_flow_imp.g_varchar2_table(422) := '3D61287B7D2C65292C653D442863652C2130292C75652E746F702D3D652E662C75652E6C6566742D3D652E65297D2C647261674F766572416E696D6174696F6E436F6D706C6574653A66756E6374696F6E28297B676526262867653D21312C6265282929';
wwv_flow_imp.g_varchar2_table(423) := '7D2C64726F703A66756E6374696F6E2874297B766172206F2C692C722C612C6E2C652C6C2C733D742E6F726967696E616C4576656E742C633D742E726F6F74456C2C753D742E706172656E74456C2C643D742E736F727461626C652C683D742E64697370';
wwv_flow_imp.g_varchar2_table(424) := '61746368536F727461626C654576656E742C663D742E6F6C64496E6465782C743D742E707574536F727461626C652C703D747C7C746869732E736F727461626C653B732626286F3D746869732E6F7074696F6E732C693D752E6368696C6472656E2C6D65';
wwv_flow_imp.g_varchar2_table(425) := '7C7C286F2E6D756C7469447261674B6579262621746869732E6D756C7469447261674B6579446F776E2626746869732E5F646573656C6563744D756C74694472616728292C6B2863652C6F2E73656C6563746564436C6173732C217E68652E696E646578';
wwv_flow_imp.g_varchar2_table(426) := '4F6628636529292C7E68652E696E6465784F66286365293F2868652E73706C6963652868652E696E6465784F66286365292C31292C6C653D6E756C6C2C55287B736F727461626C653A642C726F6F74456C3A632C6E616D653A22646573656C656374222C';
wwv_flow_imp.g_varchar2_table(427) := '746172676574456C3A63652C6F726967696E616C4576656E743A737D29293A2868652E70757368286365292C55287B736F727461626C653A642C726F6F74456C3A632C6E616D653A2273656C656374222C746172676574456C3A63652C6F726967696E61';
wwv_flow_imp.g_varchar2_table(428) := '6C4576656E743A737D292C732E73686966744B657926266C652626642E656C2E636F6E7461696E73286C65293F28723D6A286C65292C613D6A286365292C7E7226267E61262672213D3D61262666756E6374696F6E28297B666F722876617220652C743D';
wwv_flow_imp.g_varchar2_table(429) := '723C613F28653D722C61293A28653D612C722B31292C6E3D6F2E66696C7465723B653C743B652B2B297E68652E696E6465784F6628695B655D297C7C5028695B655D2C6F2E647261676761626C652C752C2131292626286E2626282266756E6374696F6E';
wwv_flow_imp.g_varchar2_table(430) := '223D3D747970656F66206E3F6E2E63616C6C28642C732C695B655D2C64293A6E2E73706C697428222C22292E736F6D652866756E6374696F6E2874297B72657475726E205028695B655D2C742E7472696D28292C752C2131297D29297C7C286B28695B65';
wwv_flow_imp.g_varchar2_table(431) := '5D2C6F2E73656C6563746564436C6173732C2130292C68652E7075736828695B655D292C55287B736F727461626C653A642C726F6F74456C3A632C6E616D653A2273656C656374222C746172676574456C3A695B655D2C6F726967696E616C4576656E74';
wwv_flow_imp.g_varchar2_table(432) := '3A737D2929297D2829293A6C653D63652C73653D7029292C6D652626746869732E69734D756C74694472616726262867653D21312C28755B4B5D2E6F7074696F6E732E736F72747C7C75213D3D63292626313C68652E6C656E6774682626286E3D582863';
wwv_flow_imp.g_varchar2_table(433) := '65292C653D6A2863652C223A6E6F74282E222B746869732E6F7074696F6E732E73656C6563746564436C6173732B222922292C21706526266F2E616E696D6174696F6E26262863652E74686973416E696D6174696F6E4475726174696F6E3D6E756C6C29';
wwv_flow_imp.g_varchar2_table(434) := '2C702E63617074757265416E696D6174696F6E537461746528292C70657C7C286F2E616E696D6174696F6E26262863652E66726F6D526563743D6E2C68652E666F72456163682866756E6374696F6E2874297B76617220653B742E74686973416E696D61';
wwv_flow_imp.g_varchar2_table(435) := '74696F6E4475726174696F6E3D6E756C6C2C74213D3D6365262628653D67653F582874293A6E2C742E66726F6D526563743D652C702E616464416E696D6174696F6E5374617465287B7461726765743A742C726563743A657D29297D29292C626528292C';
wwv_flow_imp.g_varchar2_table(436) := '68652E666F72456163682866756E6374696F6E2874297B695B655D3F752E696E736572744265666F726528742C695B655D293A752E617070656E644368696C642874292C652B2B7D292C663D3D3D6A286365292626286C3D21312C68652E666F72456163';
wwv_flow_imp.g_varchar2_table(437) := '682866756E6374696F6E2874297B742E736F727461626C65496E646578213D3D6A2874292626286C3D2130297D292C6C26262868282275706461746522292C682822736F727422292929292C68652E666F72456163682866756E6374696F6E2874297B41';
wwv_flow_imp.g_varchar2_table(438) := '2874297D292C702E616E696D617465416C6C2829292C73653D70292C28633D3D3D757C7C74262622636C6F6E6522213D3D742E6C6173745075744D6F646529262666652E666F72456163682866756E6374696F6E2874297B742E706172656E744E6F6465';
wwv_flow_imp.g_varchar2_table(439) := '2626742E706172656E744E6F64652E72656D6F76654368696C642874297D29297D2C6E756C6C696E67476C6F62616C3A66756E6374696F6E28297B746869732E69734D756C7469447261673D6D653D21312C66652E6C656E6774683D307D2C6465737472';
wwv_flow_imp.g_varchar2_table(440) := '6F79476C6F62616C3A66756E6374696F6E28297B746869732E5F646573656C6563744D756C74694472616728292C7028646F63756D656E742C22706F696E7465727570222C746869732E5F646573656C6563744D756C746944726167292C7028646F6375';
wwv_flow_imp.g_varchar2_table(441) := '6D656E742C226D6F7573657570222C746869732E5F646573656C6563744D756C746944726167292C7028646F63756D656E742C22746F756368656E64222C746869732E5F646573656C6563744D756C746944726167292C7028646F63756D656E742C226B';
wwv_flow_imp.g_varchar2_table(442) := '6579646F776E222C746869732E5F636865636B4B6579446F776E292C7028646F63756D656E742C226B65797570222C746869732E5F636865636B4B65795570297D2C5F646573656C6563744D756C7469447261673A66756E6374696F6E2874297B696628';
wwv_flow_imp.g_varchar2_table(443) := '2128766F69642030213D3D6D6526266D657C7C7365213D3D746869732E736F727461626C657C7C7426265028742E7461726765742C746869732E6F7074696F6E732E647261676761626C652C746869732E736F727461626C652E656C2C2131297C7C7426';
wwv_flow_imp.g_varchar2_table(444) := '2630213D3D742E627574746F6E2929666F72283B68652E6C656E6774683B297B76617220653D68655B305D3B6B28652C746869732E6F7074696F6E732E73656C6563746564436C6173732C2131292C68652E736869667428292C55287B736F727461626C';
wwv_flow_imp.g_varchar2_table(445) := '653A746869732E736F727461626C652C726F6F74456C3A746869732E736F727461626C652E656C2C6E616D653A22646573656C656374222C746172676574456C3A652C6F726967696E616C4576656E743A747D297D7D2C5F636865636B4B6579446F776E';
wwv_flow_imp.g_varchar2_table(446) := '3A66756E6374696F6E2874297B742E6B65793D3D3D746869732E6F7074696F6E732E6D756C7469447261674B6579262628746869732E6D756C7469447261674B6579446F776E3D2130297D2C5F636865636B4B657955703A66756E6374696F6E2874297B';
wwv_flow_imp.g_varchar2_table(447) := '742E6B65793D3D3D746869732E6F7074696F6E732E6D756C7469447261674B6579262628746869732E6D756C7469447261674B6579446F776E3D2131297D7D2C6128742C7B706C7567696E4E616D653A226D756C746944726167222C7574696C733A7B73';
wwv_flow_imp.g_varchar2_table(448) := '656C6563743A66756E6374696F6E2874297B76617220653D742E706172656E744E6F64655B4B5D3B652626652E6F7074696F6E732E6D756C7469447261672626217E68652E696E6465784F66287429262628736526267365213D3D6526262873652E6D75';
wwv_flow_imp.g_varchar2_table(449) := '6C7469447261672E5F646573656C6563744D756C74694472616728292C73653D65292C6B28742C652E6F7074696F6E732E73656C6563746564436C6173732C2130292C68652E70757368287429297D2C646573656C6563743A66756E6374696F6E287429';
wwv_flow_imp.g_varchar2_table(450) := '7B76617220653D742E706172656E744E6F64655B4B5D2C6E3D68652E696E6465784F662874293B652626652E6F7074696F6E732E6D756C74694472616726267E6E2626286B28742C652E6F7074696F6E732E73656C6563746564436C6173732C2131292C';
wwv_flow_imp.g_varchar2_table(451) := '68652E73706C696365286E2C3129297D7D2C6576656E7450726F706572746965733A66756E6374696F6E28297B766172206E3D746869732C6F3D5B5D2C693D5B5D3B72657475726E2068652E666F72456163682866756E6374696F6E2874297B76617220';
wwv_flow_imp.g_varchar2_table(452) := '653B6F2E70757368287B6D756C746944726167456C656D656E743A742C696E6465783A742E736F727461626C65496E6465787D292C653D6765262674213D3D63653F2D313A67653F6A28742C223A6E6F74282E222B6E2E6F7074696F6E732E73656C6563';
wwv_flow_imp.g_varchar2_table(453) := '746564436C6173732B222922293A6A2874292C692E70757368287B6D756C746944726167456C656D656E743A742C696E6465783A657D297D292C7B6974656D733A65286865292C636C6F6E65733A5B5D2E636F6E636174286665292C6F6C64496E646963';
wwv_flow_imp.g_varchar2_table(454) := '6965733A6F2C6E6577496E6469636965733A697D7D2C6F7074696F6E4C697374656E6572733A7B6D756C7469447261674B65793A66756E6374696F6E2874297B72657475726E226374726C223D3D3D28743D742E746F4C6F776572436173652829293F74';
wwv_flow_imp.g_varchar2_table(455) := '3D22436F6E74726F6C223A313C742E6C656E677468262628743D742E6368617241742830292E746F55707065724361736528292B742E737562737472283129292C747D7D7D297D292C48747D293B';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(6123508610550140)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_file_name=>'Sortable.min.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A204B616E62616E20426F61726420726567696F6E20706C75672D696E202854656368526576582C207777772E74656368726576782E636F6D29202A2F0A2E74782D4B616E62616E207B0A20202D2D74782D6B622D62673A20766172282D2D75742D63';
wwv_flow_imp.g_varchar2_table(2) := '6F6D706F6E656E742D6261636B67726F756E642D636F6C6F722C2023666666293B0A20202D2D74782D6B622D6C616E652D62673A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D6B622D746578742920342E35252C2076617228';
wwv_flow_imp.g_varchar2_table(3) := '2D2D74782D6B622D626729293B0A20202D2D74782D6B622D6C696E653A20766172282D2D75742D636F6D706F6E656E742D626F726465722D636F6C6F722C207267626128302C20302C20302C202E313229293B0A20202D2D74782D6B622D746578743A20';
wwv_flow_imp.g_varchar2_table(4) := '766172282D2D75742D636F6D706F6E656E742D746578742D64656661756C742D636F6C6F722C2023316632333333293B0A20202D2D74782D6B622D6D757465643A20766172282D2D75742D636F6D706F6E656E742D746578742D6D757465642D636F6C6F';
wwv_flow_imp.g_varchar2_table(5) := '722C2023366237303830293B0A20202D2D74782D6B622D616363656E742D75693A20766172282D2D75742D70616C657474652D7072696D6172792C2023333434326138293B0A20202D2D74782D6B622D64616E6765723A20236338333233633B0A20202D';
wwv_flow_imp.g_varchar2_table(6) := '2D74782D6B622D7761726E3A20236232366230303B0A2020636F6C6F723A20766172282D2D74782D6B622D74657874293B0A2020666F6E742D73697A653A20313470783B0A7D0A0A2E74782D4B616E62616E2D626172207B20646973706C61793A20666C';
wwv_flow_imp.g_varchar2_table(7) := '65783B20616C69676E2D6974656D733A2063656E7465723B206761703A20313270783B206D617267696E2D626F74746F6D3A20313270783B20666C65782D777261703A20777261703B207D0A2E74782D4B616E62616E2D736561726368207B20706F7369';
wwv_flow_imp.g_varchar2_table(8) := '74696F6E3A2072656C61746976653B20666C65783A203020312033323070783B206D696E2D77696474683A2032303070783B206D617267696E3A20303B207D0A2E74782D4B616E62616E2D73656172636820696E707574207B0A202077696474683A2031';
wwv_flow_imp.g_varchar2_table(9) := '3030253B0A20206865696768743A20333670783B0A202070616464696E673A20302031327078203020333470783B0A2020626F726465723A2031707820736F6C696420766172282D2D74782D6B622D6C696E65293B0A2020626F726465722D7261646975';
wwv_flow_imp.g_varchar2_table(10) := '733A203870783B0A20206261636B67726F756E643A20766172282D2D74782D6B622D6267293B0A2020636F6C6F723A20766172282D2D74782D6B622D74657874293B0A2020666F6E743A20696E68657269743B0A7D0A2E74782D4B616E62616E2D736561';
wwv_flow_imp.g_varchar2_table(11) := '72636820696E7075743A666F637573207B206F75746C696E653A2032707820736F6C696420766172282D2D74782D6B622D616363656E742D7569293B206F75746C696E652D6F66667365743A202D3170783B20626F726465722D636F6C6F723A20747261';
wwv_flow_imp.g_varchar2_table(12) := '6E73706172656E743B207D0A2E74782D4B616E62616E202E74782D4B616E62616E2D73656172636849636F6E2E6661207B20706F736974696F6E3A206162736F6C7574653B206C6566743A20313170783B20746F703A203530253B207472616E73666F72';
wwv_flow_imp.g_varchar2_table(13) := '6D3A207472616E736C61746559282D353025293B20666F6E742D73697A653A20313470783B20636F6C6F723A20766172282D2D74782D6B622D6D75746564293B20706F696E7465722D6576656E74733A206E6F6E653B207D0A2E74782D4B616E62616E2D';
wwv_flow_imp.g_varchar2_table(14) := '73756D6D617279207B20636F6C6F723A20766172282D2D74782D6B622D6D75746564293B20666F6E742D73697A653A20313370783B207D0A0A2E74782D4B616E62616E2D6C616E6573207B0A2020646973706C61793A20666C65783B0A20206761703A20';
wwv_flow_imp.g_varchar2_table(15) := '313270783B0A2020616C69676E2D6974656D733A20666C65782D73746172743B0A20206F766572666C6F772D783A206175746F3B0A202070616464696E672D626F74746F6D3A203670783B0A20207363726F6C6C2D736E61702D747970653A2078207072';
wwv_flow_imp.g_varchar2_table(16) := '6F78696D6974793B0A7D0A2E74782D4B616E62616E2D6C616E65207B0A20202F2A204C616E6520576964746820697320746865206D696E696D756D3A206C616E657320736861726520616E79207370616365206C656674206F766572202A2F0A2020666C';
wwv_flow_imp.g_varchar2_table(17) := '65783A20312030206D696E28766172282D2D74782D6B622D6C616E652C203239307078292C2063616C63283130307677202D203634707829293B0A2020646973706C61793A20666C65783B0A2020666C65782D646972656374696F6E3A20636F6C756D6E';
wwv_flow_imp.g_varchar2_table(18) := '3B0A20206D61782D6865696768743A20766172282D2D74782D6B622D6865696768742C203630307078293B0A2020626F726465722D7261646975733A20313270783B0A20206261636B67726F756E643A20766172282D2D74782D6B622D6C616E652D6267';
wwv_flow_imp.g_varchar2_table(19) := '293B0A2020626F726465723A2031707820736F6C696420636F6C6F722D6D697828696E20737267622C20766172282D2D74782D6B622D6C696E6529203730252C207472616E73706172656E74293B0A20207363726F6C6C2D736E61702D616C69676E3A20';
wwv_flow_imp.g_varchar2_table(20) := '73746172743B0A7D0A2E74782D4B616E62616E2D6C616E6548656164207B0A2020646973706C61793A20666C65783B0A2020616C69676E2D6974656D733A2063656E7465723B0A20206761703A203870783B0A202070616464696E673A20313270782031';
wwv_flow_imp.g_varchar2_table(21) := '3270782038707820313470783B0A7D0A2E74782D4B616E62616E2D6C616E65486561643A3A6265666F7265207B0A2020636F6E74656E743A2022223B0A2020666C65783A206E6F6E653B0A202077696474683A203870783B0A20206865696768743A2038';
wwv_flow_imp.g_varchar2_table(22) := '70783B0A2020626F726465722D7261646975733A203530253B0A20206261636B67726F756E643A20766172282D2D74782D6B622D616363656E74293B0A7D0A2E74782D4B616E62616E202E74782D4B616E62616E2D6C616E655469746C65207B0A202066';
wwv_flow_imp.g_varchar2_table(23) := '6C65783A20313B0A20206D617267696E3A20303B0A2020666F6E742D73697A653A20313370783B0A2020666F6E742D7765696768743A203635303B0A20206C696E652D6865696768743A20312E333B0A2020636F6C6F723A20766172282D2D74782D6B62';
wwv_flow_imp.g_varchar2_table(24) := '2D74657874293B0A20206F766572666C6F773A2068696464656E3B0A2020746578742D6F766572666C6F773A20656C6C69707369733B0A202077686974652D73706163653A206E6F777261703B0A7D0A2E74782D4B616E62616E2D636F756E74207B0A20';
wwv_flow_imp.g_varchar2_table(25) := '206D696E2D77696474683A20323470783B0A202070616464696E673A20317078203870783B0A2020626F726465722D7261646975733A2039393970783B0A20206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D';
wwv_flow_imp.g_varchar2_table(26) := '2D74782D6B622D74657874292038252C207472616E73706172656E74293B0A2020636F6C6F723A20766172282D2D74782D6B622D6D75746564293B0A2020666F6E742D73697A653A20313270783B0A2020666F6E742D7765696768743A203630303B0A20';
wwv_flow_imp.g_varchar2_table(27) := '20666F6E742D76617269616E742D6E756D657269633A20746162756C61722D6E756D733B0A2020746578742D616C69676E3A2063656E7465723B0A7D0A2E74782D4B616E62616E2D6C616E652E69732D66756C6C202E74782D4B616E62616E2D636F756E';
wwv_flow_imp.g_varchar2_table(28) := '74207B206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D6B622D7761726E29203136252C207472616E73706172656E74293B20636F6C6F723A20766172282D2D74782D6B622D7761726E293B207D0A';
wwv_flow_imp.g_varchar2_table(29) := '2E74782D4B616E62616E2D6C616E652E69732D6F766572207B20626F726465722D636F6C6F723A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D6B622D64616E67657229203435252C207472616E73706172656E74293B206261';
wwv_flow_imp.g_varchar2_table(30) := '636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D6B622D64616E676572292035252C20766172282D2D74782D6B622D6C616E652D626729293B207D0A2E74782D4B616E62616E2D6C616E652E69732D6F7665';
wwv_flow_imp.g_varchar2_table(31) := '72202E74782D4B616E62616E2D636F756E74207B206261636B67726F756E643A20766172282D2D74782D6B622D64616E676572293B20636F6C6F723A20236666663B207D0A2E74782D4B616E62616E2D616464207B0A2020646973706C61793A20677269';
wwv_flow_imp.g_varchar2_table(32) := '643B0A2020706C6163652D6974656D733A2063656E7465723B0A202077696474683A20323670783B0A20206865696768743A20323670783B0A202070616464696E673A20303B0A2020626F726465723A20303B0A2020626F726465722D7261646975733A';
wwv_flow_imp.g_varchar2_table(33) := '203670783B0A20206261636B67726F756E643A207472616E73706172656E743B0A2020636F6C6F723A20766172282D2D74782D6B622D6D75746564293B0A2020637572736F723A20706F696E7465723B0A7D0A2E74782D4B616E62616E2D6164643A686F';
wwv_flow_imp.g_varchar2_table(34) := '766572207B206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D6B622D74657874292039252C207472616E73706172656E74293B20636F6C6F723A20766172282D2D74782D6B622D74657874293B207D';
wwv_flow_imp.g_varchar2_table(35) := '0A2E74782D4B616E62616E2D6164643A666F6375732D76697369626C65207B206F75746C696E653A2032707820736F6C696420766172282D2D74782D6B622D616363656E742D7569293B206F75746C696E652D6F66667365743A203170783B207D0A2E74';
wwv_flow_imp.g_varchar2_table(36) := '782D4B616E62616E202E74782D4B616E62616E2D616464202E6661207B20666F6E742D73697A653A20313270783B207D0A0A2E74782D4B616E62616E2D6C697374207B0A2020666C65783A20313B0A2020646973706C61793A20666C65783B0A2020666C';
wwv_flow_imp.g_varchar2_table(37) := '65782D646972656374696F6E3A20636F6C756D6E3B0A20206761703A203870783B0A20206D696E2D6865696768743A20373270783B0A202070616464696E673A203270782038707820313070783B0A20206F766572666C6F772D793A206175746F3B0A20';
wwv_flow_imp.g_varchar2_table(38) := '206F7665727363726F6C6C2D6265686176696F723A20636F6E7461696E3B0A7D0A2E74782D4B616E62616E2D706C616365686F6C646572207B0A2020646973706C61793A20677269643B0A2020706C6163652D6974656D733A2063656E7465723B0A2020';
wwv_flow_imp.g_varchar2_table(39) := '6D696E2D6865696768743A20363470783B0A2020626F726465723A20312E3570782064617368656420636F6C6F722D6D697828696E20737267622C20766172282D2D74782D6B622D7465787429203138252C207472616E73706172656E74293B0A202062';
wwv_flow_imp.g_varchar2_table(40) := '6F726465722D7261646975733A20313070783B0A2020636F6C6F723A20766172282D2D74782D6B622D6D75746564293B0A2020666F6E742D73697A653A20313370783B0A7D0A2E74782D4B616E62616E2E69732D6472616767696E67202E74782D4B616E';
wwv_flow_imp.g_varchar2_table(41) := '62616E2D6C697374207B206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D6B622D616363656E742D7569292034252C207472616E73706172656E74293B20626F726465722D7261646975733A203020';
wwv_flow_imp.g_varchar2_table(42) := '30203132707820313270783B207D0A0A2E74782D4B616E62616E2D63617264207B0A2020706F736974696F6E3A2072656C61746976653B0A2020646973706C61793A20666C65783B0A2020666C65782D646972656374696F6E3A20636F6C756D6E3B0A20';
wwv_flow_imp.g_varchar2_table(43) := '206761703A203670783B0A202070616464696E673A20313170782031327078203131707820313370783B0A2020626F726465723A2031707820736F6C696420766172282D2D74782D6B622D6C696E65293B0A2020626F726465722D7261646975733A2031';
wwv_flow_imp.g_varchar2_table(44) := '3070783B0A20206261636B67726F756E643A20766172282D2D74782D6B622D6267293B0A2020626F782D736861646F773A2030203170782032707820726762612832302C2032342C2034302C202E3036293B0A2020637572736F723A20706F696E746572';
wwv_flow_imp.g_varchar2_table(45) := '3B0A2020757365722D73656C6563743A206E6F6E653B0A20207472616E736974696F6E3A20626F782D736861646F77202E3135732C20626F726465722D636F6C6F72202E3135733B0A7D0A2E74782D4B616E62616E2D636172642E6861732D636F6C6F72';
wwv_flow_imp.g_varchar2_table(46) := '3A3A6265666F7265207B0A2020636F6E74656E743A2022223B0A2020706F736974696F6E3A206162736F6C7574653B0A20206C6566743A202D3170783B0A2020746F703A20313070783B0A2020626F74746F6D3A20313070783B0A202077696474683A20';
wwv_flow_imp.g_varchar2_table(47) := '3370783B0A2020626F726465722D7261646975733A2030203370782033707820303B0A20206261636B67726F756E643A20766172282D2D74782D6B622D63617264293B0A7D0A2E74782D4B616E62616E2D636172643A686F766572207B20626F72646572';
wwv_flow_imp.g_varchar2_table(48) := '2D636F6C6F723A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D6B622D7465787429203232252C207472616E73706172656E74293B20626F782D736861646F773A203020337078203130707820726762612832302C2032342C20';
wwv_flow_imp.g_varchar2_table(49) := '34302C202E3038293B207D0A2E74782D4B616E62616E2D636172643A666F6375732D76697369626C65207B206F75746C696E653A2032707820736F6C696420766172282D2D74782D6B622D616363656E742D7569293B206F75746C696E652D6F66667365';
wwv_flow_imp.g_varchar2_table(50) := '743A203270783B207D0A2E74782D4B616E62616E2D636172645B68696464656E5D207B20646973706C61793A206E6F6E653B207D0A2E74782D4B616E62616E2D636172642E69732D67686F7374207B206F7061636974793A202E34353B20626F72646572';
wwv_flow_imp.g_varchar2_table(51) := '2D7374796C653A206461736865643B20626F782D736861646F773A206E6F6E653B207D0A2E74782D4B616E62616E2D636172642E69732D64726167207B207472616E73666F726D3A20726F7461746528312E35646567293B20626F782D736861646F773A';
wwv_flow_imp.g_varchar2_table(52) := '20302031327078203238707820726762612832302C2032342C2034302C202E3138293B207D0A2E74782D4B616E62616E2D636172642E69732D736176696E67207B206F7061636974793A202E36353B20637572736F723A2070726F67726573733B207D0A';
wwv_flow_imp.g_varchar2_table(53) := '0A2E74782D4B616E62616E2D6C6162656C207B0A2020616C69676E2D73656C663A20666C65782D73746172743B0A20206D61782D77696474683A20313030253B0A202070616464696E673A20327078203870783B0A2020626F726465722D726164697573';
wwv_flow_imp.g_varchar2_table(54) := '3A203670783B0A20206261636B67726F756E643A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D6B622D636172642C20766172282D2D74782D6B622D6D757465642929203134252C207472616E73706172656E74293B0A202063';
wwv_flow_imp.g_varchar2_table(55) := '6F6C6F723A20636F6C6F722D6D697828696E20737267622C20766172282D2D74782D6B622D636172642C20766172282D2D74782D6B622D6D757465642929203835252C20766172282D2D74782D6B622D7465787429293B0A2020666F6E742D73697A653A';
wwv_flow_imp.g_varchar2_table(56) := '2031312E3570783B0A2020666F6E742D7765696768743A203630303B0A20206C696E652D6865696768743A20312E353B0A20206F766572666C6F773A2068696464656E3B0A2020746578742D6F766572666C6F773A20656C6C69707369733B0A20207768';
wwv_flow_imp.g_varchar2_table(57) := '6974652D73706163653A206E6F777261703B0A7D0A2E74782D4B616E62616E202E74782D4B616E62616E2D7469746C65207B206D617267696E3A20303B20666F6E742D73697A653A20313470783B20666F6E742D7765696768743A203630303B206C696E';
wwv_flow_imp.g_varchar2_table(58) := '652D6865696768743A20312E33353B20636F6C6F723A20766172282D2D74782D6B622D74657874293B206F766572666C6F772D777261703A20616E7977686572653B207D0A2E74782D4B616E62616E202E74782D4B616E62616E2D64657363207B0A2020';
wwv_flow_imp.g_varchar2_table(59) := '6D617267696E3A20303B0A2020636F6C6F723A20766172282D2D74782D6B622D6D75746564293B0A2020666F6E742D73697A653A20313370783B0A20206C696E652D6865696768743A20312E34353B0A2020646973706C61793A202D7765626B69742D62';
wwv_flow_imp.g_varchar2_table(60) := '6F783B0A20202D7765626B69742D6C696E652D636C616D703A20333B0A20202D7765626B69742D626F782D6F7269656E743A20766572746963616C3B0A20206F766572666C6F773A2068696464656E3B0A7D0A2E74782D4B616E62616E2D666F6F74207B';
wwv_flow_imp.g_varchar2_table(61) := '20646973706C61793A20666C65783B20616C69676E2D6974656D733A2063656E7465723B206A7573746966792D636F6E74656E743A2073706163652D6265747765656E3B206761703A203870783B206D617267696E2D746F703A203270783B207D0A2E74';
wwv_flow_imp.g_varchar2_table(62) := '782D4B616E62616E2D647565207B20646973706C61793A20696E6C696E652D666C65783B20616C69676E2D6974656D733A2063656E7465723B206761703A203270783B20636F6C6F723A20766172282D2D74782D6B622D6D75746564293B20666F6E742D';
wwv_flow_imp.g_varchar2_table(63) := '73697A653A20313270783B20666F6E742D76617269616E742D6E756D657269633A20746162756C61722D6E756D733B207D0A2E74782D4B616E62616E202E74782D4B616E62616E2D647565202E6661207B20666F6E742D73697A653A20313270783B2077';
wwv_flow_imp.g_varchar2_table(64) := '696474683A206175746F3B207D0A2E74782D4B616E62616E2D6475652E69732D6F766572647565207B20636F6C6F723A20766172282D2D74782D6B622D64616E676572293B20666F6E742D7765696768743A203630303B207D0A2E74782D4B616E62616E';
wwv_flow_imp.g_varchar2_table(65) := '2D6475652E69732D736F6F6E207B20636F6C6F723A20766172282D2D74782D6B622D7761726E293B20666F6E742D7765696768743A203630303B207D0A2E74782D4B616E62616E2D6C616E652E69732D646F6E65202E74782D4B616E62616E2D64756520';
wwv_flow_imp.g_varchar2_table(66) := '7B20636F6C6F723A20766172282D2D74782D6B622D6D75746564293B20666F6E742D7765696768743A203430303B207D0A2E74782D4B616E62616E2D6C616E652E69732D646F6E65202E74782D4B616E62616E2D7469746C65207B20636F6C6F723A2076';
wwv_flow_imp.g_varchar2_table(67) := '6172282D2D74782D6B622D6D75746564293B207D0A2E74782D4B616E62616E2D617661746172207B0A2020646973706C61793A20677269643B0A2020706C6163652D6974656D733A2063656E7465723B0A2020666C65783A206E6F6E653B0A2020776964';
wwv_flow_imp.g_varchar2_table(68) := '74683A20323670783B0A20206865696768743A20323670783B0A20206D617267696E2D6C6566743A206175746F3B0A2020626F726465722D7261646975733A203530253B0A20206261636B67726F756E643A20766172282D2D74782D6B622D6176617461';
wwv_flow_imp.g_varchar2_table(69) := '72293B0A2020636F6C6F723A20236666663B0A2020666F6E742D73697A653A2031302E3570783B0A2020666F6E742D7765696768743A203730303B0A20206C65747465722D73706163696E673A202E3032656D3B0A7D0A0A2E74782D4B616E62616E2D65';
wwv_flow_imp.g_varchar2_table(70) := '6D707479207B2070616464696E673A203332707820313670783B20636F6C6F723A20766172282D2D74782D6B622D6D75746564293B20746578742D616C69676E3A2063656E7465723B207D0A2E74782D4B616E62616E2D656D7074795B68696464656E5D';
wwv_flow_imp.g_varchar2_table(71) := '2C202E74782D4B616E62616E2D6C616E65735B68696464656E5D207B20646973706C61793A206E6F6E653B207D0A0A406D656469612028707265666572732D726564756365642D6D6F74696F6E3A2072656475636529207B0A20202E74782D4B616E6261';
wwv_flow_imp.g_varchar2_table(72) := '6E2D63617264207B207472616E736974696F6E3A206E6F6E653B207D0A20202E74782D4B616E62616E2D636172642E69732D64726167207B207472616E73666F726D3A206E6F6E653B207D0A7D0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(6123345003550135)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_file_name=>'kanban.css'
,p_mime_type=>'text/css'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
begin
wwv_flow_imp.g_varchar2_table := wwv_flow_imp.empty_varchar2_table;
wwv_flow_imp.g_varchar2_table(1) := '2F2A0A202A204B616E62616E20426F61726420726567696F6E20706C75672D696E20666F72204F7261636C652041504558202854656368526576582C207777772E74656368726576782E636F6D290A202A0A202A2074656368726576782E6B616E62616E';
wwv_flow_imp.g_varchar2_table(2) := '2E696E69742820726567696F6E496420292069732063616C6C6564206279207468652072656E6465722070726F6365647572652E204974207265616473207468652073657474696E677320616E64207468652063617264732066726F6D0A202A20233C72';
wwv_flow_imp.g_varchar2_table(3) := '6567696F6E49643E5F636172647320616E64206275696C64732074686520626F61726420696E20233C726567696F6E49643E5F6B616E62616E2E204472616767696E67207573657320536F727461626C654A5320284D4954292E0A202A0A202A20436172';
wwv_flow_imp.g_varchar2_table(4) := '64204A534F4E3A207B2069642C20743A207469746C652C20733A207374617475732C20643A206465736372697074696F6E2C20613A2061737369676E65652C206475653A2022595959592D4D4D2D4444222C206C3A206C6162656C2C20633A20636F6C6F';
wwv_flow_imp.g_varchar2_table(5) := '72207D0A202A0A202A20617065782E726567696F6E2820696420292E726566726573682829202F2067657443617264732829202F206D6F766543617264282069642C207374617475732C20706F736974696F6E20290A202A204576656E7473206F6E2074';
wwv_flow_imp.g_varchar2_table(6) := '686520726567696F6E3A0A202A20202074782D6B616E62616E2D6D6F766520207B2069642C207374617475732C2066726F6D2C20706F736974696F6E2C206F72646572207D2020206166746572206120636172642069732064726F707065642028616E64';
wwv_flow_imp.g_varchar2_table(7) := '2073617665642C2077697468204D6F766520436F6465290A202A20202074782D6B616E62616E2D636C69636B207B2069642C2063617264207D202020202020202020202020202020202020202020202020202020206361726420636C69636B6564206F72';
wwv_flow_imp.g_varchar2_table(8) := '20456E7465722070726573736564206F6E2069740A202A20202074782D6B616E62616E2D6164642020207B207374617475732C206C6162656C207D202020202020202020202020202020202020202020202061206C616E652773202B20627574746F6E0A';
wwv_flow_imp.g_varchar2_table(9) := '202A2F0A282066756E6374696F6E2820242C20617065782029207B0A202020202275736520737472696374223B0A0A20202020636F6E7374206E73203D2077696E646F772E7465636872657678203D2077696E646F772E7465636872657678207C7C207B';
wwv_flow_imp.g_varchar2_table(10) := '7D2C0A202020202020202050414C45545445203D205B202223326636666465222C202223376134646462222C202223643134333766222C202223653036363261222C202223316639643535222C202223306638666138222C202223623738363062222C20';
wwv_flow_imp.g_varchar2_table(11) := '2223353136306436222C202223633033383466222C20222331343934376622205D2C0A2020202020202020444159203D2038363430303030303B0A0A2020202066756E6374696F6E20656C28207461672C20636C732C20746578742029207B0A20202020';
wwv_flow_imp.g_varchar2_table(12) := '20202020636F6E73742065203D20646F63756D656E742E637265617465456C656D656E74282074616720293B0A20202020202020206966202820636C732029207B20652E636C6173734E616D65203D20636C733B207D0A20202020202020206966202820';
wwv_flow_imp.g_varchar2_table(13) := '7465787420213D206E756C6C2029207B20652E74657874436F6E74656E74203D20746578743B207D0A202020202020202072657475726E20653B0A202020207D0A0A2020202066756E6374696F6E2068617368436F6C6F722820746578742029207B0A20';
wwv_flow_imp.g_varchar2_table(14) := '202020202020206C65742068203D20303B0A2020202020202020666F72202820636F6E7374206368206F6620537472696E6728207465787420292029207B2068203D20282068202A203331202B2063682E63686172436F6465417428203020292029207C';
wwv_flow_imp.g_varchar2_table(15) := '20303B207D0A202020202020202072657475726E2050414C455454455B204D6174682E616273282068202920252050414C455454452E6C656E677468205D3B0A202020207D0A0A2020202066756E6374696F6E20696E697469616C7328206E616D652029';
wwv_flow_imp.g_varchar2_table(16) := '207B0A2020202020202020636F6E7374207061727473203D20537472696E6728206E616D6520292E7472696D28292E73706C697428202F5B5C732E5F2D5D2B2F20292E66696C7465722820426F6F6C65616E20293B0A2020202020202020696620282021';
wwv_flow_imp.g_varchar2_table(17) := '70617274732E6C656E6774682029207B2072657475726E20223F223B207D0A202020202020202072657475726E20282070617274735B2030205D5B2030205D202B20282070617274732E6C656E677468203E2031203F2070617274735B2070617274732E';
wwv_flow_imp.g_varchar2_table(18) := '6C656E677468202D2031205D5B2030205D203A202222202920292E746F55707065724361736528293B0A202020207D0A0A202020202F2F2022544F444F3A546F20646F2C20444F494E473A496E2070726F67726573733A3322202D3E205B207B2076616C';
wwv_flow_imp.g_varchar2_table(19) := '75652C206C6162656C2C206C696D6974207D205D0A2020202066756E6374696F6E2070617273654C616E65732820746578742029207B0A202020202020202072657475726E20537472696E67282074657874207C7C20222220292E73706C69742820222C';
wwv_flow_imp.g_varchar2_table(20) := '2220292E6D6170282073203D3E20732E7472696D282920292E66696C7465722820426F6F6C65616E20292E6D6170282073203D3E207B0A202020202020202020202020636F6E73742070203D20732E73706C69742820223A2220292E6D6170282078203D';
wwv_flow_imp.g_varchar2_table(21) := '3E20782E7472696D282920292C0A202020202020202020202020202020206C696D6974203D20702E6C656E677468203E2032203F207061727365496E742820705B2032205D2C2031302029203A204E614E3B0A2020202020202020202020207265747572';
wwv_flow_imp.g_varchar2_table(22) := '6E207B2076616C75653A20705B2030205D2C206C6162656C3A20705B2031205D207C7C20705B2030205D2C206C696D69743A206C696D6974203E2030203F206C696D6974203A206E756C6C207D3B0A20202020202020207D20293B0A202020207D0A0A20';
wwv_flow_imp.g_varchar2_table(23) := '202020636C61737320426F617264207B0A2020202020202020636F6E7374727563746F722820726567696F6E49642029207B0A202020202020202020202020746869732E726567696F6E4964203D20726567696F6E49643B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(24) := '20746869732E656C203D20646F63756D656E742E676574456C656D656E74427949642820726567696F6E4964202B20225F6B616E62616E2220293B0A202020202020202020202020636F6E73742064617461203D204A534F4E2E70617273652820646F63';
wwv_flow_imp.g_varchar2_table(25) := '756D656E742E676574456C656D656E74427949642820726567696F6E4964202B20225F63617264732220292E74657874436F6E74656E7420293B0A202020202020202020202020746869732E636667203D20646174613B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(26) := '746869732E6665617475726573203D20537472696E672820646174612E6665617475726573207C7C20222220292E73706C69742820223A2220293B0A202020202020202020202020746869732E686173203D2066203D3E20746869732E66656174757265';
wwv_flow_imp.g_varchar2_table(27) := '732E696E636C7564657328206620293B0A202020202020202020202020746869732E646566696E65644C616E6573203D2070617273654C616E65732820646174612E636F6C756D6E7320293B0A202020202020202020202020746869732E717565727920';
wwv_flow_imp.g_varchar2_table(28) := '3D2022223B0A202020202020202020202020746869732E736F727461626C6573203D205B5D3B0A202020202020202020202020746869732E6275696C6428293B0A202020202020202020202020746869732E73657443617264732820646174612E636172';
wwv_flow_imp.g_varchar2_table(29) := '6473207C7C205B5D20293B0A20202020202020207D0A0A20202020202020206275696C642829207B0A202020202020202020202020746869732E656C2E74657874436F6E74656E74203D2022223B0A202020202020202020202020746869732E656C2E73';
wwv_flow_imp.g_varchar2_table(30) := '6574417474726962757465282022726F6C65222C2022726567696F6E2220293B0A2020202020202020202020206966202820746869732E6861732820227365617263682220292029207B0A20202020202020202020202020202020636F6E737420626172';
wwv_flow_imp.g_varchar2_table(31) := '203D20656C282022646976222C202274782D4B616E62616E2D6261722220292C0A202020202020202020202020202020202020202077726170203D20656C2820226C6162656C222C202274782D4B616E62616E2D7365617263682220292C0A2020202020';
wwv_flow_imp.g_varchar2_table(32) := '20202020202020202020202020202069636F6E203D20656C2820227370616E222C202274782D4B616E62616E2D73656172636849636F6E2066612066612D7365617263682220293B0A2020202020202020202020202020202069636F6E2E736574417474';
wwv_flow_imp.g_varchar2_table(33) := '726962757465282022617269612D68696464656E222C2022747275652220293B0A20202020202020202020202020202020746869732E736561726368203D20656C282022696E7075742220293B0A20202020202020202020202020202020746869732E73';
wwv_flow_imp.g_varchar2_table(34) := '65617263682E74797065203D2022736561726368223B0A20202020202020202020202020202020746869732E7365617263682E706C616365686F6C646572203D2022536561726368206361726473223B0A20202020202020202020202020202020746869';
wwv_flow_imp.g_varchar2_table(35) := '732E7365617263682E736574417474726962757465282022617269612D6C6162656C222C20225365617263682063617264732220293B0A20202020202020202020202020202020746869732E7365617263682E6164644576656E744C697374656E657228';
wwv_flow_imp.g_varchar2_table(36) := '2022696E707574222C202829203D3E207B20746869732E7175657279203D20746869732E7365617263682E76616C75652E7472696D28292E746F4C6F7765724361736528293B20746869732E66696C74657228293B207D20293B0A202020202020202020';
wwv_flow_imp.g_varchar2_table(37) := '20202020202020777261702E617070656E64282069636F6E2C20746869732E73656172636820293B0A20202020202020202020202020202020746869732E73756D6D617279203D20656C2820227370616E222C202274782D4B616E62616E2D73756D6D61';
wwv_flow_imp.g_varchar2_table(38) := '72792220293B0A20202020202020202020202020202020746869732E73756D6D6172792E736574417474726962757465282022617269612D6C697665222C2022706F6C6974652220293B0A202020202020202020202020202020206261722E617070656E';
wwv_flow_imp.g_varchar2_table(39) := '642820777261702C20746869732E73756D6D61727920293B0A20202020202020202020202020202020746869732E656C2E617070656E64282062617220293B0A2020202020202020202020207D0A202020202020202020202020746869732E6C616E6573';
wwv_flow_imp.g_varchar2_table(40) := '456C203D20656C282022646976222C202274782D4B616E62616E2D6C616E65732220293B0A202020202020202020202020746869732E656C2E617070656E642820746869732E6C616E6573456C20293B0A202020202020202020202020746869732E656D';
wwv_flow_imp.g_varchar2_table(41) := '707479203D20656C282022646976222C202274782D4B616E62616E2D656D707479222C20746869732E6366672E6E6F44617461466F756E64207C7C20224E6F2063617264732E2220293B0A202020202020202020202020746869732E656D7074792E6869';
wwv_flow_imp.g_varchar2_table(42) := '6464656E203D20747275653B0A202020202020202020202020746869732E656C2E617070656E642820746869732E656D70747920293B0A0A202020202020202020202020746869732E656C2E6164644576656E744C697374656E6572282022636C69636B';
wwv_flow_imp.g_varchar2_table(43) := '222C2065203D3E20746869732E6F6E436C69636B282065202920293B0A202020202020202020202020746869732E656C2E6164644576656E744C697374656E65722820226B6579646F776E222C2065203D3E20746869732E6F6E4B657928206520292029';
wwv_flow_imp.g_varchar2_table(44) := '3B0A20202020202020207D0A0A20202020202020202F2F206C616E6573203D20646566696E6564206C616E65732C207468656E20616E79206F746865722073746174757320666F756E6420696E2074686520646174610A20202020202020206C616E6573';
wwv_flow_imp.g_varchar2_table(45) := '466F72282063617264732029207B0A202020202020202020202020636F6E7374206C616E6573203D20746869732E646566696E65644C616E65732E6D617028206C203D3E204F626A6563742E61737369676E28207B7D2C206C202920292C0A2020202020';
wwv_flow_imp.g_varchar2_table(46) := '20202020202020202020206B6E6F776E203D206E65772053657428206C616E65732E6D617028206C203D3E206C2E76616C7565202920293B0A20202020202020202020202063617264732E666F7245616368282063203D3E207B0A202020202020202020';
wwv_flow_imp.g_varchar2_table(47) := '20202020202020636F6E73742073203D20632E73203D3D206E756C6C203F202222203A20537472696E672820632E7320293B0A202020202020202020202020202020206966202820216B6E6F776E2E68617328207320292029207B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(48) := '2020202020202020202020206B6E6F776E2E61646428207320293B0A20202020202020202020202020202020202020206C616E65732E7075736828207B2076616C75653A20732C206C6162656C3A2073207C7C20224E6F20737461747573222C206C696D';
wwv_flow_imp.g_varchar2_table(49) := '69743A206E756C6C207D20293B0A202020202020202020202020202020207D0A2020202020202020202020207D20293B0A20202020202020202020202072657475726E206C616E65733B0A20202020202020207D0A0A2020202020202020736574436172';
wwv_flow_imp.g_varchar2_table(50) := '6473282063617264732029207B0A202020202020202020202020746869732E6361726473203D206E6577204D617028293B0A20202020202020202020202063617264732E666F7245616368282063203D3E207B20632E6964203D20537472696E67282063';
wwv_flow_imp.g_varchar2_table(51) := '2E696420293B20632E73203D20632E73203D3D206E756C6C203F202222203A20537472696E672820632E7320293B20746869732E63617264732E7365742820632E69642C206320293B207D20293B0A202020202020202020202020746869732E736F7274';
wwv_flow_imp.g_varchar2_table(52) := '61626C65732E666F7245616368282073203D3E20732E64657374726F79282920293B0A202020202020202020202020746869732E736F727461626C6573203D205B5D3B0A202020202020202020202020746869732E6C616E6573456C2E74657874436F6E';
wwv_flow_imp.g_varchar2_table(53) := '74656E74203D2022223B0A202020202020202020202020746869732E6C616E6573203D20746869732E6C616E6573466F722820636172647320293B0A202020202020202020202020746869732E656D7074792E68696464656E203D20746869732E6C616E';
wwv_flow_imp.g_varchar2_table(54) := '65732E6C656E677468203E20303B0A202020202020202020202020746869732E6C616E6573456C2E68696464656E203D2021746869732E6C616E65732E6C656E6774683B0A0A202020202020202020202020746869732E6C616E65732E666F7245616368';
wwv_flow_imp.g_varchar2_table(55) := '282028206C616E652C20692029203D3E207B0A20202020202020202020202020202020636F6E73742073656374696F6E203D20656C28202273656374696F6E222C202274782D4B616E62616E2D6C616E652220292C0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(56) := '20202020202068656164203D20656C282022686561646572222C202274782D4B616E62616E2D6C616E65486561642220292C0A20202020202020202020202020202020202020207469746C65203D20656C2820226833222C202274782D4B616E62616E2D';
wwv_flow_imp.g_varchar2_table(57) := '6C616E655469746C65222C206C616E652E6C6162656C20292C0A20202020202020202020202020202020202020206C697374203D20656C282022646976222C202274782D4B616E62616E2D6C6973742220293B0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(58) := '73656374696F6E2E7374796C652E73657450726F70657274792820222D2D74782D6B622D616363656E74222C2050414C455454455B206920252050414C455454452E6C656E677468205D20293B0A2020202020202020202020202020202073656374696F';
wwv_flow_imp.g_varchar2_table(59) := '6E2E646174617365742E737461747573203D206C616E652E76616C75653B0A202020202020202020202020202020207469746C652E6964203D20746869732E726567696F6E4964202B20225F6C616E655F22202B20693B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(60) := '20202020686561642E617070656E6428207469746C6520293B0A202020202020202020202020202020206966202820746869732E686173282022636F756E74732220292029207B0A20202020202020202020202020202020202020206C616E652E636F75';
wwv_flow_imp.g_varchar2_table(61) := '6E74456C203D20656C2820227370616E222C202274782D4B616E62616E2D636F756E742220293B0A2020202020202020202020202020202020202020686561642E617070656E6428206C616E652E636F756E74456C20293B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(62) := '20202020207D0A202020202020202020202020202020206966202820746869732E6861732820226164642220292029207B0A2020202020202020202020202020202020202020636F6E737420616464203D20656C282022627574746F6E222C202274782D';
wwv_flow_imp.g_varchar2_table(63) := '4B616E62616E2D6164642220293B0A20202020202020202020202020202020202020206164642E74797065203D2022627574746F6E223B0A20202020202020202020202020202020202020206164642E646174617365742E7478416374696F6E203D2022';
wwv_flow_imp.g_varchar2_table(64) := '616464223B0A20202020202020202020202020202020202020206164642E7469746C65203D2022416464206361726420746F2022202B206C616E652E6C6162656C3B0A20202020202020202020202020202020202020206164642E736574417474726962';
wwv_flow_imp.g_varchar2_table(65) := '757465282022617269612D6C6162656C222C206164642E7469746C6520293B0A20202020202020202020202020202020202020206164642E617070656E642820656C2820227370616E222C202266612066612D706C757322202920293B0A202020202020';
wwv_flow_imp.g_varchar2_table(66) := '2020202020202020202020202020686561642E617070656E64282061646420293B0A202020202020202020202020202020207D0A202020202020202020202020202020206C6973742E736574417474726962757465282022726F6C65222C20226C697374';
wwv_flow_imp.g_varchar2_table(67) := '2220293B0A202020202020202020202020202020206C6973742E736574417474726962757465282022617269612D6C6162656C6C65646279222C207469746C652E696420293B0A202020202020202020202020202020206C6973742E646174617365742E';
wwv_flow_imp.g_varchar2_table(68) := '737461747573203D206C616E652E76616C75653B0A202020202020202020202020202020206C616E652E73656374696F6E203D2073656374696F6E3B0A202020202020202020202020202020206C616E652E6C697374203D206C6973743B0A2020202020';
wwv_flow_imp.g_varchar2_table(69) := '202020202020202020202073656374696F6E2E617070656E642820686561642C206C69737420293B0A20202020202020202020202020202020746869732E6C616E6573456C2E617070656E64282073656374696F6E20293B0A2020202020202020202020';
wwv_flow_imp.g_varchar2_table(70) := '207D20293B0A0A20202020202020202020202063617264732E666F7245616368282063203D3E20746869732E6C616E654F662820632E7320292E6C6973742E617070656E642820746869732E63617264456C2820632029202920293B0A0A202020202020';
wwv_flow_imp.g_varchar2_table(71) := '2020202020206966202820746869732E686173282022647261672220292026262077696E646F772E536F727461626C652029207B0A20202020202020202020202020202020746869732E6C616E65732E666F724561636828206C616E65203D3E207B0A20';
wwv_flow_imp.g_varchar2_table(72) := '20202020202020202020202020202020202020746869732E736F727461626C65732E70757368282077696E646F772E536F727461626C652E63726561746528206C616E652E6C6973742C207B0A2020202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(73) := '2067726F75703A202274782D6B616E62616E2D22202B20746869732E726567696F6E49642C0A202020202020202020202020202020202020202020202020616E696D6174696F6E3A203136302C0A20202020202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(74) := '202064656C61793A203136302C0A20202020202020202020202020202020202020202020202064656C61794F6E546F7563684F6E6C793A20747275652C0A202020202020202020202020202020202020202020202020647261676761626C653A20222E74';
wwv_flow_imp.g_varchar2_table(75) := '782D4B616E62616E2D63617264222C0A20202020202020202020202020202020202020202020202066696C7465723A20222E74782D4B616E62616E2D706C616365686F6C646572222C0A2020202020202020202020202020202020202020202020206768';
wwv_flow_imp.g_varchar2_table(76) := '6F7374436C6173733A202269732D67686F7374222C0A20202020202020202020202020202020202020202020202063686F73656E436C6173733A202269732D63686F73656E222C0A20202020202020202020202020202020202020202020202064726167';
wwv_flow_imp.g_varchar2_table(77) := '436C6173733A202269732D64726167222C0A2020202020202020202020202020202020202020202020206F6E53746172743A202829203D3E20746869732E656C2E636C6173734C6973742E61646428202269732D6472616767696E672220292C0A202020';
wwv_flow_imp.g_varchar2_table(78) := '2020202020202020202020202020202020202020206F6E456E643A20657674203D3E207B0A20202020202020202020202020202020202020202020202020202020746869732E656C2E636C6173734C6973742E72656D6F766528202269732D6472616767';
wwv_flow_imp.g_varchar2_table(79) := '696E672220293B0A20202020202020202020202020202020202020202020202020202020746869732E64726167676564203D20747275653B0A2020202020202020202020202020202020202020202020202020202073657454696D656F75742820282920';
wwv_flow_imp.g_varchar2_table(80) := '3D3E207B20746869732E64726167676564203D2066616C73653B207D2C203020293B0A2020202020202020202020202020202020202020202020202020202069662028206576742E66726F6D203D3D3D206576742E746F202626206576742E6F6C64496E';
wwv_flow_imp.g_varchar2_table(81) := '646578203D3D3D206576742E6E6577496E6465782029207B2072657475726E3B207D0A20202020202020202020202020202020202020202020202020202020746869732E6D6F76656428206576742E6974656D2C206576742E66726F6D2C206576742E6F';
wwv_flow_imp.g_varchar2_table(82) := '6C64496E64657820293B0A2020202020202020202020202020202020202020202020207D0A20202020202020202020202020202020202020207D202920293B0A202020202020202020202020202020207D20293B0A2020202020202020202020207D0A20';
wwv_flow_imp.g_varchar2_table(83) := '2020202020202020202020746869732E75706461746528293B0A202020202020202020202020746869732E66696C74657228293B0A20202020202020207D0A0A20202020202020206C616E654F6628207374617475732029207B0A202020202020202020';
wwv_flow_imp.g_varchar2_table(84) := '20202072657475726E20746869732E6C616E65732E66696E6428206C203D3E206C2E76616C7565203D3D3D20537472696E672820737461747573202920293B0A20202020202020207D0A0A202020202020202063617264456C2820632029207B0A202020';
wwv_flow_imp.g_varchar2_table(85) := '202020202020202020636F6E73742063617264203D20656C28202261727469636C65222C202274782D4B616E62616E2D636172642220293B0A202020202020202020202020636172642E746162496E646578203D20303B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(86) := '636172642E646174617365742E6964203D20632E69643B0A202020202020202020202020636172642E736574417474726962757465282022726F6C65222C20226C6973746974656D2220293B0A202020202020202020202020636F6E737420636F6C6F72';
wwv_flow_imp.g_varchar2_table(87) := '203D20632E63207C7C202820632E6C203F2068617368436F6C6F722820632E6C2029203A206E756C6C20293B0A2020202020202020202020206966202820636F6C6F722029207B20636172642E7374796C652E73657450726F70657274792820222D2D74';
wwv_flow_imp.g_varchar2_table(88) := '782D6B622D63617264222C20636F6C6F7220293B20636172642E636C6173734C6973742E6164642820226861732D636F6C6F722220293B207D0A0A2020202020202020202020206966202820632E6C2029207B0A20202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(89) := '636F6E7374206C6162656C203D20656C2820227370616E222C202274782D4B616E62616E2D6C6162656C222C20632E6C20293B0A20202020202020202020202020202020636172642E617070656E6428206C6162656C20293B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(90) := '20207D0A202020202020202020202020636172642E617070656E642820656C2820226834222C202274782D4B616E62616E2D7469746C65222C20632E74207C7C20632E6964202920293B0A2020202020202020202020206966202820632E642029207B20';
wwv_flow_imp.g_varchar2_table(91) := '636172642E617070656E642820656C28202270222C202274782D4B616E62616E2D64657363222C20632E64202920293B207D0A0A2020202020202020202020206966202820632E647565207C7C20632E612029207B0A2020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(92) := '2020636F6E737420666F6F74203D20656C282022646976222C202274782D4B616E62616E2D666F6F742220293B0A202020202020202020202020202020206966202820632E6475652029207B20666F6F742E617070656E642820746869732E647565456C';
wwv_flow_imp.g_varchar2_table(93) := '2820632E647565202920293B207D0A202020202020202020202020202020206966202820632E612029207B0A2020202020202020202020202020202020202020636F6E737420617661746172203D20656C2820227370616E222C202274782D4B616E6261';
wwv_flow_imp.g_varchar2_table(94) := '6E2D617661746172222C20696E697469616C732820632E61202920293B0A20202020202020202020202020202020202020206176617461722E7374796C652E73657450726F70657274792820222D2D74782D6B622D617661746172222C2068617368436F';
wwv_flow_imp.g_varchar2_table(95) := '6C6F722820632E61202920293B0A20202020202020202020202020202020202020206176617461722E7469746C65203D20632E613B0A20202020202020202020202020202020202020206176617461722E73657441747472696275746528202261726961';
wwv_flow_imp.g_varchar2_table(96) := '2D6C6162656C222C202241737369676E656420746F2022202B20632E6120293B0A2020202020202020202020202020202020202020666F6F742E617070656E64282061766174617220293B0A202020202020202020202020202020207D0A202020202020';
wwv_flow_imp.g_varchar2_table(97) := '20202020202020202020636172642E617070656E642820666F6F7420293B0A2020202020202020202020207D0A20202020202020202020202072657475726E20636172643B0A20202020202020207D0A0A2020202020202020647565456C282064756520';
wwv_flow_imp.g_varchar2_table(98) := '29207B0A202020202020202020202020636F6E7374206D203D202F5E285C647B347D292D285C647B327D292D285C647B327D292F2E65786563282064756520292C0A202020202020202020202020202020207370616E203D20656C2820227370616E222C';
wwv_flow_imp.g_varchar2_table(99) := '202274782D4B616E62616E2D6475652220292C0A2020202020202020202020202020202069636F6E203D20656C2820227370616E222C202266612066612D63616C656E6461722D6F2220293B0A20202020202020202020202069636F6E2E736574417474';
wwv_flow_imp.g_varchar2_table(100) := '726962757465282022617269612D68696464656E222C2022747275652220293B0A2020202020202020202020207370616E2E617070656E64282069636F6E20293B0A2020202020202020202020206966202820216D2029207B207370616E2E617070656E';
wwv_flow_imp.g_varchar2_table(101) := '642820222022202B2064756520293B2072657475726E207370616E3B207D0A202020202020202020202020636F6E73742064617465203D206E6577204461746528202B6D5B2031205D2C206D5B2032205D202D20312C202B6D5B2033205D20292C0A2020';
wwv_flow_imp.g_varchar2_table(102) := '2020202020202020202020202020746F646179203D206E6577204461746528292C0A2020202020202020202020202020202064617973203D204D6174682E726F756E642820282064617465202D206E657720446174652820746F6461792E67657446756C';
wwv_flow_imp.g_varchar2_table(103) := '6C5965617228292C20746F6461792E6765744D6F6E746828292C20746F6461792E67657444617465282920292029202F2044415920292C0A202020202020202020202020202020206C616E67203D20646F63756D656E742E646F63756D656E74456C656D';
wwv_flow_imp.g_varchar2_table(104) := '656E742E6C616E67207C7C20756E646566696E65642C0A20202020202020202020202020202020666D74203D206E657720496E746C2E4461746554696D65466F726D617428206C616E672C20646174652E67657446756C6C596561722829203D3D3D2074';
wwv_flow_imp.g_varchar2_table(105) := '6F6461792E67657446756C6C5965617228290A20202020202020202020202020202020202020203F207B206D6F6E74683A202273686F7274222C206461793A20226E756D6572696322207D203A207B20796561723A20226E756D65726963222C206D6F6E';
wwv_flow_imp.g_varchar2_table(106) := '74683A202273686F7274222C206461793A20226E756D6572696322207D20293B0A2020202020202020202020207370616E2E617070656E642820222022202B20666D742E666F726D6174282064617465202920293B0A2020202020202020202020207370';
wwv_flow_imp.g_varchar2_table(107) := '616E2E646174617365742E647565203D206475652E736C6963652820302C20313020293B0A202020202020202020202020696620282064617973203C20302029207B0A202020202020202020202020202020207370616E2E636C6173734C6973742E6164';
wwv_flow_imp.g_varchar2_table(108) := '6428202269732D6F7665726475652220293B0A202020202020202020202020202020207370616E2E7469746C65203D20224F7665726475652062792022202B202D64617973202B20282064617973203D3D3D202D31203F20222064617922203A20222064';
wwv_flow_imp.g_varchar2_table(109) := '6179732220293B0A2020202020202020202020207D20656C736520696620282064617973203C3D20322029207B0A202020202020202020202020202020207370616E2E636C6173734C6973742E61646428202269732D736F6F6E2220293B0A2020202020';
wwv_flow_imp.g_varchar2_table(110) := '20202020202020202020207370616E2E7469746C65203D2064617973203D3D3D2030203F202244756520746F64617922203A202244756520696E2022202B2064617973202B20282064617973203D3D3D2031203F20222064617922203A20222064617973';
wwv_flow_imp.g_varchar2_table(111) := '2220293B0A2020202020202020202020207D0A20202020202020202020202072657475726E207370616E3B0A20202020202020207D0A0A20202020202020202F2F20636F756E74732C206C696D69747320616E6420656D7074792D6C616E6520706C6163';
wwv_flow_imp.g_varchar2_table(112) := '65686F6C646572733B206C616E65732077697468206120646F6E652D6C696B652076616C7565206765742069732D646F6E6520286E6F206F76657264756520636F6C6F7273290A20202020202020207570646174652829207B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(113) := '2020746869732E6C616E65732E666F724561636828206C616E65203D3E207B0A20202020202020202020202020202020636F6E7374206E203D206C616E652E6C6973742E717565727953656C6563746F72416C6C2820222E74782D4B616E62616E2D6361';
wwv_flow_imp.g_varchar2_table(114) := '72642220292E6C656E6774683B0A2020202020202020202020202020202069662028206C616E652E636F756E74456C2029207B0A20202020202020202020202020202020202020206C616E652E636F756E74456C2E74657874436F6E74656E74203D206C';
wwv_flow_imp.g_varchar2_table(115) := '616E652E6C696D6974203F206E202B2022202F2022202B206C616E652E6C696D6974203A20537472696E6728206E20293B0A20202020202020202020202020202020202020206C616E652E636F756E74456C2E7469746C65203D206C616E652E6C696D69';
wwv_flow_imp.g_varchar2_table(116) := '74203F206E202B20222063617264732C206C696D69742022202B206C616E652E6C696D6974203A206E202B2028206E203D3D3D2031203F2022206361726422203A20222063617264732220293B0A202020202020202020202020202020207D0A20202020';
wwv_flow_imp.g_varchar2_table(117) := '2020202020202020202020206C616E652E73656374696F6E2E636C6173734C6973742E746F67676C6528202269732D6F766572222C2021216C616E652E6C696D6974202626206E203E206C616E652E6C696D697420293B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(118) := '202020206C616E652E73656374696F6E2E636C6173734C6973742E746F67676C6528202269732D66756C6C222C2021216C616E652E6C696D6974202626206E203D3D3D206C616E652E6C696D697420293B0A202020202020202020202020202020206C61';
wwv_flow_imp.g_varchar2_table(119) := '6E652E73656374696F6E2E636C6173734C6973742E746F67676C6528202269732D646F6E65222C202F5E28646F6E657C636C6F7365647C636F6D706C6574657C636F6D706C657465647C66696E697368656429242F692E7465737428206C616E652E7661';
wwv_flow_imp.g_varchar2_table(120) := '6C7565202920293B0A202020202020202020202020202020206C6574207068203D206C616E652E6C6973742E717565727953656C6563746F722820222E74782D4B616E62616E2D706C616365686F6C6465722220293B0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(121) := '2020206966202820216E202626202170682029207B0A20202020202020202020202020202020202020207068203D20656C282022646976222C202274782D4B616E62616E2D706C616365686F6C646572222C20746869732E686173282022647261672220';
wwv_flow_imp.g_varchar2_table(122) := '29203F202244726F70206361726473206865726522203A20224E6F2063617264732220293B0A20202020202020202020202020202020202020206C616E652E6C6973742E617070656E642820706820293B0A202020202020202020202020202020207D20';
wwv_flow_imp.g_varchar2_table(123) := '656C73652069662028206E2026262070682029207B0A202020202020202020202020202020202020202070682E72656D6F766528293B0A202020202020202020202020202020207D0A2020202020202020202020207D20293B0A20202020202020207D0A';
wwv_flow_imp.g_varchar2_table(124) := '0A202020202020202066696C7465722829207B0A202020202020202020202020636F6E73742071203D20746869732E71756572793B0A2020202020202020202020206C65742073686F776E203D20303B0A202020202020202020202020746869732E6361';
wwv_flow_imp.g_varchar2_table(125) := '7264732E666F724561636828202820632C2069642029203D3E207B0A20202020202020202020202020202020636F6E73742063617264203D20746869732E636172644E6F64652820696420293B0A20202020202020202020202020202020696620282021';
wwv_flow_imp.g_varchar2_table(126) := '636172642029207B2072657475726E3B207D0A20202020202020202020202020202020636F6E737420686974203D202171207C7C205B20632E742C20632E642C20632E612C20632E6C2C20632E6964205D2E736F6D65282076203D3E207620213D206E75';
wwv_flow_imp.g_varchar2_table(127) := '6C6C20262620537472696E6728207620292E746F4C6F7765724361736528292E696E636C75646573282071202920293B0A20202020202020202020202020202020636172642E68696464656E203D20216869743B0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(128) := '2069662028206869742029207B2073686F776E2B2B3B207D0A2020202020202020202020207D20293B0A2020202020202020202020206966202820746869732E73756D6D6172792029207B0A20202020202020202020202020202020746869732E73756D';
wwv_flow_imp.g_varchar2_table(129) := '6D6172792E74657874436F6E74656E74203D2071203F2073686F776E202B2022206F662022202B20746869732E63617264732E73697A65202B202220636172647322203A20746869732E63617264732E73697A65202B202820746869732E63617264732E';
wwv_flow_imp.g_varchar2_table(130) := '73697A65203D3D3D2031203F2022206361726422203A20222063617264732220293B0A2020202020202020202020207D0A20202020202020207D0A0A2020202020202020636172644E6F6465282069642029207B0A202020202020202020202020726574';
wwv_flow_imp.g_varchar2_table(131) := '75726E2041727261792E66726F6D2820746869732E656C2E717565727953656C6563746F72416C6C2820222E74782D4B616E62616E2D6361726422202920292E66696E6428206E203D3E206E2E646174617365742E6964203D3D3D20696420293B0A2020';
wwv_flow_imp.g_varchar2_table(132) := '2020202020207D0A0A20202020202020206F7264657228206C6973742029207B0A20202020202020202020202072657475726E2041727261792E66726F6D28206C6973742E717565727953656C6563746F72416C6C2820222E74782D4B616E62616E2D63';
wwv_flow_imp.g_varchar2_table(133) := '61726422202920292E6D617028206E203D3E206E2E646174617365742E696420293B0A20202020202020207D0A0A20202020202020202F2F20612063617264207761732064726F7070656420286F72206D6F766564206279206B6579626F617264293B20';
wwv_flow_imp.g_varchar2_table(134) := '736176657320697420616E64206D6F766573206974206261636B207768656E207468652073617665206661696C730A20202020202020206D6F7665642820636172642C2066726F6D4C6973742C206F6C64496E6465782029207B0A202020202020202020';
wwv_flow_imp.g_varchar2_table(135) := '202020636F6E7374206964203D20636172642E646174617365742E69642C0A2020202020202020202020202020202063203D20746869732E63617264732E6765742820696420292C0A202020202020202020202020202020206C697374203D2063617264';
wwv_flow_imp.g_varchar2_table(136) := '2E706172656E744E6F64652C0A2020202020202020202020202020202066726F6D203D20632E732C0A20202020202020202020202020202020737461747573203D206C6973742E646174617365742E7374617475732C0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(137) := '2020206F72646572203D20746869732E6F7264657228206C69737420292C0A20202020202020202020202020202020706F736974696F6E203D206F726465722E696E6465784F66282069642029202B20312C0A2020202020202020202020202020202064';
wwv_flow_imp.g_varchar2_table(138) := '617461203D207B2069642C207374617475732C2066726F6D2C20706F736974696F6E2C206F72646572207D3B0A202020202020202020202020632E73203D207374617475733B0A202020202020202020202020746869732E75706461746528293B0A2020';
wwv_flow_imp.g_varchar2_table(139) := '20202020202020202020636172642E666F63757328207B2070726576656E745363726F6C6C3A2074727565207D20293B0A0A202020202020202020202020636F6E737420646F6E65203D202829203D3E207B0A2020202020202020202020202020202061';
wwv_flow_imp.g_varchar2_table(140) := '7065782E6576656E742E747269676765722820222322202B20746869732E726567696F6E49642C202274782D6B616E62616E2D6D6F7665222C206461746120293B0A2020202020202020202020207D3B0A20202020202020202020202069662028202174';
wwv_flow_imp.g_varchar2_table(141) := '6869732E6366672E63616E536176652029207B20646F6E6528293B2072657475726E3B207D0A0A2020202020202020202020202F2F20746865204D6F766520436F6465207265667573656420286D657373616765203D206974732072616973655F617070';
wwv_flow_imp.g_varchar2_table(142) := '6C69636174696F6E5F6572726F72207465787429206F72207468652072657175657374206661696C65640A202020202020202020202020636F6E737420726576657274203D206D657373616765203D3E207B0A2020202020202020202020202020202063';
wwv_flow_imp.g_varchar2_table(143) := '2E73203D2066726F6D3B0A20202020202020202020202020202020636F6E737420726566203D2041727261792E66726F6D282066726F6D4C6973742E717565727953656C6563746F72416C6C2820222E74782D4B616E62616E2D6361726422202920292E';
wwv_flow_imp.g_varchar2_table(144) := '66696C74657228206E203D3E206E20213D3D206361726420295B206F6C64496E646578205D3B0A2020202020202020202020202020202066726F6D4C6973742E696E736572744265666F72652820636172642C20726566207C7C2066726F6D4C6973742E';
wwv_flow_imp.g_varchar2_table(145) := '717565727953656C6563746F722820222E74782D4B616E62616E2D706C616365686F6C64657222202920293B0A20202020202020202020202020202020746869732E75706461746528293B0A20202020202020202020202020202020636172642E666F63';
wwv_flow_imp.g_varchar2_table(146) := '757328207B2070726576656E745363726F6C6C3A2074727565207D20293B0A20202020202020202020202020202020617065782E6D6573736167652E636C6561724572726F727328293B0A20202020202020202020202020202020617065782E6D657373';
wwv_flow_imp.g_varchar2_table(147) := '6167652E73686F774572726F727328205B207B20747970653A20226572726F72222C206C6F636174696F6E3A202270616765222C206D6573736167653A206D657373616765207C7C2022546865206361726420636F756C64206E6F74206265206D6F7665';
wwv_flow_imp.g_varchar2_table(148) := '642E222C20756E736166653A2066616C7365207D205D20293B0A2020202020202020202020207D3B0A202020202020202020202020636172642E636C6173734C6973742E61646428202269732D736176696E672220293B0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(149) := '617065782E7365727665722E706C7567696E2820746869732E6366672E616A61784964656E7469666965722C207B0A202020202020202020202020202020207830313A20224D4F5645222C207830323A2069642C207830333A207374617475732C207830';
wwv_flow_imp.g_varchar2_table(150) := '343A20537472696E672820706F736974696F6E20292C207830353A206F726465722E6A6F696E2820222C2220292C20706167654974656D733A20746869732E6366672E6974656D73546F5375626D69740A2020202020202020202020207D2C207B206461';
wwv_flow_imp.g_varchar2_table(151) := '7461547970653A20226A736F6E22207D20290A202020202020202020202020202020202E646F6E652820726573203D3E207B206966202820726573202626207265732E6D6F766564203D3D3D2066616C73652029207B2072657665727428207265732E6D';
wwv_flow_imp.g_varchar2_table(152) := '65737361676520293B207D20656C7365207B20646F6E6528293B207D207D20290A202020202020202020202020202020202E6661696C282028206A715848522C20746578745374617475732C206572726F722029203D3E207B0A20202020202020202020';
wwv_flow_imp.g_varchar2_table(153) := '2020202020202020202077696E646F772E636F6E736F6C652E7761726E2820224B616E62616E20426F6172643A206D6F7665206661696C6564222C206572726F7220293B0A202020202020202020202020202020202020202072657665727428293B0A20';
wwv_flow_imp.g_varchar2_table(154) := '2020202020202020202020202020207D20290A202020202020202020202020202020202E616C7761797328202829203D3E20636172642E636C6173734C6973742E72656D6F766528202269732D736176696E6722202920293B0A20202020202020207D0A';
wwv_flow_imp.g_varchar2_table(155) := '0A20202020202020202F2F206D6F7665732061206361726420627920636F6465206F72206B6579626F6172643A20737461747573203D206C616E652076616C75652C20706F736974696F6E2031203D20746F70202864656661756C743A20626F74746F6D';
wwv_flow_imp.g_varchar2_table(156) := '290A20202020202020206D6F766543617264282069642C207374617475732C20706F736974696F6E2029207B0A202020202020202020202020636F6E73742063617264203D20746869732E636172644E6F64652820537472696E6728206964202920292C';
wwv_flow_imp.g_varchar2_table(157) := '0A202020202020202020202020202020206C616E65203D20746869732E6C616E654F66282073746174757320293B0A20202020202020202020202069662028202163617264207C7C20216C616E652029207B2072657475726E2066616C73653B207D0A20';
wwv_flow_imp.g_varchar2_table(158) := '2020202020202020202020636F6E73742066726F6D4C697374203D20636172642E706172656E744E6F64652C0A202020202020202020202020202020206F6C64496E646578203D2041727261792E66726F6D282066726F6D4C6973742E71756572795365';
wwv_flow_imp.g_varchar2_table(159) := '6C6563746F72416C6C2820222E74782D4B616E62616E2D6361726422202920292E696E6465784F6628206361726420292C0A202020202020202020202020202020206F7468657273203D2041727261792E66726F6D28206C616E652E6C6973742E717565';
wwv_flow_imp.g_varchar2_table(160) := '727953656C6563746F72416C6C2820222E74782D4B616E62616E2D6361726422202920292E66696C74657228206E203D3E206E20213D3D206361726420292C0A20202020202020202020202020202020726566203D20706F736974696F6E203F206F7468';
wwv_flow_imp.g_varchar2_table(161) := '6572735B20706F736974696F6E202D2031205D203A206E756C6C3B0A20202020202020202020202069662028207265662029207B206C616E652E6C6973742E696E736572744265666F72652820636172642C2072656620293B207D20656C7365207B206C';
wwv_flow_imp.g_varchar2_table(162) := '616E652E6C6973742E617070656E6428206361726420293B207D0A202020202020202020202020696620282066726F6D4C697374203D3D3D206C616E652E6C6973742026262041727261792E66726F6D28206C616E652E6C6973742E717565727953656C';
wwv_flow_imp.g_varchar2_table(163) := '6563746F72416C6C2820222E74782D4B616E62616E2D6361726422202920292E696E6465784F662820636172642029203D3D3D206F6C64496E6465782029207B2072657475726E2066616C73653B207D0A202020202020202020202020746869732E6D6F';
wwv_flow_imp.g_varchar2_table(164) := '7665642820636172642C2066726F6D4C6973742C206F6C64496E64657820293B0A20202020202020202020202072657475726E20747275653B0A20202020202020207D0A0A2020202020202020636C69636B436172642820636172642029207B0A202020';
wwv_flow_imp.g_varchar2_table(165) := '202020202020202020636F6E7374206964203D20636172642E646174617365742E69643B0A2020202020202020202020206966202820746869732E6366672E636C69636B4974656D2029207B20617065782E6974656D2820746869732E6366672E636C69';
wwv_flow_imp.g_varchar2_table(166) := '636B4974656D20292E73657456616C75652820696420293B207D0A202020202020202020202020617065782E6576656E742E747269676765722820222322202B20746869732E726567696F6E49642C202274782D6B616E62616E2D636C69636B222C207B';
wwv_flow_imp.g_varchar2_table(167) := '2069642C20636172643A204F626A6563742E61737369676E28207B7D2C20746869732E63617264732E6765742820696420292029207D20293B0A20202020202020207D0A0A20202020202020206F6E436C69636B2820652029207B0A2020202020202020';
wwv_flow_imp.g_varchar2_table(168) := '20202020636F6E737420616464203D20652E7461726765742E636C6F736573742820225B646174612D74782D616374696F6E3D6164645D2220293B0A20202020202020202020202069662028206164642029207B0A202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(169) := '20636F6E7374206C616E65203D20746869732E6C616E654F6628206164642E636C6F736573742820222E74782D4B616E62616E2D6C616E652220292E646174617365742E73746174757320293B0A20202020202020202020202020202020617065782E65';
wwv_flow_imp.g_varchar2_table(170) := '76656E742E747269676765722820222322202B20746869732E726567696F6E49642C202274782D6B616E62616E2D616464222C207B207374617475733A206C616E652E76616C75652C206C6162656C3A206C616E652E6C6162656C207D20293B0A202020';
wwv_flow_imp.g_varchar2_table(171) := '2020202020202020202020202072657475726E3B0A2020202020202020202020207D0A202020202020202020202020636F6E73742063617264203D20652E7461726765742E636C6F736573742820222E74782D4B616E62616E2D636172642220293B0A20';
wwv_flow_imp.g_varchar2_table(172) := '20202020202020202020206966202820636172642026262021746869732E647261676765642029207B20746869732E636C69636B4361726428206361726420293B207D0A20202020202020207D0A0A20202020202020206F6E4B65792820652029207B0A';
wwv_flow_imp.g_varchar2_table(173) := '202020202020202020202020636F6E73742063617264203D20652E7461726765742E636C6F7365737420262620652E7461726765742E636C6F736573742820222E74782D4B616E62616E2D636172642220293B0A20202020202020202020202069662028';
wwv_flow_imp.g_varchar2_table(174) := '202163617264207C7C20652E74617267657420213D3D20636172642029207B2072657475726E3B207D0A2020202020202020202020206966202820652E6B6579203D3D3D2022456E746572222029207B20652E70726576656E7444656661756C7428293B';
wwv_flow_imp.g_varchar2_table(175) := '20746869732E636C69636B4361726428206361726420293B2072657475726E3B207D0A0A202020202020202020202020636F6E7374206C616E6573203D20746869732E6C616E65732C0A202020202020202020202020202020206C69203D206C616E6573';
wwv_flow_imp.g_varchar2_table(176) := '2E66696E64496E64657828206C203D3E206C2E6C697374203D3D3D20636172642E706172656E744E6F646520292C0A2020202020202020202020202020202076697369626C65203D2041727261792E66726F6D2820636172642E706172656E744E6F6465';
wwv_flow_imp.g_varchar2_table(177) := '2E717565727953656C6563746F72416C6C2820222E74782D4B616E62616E2D636172643A6E6F74285B68696464656E5D2922202920292C0A202020202020202020202020202020206369203D2076697369626C652E696E6465784F662820636172642029';
wwv_flow_imp.g_varchar2_table(178) := '3B0A2020202020202020202020206966202820652E6374726C4B6579207C7C20652E6D6574614B65792029207B0A20202020202020202020202020202020696620282021746869732E686173282022647261672220292029207B2072657475726E3B207D';
wwv_flow_imp.g_varchar2_table(179) := '0A202020202020202020202020202020206C657420746172676574203D206E756C6C2C20706F73203D206E756C6C3B0A202020202020202020202020202020206966202820652E6B6579203D3D3D20224172726F77526967687422202626206C69203C20';
wwv_flow_imp.g_varchar2_table(180) := '6C616E65732E6C656E677468202D20312029207B20746172676574203D206C616E65735B206C69202B2031205D3B20706F73203D20313B207D0A202020202020202020202020202020206966202820652E6B6579203D3D3D20224172726F774C65667422';
wwv_flow_imp.g_varchar2_table(181) := '202626206C69203E20302029207B20746172676574203D206C616E65735B206C69202D2031205D3B20706F73203D20313B207D0A202020202020202020202020202020206966202820652E6B6579203D3D3D20224172726F77557022202626206369203E';
wwv_flow_imp.g_varchar2_table(182) := '20302029207B20746172676574203D206C616E65735B206C69205D3B20706F73203D20746869732E6F726465722820636172642E706172656E744E6F646520292E696E6465784F66282076697369626C655B206369202D2031205D2E646174617365742E';
wwv_flow_imp.g_varchar2_table(183) := '69642029202B20313B207D0A202020202020202020202020202020206966202820652E6B6579203D3D3D20224172726F77446F776E22202626206369203C2076697369626C652E6C656E677468202D20312029207B20746172676574203D206C616E6573';
wwv_flow_imp.g_varchar2_table(184) := '5B206C69205D3B20706F73203D20746869732E6F726465722820636172642E706172656E744E6F646520292E696E6465784F66282076697369626C655B206369202B2031205D2E646174617365742E69642029202B20323B207D0A202020202020202020';
wwv_flow_imp.g_varchar2_table(185) := '2020202020202069662028207461726765742029207B0A2020202020202020202020202020202020202020652E70726576656E7444656661756C7428293B0A2020202020202020202020202020202020202020746869732E6D6F76654361726428206361';
wwv_flow_imp.g_varchar2_table(186) := '72642E646174617365742E69642C207461726765742E76616C75652C20706F7320293B0A2020202020202020202020202020202020202020636172642E666F63757328293B0A202020202020202020202020202020207D0A202020202020202020202020';
wwv_flow_imp.g_varchar2_table(187) := '2020202072657475726E3B0A2020202020202020202020207D0A2020202020202020202020202F2F206172726F7773206D6F76652074686520666F637573206265747765656E20636172647320616E64206C616E65730A2020202020202020202020206C';
wwv_flow_imp.g_varchar2_table(188) := '6574206E657874203D206E756C6C3B0A2020202020202020202020206966202820652E6B6579203D3D3D20224172726F77446F776E222029207B206E657874203D2076697369626C655B206369202B2031205D3B207D0A20202020202020202020202069';
wwv_flow_imp.g_varchar2_table(189) := '66202820652E6B6579203D3D3D20224172726F775570222029207B206E657874203D2076697369626C655B206369202D2031205D3B207D0A2020202020202020202020206966202820652E6B6579203D3D3D20224172726F77526967687422207C7C2065';
wwv_flow_imp.g_varchar2_table(190) := '2E6B6579203D3D3D20224172726F774C656674222029207B0A20202020202020202020202020202020636F6E73742073746570203D20652E6B6579203D3D3D20224172726F77526967687422203F2031203A202D313B0A20202020202020202020202020';
wwv_flow_imp.g_varchar2_table(191) := '202020666F722028206C65742069203D206C69202B20737465703B2069203E3D20302026262069203C206C616E65732E6C656E67746820262620216E6578743B2069202B3D20737465702029207B0A202020202020202020202020202020202020202063';
wwv_flow_imp.g_varchar2_table(192) := '6F6E7374206361726473203D206C616E65735B2069205D2E6C6973742E717565727953656C6563746F72416C6C2820222E74782D4B616E62616E2D636172643A6E6F74285B68696464656E5D292220293B0A202020202020202020202020202020202020';
wwv_flow_imp.g_varchar2_table(193) := '20206E657874203D2063617264735B204D6174682E6D696E282063692C2063617264732E6C656E677468202D20312029205D3B0A202020202020202020202020202020207D0A2020202020202020202020207D0A20202020202020202020202069662028';
wwv_flow_imp.g_varchar2_table(194) := '206E6578742029207B20652E70726576656E7444656661756C7428293B206E6578742E666F63757328293B207D0A20202020202020207D0A0A2020202020202020726566726573682829207B0A202020202020202020202020617065782E6576656E742E';
wwv_flow_imp.g_varchar2_table(195) := '747269676765722820222322202B20746869732E726567696F6E49642C2022617065786265666F7265726566726573682220293B0A20202020202020202020202072657475726E20617065782E7365727665722E706C7567696E2820746869732E636667';
wwv_flow_imp.g_varchar2_table(196) := '2E616A61784964656E7469666965722C207B207830313A20224C495354222C20706167654974656D733A20746869732E6366672E6974656D73546F5375626D6974207D2C207B2064617461547970653A20226A736F6E22207D20290A2020202020202020';
wwv_flow_imp.g_varchar2_table(197) := '20202020202020202E646F6E65282064617461203D3E20746869732E73657443617264732820646174612E6361726473207C7C205B5D202920290A202020202020202020202020202020202E616C7761797328202829203D3E20617065782E6576656E74';
wwv_flow_imp.g_varchar2_table(198) := '2E747269676765722820222322202B20746869732E726567696F6E49642C20226170657861667465727265667265736822202920293B0A20202020202020207D0A202020207D0A0A20202020636F6E737420626F61726473203D207B7D3B0A202020206E';
wwv_flow_imp.g_varchar2_table(199) := '732E6B616E62616E203D207B0A2020202020202020696E69742820726567696F6E49642029207B0A202020202020202020202020636F6E73742062203D206E657720426F6172642820726567696F6E496420293B0A202020202020202020202020626F61';
wwv_flow_imp.g_varchar2_table(200) := '7264735B20726567696F6E4964205D203D20623B0A202020202020202020202020617065782E726567696F6E2E6372656174652820726567696F6E49642C207B0A20202020202020202020202020202020747970653A202254656368526576584B616E62';
wwv_flow_imp.g_varchar2_table(201) := '616E222C0A20202020202020202020202020202020726566726573683A202829203D3E20622E7265667265736828292C0A2020202020202020202020202020202067657443617264733A202829203D3E2041727261792E66726F6D2820622E6361726473';
wwv_flow_imp.g_varchar2_table(202) := '2E76616C756573282920292E6D6170282063203D3E204F626A6563742E61737369676E28207B7D2C2063202920292C0A202020202020202020202020202020206D6F7665436172643A20282069642C207374617475732C20706F736974696F6E2029203D';
wwv_flow_imp.g_varchar2_table(203) := '3E20622E6D6F766543617264282069642C207374617475732C20706F736974696F6E20292C0A202020202020202020202020202020207769646765743A202829203D3E20242820622E656C20290A2020202020202020202020207D20293B0A2020202020';
wwv_flow_imp.g_varchar2_table(204) := '2020207D2C0A20202020202020206765743A20726567696F6E4964203D3E20626F617264735B20726567696F6E4964205D0A202020207D3B0A7D20292820617065782E6A51756572792C206170657820293B0A';
null;
end;
/
begin
wwv_flow_imp_shared.create_plugin_file(
 p_id=>wwv_flow_imp.id(6123490075550138)
,p_plugin_id=>wwv_flow_imp.id(6120805635550131)
,p_file_name=>'kanban.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_imp.varchar2_to_blob(wwv_flow_imp.g_varchar2_table)
);
end;
/
prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false)
);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
