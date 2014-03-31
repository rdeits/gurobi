# Default pod makefile distributed with pods version: 12.11.14

default_target: all

# Default to a less-verbose build.  If you want all the gory compiler output,
# run "make VERBOSE=1"
$(VERBOSE).SILENT:

# Figure out where to build the software.
#   Use BUILD_PREFIX if it was passed in.
#   If not, search up to four parent directories for a 'build' directory.
#   Otherwise, use ./build.
ifeq "$(BUILD_PREFIX)" ""
BUILD_PREFIX:=$(shell for pfx in ./ .. ../.. ../../.. ../../../..; do d=`pwd`/$$pfx/build;\
               if [ -d $$d ]; then echo $$d; exit 0; fi; done; echo `pwd`/build)
endif
# create the build directory if needed, and normalize its path name
BUILD_PREFIX:=$(shell mkdir -p $(BUILD_PREFIX) && cd $(BUILD_PREFIX) && echo `pwd`)

# Default to a release build.  If you want to enable debugging flags, run
# "make BUILD_TYPE=Debug"
ifeq "$(BUILD_TYPE)" ""
BUILD_TYPE="Release"
endif

DL_PATH = https://github.com/RobotLocomotion/gurobi-tarballs/archive
UNZIP_DIR = gurobi562
ifeq ($(shell uname -s), Darwin)
  DL_NAME = gurobi5.6.2_mac64.tar.gz
else ifeq ($(shell uname -s), Linux)
  DL_NAME = gurobi5.6.2_linux64.tar.gz
endif

all: pod-build/Makefile $(HOME)/gurobi.lic 
	$(MAKE) -C pod-build all install

$(UNZIP_DIR): 
	@echo "Fetching Gurobi source tarballs from private Github repository."
	@echo "If you do not have access to this repository, please download"
	@echo "version 5.6.2 for your platform from http://www.gurobi.com.\n"
	@read -p "Enter your github username: " USERNAME; curl -sL --user $$USERNAME "$(DL_PATH)/$(DL_NAME).zip" > tarball.zip
	@echo "Extracting gurobi tarballs"
	@unzip tarball.zip || echo "Gurobi source download failed"
	@mv -i gurobi-tarballs-$(DL_NAME)/$(DL_NAME) . 
	@rm -rf gurobi-tarballs-$(DL_NAME)  
	@tar -xzf $(DL_NAME)
	@rm -rf $(DL_NAME)
	@rm tarball.zip

pod-build/Makefile: $(UNZIP_DIR)
	$(MAKE) configure

.PHONY: configure
configure: $(UNZIP_DIR)
	@echo "\nBUILD_PREFIX: $(BUILD_PREFIX)\n\n"

	# create the temporary build directory if needed
	@mkdir -p pod-build

	# run CMake to generate and configure the build scripts
	@cd pod-build && cmake -DCMAKE_INSTALL_PREFIX=$(BUILD_PREFIX) \
		   -DCMAKE_BUILD_TYPE=$(BUILD_TYPE) ..

# todo: make this logic more robust:
#   check for license path environment variable
$(HOME)/gurobi.lic : 
	@echo "You do not appear to have a license for gurobi installed in $(HOME)/gurobi.lic\n"
	@echo "Open the following url in your favorite browser and request the license:\n"
	@echo "           http://www.gurobi.com/download/licenses/free-academic\n"
	@echo "Then run the grbgetkey line provide on the website and follow the prompts to\n"
	@echo "store your license file in $(HOME)/gurobi.lic\n"
	@echo "Note that you will need to create an account on the GUROBI website if you do\n"
	@echo "not yet have one.\n"

clean:
	-if [ -e pod-build/install_manifest.txt ]; then rm -f `cat pod-build/install_manifest.txt`; fi
	-if [ -d pod-build ]; then $(MAKE) -C pod-build clean; rm -rf pod-build; fi

.PHONY: install_prereqs_macports install_prereqs_homebrew install_prereqs_ubuntu
install_prereqs_macports :
	port install curl

install_prereqs_homebrew :
	brew install curl

install_prereqs_ubuntu :
	apt-get install curl

# other (custom) targets are passed through to the cmake-generated Makefile 
%::
	$(MAKE) -C pod-build $@