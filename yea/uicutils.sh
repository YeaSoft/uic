#!/bin/bash
#
# (c) 2012-2014 YeaSoft Int'l - Leo Moll
#
# VERSION 20140502
# function collection for the unified installation creator

#####################
# Internal Variables
# generic script helpers
SCRIPTNAME=$(basename $0)
SCRIPTPATH=$(expr match "$0" '\(.*\)'\/${SCRIPTNAME})
VERBOSE=0
# uic specific
VERSION='@VERSION@'
VERSION='0.16'
SPECIALFSM="/sys /proc /dev /dev/pts /dev/shm"
SPECIALFSU="/dev/shm /dev/pts /dev /proc /sys"
SPECIALFSMOUNT=0
OLDHOSTNAME=$(hostname)
TARGET=

########################
# Overall default values

# The default working directory for installations
# Default: UIC_WORKDIR=/usr/src
UIC_WORKDIR=/usr/src

# The default APT proxy to use
# Default: none
UIC_APTPROXY=

# The default UIC template repositories (separated
# by spaces)
# Default: http://www.yeasoft.com/uic-templates
UIC_REPOSITORIES=http://www.yeasoft.com/uic-templates

#####################
# Functions

# generic script helpers

function show_name {
	echo "${SCRIPTNAME}, version ${VERSION}"
}

function show_verbose {
	if [ ${VERBOSE} -ge $1 ]; then
		echo "${SCRIPTNAME}: ${*:2}"
	fi
}

function show_warning {
	echo "${SCRIPTNAME} warning: $*" >&2
}

function show_error {
	echo "${SCRIPTNAME} error: $*" >&2
}

function test_exec {
	case $? in
	0);;
	*)	case "$1" in
		"")	show_error "last command failed with error (code $?)";;
		*)	show_error "$1 failed with error (code $?)";;
		esac
		if [ -n "$2" ]; then
			show_error "commandline: ${*:2}"
		fi
		exit $?;;
	esac
}

function test_getopt {
	case $? in
	0);;
	1) show_error "syntax or usage error (code $?)"; exit $?;;
	2) show_error "syntax or usage error (code $?) in [getopt]"; exit $?;;
	3) show_error "internal error (code $?) in [getopt]"; exit $?;;
	4) show_error "wrong getopt version installed"; exit $?;;
	*) show_error "unknown getopt error (code $?)"; exit $?;;
	esac
}

# uic specific

function init_script() {
	trap cleanup_script INT QUIT TERM EXIT
        call_hook init_script
}

function cleanup_script() {
        trap - INT QUIT TERM EXIT
        call_hook exit_script
        chroot_exit
        cleanup_mounts
}


function chroot_init() {
	if [ ${SPECIALFSMOUNT} -lt 1 ]; then
		show_verbose 1 "Mounting special file systems in environment..."
		mount_special
		enable_policy
		enable_dpkg_options
		SPECIALFSMOUNT=1
	fi
}

function mount_special() {
	for MOUNT_POINT in ${SPECIALFSM}; do
		if ! grep "${TARGET}/chroot${MOUNT_POINT}" /proc/mounts > /dev/null; then
			mount -o bind ${MOUNT_POINT} ${TARGET}/chroot${MOUNT_POINT}
		fi
	done
}

function enable_policy() {
	echo -e "#!/bin/sh\nexit 101" > "${TARGET}/chroot/usr/sbin/policy-rc.d"
	chmod +x "${TARGET}/chroot/usr/sbin/policy-rc.d"
}

function disable_policy() {
	[ -f "${TARGET}/chroot/usr/sbin/policy-rc.d" ] && rm "${TARGET}/chroot/usr/sbin/policy-rc.d"
}

