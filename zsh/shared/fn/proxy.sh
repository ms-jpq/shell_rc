#!/usr/bin/env -S -- bash

if (($#)); then
  export -- http_proxy="http://${2:-localhost}:$1"
  export -- https_proxy="$http_proxy"
  export -- HTTP_PROXY="$http_proxy"
  export -- HTTPS_PROXY="$http_proxy"
else
  unset http_proxy
  unset https_proxy
  unset HTTP_PROXY
  unset HTTPS_PROXY
fi
printf -- '%s\n' "http_proxy =$http_proxy"
printf -- '%s\n' "https_proxy=$https_proxy"