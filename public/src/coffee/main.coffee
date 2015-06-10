# main.js compiled from CodeKit download CodeKit here http://incident57.com/codekit/
define ['event-bus'], 
(EventBus) ->
    HEADER_PADDING = 45

    class MainApp extends Backbone.Marionette.Application

    app = new MainApp

    app.addInitializer ->
        router = new MainRouter
        Backbone.history.start
            root: '/'
            pushState: true

    class MainRouter extends Backbone.Router
        routes:
            '/': 'loadHome'

        initialize: ->
            @mainPage = new MainPage

        loadHome: ->
            @mainPage.load()

    class MainPage extends Backbone.Marionette.Layout
        el: 'body'

        # events:
            # 'some event': 'someHandler'

        # regions:
        #     'someRegion': '.someRegion'
            
        # initialize: ->
        #     some stuff. Grab models, whatever

        # onShow: -> // marionette's default show handler

        load: ->
            console.log 'marionette layout loaded'
            EventBus.trigger 'layout loaded'
            $(document).ready ->
                console.log 'jquery loaded'