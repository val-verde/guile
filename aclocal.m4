dnl aclocal.m4 generated automatically by aclocal 1.2c

dnl Copyright (C) 1994, 1995, 1996, 1997 Free Software Foundation, Inc.
dnl This Makefile.in is free software; the Free Software Foundation
dnl gives unlimited permission to copy and/or distribute it,
dnl with or without modifications, as long as this notice is preserved.

dnl This program is distributed in the hope that it will be useful,
dnl but WITHOUT ANY WARRANTY, to the extent permitted by law; without
dnl even the implied warranty of MERCHANTABILITY or FITNESS FOR A
dnl PARTICULAR PURPOSE.

dnl  On the NeXT, #including <utime.h> doesn't give you a definition for
dnl  struct utime, unless you #define _POSIX_SOURCE.

AC_DEFUN(GUILE_STRUCT_UTIMBUF, [
  AC_CACHE_CHECK([whether we need POSIX to get struct utimbuf],
    guile_cv_struct_utimbuf_needs_posix,
    [AC_TRY_CPP([
#ifdef __EMX__
#include <sys/utime.h>
#else
#include <utime.h>
#endif
struct utime blah;
],
                guile_cv_struct_utimbuf_needs_posix=no,
		guile_cv_struct_utimbuf_needs_posix=yes)])
  if test "$guile_cv_struct_utimbuf_needs_posix" = yes; then
     AC_DEFINE(UTIMBUF_NEEDS_POSIX)
  fi])




dnl
dnl Apparently, at CMU they have a weird version of libc.h that is
dnl installed in /usr/local/include and conflicts with unistd.h.
dnl In these situations, we should not #include libc.h.
dnl This test arranges to #define LIBC_H_WITH_UNISTD_H iff libc.h is
dnl present on the system, and is safe to #include.
dnl
AC_DEFUN([GUILE_HEADER_LIBC_WITH_UNISTD],
  [
    AC_CHECK_HEADERS(libc.h unistd.h)
    AC_CACHE_CHECK(
      "whether libc.h and unistd.h can be included together",
      guile_cv_header_libc_with_unistd,
      [
        if test "$ac_cv_header_libc_h" = "no"; then
          guile_cv_header_libc_with_unistd="no"
        elif test "$ac_cv_header_unistd.h" = "no"; then
          guile_cv_header_libc_with_unistd="yes"
        else
          AC_TRY_COMPILE(
	    [
#             include <libc.h>
#             include <unistd.h>
	    ],
	    [],
	    [guile_cv_header_libc_with_unistd=yes],
	    [guile_cv_header_libc_with_unistd=no]
          )
        fi
      ]
    )
    if test "$guile_cv_header_libc_with_unistd" = yes; then
      AC_DEFINE(LIBC_H_WITH_UNISTD_H)
    fi
  ]
)



dnl This is needed when we want to check for the same function repeatedly
dnl with other parameters, such as libraries, varying.
dnl
dnl GUILE_NAMED_CHECK_FUNC(FUNCTION, TESTNAME,
dnl                        [ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND]])
AC_DEFUN(GUILE_NAMED_CHECK_FUNC,
[AC_MSG_CHECKING([for $1])
AC_CACHE_VAL(ac_cv_func_$1_$2,
[AC_TRY_LINK(
dnl Don't include <ctype.h> because on OSF/1 3.0 it includes <sys/types.h>
dnl which includes <sys/select.h> which contains a prototype for
dnl select.  Similarly for bzero.
[/* System header to define __stub macros and hopefully few prototypes,
    which can conflict with char $1(); below.  */
#include <assert.h>
/* Override any gcc2 internal prototype to avoid an error.  */
]ifelse(AC_LANG, CPLUSPLUS, [#ifdef __cplusplus
extern "C"
#endif
])dnl
[/* We use char because int might match the return type of a gcc2
    builtin and then its argument prototype would still apply.  */
char $1();
], [
/* The GNU C library defines this for functions which it implements
    to always fail with ENOSYS.  Some functions are actually named
    something starting with __ and the normal name is an alias.  */
#if defined (__stub_$1) || defined (__stub___$1)
choke me
#else
$1();
#endif
], eval "ac_cv_func_$1_$2=yes", eval "ac_cv_func_$1_$2=no")])
if eval "test \"`echo '$ac_cv_func_'$1'_'$2`\" = yes"; then
  AC_MSG_RESULT(yes)
  ifelse([$3], , :, [$3])
else
  AC_MSG_RESULT(no)
ifelse([$4], , , [$4
])dnl
fi
])



