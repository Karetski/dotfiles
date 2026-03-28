.PHONY: install plan install-tag

install:
	./install.sh

plan:
	DRY_RUN=1 ./install.sh

install-tag:
	TAG=$(TAG) ./install.sh
