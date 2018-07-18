##
## Copyright (c) 2018-present Keith Irwin
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published
## by the Free Software Foundation, either version 3 of the License,
## or (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see
## <http://www.gnu.org/licenses/>.
##

.DEFAULT_GOAL := help
.PHONY: open server outdated

open: ## Open the application in Xcode
	@open application/ClojureBrowser.xcodeproj

server: ## Run the backend server
	@$(MAKE) -C server run

outdated: ## Check for outdated server dependencies
	@$(MAKE) -C server outdated

help: ## Show makefile based help
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}' \
		| sort
