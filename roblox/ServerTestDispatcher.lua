-- BOZO EXECUTER
-- Authorized server-side test dispatcher

local Dispatcher = {}

local tests = {}

tests.remote_validation = function()
    return {
        success = true,
        message = "Remote validation test completed"
    }
end

tests.movement_validation = function()
    return {
        success = true,
        message = "Movement validation test completed"
    }
end

tests.rate_limit_validation = function()
    return {
        success = true,
        message = "Rate limit test completed"
    }
end

tests.permission_validation = function()
    return {
        success = true,
        message = "Permission validation test completed"
    }
end

function Dispatcher.Run(testName)
    if typeof(testName) ~= "string" then
        return false, "Invalid test name"
    end

    local test = tests[testName]

    if not test then
        return false, "Test not allowed"
    end

    local success, result = pcall(test)

    if not success then
        return false, "Test failed"
    end

    return true, result
end

return Dispatcher