dnl Check checks whether dlsym (if present) requires a leading underscore.
dnl Written by Dan Hagerty <hag@ai.mit.edu> for scsh-0.5.0.
AC_DEFUN(GUILE_DLSYM_USCORE, [
  AC_MSG_CHECKING(for underscore before symbols)
  AC_CACHE_VAL(guile_cv_uscore,[
    echo "main(){int i=1;}
    fnord(){int i=23; int ltuae=42;}" > conftest.c
    ${CC} conftest.c > /dev/null
    if (nm a.out | grep _fnord) > /dev/null; then
      guile_cv_uscore=yes
    else
      guile_cv_uscore=no
    fi])
  AC_MSG_RESULT($guile_cv_uscore)
  rm -f conftest.c a.out

  if test $guile_cv_uscore = yes; then
    AC_DEFINE(USCORE)

    if test $ac_cv_func_dlopen = yes -o $ac_cv_lib_dl_dlopen = yes ; then
	AC_MSG_CHECKING(whether dlsym always adds an underscore for us)
	AC_CACHE_VAL(guile_cv_dlsym_adds_uscore,AC_TRY_RUN( [
#include <dlfcn.h>
#include <stdio.h>
fnord() { int i=42;}
main() { void *self, *ptr1, *ptr2; self=dlopen(NULL,RTLD_LAZY);
    if(self) { ptr1=dlsym(self,"fnord"); ptr2=dlsym(self,"_fnord");
    if(ptr1 && !ptr2) exit(0); } exit(1); } 
], [guile_cv_dlsym_adds_uscore=yes
	AC_DEFINE(DLSYM_ADDS_USCORE) ], guile_cv_dlsym_adds_uscore=no,
	guile_cv_dlsym_adds_uscore=no))

        AC_MSG_RESULT($guile_cv_dlsym_adds_uscore)
    fi
  fi
])

# Do all the work for Automake.  This macro actually does too much --
# some checks are only needed if your package does certain things.
# But this isn't really a big deal.

# serial 1

dnl Usage:
dnl AM_INIT_AUTOMAKE(package,version, [no-define])

AC_DEFUN(AM_INIT_AUTOMAKE,
[AC_REQUIRE([AM_PROG_INSTALL])
PACKAGE=[$1]
AC_SUBST(PACKAGE)
VERSION=[$2]
AC_SUBST(VERSION)
dnl test to see if srcdir already configured
if test "`cd $srcdir && pwd`" != "`pwd`" && test -f $srcdir/config.status; then
  AC_MSG_ERROR([source directory already configured; run "make distclean" there first])
fi
ifelse([$3],,
AC_DEFINE_UNQUOTED(PACKAGE, "$PACKAGE")
AC_DEFINE_UNQUOTED(VERSION, "$VERSION"))
AM_SANITY_CHECK
AC_ARG_PROGRAM
dnl FIXME This is truly gross.
missing_dir=`cd $ac_aux_dir && pwd`
AM_MISSING_PROG(ACLOCAL, aclocal, $missing_dir)
AM_MISSING_PROG(AUTOCONF, autoconf, $missing_dir)
AM_MISSING_PROG(AUTOMAKE, automake, $missing_dir)
AM_MISSING_PROG(AUTOHEADER, autoheader, $missing_dir)
AM_MISSING_PROG(MAKEINFO, makeinfo, $missing_dir)
AC_PROG_MAKE_SET])


# serial 1

AC_DEFUN(AM_PROG_INSTALL,
[AC_REQUIRE([AC_PROG_INSTALL])
test -z "$INSTALL_SCRIPT" && INSTALL_SCRIPT='${INSTALL_PROGRAM}'
AC_SUBST(INSTALL_SCRIPT)dnl
])

#
# Check to make sure that the build environment is sane.
#

AC_DEFUN(AM_SANITY_CHECK,
[AC_MSG_CHECKING([whether build environment is sane])
# Just in case
sleep 1
echo timestamp > conftestfile
# Do `set' in a subshell so we don't clobber the current shell's
# arguments.  Must try -L first in case configure is actually a
# symlink; some systems play weird games with the mod time of symlinks
# (eg FreeBSD returns the mod time of the symlink's containing
# directory).
if (
   set X `ls -Lt $srcdir/configure conftestfile 2> /dev/null`
   if test "[$]*" = "X"; then
      # -L didn't work.
      set X `ls -t $srcdir/configure conftestfile`
   fi
   test "[$]2" = conftestfile
   )
then
   # Ok.
   :
else
   AC_MSG_ERROR([newly created file is older than distributed files!
Check your system clock])
fi
rm -f conftest*
AC_MSG_RESULT(yes)])

dnl AM_MISSING_PROG(NAME, PROGRAM, DIRECTORY)
dnl The program must properly implement --version.
AC_DEFUN(AM_MISSING_PROG,
[AC_MSG_CHECKING(for working $2)
# Run test in a subshell; some versions of sh will print an error if
# an executable is not found, even if stderr is redirected.
# Redirect stdin to placate older versions of autoconf.  Sigh.
if ($2 --version) < /dev/null > /dev/null 2>&1; then
   $1=$2
   AC_MSG_RESULT(found)
else
   $1="$3/missing $2"
   AC_MSG_RESULT(missing)
fi
AC_SUBST($1)])

# Add --enable-maintainer-mode option to configure.
# From Jim Meyering

# serial 1

AC_DEFUN(AM_MAINTAINER_MODE,
[AC_MSG_CHECKING([whether to enable maintainer-specific portions of Makefiles])
  dnl maintainer-mode is disabled by default
  AC_ARG_ENABLE(maintainer-mode,
[  --enable-maintainer-mode enable make rules and dependencies not useful
                          (and sometimes confusing) to the casual installer],
      USE_MAINTAINER_MODE=$enableval,
      USE_MAINTAINER_MODE=no)
  AC_MSG_RESULT($USE_MAINTAINER_MODE)
  if test $USE_MAINTAINER_MODE = yes; then
    MAINT=
  else
    MAINT='#M#'
  fi
  AC_SUBST(MAINT)dnl
]
)

# Like AC_CONFIG_HEADER, but automatically create stamp file.

AC_DEFUN(AM_CONFIG_HEADER,
[AC_PREREQ([2.12])
AC_CONFIG_HEADER([$1])
dnl When config.status generates a header, we must update the stamp-h file.
dnl This file resides in the same directory as the config header
dnl that is generated.  We must strip everything past the first ":",
dnl and everything past the last "/".
AC_OUTPUT_COMMANDS(changequote(<<,>>)dnl
ifelse(patsubst(<<$1>>, <<[^ ]>>, <<>>), <<>>,
<<test -z "<<$>>CONFIG_HEADERS" || echo timestamp > patsubst(<<$1>>, <<^\([^:]*/\)?.*>>, <<\1>>)stamp-h<<>>dnl>>,
<<am_indx=1
for am_file in <<$1>>; do
  case " <<$>>CONFIG_HEADERS " in
  *" <<$>>am_file "*<<)>>
    echo timestamp > `echo <<$>>am_file | sed -e 's%:.*%%' -e 's%[^/]*$%%'`stamp-h$am_indx
    ;;
  esac
  am_indx=`expr "<<$>>am_indx" + 1`
done<<>>dnl>>)
changequote([,]))])


# serial 15 AM_PROG_LIBTOOL
AC_DEFUN(AM_PROG_LIBTOOL,
[AC_REQUIRE([AC_CANONICAL_HOST])
AC_REQUIRE([AC_PROG_RANLIB])
AC_REQUIRE([AC_PROG_CC])
AC_REQUIRE([AM_PROG_LD])
AC_REQUIRE([AM_PROG_NM])
AC_REQUIRE([AC_PROG_LN_S])

# Always use our own libtool.
LIBTOOL='$(SHELL) $(top_builddir)/libtool'
AC_SUBST(LIBTOOL)

dnl Allow the --disable-shared flag to stop us from building shared libs.
AC_ARG_ENABLE(shared,
[  --enable-shared         build shared libraries [default=yes]],
[if test "$enableval" = no; then
  enable_shared=no
else
  enable_shared=yes
fi])
libtool_shared=
test "$enable_shared" = no && libtool_shared=" --disable-shared"

dnl Allow the --disable-static flag to stop us from building static libs.
AC_ARG_ENABLE(static,
[  --enable-static         build static libraries [default=yes]],
[if test "$enableval" = no; then
  enable_static=no
else
  enable_static=yes
fi])
libtool_static=
test "$enable_static" = no && libtool_static=" --disable-static"

libtool_flags="$libtool_shared$libtool_static"
test "$silent" = yes && libtool_flags="$libtool_flags --silent"
test "$ac_cv_prog_gcc" = yes && libtool_flags="$libtool_flags --with-gcc"
test "$ac_cv_prog_gnu_ld" = yes && libtool_flags="$libtool_flags --with-gnu-ld"

# Some flags need to be propagated to the compiler or linker for good
# libtool support.
[case "$host" in
*-*-irix6*)
  ac_save_CFLAGS="$CFLAGS"
  # -n32 always needs to be added to the linker when using GCC.
  test "$ac_cv_prog_gcc" = yes && CFLAGS="$CFLAGS -n32"
  for f in '-32' '-64' '-cckr' '-n32' '-mips1' '-mips2' '-mips3' '-mips4'; do
    if echo " $CC $CFLAGS " | egrep -e "[ 	]$f[	 ]" > /dev/null; then
      LD="${LD-ld} $f"
    fi
  done
  CFLAGS="$ac_save_CFLAGS"
  ;;

*-*-sco3.2v5*)
  # On SCO OpenServer 5, we need -belf to get full-featured binaries.
  CFLAGS="$CFLAGS -belf"
  ;;
esac]

# Actually configure libtool.  ac_aux_dir is where install-sh is found.
CC="$CC" CFLAGS="$CFLAGS" CPPFLAGS="$CPPFLAGS" \
LD="$LD" NM="$NM" RANLIB="$RANLIB" LN_S="$LN_S" \
${CONFIG_SHELL-/bin/sh} $ac_aux_dir/ltconfig \
$libtool_flags --no-verify $ac_aux_dir/ltmain.sh $host \
|| AC_MSG_ERROR([libtool configure failed])
])

