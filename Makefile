.PHONY: install plan install-tag install-confirm

install:
	./install.sh

plan:
	DRY_RUN=1 ./install.sh

install-tag:
	TAG=$(TAG) ./install.sh

install-confirm:
	CONFIRM_MODE=1 ./install.sh
