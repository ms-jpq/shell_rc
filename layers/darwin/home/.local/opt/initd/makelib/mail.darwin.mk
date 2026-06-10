.PHONY: app.aerc

APP_AERC := $(OPT)/Aerc.app
$(APP_AERC): $(OPT)/initd/libexec/aerc-mailto.cjs
	rm -fr -v -- '$@'
	osacompile -l JavaScript -o '$@' '$<'

mail: app.aerc
app.aerc: $(APP_AERC)/Contents/Info.plist
$(APP_AERC)/Contents/Info.plist: $(APP_AERC)
	ARGV=(/usr/libexec/PlistBuddy)
	ARGV+=(-c 'Add :CFBundleIdentifier string com.aerc.mailto')
	ARGV+=(-c 'Add :CFBundleURLTypes array')
	ARGV+=(-c 'Add :CFBundleURLTypes:0 dict')
	ARGV+=(-c 'Add :CFBundleURLTypes:0:CFBundleURLName string mailto')
	ARGV+=(-c 'Add :CFBundleURLTypes:0:CFBundleURLSchemes array')
	ARGV+=(-c 'Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string mailto')

	"$${ARGV[@]}" '$@'