# AM_PROG_LD - find the path to the GNU or non-GNU linker
AC_DEFUN(AM_PROG_LD,
[AC_ARG_WITH(gnu-ld,
[  --with-gnu-ld           assume the C compiler uses GNU ld [default=no]],
test "$withval" = no || with_gnu_ld=yes, with_gnu_ld=no)
AC_REQUIRE([AC_PROG_CC])
ac_prog=ld
if test "$ac_cv_prog_gcc" = yes; then
  # Check if gcc -print-prog-name=ld gives a path.
  AC_MSG_CHECKING([for ld used by GCC])
  ac_prog=`($CC -print-prog-name=ld) 2>&5`
  case "$ac_prog" in
  # Accept absolute paths.
  /*)
    test -z "$LD" && LD="$ac_prog"
    ;;
  "")
    # If it fails, then pretend we aren't using GCC.
    ac_prog=ld
    ;;
  *)
    # If it is relative, then search for the first ld in PATH.
    with_gnu_ld=unknown
    ;;
  esac
elif test "$with_gnu_ld" = yes; then
  AC_MSG_CHECKING([for GNU ld])
else
  AC_MSG_CHECKING([for non-GNU ld])
fi
AC_CACHE_VAL(ac_cv_path_LD,
[if test -z "$LD"; then
  IFS="${IFS= 	}"; ac_save_ifs="$IFS"; IFS="${IFS}:"
  for ac_dir in $PATH; do
    test -z "$ac_dir" && ac_dir=.
    if test -f "$ac_dir/$ac_prog"; then
      ac_cv_path_LD="$ac_dir/$ac_prog"
      # Check to see if the program is GNU ld.  I'd rather use --version,
      # but apparently some GNU ld's only accept -v.
      # Break only if it was the GNU/non-GNU ld that we prefer.
      if "$ac_cv_path_LD" -v 2>&1 < /dev/null | egrep '(GNU|with BFD)' > /dev/null; then
	test "$with_gnu_ld" != no && break
      else
        test "$with_gnu_ld" != yes && break
      fi
    fi
  done
  IFS="$ac_save_ifs"
else
  ac_cv_path_LD="$LD" # Let the user override the test with a path.
fi])
LD="$ac_cv_path_LD"
if test -n "$LD"; then
  AC_MSG_RESULT($LD)
else
  AC_MSG_RESULT(no)
fi
test -z "$LD" && AC_MSG_ERROR([no acceptable ld found in \$PATH])
AC_SUBST(LD)
AM_PROG_LD_GNU
])

AC_DEFUN(AM_PROG_LD_GNU,
[AC_CACHE_CHECK([if the linker ($LD) is GNU ld], ac_cv_prog_gnu_ld,
[# I'd rather use --version here, but apparently some GNU ld's only accept -v.
if $LD -v 2>&1 </dev/null | egrep '(GNU|with BFD)' 1>&5; then
  ac_cv_prog_gnu_ld=yes
else
  ac_cv_prog_gnu_ld=no
fi])
])

# AM_PROG_NM - find the path to a BSD-compatible name lister
AC_DEFUN(AM_PROG_NM,
[AC_MSG_CHECKING([for BSD-compatible nm])
AC_CACHE_VAL(ac_cv_path_NM,
[case "$NM" in
/*)
  ac_cv_path_NM="$NM" # Let the user override the test with a path.
  ;;
*)
  IFS="${IFS= 	}"; ac_save_ifs="$IFS"; IFS="${IFS}:"
  for ac_dir in /usr/ucb $PATH /bin; do
    test -z "$ac_dir" && dir=.
    if test -f $ac_dir/nm; then
      # Check to see if the nm accepts a BSD-compat flag.
      if ($ac_dir/nm -B /dev/null 2>&1; exit 0) | grep /dev/null >/dev/null; then
        ac_cv_path_NM="$ac_dir/nm -B"
      elif ($ac_dir/nm -p /dev/null 2>&1; exit 0) | grep /dev/null >/dev/null; then
        ac_cv_path_NM="$ac_dir/nm -p"
      else
        ac_cv_path_NM="$ac_dir/nm"
      fi
      break
    fi
  done
  IFS="$ac_save_ifs"
  test -z "$ac_cv_path_NM" && ac_cv_path_NM=nm
  ;;
esac])
NM="$ac_cv_path_NM"
AC_MSG_RESULT([$NM])
AC_SUBST(NM)
])

dnl
dnl CY_AC_WITH_THREADS determines which thread library the user intends
dnl to put underneath guile.  Pass it the path to find the guile top-level
dnl source directory.  Eg CY_AC_WITH_THREADS(../..) for tcl/unix.
dnl

AC_DEFUN([CY_AC_WITH_THREADS],[
AC_CACHE_CHECK("threads package type",cy_cv_threads_package,[
AC_CACHE_VAL(cy_cv_threads_cflags,[
AC_CACHE_VAL(cy_cv_threads_libs,[
use_threads=no;
AC_ARG_WITH(threads,[  --with-threads          thread interface],
            use_threads=$withval, use_threads=no)
test -n "$use_threads" || use_threads=qt
threads_package=unknown
if test "$use_threads" != no; then
dnl
dnl Test for the qt threads package - used for cooperative threads
dnl This may not necessarily be built yet - so just check for the
dnl header files.
dnl
  if test "$use_threads" = yes || test "$use_threads" = qt; then
     # Look for qt in source directory. 
     if test -f $srcdir/qt/qt.c; then
	qtsrcdir="`(cd $srcdir; pwd)`/qt"
	threads_package=COOP
	cy_cv_threads_cflags="-I$qtsrcdir -I../qt"
	cy_cv_threads_libs="../qt/libqthreads.a"
     fi
  else
     if test -f $use_threads/qt.c; then
	# FIXME seems as though we should try to use an installed qt here.
	threads_package=COOP
	cy_cv_threads_cflags="-I$use_threads -I../qt"
	cy_cv_threads_libs="../qt/libqthreads.a"
     fi
  fi
  if test "$use_threads" = pthreads; then
     # Look for pthreads in srcdir.  See above to understand why
     # we always set threads_package.
     if test -f $srcdir/../../pthreads/pthreads/queue.c \
	  || test -f $srcdir/../pthreads/pthreads/queue.c; then
	threads_package=MIT
	cy_cv_threads_cflags="-I$srcdir/../../pthreads/include"
	cy_cv_threads_libs="-L../../pthreads/lib -lpthread"
     fi
  fi
  saved_CPP="$CPPFLAGS"
  saved_LD="$LDFLAGS"
  saved_LIBS="$LIBS"
  if test "$threads_package" = unknown; then
dnl
dnl Test for the FSU threads package
dnl
    CPPFLAGS="-I$use_threads/include"
    LDFLAGS="-L$use_threads/lib"
    LIBS="-lgthreads -lmalloc"
    AC_TRY_LINK([#include <pthread.h>],[
pthread_equal(NULL,NULL);
], threads_package=FSU)
  fi
  if test "$threads_package" = unknown; then
dnl
dnl Test for the MIT threads package
dnl
    LIBS="-lpthread"
    AC_TRY_LINK([#include <pthread.h>],[
pthread_equal(NULL,NULL);
], threads_package=MIT)
  fi
  if test "$threads_package" = unknown; then
dnl
dnl Test for the PCthreads package
dnl
    LIBS="-lpthreads"
    AC_TRY_LINK([#include <pthread.h>],[
pthread_equal(NULL,NULL);
], threads_package=PCthreads)
  fi
dnl
dnl Set the appropriate flags!
dnl 
  cy_cv_threads_cflags="$CPPFLAGS $cy_cv_threads_cflags"
  cy_cv_threads_libs="$LDFLAGS $LIBS $cy_cv_threads_libs"
  cy_cv_threads_package=$threads_package
  CPPFLAGS="$saved_CPP"
  LDFLAGS="$saved_LD"
  LIBS="$saved_LIBS"
  if test "$threads_package" = unknown; then
    AC_MSG_ERROR("cannot find thread library installation")
  fi
fi
])
])
],
dnl
dnl Set flags according to what is cached.
dnl
CPPFLAGS="$cy_cv_threads_cflags"
LIBS="$cy_cv_threads_libs"
)
])