function enable_dpkg_options() {
	# this method does not work with older versions of dpkg
	# mkdir -p "${TARGET}/chroot/etc/dpkg/dpkg.cfg.d"
	# echo "# automatically added by uic - will be deleted at end of operation" > "${TARGET}/chroot/etc/dpkg/dpkg.cfg.d/zzuicopts"
	# echo "force-confdef" >> "${TARGET}/chroot/etc/dpkg/dpkg.cfg.d/zzuicopts"
	# echo "force-confold" >> "${TARGET}/chroot/etc/dpkg/dpkg.cfg.d/zzuicopts"
	# alternative method
	mv "${TARGET}/chroot/etc/dpkg/dpkg.cfg" "${TARGET}/chroot/etc/dpkg/dpkg.cfg.uic-save"
	cp "${TARGET}/chroot/etc/dpkg/dpkg.cfg.uic-save" "${TARGET}/chroot/etc/dpkg/dpkg.cfg"
	echo "# automatically added by uic - will be deleted at end of operation" >> "${TARGET}/chroot/etc/dpkg/dpkg.cfg"
	echo "force-confdef" >> "${TARGET}/chroot/etc/dpkg/dpkg.cfg"
	echo "force-confold" >> "${TARGET}/chroot/etc/dpkg/dpkg.cfg"
}

function disable_dpkg_options() {
	# this method does not work with older versions of dpkg
	# [ -f "${TARGET}/chroot/etc/dpkg/dpkg.cfg.d/zzuicopts" ] && rm "${TARGET}/chroot/etc/dpkg/dpkg.cfg.d/zzuicopts"
	# alternative method
	[ -f "${TARGET}/chroot/etc/dpkg/dpkg.cfg.uic-save" ] && mv "${TARGET}/chroot/etc/dpkg/dpkg.cfg.uic-save" "${TARGET}/chroot/etc/dpkg/dpkg.cfg"
}

function umount_special() {
	for MOUNT_POINT in ${SPECIALFSU}; do
		if grep "${TARGET}/chroot${MOUNT_POINT}" /proc/mounts > /dev/null; then
			umount ${TARGET}/chroot${MOUNT_POINT}
		fi
	done
}

function chroot_exit() {
	if [ ${SPECIALFSMOUNT} -gt 0 ]; then
		show_verbose 1 "Unmounting special file systems in environment..."
		disable_dpkg_options
		disable_policy
		umount_special 2> /dev/null
		SPECIALFSMOUNT=0
	fi
}

function test_mountinuse() {
	if grep "${TARGET}/chroot/" /proc/mounts; then
		show_error "WARNING: There are active mounts in the installation environment probably"
		show_error "         because of an active preparation session. The execution will be"
		show_error "         terminated in order to prevent damage to the installation environment"
		exit 5
	fi
}

function cleanup_mounts() {
	if grep "${TARGET}/chroot/" /proc/mounts; then
		# let's try to unmount them
		for MOUNT_POINT in $(grep "${TARGET}/chroot/" /proc/mounts | awk '{print $2}'); do
			umount ${MOUNT_POINT} 2> /dev/null
		done
	fi
	while [ $(mount | grep "/run/shm on /run/shm" | wc -l) -gt 1 ]; do
		umount /run/shm
	done
	if [ -z $1 ]; then
		SHELL_REPEAT=3
	else
		SHELL_REPEAT=$(($1))
	fi
	while grep "${TARGET}/chroot/" /proc/mounts > /dev/null; do
		echo >&2
		show_error "WARNING: There are some active mounts in the installation environment that"
		show_error "         cannot be unmounted automatically because probably they are still"
		show_error "         in use by some running process."
		show_error "         Following you get some useful information for solving the problem"
		show_error "         manually."
		echo >&2
		echo "Active filesystem mounts" >&2
		echo "--------------------------------" >&2
		grep "${TARGET}/chroot/" /proc/mounts | awk '{print $2}' >&2
		echo >&2
		echo "Active processes having open handles on the mountpoints" >&2
		echo "-------------------------------------------------------" >&2
		for MOUNT_POINT in $(grep "${TARGET}/chroot/" /proc/mounts | awk '{print $2}'); do
			lsof | grep ${MOUNT_POINT} >&2
		done

		if [ ${SHELL_REPEAT} -lt 1 ]; then
			echo >&2
			echo "Please try to unmount them manually before continuing or reboot." >&2
			exit 1
		fi

		echo "A chroot shell into the target environment will be launched for you" >&2
		(( SHELL_REPEAT-- ))
		if [ ${SHELL_REPEAT} -lt 1 ]; then
			echo "so that you may solve the problem." >&2
		else
			echo "so that you may solve the problem. Upon exiting the shell, the dismount" >&2
			echo "will be attempted again." >&2
		fi
		echo "ENTERING CHROOT SHELL...." >&2
		mount_special
		export debian_chroot="${TARGET} Environment"
		chroot "${TARGET}/chroot" /bin/bash

		if grep "${TARGET}/chroot/" /proc/mounts > /dev/null; then
			# trying again to dismount
			umount_special 2> /dev/null
			for MOUNT_POINT in $(grep "${TARGET}/chroot/" /proc/mounts | awk '{print $2}'); do
				umount ${MOUNT_POINT} 2> /dev/null
			done
		fi
	done
}


