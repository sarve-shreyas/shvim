local ls = require('luasnip');
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node


return {
    s("fn", {
        t("int "),
        i(1, "name"),
        t("("),
        i(2, "void"),
        t({ ") {", "\t" }),
        i(3),
        t({ "", "}" }),
    }),
}

