#! /usr/bin/env bash
set -euxo pipefail

# no args, run as root
(( ! $# )) && (( ! "$UID" ))

# nicer priority
renice -n +19 "$$"

# close stdin, not that it will help
exec 0<&-



# II. Preparing for the Build
# 2. Preparing the Host System
# 2.6. Setting The $LFS Variable
export LFS="${LFS:-/mnt/lfs}" # ACHTUNG! untested
# 4.5. About SBUs
export MAKEFLAGS="${MAKEFLAGS:--j $(nproc)}"
# 4.6. About the Test Suites
export TEST="${TEST:-0}"

# TODO host system requirements
# 2.2. Host System Requirements



function clean_lfs {
  # cleanup everything but /mnt/lfs/sources
  ( GLOBIGNORE="$LFS/sources:$LFS/repos:$LFS/musl:$LFS/musl-build"
  rm -rf "$LFS"/* )

  # remove possibly partially built tools
  #rm -rf "$LFS/tools" "$LFS/build"
  rm -vf      /tools

  return $?
}
clean_lfs



# 3. Packages and Patches
# 3.1. Introduction
$SHELL -euxo pipefail 3_1_introduction



# check for tools backup
if [[ ! -e /tools.tar.lrz.zpaq ]] ; then

  # 4.2. Creating the $LFS/tools Directory
  #mkdir -v "$LFS/tools" "$LFS/build"
  mkdir -v "$LFS/tools"
  ln   -sv "$LFS/tools" /



  #find /mnt/lfs/sources -mindepth 1 \! -name wget-list \! -name md5sums |
  #xargs -I% $SHELL -euo pipefail -c \
  #  'ln -s "$LFS/sources/`basename %`" "$LFS/build/`basename %`"'
  function create_builddir {
    mkdir -v "$LFS/build"

    find $LFS/sources -mindepth 1 \! -name wget-list \! -name md5sums |
    xargs -I% $SHELL -euo pipefail -c \
      'ln -s "$LFS/sources/`basename %`" "$LFS/build/`basename %`"'

    return $?
  }
  create_builddir

  # delete possibly-existing user and group
  function clean_user {
    deluser --remove-home lfs || :
    delgroup lfs              || :
  }
  clean_user



  # 4.3. Adding the LFS User
  groupadd lfs
  useradd -s /bin/bash -g lfs -m -k /dev/null lfs

  { echo defaultpw ; echo defaultpw ; } | passwd lfs

  chown -v lfs $LFS/tools

  #chown -v lfs $LFS/sources

  chown -R lfs  $LFS/build
  chmod 0777    $LFS/build
  #chmod 0444    $LFS/build/*
  chmod -v a+wt $LFS/build



  #unbuffer -p \
    su - lfs < 4_4_setting_up_the_environment

  # 4.5. About SBUs
  echo "echo export MAKEFLAGS=\'$MAKEFLAGS\' >> ~/.bashrc" |
  script /dev/null -e -c 'su - lfs'
# << EOF
#  echo export MAKEFLAGS='"$MAKEFLAGS"' >> ~/.bashrc
#EOF

  # 4.6. About the Test Suites
  echo "echo export TEST=\'$TEST\' >> ~/.bashrc" |
  script /dev/null -e -c 'su - lfs'
#<< EOF
#  echo export TEST='"$TEST"' >> ~/.bashrc
#EOF

  # 5.3. General Compilation Instructions
  echo 'echo $LFS | grep /mnt/lfs' |
  script /dev/null -e -c 'su - lfs'

  # sanity check
  echo 'echo $MAKEFLAGS | grep -e -j' |
  script /dev/null -e -c 'su - lfs'

  echo 'echo $TEST | grep '"$TEST" |
  script /dev/null -e -c 'su - lfs'

  # Chapter 5. Constructing a Temporary System

  function ch5 {
    (( $# == 2  ||  $# == 3 ))
    { echo PKG="$1" ;
      (( $# != 3 ))   ||
      echo DIR="$3"   ;
      cat 5_3_general_compilation_instructions \
          "$2"        ;
      echo exit '$?'  ;
      echo exit '$?'  ; } |
    #unbuffer -p \
      script /dev/null -e -f -c 'su - lfs'
    return $?
  }

  #{ echo PKG=binutils-2.34.tar.xz            ;
  #  echo 'echo $PKG | grep binutils'         ;
  #  cat 5_3_general_compilation_instructions \
  #      5_4_binutils_pass_1              ; } |
  #script /dev/null -e -c 'su - lfs'

  for pkg in \
    'binutils-2.34.tar.xz    5_4_binutils_pass_1'    \
    'gcc-9.2.0.tar.xz        5_5_gcc_pass_1'         \
    'linux-5.5.3.tar.xz      5_6_linux_api_headers'  \
    'glibc-2.31.tar.xz       5_7_glibc'              \
    'gcc-9.2.0.tar.xz        5_8_libstdc++'          \
    'binutils-2.34.tar.xz    5_9_binutils_pass_2'    \
    'gcc-9.2.0.tar.xz        5_10_gcc_pass_2'        \
    'tcl8.6.10-src.tar.gz    5_11_tcl     tcl8.6.10' \
    'expect5.45.4.tar.gz     5_12_expect'            \
    'dejagnu-1.6.2.tar.gz    5_13_dejagnu'           \
    'm4-1.4.18.tar.xz        5_14_m4'                \
    'ncurses-6.2.tar.gz      5_15_ncurses'           \
    'bash-5.0.tar.gz         5_16_bash'              \
    'bison-3.5.2.tar.xz      5_17_bison'             \
    'bzip2-1.0.8.tar.gz      5_18_bzip2'             \
    'coreutils-8.31.tar.xz   5_19_coreutils'         \
    'diffutils-3.7.tar.xz    5_20_diffutils'         \
    'file-5.38.tar.gz        5_21_file'              \
    'findutils-4.7.0.tar.xz  5_22_findutils'         \
    'gawk-5.0.1.tar.xz       5_23_gawk'              \
    'gettext-0.20.1.tar.xz   5_24_gettext'           \
    'grep-3.4.tar.xz         5_25_grep'              \
    'gzip-1.10.tar.xz        5_26_gzip'              \
    'make-4.3.tar.gz         5_27_make'              \
    'patch-2.7.6.tar.xz      5_28_patch'             \
    'perl-5.30.1.tar.xz      5_29_perl'              \
    'Python-3.8.1.tar.xz     5_30_python'            \
    'sed-4.8.tar.xz          5_31_sed'               \
    'tar-1.32.tar.xz         5_32_tar'               \
    'texinfo-6.7.tar.xz      5_33_texinfo'           \
    'xz-5.2.4.tar.xz         5_34_xz'
  do ch5 $pkg || exit $? ; done

  # 5.35. Stripping
  { cat 5_35_stripping ;
    echo exit '$?'     ; } |
  script /dev/null -e -c 'su - lfs'

  # 5.36. Changing Ownership
  $SHELL -euxo pipefail 5_36_changing_ownership

  # delete user and group
  #deluser --remove-home lfs || :
  #delgroup lfs              || :
  clean_user

  # create tools backup
  #( trap 'rm -f tools.tar.lrz' 0
  #  tar cf - "/tools" "$LFS/tools" | lrzip -n > tools.tar.lrz
  #  zpaq c /tools.tar.lrz.zpaq tools.tar.lrz )
  tar cf /tools.tar.lrz.zpaq -I 'lrzip -U -n -z' "/tools" "$LFS/tools"

  #( GLOBIGNORE="$LFS/sources"
  #rm -rf "$LFS"/* )
  ##rm -rf "$LFS/tools" "$LFS/build"
  #rm -vf      /tools
  clean_lfs
fi

# extract tools backup
#( trap 'rm -f tools.tar.lrz' 0
#  zpaq x /tools.tar.lrz.zpaq
#  lrzip -d < tools.tar.lrz | tar xf - -C / )
tar xf /tools.tar.lrz.zpaq -I 'lrzip -U -n -z' -C /

function create_builddir {
  mkdir -v "$LFS/build"

  find $LFS/sources -mindepth 1 \! -name wget-list \! -name md5sums |
  xargs -I% $SHELL -euo pipefail -c \
    'ln -s "/sources/`basename %`" "$LFS/build/`basename %`"'

  return $?
}
create_builddir

function umount_kern_filesys {
  umount $LFS/dev/pts
  umount $LFS/dev
  umount $LFS/run
  umount $LFS/sys
  umount $LFS/proc
  #rm $LFS/dev/null
  #rm $LFS/dev/console
  #rmdir $LFS/$(readlink $LFS/dev/shm)
  #rmdir $LFS/{dev,proc,sys,run}
}
umount_kern_filesys || :



# III. Building the LFS System
# 6. Installing Basic System Software

# 6.2. Preparing Virtual Kernel File Systems
trap umount_kern_filesys 0
$SHELL -euxo pipefail 6_2_preparing_virtual_kernel_file_systems

# 6.5. Creating Directories
chroot "$LFS" /tools/bin/env -i                 \
  HOME=/root                                    \
  TERM="$TERM"                                  \
  PS1='(lfs chroot) \u:\w\$ '                   \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
  /tools/bin/bash --login +h < 6_5_creating_directories

# 6.6. Creating Essential Files and Symlinks
chroot "$LFS" /tools/bin/env -i                 \
  HOME=/root                                    \
  TERM="$TERM"                                  \
  PS1='(lfs chroot) \u:\w\$ '                   \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
  /tools/bin/bash --login +h < 6_6_creating_essential_files_and_symlinks



function ch6 {
  (( $# == 2  ||  $# == 3 ))
  { echo export TEST="$TEST"           ;
    echo export MAKEFLAGS="$MAKEFLAGS" ;
    echo PKG="$1"                      ;
    (( $# != 3 ))                     ||
    echo DIR="$3"                      ;
    cat 6_general_compilation_instructions \
        "$2"                           ;
    echo exit '$?'                     ;
    echo exit '$?'                     ; } |
  chroot "$LFS" /tools/bin/env -i                 \
    HOME=/root                                    \
    TERM="$TERM"                                  \
    PS1='(lfs chroot) \u:\w\$ '                   \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h
  return $?
}

for pkg in \
  'linux-5.5.3.tar.xz    6_7_linux_api_headers' \
  'man-pages-5.05.tar.xz 6_8_manpages'          \
  'glibc-2.31.tar.xz     6_9_glibc'
do ch6 $pkg || exit $? ; done



# 6.10. Adjusting the Toolchain
chroot "$LFS" /tools/bin/env -i                 \
  HOME=/root                                    \
  TERM="$TERM"                                  \
  PS1='(lfs chroot) \u:\w\$ '                   \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
  /tools/bin/bash --login +h < 6_10_adjusting_the_toolchain



for pkg in \
  'zlib-1.2.11.tar.xz       6_11_zlib'        \
  'bzip2-1.0.8.tar.gz       6_12_bzip2'       \
  'xz-5.2.4.tar.xz          6_13_xz'          \
  'file-5.38.tar.gz         6_14_file'        \
  'readline-8.0.tar.gz      6_15_readline'    \
  'm4-1.4.18.tar.xz         6_16_m4'          \
  'bc-2.5.3.tar.gz          6_17_bc'          \
  'binutils-2.34.tar.xz     6_18_binutils'    \
  'gmp-6.2.0.tar.xz         6_19_gmp'         \
  'mpfr-4.0.2.tar.xz        6_20_mpfr'        \
  'mpc-1.1.0.tar.gz         6_21_mpc'         \
  'attr-2.4.48.tar.gz       6_22_attr'        \
  'acl-2.2.53.tar.gz        6_23_acl'         \
  'shadow-4.8.1.tar.xz      6_24_shadow'      \
  'gcc-9.2.0.tar.xz         6_25_gcc'         \
  'pkg-config-0.29.2.tar.gz 6_26_pkgconfig'   \
  'ncurses-6.2.tar.gz       6_27_ncurses'     \
  'libcap-2.31.tar.xz       6_28_libcap'      \
  'sed-4.8.tar.xz           6_29_sed'         \
  'psmisc-23.2.tar.xz       6_30_psmisc'      \
  'iana-etc-2.30.tar.bz2    6_31_iana_etc'    \
  'bison-3.5.2.tar.xz       6_32_bison'       \
  'flex-2.6.4.tar.gz        6_33_flex'        \
  'grep-3.4.tar.xz          6_34_grep'        \
  'bash-5.0.tar.gz          6_35_bash'        \
  'libtool-2.4.6.tar.xz     6_36_libtool'     \
  'gdbm-1.18.1.tar.gz       6_37_gdbm'        \
  'gperf-3.1.tar.gz         6_38_gperf'       \
  'expat-2.2.9.tar.xz       6_39_expat'       \
  'inetutils-1.9.4.tar.xz   6_40_inetutils'   \
  'perl-5.30.1.tar.xz       6_41_perl'        \
  'XML-Parser-2.46.tar.gz   6_42_xml_parser'  \
  'intltool-0.51.0.tar.gz   6_43_intltool'    \
  'autoconf-2.69.tar.xz     6_44_autoconf'    \
  'automake-1.16.1.tar.xz   6_45_automake'    \
  'kmod-26.tar.xz           6_46_kmod'        \
  'gettext-0.20.1.tar.xz    6_47_gettext'     \
  'elfutils-0.178.tar.bz2   6_48_libelf'      \
  'libffi-3.3.tar.gz        6_49_libffi'      \
  'openssl-1.1.1d.tar.gz    6_50_openssl'     \
  'Python-3.8.1.tar.xz      6_51_python'      \
  'ninja-1.10.0.tar.gz      6_52_ninja'       \
  'meson-0.53.1.tar.gz      6_53_meson'       \
  'coreutils-8.31.tar.xz    6_54_coreutils'   \
  'check-0.14.0.tar.gz      6_55_check'       \
  'diffutils-3.7.tar.xz     6_56_diffutils'   \
  'gawk-5.0.1.tar.xz        6_57_gawk'        \
  'findutils-4.7.0.tar.xz   6_58_findutils'   \
  'groff-1.22.4.tar.gz      6_59_groff'       \
  'grub-2.04.tar.xz         6_60_grub'        \
  'less-551.tar.gz          6_61_less'        \
  'gzip-1.10.tar.xz         6_62_gzip'        \
  'zstd-1.4.4.tar.gz        6_63_zstd'        \
  'iproute2-5.5.0.tar.xz    6_64_iproute2'    \
  'kbd-2.2.0.tar.xz         6_65_kbd'         \
  'libpipeline-1.5.2.tar.gz 6_66_libpipeline' \
  'make-4.3.tar.gz          6_67_make'        \
  'patch-2.7.6.tar.xz       6_68_patch'       \
  'man-db-2.9.0.tar.xz      6_69_mandb'       \
  'tar-1.32.tar.xz          6_70_tar'         \
  'texinfo-6.7.tar.xz       6_71_texinfo'     \
  'vim-8.2.0190.tar.gz      6_72_vim'         \
  'procps-ng-3.3.15.tar.xz  6_73_procps_ng'   \
  'util-linux-2.35.1.tar.xz 6_74_util_linux'  \
  'e2fsprogs-1.45.5.tar.gz  6_75_e2fsprogs'   \
  'sysklogd-1.5.1.tar.gz    6_76_sysklogd'    \
  'sysvinit-2.96.tar.xz     6_77_sysvinit'    \
  'eudev-3.2.9.tar.gz       6_78_eudev'
do ch6 $pkg || exit $? ; done



# 6.80. Stripping Again
chroot "$LFS" /tools/bin/env -i                 \
  HOME=/root                                    \
  TERM="$TERM"                                  \
  PS1='(lfs chroot) \u:\w\$ '                   \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
  /tools/bin/bash --login +h < 6_80_stripping_again



# 6.81. Cleaning Up
echo 'rm -rf /tmp/*' |
chroot "$LFS" /tools/bin/env -i                 \
  HOME=/root                                    \
  TERM="$TERM"                                  \
  PS1='(lfs chroot) \u:\w\$ '                   \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
  /tools/bin/bash --login +h

chroot "$LFS" /usr/bin/env -i        \
  HOME=/root TERM="$TERM"            \
  PS1='(lfs chroot) \u:\w\$ '        \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin \
  /bin/bash --login << "EOF"
  rm -f /usr/lib/lib{bfd,opcodes}.a
  rm -f /usr/lib/libbz2.a
  rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
  rm -f /usr/lib/libltdl.a
  rm -f /usr/lib/libfl.a
  rm -f /usr/lib/libz.a

  find /usr/lib /usr/libexec -name \*.la -delete
EOF



function ch7 {
  (( $# == 2  ||  $# == 3 ))
  { echo export TEST="$TEST"           ;
    echo export MAKEFLAGS="$MAKEFLAGS" ;
    echo PKG="$1"                      ;
    (( $# != 3 ))                     ||
    echo DIR="$3"                      ;
    cat 6_general_compilation_instructions \
        "$2"                           ;
    echo exit '$?'                     ;
    echo exit '$?'                     ; } |
  chroot "$LFS" /usr/bin/env -i        \
    HOME=/root TERM="$TERM"            \
    PS1='(lfs chroot) \u:\w\$ '        \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login
  return $?
}

# 7. System Configuration
# 7.2. LFS-Bootscripts-20191031 
ch7 lfs-bootscripts-20191031.tar.xz 7_2_lfs_bootscripts

# 7.4. Managing Devices
chroot "$LFS" /usr/bin/env -i        \
  HOME=/root TERM="$TERM"            \
  PS1='(lfs chroot) \u:\w\$ '        \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin \
  /bin/bash --login < 7_4_managing_devices

# 7.5. General Network Configuration
chroot "$LFS" /usr/bin/env -i        \
  HOME=/root TERM="$TERM"            \
  PS1='(lfs chroot) \u:\w\$ '        \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin \
  /bin/bash --login < 7_5_general_network_configuration

# 7.6. System V Bootscript Usage and Configuration
chroot "$LFS" /usr/bin/env -i        \
  HOME=/root TERM="$TERM"            \
  PS1='(lfs chroot) \u:\w\$ '        \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin \
  /bin/bash --login < 7_6_system_v_bootscript_usage_and_configuration

# 7.7. The Bash Shell Startup Files
chroot "$LFS" /usr/bin/env -i        \
  HOME=/root TERM="$TERM"            \
  PS1='(lfs chroot) \u:\w\$ '        \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin \
  /bin/bash --login < 7_7_bash_shell_startup_files

# 7.8. Creating the /etc/inputrc File
chroot "$LFS" /usr/bin/env -i        \
  HOME=/root TERM="$TERM"            \
  PS1='(lfs chroot) \u:\w\$ '        \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin \
  /bin/bash --login < 7_8_creating_the_inputrc_file

# 7.9. Creating the /etc/shells File
chroot "$LFS" /usr/bin/env -i        \
  HOME=/root TERM="$TERM"            \
  PS1='(lfs chroot) \u:\w\$ '        \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin \
  /bin/bash --login < 7_9_creating_the_shells_file

# 8. Making the LFS System Bootable

# 8.2. Creating the /etc/fstab File
chroot "$LFS" /usr/bin/env -i        \
  HOME=/root TERM="$TERM"            \
  PS1='(lfs chroot) \u:\w\$ '        \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin \
  /bin/bash --login < 8_2_creating_the_fstab_file

# 8.3. Linux-5.5.3
ch7 linux-5.5.3.tar.xz 8_3_linux

# 8.4. Using GRUB to Set Up the Boot Process
chroot "$LFS" /usr/bin/env -i        \
  HOME=/root TERM="$TERM"            \
  PS1='(lfs chroot) \u:\w\$ '        \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin \
  /bin/bash --login < 8_4_using_grub_to_set_up_the_boot_process

# 9. The End
# 9.1. The End
chroot "$LFS" /usr/bin/env -i        \
  HOME=/root TERM="$TERM"            \
  PS1='(lfs chroot) \u:\w\$ '        \
  PATH=/bin:/usr/bin:/sbin:/usr/sbin \
  /bin/bash --login < 9_1_the_end

# 9.2. Get Counted
xdg-open http://www.linuxfromscratch.org/cgi-bin/lfscounter.php

# 9.3. Rebooting the System
umount_kern_filesys
trap '' 0

# TODO install books
# TODO blfs