function find_environment() {
	if [ $# -lt 1 ]; then
		# no environment name specified. It must be here....
		test_environment "$(pwd)"
		TARGET="$(pwd)"
	elif [ "${1:0:1}" = "/" ]; then
		# absolute path specified
		test_environment "$1"
		TARGET="$1"
	elif [ -d "$(pwd)/$1" ]; then
		# specified environment under the current directory?
		test_environment "$(pwd)/$1"
		TARGET="$(pwd)/$1"
	elif [ -d "${UIC_WORKDIR}/$1" ]; then
		# specified environment under the default working directory?
		test_environment "${UIC_WORKDIR}/$1"
		TARGET="${UIC_WORKDIR}/$1"
	else
		show_error "Environment $1 does not exist"
		exit 2
	fi
	TARGETNAME=$(basename ${TARGET})
	TARGETPATH=$(dirname ${TARGET})
	if [ "${TARGETPATH}" = "/" ]; then
		TARGET="/${TARGETNAME}"
	else
		TARGET="${TARGETPATH}/${TARGETNAME}"
	fi
}

function test_environment() {
	if [ ! -d "$1" ]; then
		show_error "Environment $1 does not exist"
		exit 1
	fi

	if [ ! -f "$1/uictpl.conf" ]; then
		show_error "Environment $1 does not contain a configuration file"
		exit 1
	fi

	if [ ! -d "$1/files" ]; then
		show_error "Environment $1 is invalid"
		exit 1
	fi
}

function test_environment_empty() {
	if [ ! -d "${TARGET}/chroot" ]; then
		show_error "Installation environment is empty. Use 'uic create' to create a new one."
		exit 1
	fi
	if [ $(find "${TARGET}/chroot" | wc -l) -lt 2 ]; then
		show_error "Installation environment is empty. Use 'uic create' to create a new one."
		exit 1
	fi
}

function test_environment_configuration() {
	if [ -z "${UIC_SRCNAME}" ]; then
		show_error "UIC_SRCNAME missing in environment configuration file"
		exit 1
	fi
	if [ -z "${UIC_SRCVERSION}" ]; then
		show_error "UIC_SRCVERSION missing in environment configuration file"
		exit 1
	fi
	if [ -z "${UIC_ARCH}" ]; then
		show_error "UIC_ARCH missing in environment configuration file"
		exit 1
	fi
	if [ -z "${UIC_RELEASE}" ]; then
		show_error "UIC_RELEASE missing in environment configuration file"
		exit 1
	fi
	if [ -z "${UIC_REPOSITORY}" ]; then
		show_error "UIC_REPOSITORY missing in environment configuration file"
		exit 1
	fi
	if [ -z "${UIC_KERNEL}" ]; then
		show_error "UIC_KERNEL missing in environment configuration file"
		exit 1
	fi
	if [ -z "${UIC_ROOTPASSWORD}" ]; then
		show_error "UIC_ROOTPASSWORD missing in environment configuration file"
		exit 1
	fi
}

function test_arch_compatibility() {
	MY_ARCH=$(dpkg-query -W -f='${Architecture}\n' dpkg)
	if [ "${MY_ARCH}" = "${UIC_ARCH}" ]; then
		show_verbose 2 "Target has the same architecture (${MY_ARCH})"
		return 0
	fi
	case "${MY_ARCH}" in
	"amd64")	if [ "${UIC_ARCH}" = "i386" ]; then
				show_verbose 2 "Target has a compatible architecture"
				return 0
			fi
			;;
	esac
	return 3
}

