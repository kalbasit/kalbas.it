.PHONY: serve

HOST ?= $(shell ip route get 1 | awk '{print $$NF;exit}')

serve:
	@echo "==="
	@echo "--- Website available at http://$(HOST):1313/ ---"
	@echo "---"
	@hugo serve -D --bind 0.0.0.0 --baseURL http://$(HOST)/
