#!/usr/bin/env -S -- sed -E -f

:l1
/./,$!d
/^\n*$/{$d;N;}
/\n$/bl1