function test_distributor_compatibility() {
	if ! which lsb_release > /dev/null; then
		# no lsb_release on this platform
		return 3;
	fi
	MY_DISTRIB=$(lsb_release -is)
	case "${MY_DISTRIB}" in
	"Ubuntu")	return 0;;
	"Debian")	return 0;;
	esac
	return 3
}

function test_release_compatibility() {
	if [ -f "/usr/share/debootstrap/scripts/${UIC_RELEASE}" ]; then
		return 0
	fi
	return 3
}

function test_builder_compatibility() {
	if ! test_distributor_compatibility; then
		show_error "This system is not compatible with the specified template"
		exit 3
	fi
	if ! test_release_compatibility; then
		show_error "The release of this computer is not compatible with the specified template"
		exit 3
	fi
	if ! test_arch_compatibility; then
		show_error "Target architecture ${UIC_ARCH} not compatible with ${MY_ARCH}"
		exit 3
	fi
	return 0
}

function cleanup_apt_cache() {
	show_verbose 2 "Cleaning up APT cache"
	if [ -z "$1" ]; then
		apt-get clean
	else
		chroot "$1" apt-get clean
	fi
}

function cleanup_apt_all() {
	show_verbose 2 "Cleaning up all APT files"
	rm -f $1/var/lib/apt/cdroms.list~
	rm -rf $1/var/lib/apt/lists/
	mkdir -p $1/var/lib/apt/lists/partial
	touch $1/var/lib/apt/lists/partial/.delete-me-later
	rm -rf $1/var/cache/apt
	mkdir -p $1/var/cache/apt/archives/partial
}

function cleanup_log_all() {
	show_verbose 2 "Cleaning up log files"
	logfiles="$(find $1/var/log -name '*.[0-9]*')"
	logfiles="$logfiles $(find $1/var/log -name '*.gz')"
	for logfile in $logfiles; do
		show_verbose 3 "Deleting $logfile"
	        rm -f "$logfile"
	done
	for logfile in $(find "$1/var/log" -type f); do
		show_verbose 3 "Truncating $logfile"
		>"$logfile"
	done
}

function cleanup_history() {
	show_verbose 2 "Removing history files of user root"
	rm -f $1/root/.*_history
}

function cleanup_fixed_devices() {
	show_verbose 2 "Cleaning up persistent device assignments"
	rm -f $1/etc/udev/rules.d/70-persistent-cd.rules
	rm -f $1/etc/udev/rules.d/70-persistent-net.rules
}

function cleanup_all() {
	cleanup_apt_cache $1
	cleanup_apt_all $1
	cleanup_log_all $1
	cleanup_history $1
	cleanup_fixed_devices $1
}

function cleanup_environment() {
	show_verbose 1 "Cleaning up installation environment..."
	cleanup_all "${TARGET}/chroot"
}

function verify_environment() {
	if [ -z "$1" ]; then
		TESTPATH=${TARGET}
	else
		TESTPATH=${1}
	fi
	if [ ! -f "${TESTPATH}/uictpl.md5" ]; then
		show_verbose 1 "No integrity checksums found."
		return 0;
	fi
	show_verbose 2 "Testing integrity checksums"
	MD5TEMP=$(mktemp)
	SEDFORMULA="s/ \*/ \*"$(echo -n "$TESTPATH" | sed -e 's/\//\\\//g')"\//g" 
	sed -e "$SEDFORMULA" < "${TESTPATH}/uictpl.md5" > "$MD5TEMP"
	md5sum --quiet -c "$MD5TEMP"
	if [ $? -ne 0 ]; then
		show_warning "Environment integrity error."
		rm "$MD5TEMP"
		return 1
	fi
	rm "$MD5TEMP"
	return 0
}

function test_prereq() {
	if [ -z $(which debootstrap) ]; then
		show_error "Package debootstrap not installed."
		exit 1
	fi
}

