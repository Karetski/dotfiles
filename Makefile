.PHONY: install plan install-tag

install:
	ansible-playbook site.yml

test:
	ansible-playbook site.yml --check --diff

install-tag:
	ansible-playbook site.yml --tags $(TAG)
