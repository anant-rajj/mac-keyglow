.PHONY: all build release app install uninstall clean

APP_NAME = KeyGlow
BIN_NAME = keyglow
INSTALL_DIR = /usr/local/bin
APPS_DIR = /Applications
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app

all: release

build:
	swift build

release:
	swift build -c release

app: release
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp Resources/Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@echo "Created standalone macOS app: $(APP_BUNDLE)"

install: release
	@mkdir -p $(INSTALL_DIR)
	@cp $(BUILD_DIR)/$(APP_NAME) $(INSTALL_DIR)/$(BIN_NAME)
	@chmod +x $(INSTALL_DIR)/$(BIN_NAME)
	@echo "Installed $(BIN_NAME) to $(INSTALL_DIR)/$(BIN_NAME)"

install-app: app
	@rm -rf $(APPS_DIR)/$(APP_BUNDLE)
	@cp -R $(APP_BUNDLE) $(APPS_DIR)/
	@echo "Installed $(APP_BUNDLE) to $(APPS_DIR)/$(APP_BUNDLE)"

uninstall:
	@rm -f $(INSTALL_DIR)/$(BIN_NAME)
	@rm -rf $(APPS_DIR)/$(APP_BUNDLE)
	@echo "Uninstalled KeyGlow from $(INSTALL_DIR) and $(APPS_DIR)"

clean:
	swift package clean
	@rm -rf $(APP_BUNDLE)
