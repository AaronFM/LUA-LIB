-------------------------------------------------------------------------------
-- Library for K400 application support.
-- Provides wrappers for all device services
-- @module rinLibrary.K400
-- @author Darren Pearson
-- @author Merrick Heley
-- @copyright 2013 Rinstrum Pty Ltd
-------------------------------------------------------------------------------

-- submodules are merged in as follows (and in this order):
local modules = {
    "K400Reg",
    "K400Util",
    "K400Stream",
    "K400Status",
    "K400Keys",
    "K400LCD",
    "K400Dialog",
    "K400RTC",
    "K400Analog",
    "K400Setpoint",
    "K400Print",
    "K400Command"
}

-- Start the entire process by loading rinCon directly.
local _M = require "rinLibrary.rinCon"
package.loaded["rinLibrary.rinCon"] = nil

for i = 1, #modules do
    require("rinLibrary." .. modules[i])(_M)
end

return _M
