---@class RGBColor
---@field r integer
---@field g integer
---@field b integer

local M = {}

---@param rgb RGBColor
---@return string
function M.rgb_to_hex(rgb)
    return string.format("#%02x%02x%02x", rgb.r, rgb.g, rgb.b)
end

---@param hex string
---@return RGBColor|nil
function M.hex_to_rgb(hex)
    local normalized = hex:gsub("#", "")
    if #normalized ~= 6 or normalized:find("[^0-9a-fA-F]") then
        return nil
    end

    return {
        r = tonumber(normalized:sub(1, 2), 16),
        g = tonumber(normalized:sub(3, 4), 16),
        b = tonumber(normalized:sub(5, 6), 16),
    }
end

---@param hex string
---@return string|nil
function M.invert_hex(hex)
    local rgb = M.hex_to_rgb(hex)
    if not rgb then
        return nil
    end

    return M.rgb_to_hex({
        r = 255 - rgb.r,
        g = 255 - rgb.g,
        b = 255 - rgb.b,
    })
end

---@param hex string
---@return string|nil
function M.contrast_hex(hex)
    local rgb = M.hex_to_rgb(hex)
    if not rgb then
        return nil
    end

    -- Perceived luminance (YIQ) to choose readable black/white text color.
    local yiq = ((rgb.r * 299) + (rgb.g * 587) + (rgb.b * 114)) / 1000
    return yiq >= 128 and "#000000" or "#ffffff"
end

---@param group string
---@return string|nil
function M.get_highlight_bg(group)
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    if not hl.bg then
        return nil
    end
    return string.format("#%06x", hl.bg)
end

---@return string|nil
function M.get_normal_bg()
    return M.get_highlight_bg("Normal")
end

---@param group string
---@return string|nil
function M.get_contrast_highlight_bg(group)
    local bg = M.get_highlight_bg(group)
    if not bg then
        return nil
    end
    return M.contrast_hex(bg)
end

---@return string|nil
function M.get_inverted_normal_bg()
    local bg = M.get_normal_bg()
    if not bg then
        return nil
    end
    return M.invert_hex(bg)
end

---@return string|nil
function M.get_contrast_normal_bg()
    return M.get_contrast_highlight_bg("Normal")
end

return M
