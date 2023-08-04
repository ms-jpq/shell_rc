.PHONY: pkg pkg.posix

pkg: pkg.posix

pkg.posix: ./libexec/pkg.sh
	HOME='$(call UNESC_DRIVE,$(HOME))' '$<'
