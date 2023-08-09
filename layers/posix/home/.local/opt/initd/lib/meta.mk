define META_2D
$(foreach line,$($1),$(eval $(call $2,$(firstword $(subst !, ,$(line))),$(lastword $(subst !, ,$(line))))))
endef
