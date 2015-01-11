local EventNode = Middleclass("EventNode")
function EventNode:initialize(event, callback)
    self.event = event
    self.callback = callback
end

gace.EventEmitter = {
    on = function(self, event, callback)
        self.eventListeners = self.eventListeners or {}
        self.eventListeners[event] = self.eventListeners[event] or {}

        local node = EventNode:new(event, callback)
        table.insert(self.eventListeners[event], node)

        return self
    end,
    emit = function(self, event, ...)
        if not self.eventListeners then return end
        if not self.eventListeners[event] then return end

        for _,node in pairs(self.eventListeners[event]) do
            node.callback(...)
        end
    end
}
