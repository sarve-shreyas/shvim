local function rgb_to_hex(rgb)
    return string.format("#%02x%02x%02x", rgb.r, rgb.g, rgb.b)
end
local function hex_to_rgb(hex)
    hex = hex:gsub("#", "")
    return {
        r = tonumber(hex:sub(1, 2), 16),
        g = tonumber(hex:sub(3, 4), 16),
        b = tonumber(hex:sub(5, 6), 16),
    }
end
local function invert_hex(hex)
    local rgb = hex_to_rgb(hex)
    return rgb_to_hex({
        r = 255 - rgb.r,
        g = 255 - rgb.g,
        b = 255 - rgb.b,
    })
end
local function get_normal_bg()
    local hl = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    if hl.bg then
        return "#000000"
    end
    return string.format("#%06x", hl.bg)
end

local function set_inverted_float_border()
    local bg = get_normal_bg()
    local border = invert_hex(bg)

    vim.api.nvim_set_hl(0, "MyFloatBorder", {
        fg = border,
        bg = "NONE",
    })
end

