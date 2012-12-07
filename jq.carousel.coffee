#
#  Carousel
#  Originally by uniqname@github.com
# 
#  Version 1.2   -   Updated: July. 26, 2012
# 
#  This plugin creates a carousel and expects a list to exist within the container:

do ->
    $ = jQuery
    options =
        keyboard:   false # Allows control of carousel with keyboard
        fxSpeed:    0.5 # in seconds
        forGallery: null
        itemsPerSet: null
        orientation: 'horizontal'
        alignment: ''
    states =
        currentIndex: 0
        currentSet: 0
        numSets: 1
    methods = 
        init: (opts) ->
            @.each ->
                $this = $ this 
                $markers = $this.children('ul, ol').first().addClass 'markers'
                $markerItems = $markers.children()
                return if not $markerItems.length
                data = $this.data 'carousel'
                controls = {}

                if not data
                    state = $.extend {}, states
                    settings = $.extend {}, options, opts
                    settings.fxSpeed *= 1000 # convert from seconds
                    settings.itemsPerSet = parseInt settings.itemsPerSet, 10
                    $this.addClass "carouselJS #{ settings.orientation }"

                    # Add navigation controls
                    controls = 
                        $nextSet: $('<button />', 
                            class: 'control next'
                            title: 'next set'
                            html: '&nbsp;' # for IE8
                        )

                        $prevSet: $('<button />', 
                            class: 'control prev'
                            title: 'previous set'
                            html: '&nbsp;' # for IE8
                        )
                    $markers.before controls.$prevSet
                    $markers.after controls.$nextSet

                    state.numSets = Math.ceil $markerItems.length / settings.itemsPerSet
                    i = 0
                    $(item).addClass "set_#{ i++ }" for item in $markerItems by settings.itemsPerSet

                    if settings.orientation is 'horizontal'
                        markersWidth = $markers.outerWidth()
                        controls.$nextSet.addClass 'icon-chevron-right'
                        controls.$prevSet.addClass 'icon-chevron-left'
                        itemWidth = $markerItems.eq(0).outerWidth()
                        settings.itemsPerSet = (Math.floor markersWidth / $markerItems.eq(0).outerWidth()) or 1 if not settings.itemsPerSet
                        state.numSets = Math.ceil $markerItems.length / settings.itemsPerSet
                        # nrmlzd_itemWidth = markersWidth / settings.itemsPerSet
                        # lr_padding = ( nrmlzd_itemWidth - itemWidth ) / 2
                        # $markerItems.css 
                        #     # 'max-width': "#{ nrmlzd_itemWidth }px"
                        #     padding: "0 #{ lr_padding }px"
                        # # $markerItems.width(Math.ceil  markersWidth / settings.itemsPerSet)
                        i = 0
                        $(item).addClass "set_#{ i++ }" for item in $markerItems by settings.itemsPerSet
                    else if settings.orientation is 'vertical'
                        controls.$nextSet.addClass 'icon-chevron-down'
                        controls.$prevSet.addClass 'icon-chevron-up'

                    $current = $this.find '.current'
                    if $current.length 
                        state.currentIndex = $current.index()
                    else 
                        $markerItems.eq(state.currentIndex).addClass 'current'

                    state.currentSet = methods.set.call $this[0]

                    $this.data 'carousel', 
                        settings: settings
                        state: state

                    #container resizes to fit set size
                    refit.apply $this[0], [$markers, settings.orientation, state.currentSet]

                    methods.item.call $this[0], state.currentIndex
                    methods.set.call $this[0], state.currentSet
                    
                    $this.find('img').on 'load.carousel', ( e ) -> 
                        refit.apply $this[0], [$markers, settings.orientation, state.currentSet]

                    resizeTimeoutID = 0
                    $(window).on 'resize.carousel', ( e ) ->
                        clearTimeout resizeTimeoutID
                        resizeTimeoutID = setTimeout () ->
                            refit.apply $this[0], [$markers, settings.orientation, state.currentSet]
                            return
                        , 200
                        return

                    $this.on 'click.carousel', '.next, .prev', ( e ) ->
                        #Handles clicking on next, prev or play control
                        $target = $ @

                        e.preventDefault()
                        direction = if $target.hasClass 'prev' then 'prev' else 'next'
                        newSet = if direction is 'prev' then state.currentSet - 1 else state.currentSet + 1
                        methods.set.call $this[0], newSet

                    if settings.forGallery
                        $this.on 'click.carousel', '.markers li', (e) ->
                            e.preventDefault()
                            methods.item.call $this[0], $(this).index()
                            return false

                    if settings.keyboard
                        $(document.documentElement).on 'keyup.gallery', (e) ->
                            e.preventDefault()
                            if e.which is 37
                                # left arrow
                                methods.item.call $this[0], state.currentIndex - 1
                            else if e.which is 39
                                # right arrow
                                methods.item.call $this[0], state.currentIndex + 1
                            return false

                    $(settings.forGallery).on 'galleryItemChange', (e) ->
                        methods.item.call $this[0], e.item

        set: (setIndex) ->
            $this = $ @
            data = $this.data('carousel')
            $markers = $this.find('.markers').first()
            if setIndex isnt undefined and setIndex isnt null
                $controls = $markers.siblings()

                data.state.currentSet = setIndex = if setIndex > data.state.numSets - 1 then data.state.numSets - 1 else if setIndex < 0 then 0 else setIndex
                setNum = ".set_#{ data.state.currentSet }"
                $markers.scrollTo setNum, data.settings.fxSpeed if $markers.find(setNum).length

                mutateNextClass = if setIndex is data.state.numSets - 1 then 'addClass' else 'removeClass'
                mutatePrevClass = if setIndex is 0 then 'addClass' else 'removeClass'

                $controls.filter('.next')[mutateNextClass]('disabled')
                $controls.filter('.prev')[mutatePrevClass]('disabled')
                $this.data 'carousel', data
                return setIndex
            else
                #Always return current set
                $currentItem = $markers.find '.current'
                $currentItem = if $currentItem.length then $currentItem else $markers.children().first() 
                currentSetClass = if $currentItem.filter('[class*="set_"]').length then $currentItem.attr 'class' else $currentItem.prevAll('[class*="set_"]').attr 'class'
                currentSetClass = currentSetClass.split(' ')
                return parseInt klass.replace('set_', '') for klass in currentSetClass when klass.match 'set_'

        next: (refItem) ->
            refItem = refItem or $(this).find('.current').index()
            methods.item.call this, indexify(refItem) + 1

        prev: (refItem) ->
            refItem = refItem of $(this).find('.current').index()
            methods.item.call this, indexify(refItem) - 1
            
        item: (item) ->
            # item takes a selector, jQuery object or index number and shows the slide it
            # corresponds to if it is found.
            $this = $ @
            data = $this.data('carousel')
            $markerItems = $this.children('ul, ol').first().children()
            markersLen = $markerItems.length

            activeItem = (markerIndex) ->
                #Highlight the current marker
                $markerItems.filter('.current').removeClass 'current'
                $markerItems.eq(markerIndex).addClass 'current'

                #Ensure current marker is visible in set
                methods.set.call $this[0], Math.floor(markerIndex / data.settings.itemsPerSet)
                markerIndex

            item = indexify(item) % markersLen #Keeps index in bounds
            item = if not isNaN item then item else 0

            #Support negative indexing
            while item < 0
                item += markersLen
            
            oldItem = data.state.currentIndex
            data.state.currentIndex = item
            activeItem item

            if oldItem isnt data.state.currentIndex
                $this.trigger
                    type: 'carouselItemChange'
                    item: item
            
            $this.data 'carousel', data
            item


    indexify = (item) ->
        if typeof item is 'number'
            item #Already indexified

        else if typeof item is 'string'
            itemIndex = $(item).index()
            if itemIndex isnt -1 then itemIndex else null

        else 
            null #null coerces to 0, so if there is no check it assumes index is 0

    refit = ($items, orientation, currentSet) ->
        data = $(this).data 'carousel'
        item_rep =  $items.eq(0)
        $set_1 = $items.find ".set_1"
        if not $set_1.length then $set_1 = $items.children().last();
        if orientation is 'vertical'
            $items.height $set_1.position()?.top - $items.find(".set_0").position()?.top

        else if orientation is 'horizontal' 
            normalized_width = $items.width() / data.settings.itemsPerSet
            img_width = if $set_1.find('img').length is 0 then 0 else $set_1.find('img').width()
            if img_width isnt 0
                $items.children().css 
                    width: normalized_width
                    padding: "0 #{( normalized_width - img_width ) / 2}px"

        methods.set.call this, currentSet

    $.fn.carousel = ( method ) ->
        if methods[method]
            methods[method].apply this, Array.prototype.slice.call( arguments, 1 )
        else if typeof method is 'object' or not method 
            methods.init.apply this, arguments
        else
            $.error "Method #{ method } does not exist on jQuery.carousel"