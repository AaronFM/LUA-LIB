-------------------------------------------------------------------------------
-- Buzzer unit test.
-- @author Pauli
-- @copyright 2014 Rinstrum Pty Ltd
-------------------------------------------------------------------------------

describe("analog #analog", function ()
    local regData, regType, regClip, regSource = 0x0323, 0xA801, 0xA806, 0xA805
    local volt, current, comms = 1, 0, 3

    local function makeModule()
        local m, p, d = {}, {}, {}
        require("rinLibrary.utilities")(m, p, d)
        require("rinLibrary.K400Analog")(m, p, d)
        return m, p, d
    end

    it("registers", function()
        local _, _, d = makeModule()
        assert.equal(regData,   d.REG_ANALOGUE_DATA)
        assert.equal(regType,   d.REG_ANALOGUE_TYPE)
        assert.equal(regClip,   d.REG_ANALOGUE_CLIP)
        assert.equal(regSource, d.REG_ANALOGUE_SOURCE)
    end)

    it("enumerations", function()
        local _, _, d = makeModule()
        assert.equal(current,   d.CUR)
        assert.equal(volt,      d.VOLT)
        assert.equal(comms,     d.ANALOG_COMMS)
    end)

    -- These tests are digging deep into the non-exposed internals
    describe("type", function()
        local m, p = makeModule()
        local z = require "tests.messages"
        local cases = {
            { type = volt,      ex = volt       },
            { type = current,   ex = current    },
            { type = 'volt',    ex = volt       },
            { type = 'current', ex = current    },
            { type = 'unknown', ex = volt       }
        }

        for i, v in pairs(cases) do
            it("test "..i, function()
                z.checkWriteReg(m, {{ r=regType, v.ex }}, m.setAnalogType, v.type)
            end)
        end
    end)

    describe("clip", function()
        local m, p = makeModule()
        local z = require "tests.messages"
        local cases = {
            { clip = true,  ex = 1  },
            { clip = false, ex = 0  },
            { clip = 0,     ex = 0  },
            { clip = 1,     ex = 1  }
        }

        for i, v in pairs(cases) do
            it("test "..i, function()
                z.checkWriteRegAsync(m, {{ r=regClip, v.ex }}, m.setAnalogClip, v.clip)
            end)
        end
    end)

    describe("raw", function()
        local m, p = makeModule()
        local z = require "tests.messages"
        local cases = {
            { raw = 0,      ex = 0      },
            { raw = 50000,  ex = 50000  },
            { raw = 10000,  ex = 10000  }
        }

        for i, v in pairs(cases) do
            it("test "..i, function()
                z.checkWriteRegAsync(m, {{ r=regData, v.ex }}, m.setAnalogRaw, v.raw)
            end)
        end
    end)

    it("val", function()
        local m, p = makeModule()
        local cases = {
            { val = 0,          ex = 0      },
            { val = 1,          ex = 50000  },
            { val = 0.5,        ex = 25000  },
            { val = 0.777799,   ex = 38890  }
        }
        for i, v in pairs(cases) do
            it("test "..i, function()
                stub(m, 'setAnalogRaw')
                m.setAnalogVal(v.val)
                assert.stub(m.setAnalogRaw).was.called_with(v.ex)
                m.setAnalogRaw:revert()
            end)
        end
    end)

    it("percent", function()
        local m, p = makeModule()
        local cases = {
            { val = 0,          ex = 0      },
            { val = 100,        ex = 50000  },
            { val = 50,         ex = 25000  },
            { val = 77.7799,    ex = 38890  }
        }
        for i, v in pairs(cases) do
            it("test "..i, function()
                stub(m, 'setAnalogRaw')
                m.setAnalogPC(v.val)
                assert.stub(m.setAnalogRaw).was.called_with(v.ex)
                m.setAnalogRaw:revert()
            end)
        end
    end)

    it("current", function()
        local m, p = makeModule()
        local cases = {
            { val = 4,          ex = 0      },
            { val = 20,         ex = 50000  },
            { val = 12,         ex = 25000  },
            { val = 13,         ex = 28125  }
        }
        for i, v in pairs(cases) do
            it("test "..i, function()
                stub(m, 'setAnalogRaw')
                stub(m, 'setAnalogType')

                m.setAnalogCur(v.val)
                assert.stub(m.setAnalogRaw).was.called_with(v.ex)
                assert.stub(m.setAnalogType).was.called_with(current)

                m.setAnalogRaw:revert()
                m.setAnalogType:revert()
            end)
        end
    end)

    it("volt", function()
        local m, p = makeModule()
        local cases = {
            { val = 0,          ex = 0      },
            { val = 10,         ex = 50000  },
            { val = 1.2345678,  ex = 6173   }
        }
        for i, v in pairs(cases) do
            it("test "..i, function()
                stub(m, 'setAnalogRaw')
                stub(m, 'setAnalogType')

                m.setAnalogVolt(v.val)
                assert.stub(m.setAnalogRaw).was.called_with(v.ex)
                assert.stub(m.setAnalogType).was.called_with(volt)

                m.setAnalogRaw:revert()
                m.setAnalogType:revert()
            end)
        end
    end)
end)
