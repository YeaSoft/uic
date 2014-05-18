Unified Installation Creator - Release Notes
============================================

Release Scope
-------------

By implementing the possibility to seamlessly add any package repository from
a template, UIC has discarded the last dependency to Ubuntu's infrastructure
allowing the development of templates for different distributions with minimal
differences.

The addition of some new template settings and a dramatically improved
autogenerator of essential files and settings notably simplifies many
templates by making many customisations in the /file section superfluous.

The compatibility between the build system and the target system is now
checked against the effective capabilities of the system.

After two years of internal use, the project is now getting more mature and
therefore the project will be maintained on GitHub starting from now.


What's new in Version 0.16.6 (2014-05-16)
-----------------------------------------

  * Feature: Support encrypted passwords in `UIC_ROOTPASSWORD` by
    specifying `UIC_ROOTPASSWORD=SHADOW:$6$HnFcw.Hb$G5.....`
  * Feature: improved and streamlined `/etc/fstab` autogeneration
  * Feature: Configuration of target hostname via `UIC_HOSTNAME` will
    replace most customised files in `/files`
  * Feature: Locale `en_US.UTF-8` will now be configured by default
    (no need any more to supply adapted files)
  * Feature: Resolver file `/etc/resolv.conf` will always be automatically
    created if no custom resolver is supplied via `/files`
  * Feature: Automatically created resolver file `/etc/resolv.conf` will
    be based on data stored in `UIC_PUBLICDNS`
  * Feature: Add support for installing trusted keys for external
    repositories from the `/install` directory (Closes #2)
  * Feature: release compatibility is now tested towards the
    distributions supported by `debootstrap` (Closes #3)
  * Feature: New commands for direct installation/purge of
    packages (Closes #4)
  * Feature: Added `-e` option to `uic_get` to enter directly
    the installation area (Closes #5)
  * Feature: Added template compatibility check (Closes #6)
  * Feature: decent `/etc/apt/sources.list` autocreated by uic if not
    supplied via `/files`
  * Fix: improved APT proxy handling
  * Fix: `debootstrap` errors are now detected and cause `uic_create`
    to stop further processing (Closes 8)
  * Fix: The variables `UIC_WORKDIR`, `UIC_APTPROXY` and `UIC_REPOSITORIES`
    are not overwritten by initialisation if they are already defined
    in the environment (Closes #9)
  * Fix: Special file systems in environment are now unmounted with
    any target path specification on the commandline (Closes #10)

Known Problems
--------------

 * During the execution of `uic_create` and `uic_upgrade` it may still happen that
   some process is started in the chroot by the package manager preventing the
   special filesystems to be unmounted. This has been observed specifically
   with projects based on Ubuntu 10.04.
   This can be circumvented with a workaround stopping all possibly affected
   services in the hook script `chroot_post_installation`.


Release History
---------------

### Version 0.15 released on 2013-03-14 ###

  * Feature: added support for debian 7 (wheezy)
  * Feature: new command uic install permits the direct installation of
    packages into the installation environment
  * Fix: PPA can now also be installed if the certificate of the launchpad
    site cannot be verified
  * Feature: uic prepare has been renamed to uic get since this name
    describes better the function from the user's point of view
  * Feature: new function of uic get to list all templates available
    on the repositories

### Version 0.14 released on 2012-05-23 ###

 * Fix: dpkg unattended setup/update was not working for older ubuntu
   versions
 * Fix: compatibility matrix prevented installation of debian from
   ubuntu lucid and maverick
 * Fix: uic pack now creates a clean .md5 file without any path component
 * Fix: uic create and uic upgrade should not ask any more for user input
   when trying to overwrite modified configuration files from the uic template
 * Fix: file customizations are re-applied at the end of uic create and uic
   upgrade since sometimes package update or installation overwrite files
   without asking
 * Fix: verbosity of apt is now dependant upon the uic verbosity level
 * Fix: compatibility checking prevents running uic on unsupported platforms
   or with templates with targets not compatible with the hosting system

### Version 0.13 released on 2012-05-22 ###

 * Fix: uic pack now creates a clean .md5 file without any path component
 * Fix: uic create and uic upgrade should not ask any more for user input
   when trying to overwrite modified configuration files from the uic template
 * Fix: file customizations are re-applied at the end of uic create and uic
   upgrade since sometimes package update or installation overwrite files
   without asking
 * Fix: verbosity of apt is now dependant upon the uic verbosity level
 * Fix: compatibility checking prevents running uic on unsupported platforms
   or with templates with targets not compatible with the hosting system

### Version 0.12 released on 2012-05-11 ###

  * Fix: working dir is created in uic attach if not existent
  * Feature: uic_build can now accept a comma separated list of build steps
  * Fix: fixed uic_create that did not take in consideration lost+found when
    testing the working dir for emptiness
  * Feature: new template option UIC_PREINSTALL permits to define additional
    packages to install during debootstrap (e.g. all packages that need
    reconfiguration). WARNING: this feature works only in uic_create but not
    in uic_upgrade -I

### Version 0.11 released on 2012-05-09 ###

  * Fix: made deb package compatible with ubuntu hardy
  * Fix: added missing commands uic_attach and uic_detach to
    deb package

### Version 0.10 released on 2012-05-09 ###

  * Feature: Added support for Debian squeeze
  * Feature: Added support for installing bundled .deb packages
  * Feature: New build step "report" creates an installation report
  * Feature: New build step "archive" produces an archive of the root
    filesystem
  * Fix: binary package architecture set to "all"
  * Fix: remove debris (/run/shm on /run/shm) in mount table after
    operations requiring special fs mounts
  * Fix: reconfigure steps are not mandatory any more (UIC_RECONFIGURE
    can be left empty)
  * Fix: locales are regenerated also on uic_upgrade

### Version 0.09 released on 2012-04-29 ###

  * Added support for launchpad PPA through UIC_PPAS in uictpl.conf

### Version 0.08 not released (only for internal use) ###

  * Critical Fix: Fixed a serious bug (missing chroot) in processing
    file remove lists during the customization phase. This bug could
    in certain cases compromise the host system.
  * Added new commands uic_attach and uic_detach
  * Updated version numbers and release numbers in man pages

### Version 0.07 released on 2012-04-17 ###

  * Added missing command uic_clean
  * Added missing APT proxy support to uic_upgrade
  * Added missing options to /etc/uic.conf

### Version 0.05 released on 2012-03-26 ###

  * First public release