function call_hook() {
	if [ -z "$1" ]; then
		return 0
	fi
	show_verbose 3 "Searching hook $1..."
	if [ -x "${TARGET}/hooks/$1" ]; then
		show_verbose 2 "Executing hook $1..."
		source "${TARGET}/hooks/$1"
		test_exec $1
	fi
}

function call_chroot_hook() {
	if [ -z "$1" ]; then
		return 0
	fi
	show_verbose 3 "Searching chroot hook $1..."
	if [ -x "${TARGET}/hooks/$1" ]; then
		show_verbose 2 "Copying chroot hook $1 into the installation environment..."
		cp "${TARGET}/hooks/$1" "${TARGET}/chroot/tmp"
		show_verbose 2 "Executing hook $1..."
		chroot "${TARGET}/chroot" "/tmp/$1"
		test_exec $1
		show_verbose 2 "Removing chroot hook $1 from the installation environment..."
		rm "${TARGET}/chroot/tmp/$1"
	fi
}

function apply_customizations() {
	CUST_SUBDIR=${1:-files}
	KEYS_SUBDIR=${2:-install}
	show_verbose 1 "Applying customizations to the target installation environment..."
	call_hook pre_customization
	call_chroot_hook chroot_pre_customization
	# install files delivered with the template
	show_verbose 2 "Installing custom files from '${CUST_SUBDIR}'"
	cp -a "${TARGET}/${CUST_SUBDIR}/." "${TARGET}/chroot/"
	# remove files as requested by the template
	if [ -f "${TARGET}/${CUST_SUBDIR}.remove" ]; then
		show_verbose 2 "Processing file deletion list ${CUST_SUBDIR}.remove"
		xargs -r -a "${TARGET}/${CUST_SUBDIR}.remove" chroot "${TARGET}/chroot" rm -rf
	fi
	# make sure the essential files are existing
	create_minimal_files
	# install trusted keys from the template, if provided
	if [ -d "${TARGET}/${KEYS_SUBDIR}" ]; then
		show_verbose 2 "Installing supplied signing keys from '${KEYS_SUBDIR}'"
		mkdir -p "${TARGET}/chroot/aptkeys"
		mount -o bind "${TARGET}/${KEYS_SUBDIR}" "${TARGET}/chroot/aptkeys"
		for KEYFILE in $(find "${TARGET}/${KEYS_SUBDIR}" -name '*.key' -printf " %f"); do
			chroot "${TARGET}/chroot" apt-key add /aptkeys/${KEYFILE}
			RESULT=$?
			if [ ${RESULT} -ne 0 ]; then
				umount "${TARGET}/chroot/aptkeys"
				rmdir "${TARGET}/chroot/aptkeys"
				show_error "Failed to install supplied signing key ${KEYFILE}"
				exit ${RESULT}
			fi
		done
		umount "${TARGET}/chroot/aptkeys"
		rmdir "${TARGET}/chroot/aptkeys"
	fi
	call_chroot_hook chroot_post_customization
	call_hook post_customization
}

function process_locales() {
	show_verbose 1 "(Re)initalizing system locales..."
	if [ $(grep -s -i ubuntu "${TARGET}/chroot/etc/lsb-release" | wc -l) != "0" ]; then
		# ubuntu
		chroot "${TARGET}/chroot" dpkg-reconfigure locales
		test_exec chroot chroot ${TARGET}/chroot dpkg-reconfigure locales
	else
		if ! chroot "${TARGET}/chroot" which locale-gen > /dev/null; then
			init_apt_proxy
			chroot "${TARGET}/chroot" apt-get install locales
			test_exec apt-get apt-get install locales
			exit_apt_proxy
		fi
		chroot "${TARGET}/chroot" locale-gen
		test_exec locale-gen
	fi
}

