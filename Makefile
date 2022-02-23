.PHONY: build
build: tabler-icons
	crystal run -p src/builder.cr

tabler-icons:
	git clone https://github.com/tabler/tabler-icons.git
