local MasonInstaller = {}
MasonInstaller.__index = MasonInstaller

function MasonInstaller.new(packages)
  local self = setmetatable({}, MasonInstaller)
  self.packages = packages or {}
  self.registry = require("mason-registry")
  return self
end

function MasonInstaller:log(message, level)
  -- vim.notify(message, level or vim.log.levels.INFO)
end

function MasonInstaller:ensure_packages()
  self:log("ensuring mason packages")

  for _, name in ipairs(self.packages) do
    self:log("checking package: " .. name)

    local ok_pkg, pkg = pcall(self.registry.get_package, name)
    if not ok_pkg then
      self:log("package not found in registry: " .. name, vim.log.levels.WARN)
    elseif pkg:is_installed() then
      self:log("already installed: " .. name)
    else
      self:log("installing package: " .. name)
      pkg:install()

      pkg:once("install:success", function()
        self:log("installed successfully: " .. name)
      end)

      pkg:once("install:failed", function()
        self:log("failed to install: " .. name, vim.log.levels.ERROR)
      end)
    end
  end
end

function MasonInstaller:run()
  local ok, mason = pcall(require, "mason")
  if not ok then
    self:log("mason not found", vim.log.levels.ERROR)
    return
  end

  self:log("setting up mason")
  mason.setup()

  if self.registry.refresh then
    self:log("refreshing mason registry")
    self.registry.refresh(function()
      self:log("mason registry refreshed")
      self:ensure_packages()
    end)
  else
    self:log("mason registry refresh not available, proceeding directly", vim.log.levels.WARN)
    self:ensure_packages()
  end
end


require("mason").setup({
    ui = {
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
        }
    }
})

local installer = MasonInstaller.new({
  "clangd",
  "clang-format",
})

installer:run()