function create_minimal_files() {
	# locale
	if [ $(grep -s -i ubuntu "${TARGET}/chroot/etc/lsb-release" | wc -l) != "0" ]; then
		# ubuntu
		if [ ! -f "${TARGET}/chroot/var/lib/locales/supported.d/local" ]; then
			echo -e "en_US.UTF-8 UTF-8" > "${TARGET}/chroot/var/lib/locales/supported.d/local"
		fi
	else
		if [ ! -f "${TARGET}/chroot/etc/locale.gen" ]; then
			echo -e "en_US.UTF-8 UTF-8" > "${TARGET}/chroot/etc/locale.gen"
		fi
		if [ ! -f "${TARGET}/chroot/etc/default/locale" ]; then
			echo "#  File generated by update-locale" > "${TARGET}/chroot/etc/default/locale"
			echo "LANG=\"en_US.UTF-8\"" >> "${TARGET}/chroot/etc/default/locale"
			echo "LANGUAGE=\"en_US:en\"" >> "${TARGET}/chroot/etc/default/locale"
		fi
	fi
	# hostname
	if [ ! -f "${TARGET}/chroot/etc/hostname" ]; then
		echo $UIC_SRCNAME > "${TARGET}/chroot/etc/hostname"
	fi
	# dns resolution
	if [ ! -f "${TARGET}/chroot/etc/resolv.conf" ]; then
		echo -e "nameserver 208.67.222.222\nnameserver 208.67.220.220" > "${TARGET}/chroot/etc/resolv.conf"
	fi
	# file system table
	if [ ! -f "${TARGET}/chroot/etc/fstab" ]; then
		echo -e "# /etc/fstab: static file system information." > "${TARGET}/chroot/etc/fstab"
		echo -e "#" >> "${TARGET}/chroot/etc/fstab"
		echo -e "# <file system>\t\t\t<mount point>\t<type>\t<options>\t\t\t<dump>\t<pass>" >> "${TARGET}/chroot/etc/fstab"
		echo -e "proc\t\t\t\t/proc\t\tproc\tdefaults\t\t\t0\t0" >> "${TARGET}/chroot/etc/fstab"
		echo -e "" >> "${TARGET}/chroot/etc/fstab"
		echo -e "tmpfs\t\t\t\t/tmp\t\ttmpfs\tdefaults,noatime\t\t0\t0" >> "${TARGET}/chroot/etc/fstab"
		echo -e "tmpfs\t\t\t\t/var/tmp\ttmpfs\tdefaults,noatime\t\t0\t0" >> "${TARGET}/chroot/etc/fstab"
	fi
}

function get_filtered_repository() {
	if [ -z "${UIC_APTPROXY}" ]; then
		echo ${UIC_REPOSITORY}
	else
		echo ${UIC_REPOSITORY} | sed -e "s/http:\/\/[^\/]*/http:\/\/${UIC_APTPROXY}/g"
	fi
}

function init_apt_proxy() {
	if [ -z "${UIC_APTPROXY}" ]; then
		return 0
	fi
	echo -e "Acquire::http { Proxy \"http://${UIC_APTPROXY}\"; };" > "${TARGET}/chroot/etc/apt/apt.conf.d/02uicproxy"
}

function exit_apt_proxy() {
	if [ -f "${TARGET}/chroot/etc/apt/apt.conf.d/02uicproxy" ]; then
		rm -f "${TARGET}/chroot/etc/apt/apt.conf.d/02uicproxy"
	fi
}

