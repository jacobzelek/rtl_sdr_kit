#    rtl_sdr_kit - Installs and updates GNURadio, OsmoSDR, RTLSDR, and GQRX from source code hosted at respective Git repositories.
#    Copyright (C) 2013  Jacob Zelek <jacob@jacobzelek.com>
#
#     Updates:
#     2013-09-15 - GQRX installation added
#
#     2013-02-11 - Rewritten to detect if sudo is installed then display commands to install it.
#		apt-get command given --force-yes argument to force unauthenticated packages to install.
#		"apt-get update" line added to update package index before installing prereqs (Thanks to Wolfgang Schenk for bug report)
#    
#     2014-01-14 - Memory check prior to installation, tests for QT version, spell fix, prerequisites only target available (Ian Gibbs <realflash.uk@googlemail.com>)
#
#     2014-01-26 - Automatically blacklist RTL28xxu DVB Kernel module
#
#     2014-02-19 - Improve QT version check to cover no QT installed scenario, add support for Lubuntu by installing pulseaudio if required and rebooting as necessary  (Ian Gibbs <realflash.uk@googlemail.com>)
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#!/bin/bash
check_package_status()
{
	RES=dpkg -l $1 2>&1 | sed -n '7p' | awk '{print $1}'
	echo $RES
}

preinstall()
{
	# Debian-based distros without QT5 will be fine
	# Newer ones have QT5 and QT4, with QT5 set as the default.
	# GQRX requires QT4 to be the default
	TMP=`dpkg -l qt5-default 2>&1`
	QT5_RETURN=$?
	if [ $QT5_RETURN -eq 0 ]; then
	{	# QT5 is available, which may stop GQRX from compiling
		QT5_STATUS=$(check_package_status qt5-default)
		if [ "$QT5_STATUS" == "ii" -o "$QT5_STATUS" == "un" ]; then
		{	# If it is installed it will cause a problem with GQRX
			# If it is not installed it will get selected as a dependency of other things, so we still need to override it
			ADDITIONS="qt4-default"		# If this is already installed APT will silently ignore it
		}
		else
		{
			echo "Can't determine if package qt5-default is properly installed: examine the below for problems"
			`dpkg -l qt5-default`
			exit 1		
		}
		fi
	}
	fi
	# Lubuntu doesn't have pulseaudio which is needed for GQRX and dl-fldigi
	PA_STATUS=$(check_package_status pulseadio)
	if [ "$PA_STATUS" != "ii" ]; then
	{
		ADDITIONS="$ADDITIONS pulseaudio"
		REBOOT_REQUIRED=1
	}
	fi
	# Ready to install
	sudo apt-get update
	sudo apt-get -y --force-yes install libfontconfig1-dev libxrender-dev libpulse-dev \
	swig g++ automake autoconf libtool python-dev libfftw3-dev \
	libcppunit-dev libboost-all-dev libusb-1.0.0-dev fort77 \
	libsdl1.2-dev python-wxgtk2.8 git-core guile-1.8-dev \
	libqt4-dev python-numpy ccache python-opengl libgsl0-dev \
	python-cheetah python-lxml doxygen qt4-dev-tools \
	libqwt5-qt4-dev libqwtplot3d-qt4-dev pyqt4-dev-tools python-qwt5-qt4 \
	cmake git-core qtcreator $ADDITIONS
	
	return 0
}

git_gqrx()
{
	git clone https://github.com/csete/gqrx.git gqrx &> /dev/null
	return $?
}

pull_gqrx()
{
	cd gqrx/
	git pull &> /dev/null
	EXIT_CODE=$?
	cd ..

	return $EXIT_CODE
}

in_gqrx()
{
	cd gqrx/
	mkdir build
	cd build/

	qmake ../
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]
	then
		return $EXIT_CODE
	fi	
	
	echo "Compiling..."

	make
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]
	then
		return $EXIT_CODE
	fi

	echo "Installing..."

	sudo make install
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]
	then
		return $EXIT_CODE
	fi

	sudo ldconfig
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]
	then
		return $EXIT_CODE
	fi

	cd ../..
	return $?
}

