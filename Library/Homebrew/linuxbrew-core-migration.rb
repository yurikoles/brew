# typed: strong
# frozen_string_literal: true

# Hash of formulae with their old linuxbrew-core pkg_version strings.
# These formulae had a revision in linuxbrew-core that was different
# than in homebrew-core.
LINUXBREW_CORE_MIGRATION_OLD_PKG_VERSIONS = T.let({
  "apng2gif"         => "1.8_2",
  "argon2"           => "20190702_2",
  "csvtomd"          => "0.3.0_4",
  "cvs"              => "1.12.13_5",
  "cxxtest"          => "4.4_4",
  "datetime-fortran" => "1.7.0_1",
  "docbook2x"        => "0.8.8_3",
  "exif"             => "0.6.22_1",
  "ftgl"             => "2.1.3-rc5_1",
  "gflags"           => "2.2.2_2",
  "glew"             => "2.2.0_2",
  "glui"             => "2.37_2",
  "gtkmm"            => "2.24.5_9",
  "intltool"         => "0.51.0_3",
  "io"               => "2017.09.06_2",
  "jed"              => "0.99-19_1",
  "mecab"            => "0.996_1",
  "openmotif"        => "2.3.8_3",
  "osmfilter"        => "0.9_1",
  "pius"             => "3.0.0_4",
  "plotutils"        => "2.6_5",
  "plplot"           => "5.15.0_4",
  "softhsm"          => "2.6.1_1",
  "tasksh"           => "1.2.0_2",
  "xclip"            => "0.13_4",
}.freeze, T::Hash[String, String])

# List of formulae that had a revision in linuxbrew-core
# that was different than in homebrew-core
# We will use this list to modify the version_scheme
# during the migration from linuxbrew-core to homebrew-core.
LINUXBREW_CORE_MIGRATION_LIST = T.let(LINUXBREW_CORE_MIGRATION_OLD_PKG_VERSIONS.keys.freeze, T::Array[String])
