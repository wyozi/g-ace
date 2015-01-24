local gat = gace.AddTest

gat("TableSplit library: object size computation", function(t)
    local cs = gace.tablesplit.ComputeSize

    t.assertEquals(cs(nil), 1, "nil size")
    t.assertEquals(cs(true), 1, "boolean size")
    t.assertEquals(cs(12), 8, "integer size")
    t.assertEquals(cs(12.42), 8, "float size")
    t.assertEquals(cs("hello world"), 13, "string size")

    t.assertEquals(cs({a = "Hello", key2 = 42}), (3+7) + (6+8), "simple table size")
    t.assertEquals(cs({1, 2, 3}), 3 * (8+8), "seq. table size")
    t.assertEquals(cs({tbl = {a = true}}), (5+(3+1)), "nested table size")

    t.assertEquals(cs(42, 1), 8, "typeHeaderSize on non-table")
    t.assertEquals(cs({42}, 1), 9+9, "typeHeaderSize on table")

    t.assertEquals(cs({{42}}, 1), 9 + 1+(9+9), "typeHeaderSize should inherit to subtables")
end)

local function CreateData(byteCount)
    return string.rep(" ", byteCount)
end

gat("TableSplit library: splitting", function(t)
    local split = gace.tablesplit.Split

    t.assertEquals(#split({d = CreateData(100)}, 60), 2, "two way split")
    t.assertEquals(#split({d = CreateData(150)}, 60), 3, "three way split")
end)

gat("TableSplit library: splitting & merging", function(t)
    local split = gace.tablesplit.Split
    local merge = gace.tablesplit.MergeInto

    local tbl = {a = "lol", b = 42, c = true}
    local res = {}
    for k,v in ipairs(split(tbl, 3)) do merge(res, v) end

    t.assertDeepEquals(tbl, res, "simple split&merge")

    local tbl = {a = "abcdeffg 4rghtrwg dfg dsgr eeg ergg "}
    local res = {}
    for k,v in ipairs(split(tbl, 3)) do merge(res, v) end

    t.assertDeepEquals(tbl, res, "string split&merge")

    local tbl = {a = {s = "abcdeffg 4rghtrwg dfg dsgr eeg ergg "}}
    local res = {}
    for k,v in ipairs(split(tbl, 8)) do merge(res, v) end

    t.assertDeepEquals(tbl, res, "nested table string split&merge")
end)