git_gnuradio()
{
	git clone https://github.com/gnuradio/gnuradio.git gnuradio &> /dev/null
	return $?
}

pull_gnuradio()
{
	cd gnuradio/
	git pull &> /dev/null
	EXIT_CODE=$?
	cd ..

	return $EXIT_CODE
}

in_gnuradio()
{
	cd gnuradio/
	mkdir build
	cd build/

	cmake ../
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]
	then
		return $EXIT_CODE
	fi	
	
	echo "Compiling..."

	make
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]
	then
		return $EXIT_CODE
	fi

	echo "Installing..."

	sudo make install
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]
	then
		return $EXIT_CODE
	fi

	sudo ldconfig
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]
	then
		return $EXIT_CODE
	fi

	cd ../..
	return $?
}

git_osmosdr()
{
	git clone git://git.osmocom.org/gr-osmosdr gr-osmosdr &> /dev/null
	return $?
}

pull_osmosdr()
{
	cd gr-osmosdr/
	git pull &> /dev/null
	EXIT_CODE=$?
	cd ..
	return $EXIT_CODE
}

in_osmosdr()
{
	cd gr-osmosdr/
	mkdir build
	cd build/
	cmake ../
	echo "Compiling..."
	make
	echo "Installing..."
	sudo make install
	sudo ldconfig
	cd ../..
	return $?
}

git_rtlsdr()
{
	git clone git://git.osmocom.org/rtl-sdr.git rtl-sdr &> /dev/null
	return $?
}

pull_rtlsdr()
{
	cd rtl-sdr/
	git pull &> /dev/null
	EXIT_CODE=$?
	cd ..
	return $EXIT_CODE
}

in_rtlsdr()
{
	cd rtl-sdr/
	mkdir build
	cd build/

	cmake ../
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]
	then
		return $EXIT_CODE
	fi

	echo "Compiling..."

	make
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]
	then
		return $EXIT_CODE
	fi
	echo "Installing..."

	sudo make install
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]
	then
		return $EXIT_CODE
	fi
	
	echo "Installing udev rules"
	sudo cp ../rtl-sdr.rules /etc/udev/rules.d/15-rtl-sdr.rules

	sudo ldconfig
	EXIT_CODE=$?
	if [ $EXIT_CODE -ne 0 ]
	then
		return $EXIT_CODE
	fi

	cd ../..
	return $?
}

