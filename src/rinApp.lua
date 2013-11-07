-------------------------------------------------------------------------------
-- Module manager for L401
-- @module rinApp
-- @author Darren Pearson
-- @author Merrick Heley
-- @author Sean Liddle
-- @copyright 2013 Rinstrum Pty Ltd
-------------------------------------------------------------------------------

local assert = assert

local _M = {}
_M.running = false


-- Create the rinApp resources

_M.system = require "rinSystem.Pack"
_M.userio = require "IOSocket.Pack"
_M.dbg    = require "rinLibrary.rinDebug"

package.loaded["rinLibrary.rinDebug"] = nil


_M.devices = {}
_M.dbg.configureDebug(arg[1], false, 'Application')
_M.dbg.printVar('',arg[1])

-- captures input from terminal to change debug level
local function userioCallback(sock)
    local data = sock:receive("*l")
      
    if data == 'exit' then
     _M.running = false
    else  
     for k,v in pairs(_M.devices) do
        v.dbg.configureDebug(data)
     end 
     _M.dbg.configureDebug(data)
    end  
end

-------------------------------------------------------------------------------
-- Called to connect to the K400 instrument, and establish the timers,
-- streams and other services
-- @param model Software model expected for the instrument (eg "K401")
-- @param ip IP address for the socket, "127.1.1.1" used as a default
-- @param port port address for the socket 2222 used as default
-- @return device object for this instrument

function _M.addK400(model, ip, port)
    
    -- Create the socket
    local ip = ip or "127.1.1.1"
    local port = port or 2222
    local app = app or ""
    
    local device = require "rinLibrary.K400"
    
    package.loaded["rinLibrary.L401"] = nil

    _M.devices[#_M.devices+1] = device
  
    
    local s = assert(require "socket".tcp())
    s:connect(ip, port)
    s:settimeout(0.1)
    
  
    -- Connect to the K400, and attach system if using the system library
    device.connect(app, s, _M)
    -- Register the L401 with system
    _M.system.sockets.addSocket(device.socket, device.socketCallback)
    -- Add a timer to send data every 5ms
    _M.system.timers.addTimer(5, 100, device.sendQueueCallback)
    -- Add a timer for the heartbeat (every 5s)
    _M.system.timers.addTimer(5000, 1000, device.sendMsg, "20110001:", true)

    _M.system.sockets.addSocket(_M.userio.connectDevice(), userioCallback)
    
    device.streamCleanup()  -- Clean up any existing streams on connect
    device.setupKeys()
    device.setupStatus()
    
    return device, device.configure()
end


    
-------------------------------------------------------------------------------
-- Called to restore the system to initial state by shutting down services
-- enabled by configure() 
function _M.cleanup()
    for k,v in pairs(_M.devices) do
        v.restoreLcd()
        v.streamCleanup()
        v.endKeys()
        v.delay(50)
     end 
    _M.dbg.printVar('------   Application Finished  ------','', _M.dbg.INFO)
end

_M.running = true
_M.dbg.printVar('------   Application Started   -----', '', _M.dbg.INFO)

return _M