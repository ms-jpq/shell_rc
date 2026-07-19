require "hs.ipc"

require("og.desktop").init()
require("og.kitty").init()
require("og.screen-brightness").init()
require("og.screen-size").init()
require("og.vpn").init()

hs.alert.show ">>> hs <<<"
