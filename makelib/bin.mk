$(TMP)/rsync.tar.zst:
	REPO='https://repo.msys2.org/msys/x86_64'
	REF="$$($(CURL) -- "$$REPO" | htmlq --attribute href -- 'html > body > pre > a[href*="rsync-"]')"
	readarray -t -d $$'\n' -- REFS <<<"$$REF"
	$(CURL) --output '$@' -- "$$REPO/$${REFS[0]}"
