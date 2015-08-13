function gace.RejectedATPromise(reason)
    return ATPromise(function(resolver)
        resolver:reject(reason)
    end)
end
