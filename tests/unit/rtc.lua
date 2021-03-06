-------------------------------------------------------------------------------
-- RTC unit test.
-- @author Pauli
-- @copyright 2014 Rinstrum Pty Ltd
-------------------------------------------------------------------------------

describe("RTC #rtc", function ()
    local dmy, dmyy, mdy, mdyy, ymd, yymd = 0, 1, 2, 3, 4, 5
    local dregs = {
        timecur          = 0x0150,
        timeformat       = 0x0151,
        timeday          = 0x0152,
        timemon          = 0x0153,
        timeyear         = 0x0154,
        timehour         = 0x0155,
        timemin          = 0x0156,
        timesec          = 0x0157,
        msec1000         = 0x015C,
        msec             = 0x015D,
        mseclast         = 0x015F
    }

    local function makeModule()
        local m, p, d = {}, {}, {}
        require("rinLibrary.utilities")(m, p, d)
        require("rinLibrary.K400RTC")(m, p, d)
        m.flushed = 0
        m.flush = function() m.flushed = m.flushed + 1 end
        return m, p, d
    end

    describe("deprecated registers", function()
        local _, _, d = makeModule()
            for k, v in pairs(dregs) do
            it("test "..k, function()
                assert.equal(v, d["REG_" .. string.upper(k)])
            end)
        end
    end)

    it("enumerations", function()
        local _, _, d = makeModule()
        assert.equal(dmy,   d.TM_DDMMYY)
        assert.equal(dmyy,  d.TM_DDMMYYYY)
        assert.equal(mdy,   d.TM_MMDDYY)
        assert.equal(mdyy,  d.TM_MMDDYYYY)
        assert.equal(ymd,   d.TM_YYMMDD)
        assert.equal(yymd,  d.TM_YYYYMMDD)
    end)

    describe("month lengths #monlen", function()
        local tc = {
            { y = 2000, m =  2, r = 29 },
            { y = 1900, m =  2, r = 28 },
            { y = 1800, m =  2, r = 28 },
            { y = 1700, m =  2, r = 28 },
            { y = 1600, m =  2, r = 29 },
            { y = 1004, m =  2, r = 29 },
            { y =  999, m =  1, r = 31 },
            { y = 2000, m =  3, r = 31 },
            { y = 1003, m =  4, r = 30 },
            { y = 2654, m =  5, r = 31 },
            { y = 9999, m =  6, r = 30 },
            { y =    1, m =  7, r = 31 },
            { y = 1999, m =  8, r = 31 },
            { y = 2014, m =  9, r = 30 },
            { y = 2015, m = 10, r = 31 },
            { y = 2016, m = 11, r = 30 },
            { y = 2016, m = 12, r = 31 }
        }

        for k,t in ipairs(tc) do
            it("test "..k, function()
                assert.equal(t.r, makeModule().monthLength(t.y, t.m))
            end)
        end
    end)

    local function makeResults(yr, mo, da, ho, mi, se)
        local results = {}
        if yr ~= nil then table.insert(results, { r=dregs.timeyear, yr }) end
        if mo ~= nil then table.insert(results, { r=dregs.timemon,  mo }) end
        if da ~= nil then table.insert(results, { r=dregs.timeday,  da }) end
        if ho ~= nil then table.insert(results, { r=dregs.timehour, ho }) end
        if mi ~= nil then table.insert(results, { r=dregs.timemin,  mi }) end
        if se ~= nil then table.insert(results, { r=dregs.timesec,  se }) end
        return results
    end

    describe("set date #setdate", function()
        local z = require "tests.messages"
        for k, v in pairs({
                        { 2000, 12, 5,  nil, 12, 5 },   { 2020, 2, 29,  2020, 2, 29 },
                        { 2200, 15, 1,  nil, nil, 1 },  { 2015, 2, 28,  2015, 2, 28 }
                    }) do
            it("test "..k, function()
                local sy, sm, sd = v[1], v[2], v[3]
                local ey, em, ed = v[4], v[5], v[6]
                local results = makeResults(ey, em, ed)
                local m = makeModule()

                z.checkWriteReg(m, results, m.RTCwriteDate, sy, sm, sd)
            end)
        end
    end)

    describe("set time #settime", function()
        local z = require "tests.messages"
        for k, v in pairs({
                        { 3, 30, 2,     3, 30, 2},  { 25, 66, 23,   nil, nil, 23 },
                        { 7, 23, 66,    7, 23, nil }
                    }) do
            it("test "..k, function()
                local sh, sm, ss = v[1], v[2], v[3]
                local eh, em, es = v[4], v[5], v[6]
                local results = makeResults(nil, nil, nil, eh, em, es)
                local m = makeModule()

                z.checkWriteReg(m, results, m.RTCwriteTime, sh, sm, ss)
                assert.is_equal(1, m.flushed)
            end)
        end
    end)

    describe("set all #settimedate", function()
        local z = require "tests.messages"
        for k, v in pairs({
                    { 2038, 1, 19, 3, 14, 8 },
                    { 2020, 5, 22, 12, 6, 14 }
                }) do
            it("test "..k, function()
                local yr, mo, da, ho, mi, se = v[1], v[2], v[3], v[4], v[5], v[6]
                local results = makeResults(unpack(v))
                local m = makeModule()

                z.checkWriteReg(m, results, m.RTCwrite, unpack(v))
                assert.is_same({ yr, mo, da, n=3 }, table.pack(m.RTCreadDate()))
                assert.is_same({ ho, mi, se, n=3 }, table.pack(m.RTCreadTime()))
                assert.is_equal(1, m.flushed)
            end)
        end
    end)

    it("tick", function()
        local z = require "tests.messages"
        local m = makeModule()
        local yr, mo, da, ho, mi, se = 2050, 3, 6, 22, 59, 59
        local results = makeResults(yr, mo, da, ho, mi, se)

        z.checkWriteReg(m, results, m.RTCwrite, yr, mo, da, ho, mi, se)
        m.RTCtick()
        assert.is_same({ yr, mo, da, n=3 }, table.pack(m.RTCreadDate()))
        assert.is_same({ 23, 0, 0, n=3 }, table.pack(m.RTCreadTime()))
        assert.is_equal(1, m.flushed)
    end)

    it("format", function()
        local z = require "tests.messages"
        local m = makeModule()
        local yr, mo, da, ho, mi, se = 2022, 1, 2, 3, 4, 5
        local results = makeResults(yr, mo, da, ho, mi, se)

        z.checkWriteReg(m, results, m.RTCwrite, yr, mo, da, ho, mi, se)
        assert.is_equal(1, m.flushed)
        assert.is_same({ yr, mo, da, n=3 }, table.pack(m.RTCreadDate()))
        assert.is_same({ ho, mi, se, n=3 }, table.pack(m.RTCreadTime()))
        assert.is_equal("02/01/2022 03:04:05", m.RTCtostring())
        assert.is_same({ "day", "month", "year", n=3 },  table.pack(m.RTCgetDateFormat()))

        m.RTCdateFormat('month', 'day', 'year')
        assert.is_same({ yr, mo, da, n=3 }, table.pack(m.RTCreadDate()))
        assert.is_same({ ho, mi, se, n=3 }, table.pack(m.RTCreadTime()))
        assert.is_equal("01/02/2022 03:04:05", m.RTCtostring())
        assert.is_same({ "month", "day", "year", n=3 },  table.pack(m.RTCgetDateFormat()))

        m.RTCdateFormat('year', 'month', 'day')
        assert.is_equal("2022/01/02 03:04:05", m.RTCtostring())
        assert.is_same({ "year", "month", "day", n=3 },  table.pack(m.RTCgetDateFormat()))

        m.RTCdateFormat('day', 'month', 'year')
        assert.is_equal("02/01/2022 03:04:05", m.RTCtostring())
        assert.is_same({ "day", "month", "year", n=3 },  table.pack(m.RTCgetDateFormat()))
    end)

    it("rtc read", function()
        pending("unimplemented test case")
    end)

    it("rtc read date format", function()
        pending("unimplemented test case")
    end)

    it("rtc send date format", function()
        pending("unimplemented test case")
    end)
end)