execute()
{
	actions=$1	
	msgs=$2

	for (( i=0; i<${#actions[@]}; i++ ))
	do
		echo ${msgs[i]} "[IN PROGRESS]"

		${actions[i]}

		if [ $? -eq 0 ]
		then
			echo ${msgs[i]} "[DONE]"
		else
			echo ${msgs[i]} "[FAIL]"
			exit 2
		fi
	done
}

check_memory()
{
	# Compiling GNUradio needs at least this amount of memory or the compiler will crash
	# This memory requirement arrived at by experimentation. Accurate to +- 50Mb
	MINIMUM_MEM_KB=1400000
	SWAP_KB=`cat /proc/swaps | awk '!/^Filename.*/ { total += $3 } END { print total }'`
	MEMINFO=`cat /proc/meminfo`
	MEM_FREE_KB=`cat /proc/meminfo | awk '/^MemFree.*/ { print $2 }'`
	BUFFERS_KB=`cat /proc/meminfo | awk '/^Buffers.*/ { print $2 }'`
	CACHED_KB=`cat /proc/meminfo | awk '/^Cached.*/ { print $2 }'`
	AVAILABLE_KB=`expr $SWAP_KB + $MEM_FREE_KB + $BUFFERS_KB + $CACHED_KB`
	echo "Available memory: ${AVAILABLE_KB}Kb"
	if [ $AVAILABLE_KB -lt $MINIMUM_MEM_KB ]
	then
		echo "You must have at least ${MINIMUM_MEM_KB}Kb memory free to compile GNUradio (you have ${AVAILABLE_KB}Kb). Add more RAM or swap space."
		return 1
	fi
	return 0
}

blacklist_dvb()
{
  sudo sh -c "echo 'blacklist dvb_usb_rtl28xxu' > /etc/modprobe.d/blacklist-dvb-rtl28xxu.conf"
  return $?
}

check_reboot()
{
	if [ "$REBOOT_REQUIRED" -gt 0 ]; then
	{
		echo -ne "\e[0;33m"
		echo "One of the components that was installed requires the computer to be rebooted before it will work."
		echo -ne "\e[0m"
		if [ ! -z "$AUTO_REBOOT" ]; then
		{
			echo "You have requested an automatic reboot. The computer will reboot in 60s."
			shutdown -r +1
		}
		else
		{
			echo "Please reboot the computer at your covnenience."
		}
		fi
	}
	fi
	return 0 
}

install()
{
	actions=("check_memory" "preinstall" "git_gnuradio" "git_rtlsdr" "git_osmosdr" "git_gqrx" "in_gnuradio" "in_rtlsdr" "in_osmosdr" "in_gqrx" "blacklist_dvb" "check_reboot")
	msgs=("Check memory" "Install prerequisites" "Git checkout GNURadio" "Git checkout RTL-SDR" "Git checkout OsmoSDR" "Git checkout GQRX" "Install GNU Radio" "Install RTL-SDR" "Install OsmoSDR" "Install GQRX" "Blacklisting Linux RTL28xxu DVB Module" "Check if a reboot is required")

	execute "${actions}" "${msgs}"
}

update()
{
	actions=("check_memory" "pull_gnuradio" "pull_rtlsdr" "pull_osmosdr" "pull_gqrx" "in_gnuradio" "in_rtlsdr" "in_osmosdr" "in_gqrx")
	msgs=("Check memory" "Git pull GNU Radio" "Git pull RTL-SDR" "Git pull OsmoSDR" "Git pull GQRX" "Install GNU Radio" "Install RTL-SDR" "Install OsmoSDR" "Install GQRX")

	execute "${actions}" "${msgs}"
}

fetch()
{
	actions=("pull_gnuradio" "pull_rtlsdr" "pull_osmosdr" "pull_gqrx")
	msgs=("Git pull GNURadio" "Git pull RTL-SDR" "Git pull OsmoSDR" "Git pull GQRX")

	execute "${actions}" "${msgs}"
}

prerequisites()
{
	actions=("preinstall" "check_reboot")
	msgs=("Install prerequisites" "Check if a reboot is required")

	execute "${actions}" "${msgs}"
}

check_sudo()
{
	sudo > /dev/null 2> /dev/null
	if [ $? -eq 127 ]
	then
		echo "This script requires sudo. Use the following commands to do this:"
		echo ""
		echo "$ su"
		echo "# apt-get install sudo"
		echo "# adduser <username> sudo"
		echo "# exit"	
		exit 1
	fi
}

case "$1" in
	install)
		check_sudo
		install
		;;
	update)
		check_sudo
		update
		;;
	fetch)
		fetch
		;;
	prerequisites)
		check_sudo
		prerequisites
		;;
	*)
		echo "rtl_sdr_kit - Installs and updates GNURadio, OsmoSDR, RTLSDR, and GQRX from source code hosted at respective Git repositories."
		echo ""
		echo "Usage: $0 [install|update|fetch|prerequisites]"
		echo ""
		echo "Some newly-installed components may require the computer to be rebooted before they will run properly. You will be told at the end of the installation if this is the case. To have the script automatically reboot the computer if required, set the environment variable AUTO_REBOOT to a non-empty string:
	
AUTO_REBOOT=y; $0 [install|prerequisistes]"
		echo ""
		exit 1
		;; 
esac

