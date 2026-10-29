/*
 * Kanban Board region plug-in for Oracle APEX (TechRevX, www.techrevx.com)
 *
 * techrevx.kanban.init( regionId ) is called by the render procedure. It reads the settings and the cards from
 * #<regionId>_cards and builds the board in #<regionId>_kanban. Dragging uses SortableJS (MIT).
 *
 * Card JSON: { id, t: title, s: status, d: description, a: assignee, due: "YYYY-MM-DD", l: label, c: color }
 *
 * apex.region( id ).refresh() / getCards() / moveCard( id, status, position )
 * Events on the region:
 *   tx-kanban-move  { id, status, from, position, order }   after a card is dropped (and saved, with Move Code)
 *   tx-kanban-click { id, card }                            card clicked or Enter pressed on it
 *   tx-kanban-add   { status, label }                       a lane's + button
 */
( function( $, apex ) {
    "use strict";

    const ns = window.techrevx = window.techrevx || {},
        PALETTE = [ "#2f6fde", "#7a4ddb", "#d1437f", "#e0662a", "#1f9d55", "#0f8fa8", "#b7860b", "#5160d6", "#c0384f", "#14947f" ],
        DAY = 86400000;

    function el( tag, cls, text ) {
        const e = document.createElement( tag );
        if ( cls ) { e.className = cls; }
        if ( text != null ) { e.textContent = text; }
        return e;
    }

    function hashColor( text ) {
        let h = 0;
        for ( const ch of String( text ) ) { h = ( h * 31 + ch.charCodeAt( 0 ) ) | 0; }
        return PALETTE[ Math.abs( h ) % PALETTE.length ];
    }

    function initials( name ) {
        const parts = String( name ).trim().split( /[\s._-]+/ ).filter( Boolean );
        if ( !parts.length ) { return "?"; }
        return ( parts[ 0 ][ 0 ] + ( parts.length > 1 ? parts[ parts.length - 1 ][ 0 ] : "" ) ).toUpperCase();
    }

    // "TODO:To do, DOING:In progress:3" -> [ { value, label, limit } ]
    function parseLanes( text ) {
        return String( text || "" ).split( "," ).map( s => s.trim() ).filter( Boolean ).map( s => {
            const p = s.split( ":" ).map( x => x.trim() ),
                limit = p.length > 2 ? parseInt( p[ 2 ], 10 ) : NaN;
            return { value: p[ 0 ], label: p[ 1 ] || p[ 0 ], limit: limit > 0 ? limit : null };
        } );
    }

    class Board {
        constructor( regionId ) {
            this.regionId = regionId;
            this.el = document.getElementById( regionId + "_kanban" );
            const data = JSON.parse( document.getElementById( regionId + "_cards" ).textContent );
            this.cfg = data;
            this.features = String( data.features || "" ).split( ":" );
            this.has = f => this.features.includes( f );
            this.definedLanes = parseLanes( data.columns );
            this.query = "";
            this.sortables = [];
            this.build();
            this.setCards( data.cards || [] );
        }

        build() {
            this.el.textContent = "";
            this.el.setAttribute( "role", "region" );
            if ( this.has( "search" ) ) {
                const bar = el( "div", "tx-Kanban-bar" ),
                    wrap = el( "label", "tx-Kanban-search" ),
                    icon = el( "span", "tx-Kanban-searchIcon fa fa-search" );
                icon.setAttribute( "aria-hidden", "true" );
                this.search = el( "input" );
                this.search.type = "search";
                this.search.placeholder = "Search cards";
                this.search.setAttribute( "aria-label", "Search cards" );
                this.search.addEventListener( "input", () => { this.query = this.search.value.trim().toLowerCase(); this.filter(); } );
                wrap.append( icon, this.search );
                this.summary = el( "span", "tx-Kanban-summary" );
                this.summary.setAttribute( "aria-live", "polite" );
                bar.append( wrap, this.summary );
                this.el.append( bar );
            }
            this.lanesEl = el( "div", "tx-Kanban-lanes" );
            this.el.append( this.lanesEl );
            this.empty = el( "div", "tx-Kanban-empty", this.cfg.noDataFound || "No cards." );
            this.empty.hidden = true;
            this.el.append( this.empty );

            this.el.addEventListener( "click", e => this.onClick( e ) );
            this.el.addEventListener( "keydown", e => this.onKey( e ) );
        }

        // lanes = defined lanes, then any other status found in the data
        lanesFor( cards ) {
            const lanes = this.definedLanes.map( l => Object.assign( {}, l ) ),
                known = new Set( lanes.map( l => l.value ) );
            cards.forEach( c => {
                const s = c.s == null ? "" : String( c.s );
                if ( !known.has( s ) ) {
                    known.add( s );
                    lanes.push( { value: s, label: s || "No status", limit: null } );
                }
            } );
            return lanes;
        }

        setCards( cards ) {
            this.cards = new Map();
            cards.forEach( c => { c.id = String( c.id ); c.s = c.s == null ? "" : String( c.s ); this.cards.set( c.id, c ); } );
            this.sortables.forEach( s => s.destroy() );
            this.sortables = [];
            this.lanesEl.textContent = "";
            this.lanes = this.lanesFor( cards );
            this.empty.hidden = this.lanes.length > 0;
            this.lanesEl.hidden = !this.lanes.length;

            this.lanes.forEach( ( lane, i ) => {
                const section = el( "section", "tx-Kanban-lane" ),
                    head = el( "header", "tx-Kanban-laneHead" ),
                    title = el( "h3", "tx-Kanban-laneTitle", lane.label ),
                    list = el( "div", "tx-Kanban-list" );
                section.style.setProperty( "--tx-kb-accent", PALETTE[ i % PALETTE.length ] );
                section.dataset.status = lane.value;
                title.id = this.regionId + "_lane_" + i;
                head.append( title );
                if ( this.has( "counts" ) ) {
                    lane.countEl = el( "span", "tx-Kanban-count" );
                    head.append( lane.countEl );
                }
                if ( this.has( "add" ) ) {
                    const add = el( "button", "tx-Kanban-add" );
                    add.type = "button";
                    add.dataset.txAction = "add";
                    add.title = "Add card to " + lane.label;
                    add.setAttribute( "aria-label", add.title );
                    add.append( el( "span", "fa fa-plus" ) );
                    head.append( add );
                }
                list.setAttribute( "role", "list" );
                list.setAttribute( "aria-labelledby", title.id );
                list.dataset.status = lane.value;
                lane.section = section;
                lane.list = list;
                section.append( head, list );
                this.lanesEl.append( section );
            } );

            cards.forEach( c => this.laneOf( c.s ).list.append( this.cardEl( c ) ) );

            if ( this.has( "drag" ) && window.Sortable ) {
                this.lanes.forEach( lane => {
                    this.sortables.push( window.Sortable.create( lane.list, {
                        group: "tx-kanban-" + this.regionId,
                        animation: 160,
                        delay: 160,
                        delayOnTouchOnly: true,
                        draggable: ".tx-Kanban-card",
                        filter: ".tx-Kanban-placeholder",
                        ghostClass: "is-ghost",
                        chosenClass: "is-chosen",
                        dragClass: "is-drag",
                        onStart: () => this.el.classList.add( "is-dragging" ),
                        onEnd: evt => {
                            this.el.classList.remove( "is-dragging" );
                            this.dragged = true;
                            setTimeout( () => { this.dragged = false; }, 0 );
                            if ( evt.from === evt.to && evt.oldIndex === evt.newIndex ) { return; }
                            this.moved( evt.item, evt.from, evt.oldIndex );
                        }
                    } ) );
                } );
            }
            this.update();
            this.filter();
        }

        laneOf( status ) {
            return this.lanes.find( l => l.value === String( status ) );
        }

        cardEl( c ) {
            const card = el( "article", "tx-Kanban-card" );
            card.tabIndex = 0;
            card.dataset.id = c.id;
            card.setAttribute( "role", "listitem" );
            const color = c.c || ( c.l ? hashColor( c.l ) : null );
            if ( color ) { card.style.setProperty( "--tx-kb-card", color ); card.classList.add( "has-color" ); }

            if ( c.l ) {
                const label = el( "span", "tx-Kanban-label", c.l );
                card.append( label );
            }
            card.append( el( "h4", "tx-Kanban-title", c.t || c.id ) );
            if ( c.d ) { card.append( el( "p", "tx-Kanban-desc", c.d ) ); }

            if ( c.due || c.a ) {
                const foot = el( "div", "tx-Kanban-foot" );
                if ( c.due ) { foot.append( this.dueEl( c.due ) ); }
                if ( c.a ) {
                    const avatar = el( "span", "tx-Kanban-avatar", initials( c.a ) );
                    avatar.style.setProperty( "--tx-kb-avatar", hashColor( c.a ) );
                    avatar.title = c.a;
                    avatar.setAttribute( "aria-label", "Assigned to " + c.a );
                    foot.append( avatar );
                }
                card.append( foot );
            }
            return card;
        }

        dueEl( due ) {
            const m = /^(\d{4})-(\d{2})-(\d{2})/.exec( due ),
                span = el( "span", "tx-Kanban-due" ),
                icon = el( "span", "fa fa-calendar-o" );
            icon.setAttribute( "aria-hidden", "true" );
            span.append( icon );
            if ( !m ) { span.append( " " + due ); return span; }
            const date = new Date( +m[ 1 ], m[ 2 ] - 1, +m[ 3 ] ),
                today = new Date(),
                days = Math.round( ( date - new Date( today.getFullYear(), today.getMonth(), today.getDate() ) ) / DAY ),
                lang = document.documentElement.lang || undefined,
                fmt = new Intl.DateTimeFormat( lang, date.getFullYear() === today.getFullYear()
                    ? { month: "short", day: "numeric" } : { year: "numeric", month: "short", day: "numeric" } );
            span.append( " " + fmt.format( date ) );
            span.dataset.due = due.slice( 0, 10 );
            if ( days < 0 ) {
                span.classList.add( "is-overdue" );
                span.title = "Overdue by " + -days + ( days === -1 ? " day" : " days" );
            } else if ( days <= 2 ) {
                span.classList.add( "is-soon" );
                span.title = days === 0 ? "Due today" : "Due in " + days + ( days === 1 ? " day" : " days" );
            }
            return span;
        }

        // counts, limits and empty-lane placeholders; lanes with a done-like value get is-done (no overdue colors)
        update() {
            this.lanes.forEach( lane => {
                const n = lane.list.querySelectorAll( ".tx-Kanban-card" ).length;
                if ( lane.countEl ) {
                    lane.countEl.textContent = lane.limit ? n + " / " + lane.limit : String( n );
                    lane.countEl.title = lane.limit ? n + " cards, limit " + lane.limit : n + ( n === 1 ? " card" : " cards" );
                }
                lane.section.classList.toggle( "is-over", !!lane.limit && n > lane.limit );
                lane.section.classList.toggle( "is-full", !!lane.limit && n === lane.limit );
                lane.section.classList.toggle( "is-done", /^(done|closed|complete|completed|finished)$/i.test( lane.value ) );
                let ph = lane.list.querySelector( ".tx-Kanban-placeholder" );
                if ( !n && !ph ) {
                    ph = el( "div", "tx-Kanban-placeholder", this.has( "drag" ) ? "Drop cards here" : "No cards" );
                    lane.list.append( ph );
                } else if ( n && ph ) {
                    ph.remove();
                }
            } );
        }

        filter() {
            const q = this.query;
            let shown = 0;
            this.cards.forEach( ( c, id ) => {
                const card = this.cardNode( id );
                if ( !card ) { return; }
                const hit = !q || [ c.t, c.d, c.a, c.l, c.id ].some( v => v != null && String( v ).toLowerCase().includes( q ) );
                card.hidden = !hit;
                if ( hit ) { shown++; }
            } );
            if ( this.summary ) {
                this.summary.textContent = q ? shown + " of " + this.cards.size + " cards" : this.cards.size + ( this.cards.size === 1 ? " card" : " cards" );
            }
        }

        cardNode( id ) {
            return Array.from( this.el.querySelectorAll( ".tx-Kanban-card" ) ).find( n => n.dataset.id === id );
        }

        order( list ) {
            return Array.from( list.querySelectorAll( ".tx-Kanban-card" ) ).map( n => n.dataset.id );
        }

        // a card was dropped (or moved by keyboard); saves it and moves it back when the save fails
        moved( card, fromList, oldIndex ) {
            const id = card.dataset.id,
                c = this.cards.get( id ),
                list = card.parentNode,
                from = c.s,
                status = list.dataset.status,
                order = this.order( list ),
                position = order.indexOf( id ) + 1,
                data = { id, status, from, position, order };
            c.s = status;
            this.update();
            card.focus( { preventScroll: true } );

            const done = () => {
                apex.event.trigger( "#" + this.regionId, "tx-kanban-move", data );
            };
            if ( !this.cfg.canSave ) { done(); return; }

            // the Move Code refused (message = its raise_application_error text) or the request failed
            const revert = message => {
                c.s = from;
                const ref = Array.from( fromList.querySelectorAll( ".tx-Kanban-card" ) ).filter( n => n !== card )[ oldIndex ];
                fromList.insertBefore( card, ref || fromList.querySelector( ".tx-Kanban-placeholder" ) );
                this.update();
                card.focus( { preventScroll: true } );
                apex.message.clearErrors();
                apex.message.showErrors( [ { type: "error", location: "page", message: message || "The card could not be moved.", unsafe: false } ] );
            };
            card.classList.add( "is-saving" );
            apex.server.plugin( this.cfg.ajaxIdentifier, {
                x01: "MOVE", x02: id, x03: status, x04: String( position ), x05: order.join( "," ), pageItems: this.cfg.itemsToSubmit
            }, { dataType: "json" } )
                .done( res => { if ( res && res.moved === false ) { revert( res.message ); } else { done(); } } )
                .fail( ( jqXHR, textStatus, error ) => {
                    window.console.warn( "Kanban Board: move failed", error );
                    revert();
                } )
                .always( () => card.classList.remove( "is-saving" ) );
        }

        // moves a card by code or keyboard: status = lane value, position 1 = top (default: bottom)
        moveCard( id, status, position ) {
            const card = this.cardNode( String( id ) ),
                lane = this.laneOf( status );
            if ( !card || !lane ) { return false; }
            const fromList = card.parentNode,
                oldIndex = Array.from( fromList.querySelectorAll( ".tx-Kanban-card" ) ).indexOf( card ),
                others = Array.from( lane.list.querySelectorAll( ".tx-Kanban-card" ) ).filter( n => n !== card ),
                ref = position ? others[ position - 1 ] : null;
            if ( ref ) { lane.list.insertBefore( card, ref ); } else { lane.list.append( card ); }
            if ( fromList === lane.list && Array.from( lane.list.querySelectorAll( ".tx-Kanban-card" ) ).indexOf( card ) === oldIndex ) { return false; }
            this.moved( card, fromList, oldIndex );
            return true;
        }

        clickCard( card ) {
            const id = card.dataset.id;
            if ( this.cfg.clickItem ) { apex.item( this.cfg.clickItem ).setValue( id ); }
            apex.event.trigger( "#" + this.regionId, "tx-kanban-click", { id, card: Object.assign( {}, this.cards.get( id ) ) } );
        }

        onClick( e ) {
            const add = e.target.closest( "[data-tx-action=add]" );
            if ( add ) {
                const lane = this.laneOf( add.closest( ".tx-Kanban-lane" ).dataset.status );
                apex.event.trigger( "#" + this.regionId, "tx-kanban-add", { status: lane.value, label: lane.label } );
                return;
            }
            const card = e.target.closest( ".tx-Kanban-card" );
            if ( card && !this.dragged ) { this.clickCard( card ); }
        }

        onKey( e ) {
            const card = e.target.closest && e.target.closest( ".tx-Kanban-card" );
            if ( !card || e.target !== card ) { return; }
            if ( e.key === "Enter" ) { e.preventDefault(); this.clickCard( card ); return; }

            const lanes = this.lanes,
                li = lanes.findIndex( l => l.list === card.parentNode ),
                visible = Array.from( card.parentNode.querySelectorAll( ".tx-Kanban-card:not([hidden])" ) ),
                ci = visible.indexOf( card );
            if ( e.ctrlKey || e.metaKey ) {
                if ( !this.has( "drag" ) ) { return; }
                let target = null, pos = null;
                if ( e.key === "ArrowRight" && li < lanes.length - 1 ) { target = lanes[ li + 1 ]; pos = 1; }
                if ( e.key === "ArrowLeft" && li > 0 ) { target = lanes[ li - 1 ]; pos = 1; }
                if ( e.key === "ArrowUp" && ci > 0 ) { target = lanes[ li ]; pos = this.order( card.parentNode ).indexOf( visible[ ci - 1 ].dataset.id ) + 1; }
                if ( e.key === "ArrowDown" && ci < visible.length - 1 ) { target = lanes[ li ]; pos = this.order( card.parentNode ).indexOf( visible[ ci + 1 ].dataset.id ) + 2; }
                if ( target ) {
                    e.preventDefault();
                    this.moveCard( card.dataset.id, target.value, pos );
                    card.focus();
                }
                return;
            }
            // arrows move the focus between cards and lanes
            let next = null;
            if ( e.key === "ArrowDown" ) { next = visible[ ci + 1 ]; }
            if ( e.key === "ArrowUp" ) { next = visible[ ci - 1 ]; }
            if ( e.key === "ArrowRight" || e.key === "ArrowLeft" ) {
                const step = e.key === "ArrowRight" ? 1 : -1;
                for ( let i = li + step; i >= 0 && i < lanes.length && !next; i += step ) {
                    const cards = lanes[ i ].list.querySelectorAll( ".tx-Kanban-card:not([hidden])" );
                    next = cards[ Math.min( ci, cards.length - 1 ) ];
                }
            }
            if ( next ) { e.preventDefault(); next.focus(); }
        }

        refresh() {
            apex.event.trigger( "#" + this.regionId, "apexbeforerefresh" );
            return apex.server.plugin( this.cfg.ajaxIdentifier, { x01: "LIST", pageItems: this.cfg.itemsToSubmit }, { dataType: "json" } )
                .done( data => this.setCards( data.cards || [] ) )
                .always( () => apex.event.trigger( "#" + this.regionId, "apexafterrefresh" ) );
        }
    }

    const boards = {};
    ns.kanban = {
        init( regionId ) {
            const b = new Board( regionId );
            boards[ regionId ] = b;
            apex.region.create( regionId, {
                type: "TechRevXKanban",
                refresh: () => b.refresh(),
                getCards: () => Array.from( b.cards.values() ).map( c => Object.assign( {}, c ) ),
                moveCard: ( id, status, position ) => b.moveCard( id, status, position ),
                widget: () => $( b.el )
            } );
        },
        get: regionId => boards[ regionId ]
    };
} )( apex.jQuery, apex );
