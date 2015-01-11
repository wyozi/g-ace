function gace.RejectedPromise(reason)
    return Promise(function(resolver)
        resolver:reject(reason)
    end)
end
