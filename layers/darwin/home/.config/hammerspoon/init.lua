require "hs.ipc"

require("togo.cursor").init()
require("togo.desktop").init()
require("togo.kitty").init()
require("togo.screen-brightness").init()
require("togo.screen-size").init()
require("togo.vpn").init()

hs.alert.show ">>> hs <<<"
