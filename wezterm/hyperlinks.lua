-- Use the defaults as a base
local wezterm = require "wezterm"
local ok, hyperlink_rules = pcall(wezterm.default_hyperlink_rules)
if not ok then
  hyperlink_rules = {}
end

-- make task numbers clickable
-- the first matched regex group is captured in $1.

-- table.insert(hyperlink_rules, {
--   regex = [[\b[tt](\d+)\b]],
--   format = "https://example.com/tasks/?t=$1",
-- })

-- make username/project paths clickable. this implies paths like the following are for github.
-- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
-- as long as a full url hyperlink regex exists above this it should not match a full url to
-- github or gitlab / bitbucket (i.e. https://gitlab.com/user/project.git is still a whole clickable url)
table.insert(hyperlink_rules, {
  regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
  format = "https://www.github.com/$1/$3",
})

-- match the URL with a PORT
-- such 'http://localhost:3000/index.html'
table.insert(hyperlink_rules, {
  regex = "\\b\\w+://(?:[\\w.-]+):\\d+\\S*\\b",
  format = "$0",
})

table.insert(hyperlink_rules, {
  regex = "\\b\\w+://\\S+[)/a-zA-Z0-9-]+",
  format = "$0",
})

return hyperlink_rules
