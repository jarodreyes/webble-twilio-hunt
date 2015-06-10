define ['module'], (module) ->
    # This is just a simple class that supports the `Backbone.Events`
    # functionality.
    class EventBus
        _.extend @prototype, Backbone.Events

        constructor: ->

    # Return an instance of `EventBus`, not the class itself. This way, it
    # acts like a singleton throughout the entire app since require.js caches
    # the module.
    return new EventBus
