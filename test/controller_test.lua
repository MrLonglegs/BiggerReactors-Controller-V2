-- Controller Unit Tests

local Controller = require("reactors_controller.core.controller")
local ApiHelper = require("reactors_controller.core.apihelper")

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
    end
end

local function assert_nil(value, message)
    if value ~= nil then
        error(string.format("%s: expected nil, got %s", message, tostring(value)))
    end
end

local function run_tests()
    print("Running controller tests...")
    
    -- Test 1: Controller creation
    local ctrl = Controller.new()
    assert_equal(type(ctrl), "table", "Controller should be a table")
    assert_equal(ctrl.running, false, "Controller should not be running initially")
    assert_equal(#ctrl.reactors, 0, "Controller should have no reactors initially")
    print("✓ Test 1 passed: Controller creation")
    
    -- Test 2: Add reactor
    ctrl:add_reactor({name = "Test Reactor", address = "reactor_1"})
    assert_equal(#ctrl.reactors, 1, "Should have 1 reactor after adding")
    assert_equal(ctrl.reactors[1].name, "Test Reactor", "Reactor name should match")
    print("✓ Test 2 passed: Add reactor")
    
    -- Test 3: Config defaults
    assert_equal(ctrl.config.update_interval, 1, "Default update interval should be 1")
    assert_equal(ctrl.config.safety_threshold, 0.9, "Default safety threshold should be 0.9")
    print("✓ Test 3 passed: Config defaults")
    
    -- Test 4: Stop controller
    ctrl.running = true
    ctrl:stop()
    assert_equal(ctrl.running, false, "Controller should stop")
    print("✓ Test 4 passed: Stop controller")
    
    -- Test 5: ApiHelper creation
    local api = ApiHelper.new("http://test.local:8080")
    assert_equal(api.base_url, "http://test.local:8080", "Base URL should be set")
    assert_equal(api.timeout, 5000, "Timeout should be 5000ms")
    print("✓ Test 5 passed: ApiHelper creation")
    
    print("\nAll tests passed!")
end

run_tests()