function add_ppa() {
	PPA="$1"
	if [ -z "$PPA" ]; then
		show_verbose 1 "No PPA specified"
		return 1
	fi

	# explode the ppa name into user part and area name
	PPA_USER=$(expr match "$PPA" 'ppa:\(.*\)/.*')
	PPA_AREA=$(expr match "$PPA" 'ppa:.*/\(.*\)')

	if [ -z "$PPA_USER" -o -z "$PPA_AREA" ]; then
		show_error "Specified PPA $PPA is not valid"
		exit 3
	fi

	# check if ppa is already installed
	if [ -f "${TARGET}/chroot/etc/apt/sources.list.d/${PPA_USER}-${PPA_AREA}-${UIC_RELEASE}.list" ]; then
		show_verbose 1 "PPA $1 already installed"
		return 0
	fi

	# query the signing key through the launchpad API
	TEMPFILE=$(mktemp)
	wget -q -O $TEMPFILE https://api.launchpad.net/1.0/~$PPA_USER/+archive/$PPA_AREA
	if [ $? -ne 0 ]; then
		wget --no-check-certificate -q -O $TEMPFILE https://api.launchpad.net/1.0/~$PPA_USER/+archive/$PPA_AREA
		ERR=$?
		if [ $ERR -ne 0 ]; then
			show_error "Specified PPA $PPA cannot be queried on launchpad"
			exit $ERR
		fi
	fi
	PPA_INFO=$(sed -e "s/\"//g" < $TEMPFILE)
	rm $TEMPFILE
	PPA_FINGERPRINT=$(expr match "$PPA_INFO" '.*signing_key_fingerprint: \([0-9A-F]*\)')
	if [ -z "$PPA_FINGERPRINT" ]; then
		show_error "Cannot determine signing key for PPA $PPA"
		exit 3
	fi

	# now add the signing key to the APT keyring
	chroot "${TARGET}/chroot" apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $PPA_FINGERPRINT
	test_exec apt-key apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $PPA_FINGERPRINT

	# now create the ppa entries
	echo "# apt sources for ${PPA}" > "${TARGET}/chroot/etc/apt/sources.list.d/${PPA_USER}-${PPA_AREA}-${UIC_RELEASE}.list"
	echo "deb http://ppa.launchpad.net/${PPA_USER}/${PPA_AREA}/ubuntu ${UIC_RELEASE} main" >> "${TARGET}/chroot/etc/apt/sources.list.d/${PPA_USER}-${PPA_AREA}-${UIC_RELEASE}.list"
	echo "deb-src http://ppa.launchpad.net/${PPA_USER}/${PPA_AREA}/ubuntu ${UIC_RELEASE} main" >> "${TARGET}/chroot/etc/apt/sources.list.d/${PPA_USER}-${PPA_AREA}-${UIC_RELEASE}.list"

	return 0
}

function update_sources {
	show_verbose 1 "Updating package sources..."
	chroot "${TARGET}/chroot" apt-get ${QUIET} update
	test_exec chroot apt-get ${QUIET} update
}

function update_system {
	show_verbose 1 "Updating system..."
	chroot ${TARGET}/chroot apt-get ${QUIET} -y upgrade
	test_exec chroot "${TARGET}/chroot" apt-get ${QUIET} -y upgrade
}

function install_ppas {
	if [ -n "$UIC_PPAS" ]; then
		for elem in "$UIC_PPAS"; do
			show_verbose 1 "Adding PPA $elem"
			add_ppa $elem
		done
	fi
}

function install_software {
	if [ -n "$UIC_SOFTWARE" ]; then
		show_verbose 1 "Installing software..."
		chroot "${TARGET}/chroot" apt-get ${QUIET} -y install $UIC_SOFTWARE
		test_exec chroot ${TARGET}/chroot apt-get ${QUIET} -y install $UIC_SOFTWARE
	fi
}

function install_packages {
	if [ -d "${TARGET}/install" ]; then
		show_verbose 1 "Installing supplied packages"
		mkdir -p "${TARGET}/chroot/install"
		mount -o bind "${TARGET}/install" "${TARGET}/chroot/install"
		chroot "${TARGET}/chroot" dpkg --recursive --install /install
		RESULT=$?
		umount "${TARGET}/chroot/install"
		rmdir "${TARGET}/chroot/install"
		case ${RESULT} in
		0)	;;
		1)	chroot "${TARGET}/chroot" apt-get ${QUIET} -y -f install
			test_exec chroot "${TARGET}/chroot" apt-get ${QUIET} -y -f install
			;;
		2)	;;
		*)	show_error "Failed to install additional packages ($result)"
			exit ${RESULT}
			;;
		esac
	fi
}

function install_kernel {
	if [ -n "${UIC_KERNEL}" ]; then
		show_verbose 1 "Installing kernel..."
		chroot "${TARGET}/chroot" apt-get ${QUIET} -y install ${UIC_KERNEL}
		test_exec chroot ${TARGET}/chroot apt-get ${QUIET} -y install ${UIC_KERNEL}
	fi
}