#! /bin/sh
# Copyright (C) 2012-2013 Free Software Foundation, Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Try to find the pkg-config '.m4' files and make them easily accessed
# to the test cases requiring them.

. test-init.sh

echo "# Automatically generated by $me." > get.sh
echo : >> get.sh

if ver=$(pkg-config --version) && test -n "$ver"; then
   echo "printf 'pkg-config version: %s\\n' '$ver'" >> get.sh
else
   echo "skip_all_ \"'pkg-config' not available\"" >> get.sh
fi

cat > configure.ac <<'END'
AC_INIT([pkg], [1.0])
PKG_CHECK_MODULES([GOBJECT], [gobject-2.0 >= 2.4])
END

have_pkg_config_macros ()
{
  $AUTOCONF && ! $FGREP PKG_CHECK_MODULES configure
}

if have_pkg_config_macros; then
  # The pkg-config macros are already available, nothing to do.
  exit 0
fi

# Usual locations where pkg.m4 *might* be installed.
XT_ACLOCAL_PATH=/usr/local/share/aclocal:/usr/share/aclocal

# Find the location of the pkg-config executable.
oIFS=$IFS dir=
IFS=:
for d in $PATH; do
  IFS=$oIFS
  if test -f $d/pkg-config || test -f $d/pkg-config.exe; then
    dir=$d
    break
  fi
done
IFS=$oIFS

# Now try to use the location of the pkg-config executable to guess
# where the corresponding pkg.m4 might be installed.
if test -n "$dir"; then
  # Only support standard installation layouts.
  XT_ACLOCAL_PATH=${dir%/bin}/share/aclocal:$XT_ACLOCAL_PATH
fi

XT_ACLOCAL_PATH=$XT_ACLOCAL_PATH${ACLOCAL_PATH+":$ACLOCAL_PATH"}

# Try once again to fetch the pkg-config macros.
mkdir m4
ACLOCAL_PATH=$XT_ACLOCAL_PATH $ACLOCAL -Wno-syntax --install -I m4
if test -f m4/pkg.m4 && have_pkg_config_macros; then
   echo "ACLOCAL_PATH='$(pwd)/m4':\$ACLOCAL_PATH" >> get.sh
   echo "export ACLOCAL_PATH" >> get.sh
   echo "sed 20q '$(pwd)/m4/pkg.m4' # For debugging." >> get.sh
else
   echo "skip_all_ \"pkg-config m4 macros not found\"" >> get.sh
fi

ACLOCAL_PATH=; unset ACLOCAL_PATH
. ./get.sh

$ACLOCAL --force -I m4 || cat >> get.sh <<'END'
# We need to use '-Wno-syntax', since we do not want our test suite
# to fail merely because some third-party '.m4' file is underquoted.
ACLOCAL="$ACLOCAL -Wno-syntax"
END

# The pkg-config m4 file(s) we might fetched will be copied in the
# 'm4' subdirectory of the test directory are going to be needed by
# other tests, so we must not remove the test directory.
keep_testdirs=yes

: