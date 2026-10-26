local M = {}

local function read_lines(path, bufnr)
  if bufnr and bufnr > 0 and vim.api.nvim_buf_is_valid(bufnr) then
    local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, 120, false)
    if ok and #lines > 0 then
      return lines
    end
  end
  if not path or path == "" then
    return {}
  end
  local ok, lines = pcall(vim.fn.readfile, path, "", 120)
  return ok and lines or {}
end

local function detect_pl(path, bufnr)
  local lines = read_lines(path, bufnr)
  local prolog = 0
  local perl = 0
  local in_block = false
  local in_pod = false

  for i, raw in ipairs(lines) do
    local trimmed = raw:match("^%s*(.-)%s*$")
    if trimmed ~= "" then
      if in_pod then
        if trimmed:match("^=cut") then
          in_pod = false
        end
      elseif trimmed:match("^=[a-z]") then
        if not trimmed:match("^=cut") then
          in_pod = true
        end
      elseif in_block then
        if trimmed:match("%*/") then
          in_block = false
        end
      elseif trimmed:match("^/%*") then
        prolog = prolog + 1
        if not trimmed:match("%*/") then
          in_block = true
        end
      elseif trimmed:match("^%%") then
        if trimmed:match("^%%[%a_][%w_]*%s*=") then
          perl = perl + 2
        else
          prolog = prolog + 1
        end
      elseif trimmed:match("^#") then
        if i == 1 and (trimmed:match("^#!.*swipl") or trimmed:match("^#!.*prolog")) then
          prolog = prolog + 4
        elseif i == 1 and trimmed:match("^#!.*perl") then
          perl = perl + 4
        else
          perl = perl + 1
        end
      else
        if trimmed:match("^:%-") or trimmed:match("^%?%-") then
          prolog = prolog + 4
        end
        if trimmed:match("^[a-z][%w_]*%s*%b()%s*:%-") then
          prolog = prolog + 4
        end
        if trimmed:match("^[a-z][%w_]*%s*:%-") then
          prolog = prolog + 4
        end
        if trimmed:match("^[a-z][%w_]*%s*%-%-%>") then
          prolog = prolog + 2
        end
        if trimmed:match("=%.%.") then
          prolog = prolog + 2
        end
        if trimmed:match("\\%+") then
          prolog = prolog + 1
        end
        if trimmed:match("@[<>=]") then
          prolog = prolog + 1
        end
        if trimmed:match("^use%s+") or trimmed:match("^require%s+") then
          perl = perl + 3
        end
        if trimmed:match("^sub%s+") or trimmed:match("^package%s+") then
          perl = perl + 3
        end
        if trimmed:match("%f[%w_](my|our|local|state)%f[%W]") then
          perl = perl + 2
        end
        if trimmed:match("[%$@%%][%a_]") then
          perl = perl + 1
        end
        if trimmed:match("=~") then
          perl = perl + 2
        end
        if trimmed:match(";%s*$") then
          perl = perl + 1
        end
        local code = trimmed:gsub("%s*%%.*$", "")
        if code:match("[%w_%)%]%.]$") and not code:match("%.%.$") and not code:match("%d+%.$") then
          prolog = prolog + 1
        end
      end
    end
  end

  if prolog > perl and prolog > 0 then
    return "prolog"
  end
  if perl > prolog and perl > 0 then
    return "perl"
  end
  return require("vim.filetype.detect").pl(path, bufnr) or "perl"
end

M.detect_pl = detect_pl

vim.filetype.add({
  extension = {
    pl = detect_pl,
    PL = detect_pl,
  },
})

local group = vim.api.nvim_create_augroup("PrologFiletype", { clear = true })

local function recheck_pl(buf)
  if vim.b[buf].prolog_detect_off then
    return
  end
  if vim.bo[buf].filetype ~= "perl" then
    return
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if not name:match("%.pl$") and not name:match("%.PL$") then
    return
  end
  if detect_pl(name, buf) == "prolog" then
    vim.bo[buf].filetype = "prolog"
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "perl",
  callback = function(args)
    recheck_pl(args.buf)
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = { "*.pl", "*.PL" },
  callback = function(args)
    recheck_pl(args.buf)
  end,
})

return M
