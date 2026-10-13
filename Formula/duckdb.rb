class Duckdb < Formula
  desc "Embeddable SQL OLAP Database Management System"
  homepage "https://www.duckdb.org"
  license "MIT"

  stable do
    url "https://github.com/duckdb/duckdb.git", revision: "53d3003"
    version "v2.0-cyanoptera"

    resource "quack" do
      url "https://github.com/duckdb/duckdb-quack.git", revision: "c19ca48"
    end
  end

  head do
    url "https://github.com/duckdb/duckdb.git", branch: "v2.0-cyanoptera"

    # Unlike the other out-of-tree extensions, quack is built from main: DuckDB pins it to a commit
    # that predates quack's server TLS.
    resource "quack" do
      url "https://github.com/duckdb/duckdb-quack.git", branch: "main"
    end
  end
  # A -dev build cannot INSTALL extensions (the repository is keyed by release commit), so every
  # first-party extension is linked in. Out-of-tree ones are fetched at configure time at the commits
  # pinned in .github/config/extensions/*.cmake. Left out: azure (the Azure SDK is not in Homebrew),
  # mysql_scanner (its build hardcodes vcpkg's include path), spatial (written against GDAL 3.8; Homebrew's
  # GDAL has a newer, incompatible VSI file API), odbc_scanner (a C-API extension built only as a
  # loadable module, so it cannot be linked in), and the test-only sqlsmith/test-utils.
  # Linked extensions load in this order, and iceberg and glue autoload parquet (iceberg also avro)
  # while loading, which tries to INSTALL it unless it has already loaded. So the built-in four come
  # first; they are linked by default, but listing them here is what moves them to the front.
  LINKED_EXTENSIONS = %w[
    core_functions parquet json icu
    autocomplete avro aws delta ducklake encodings excel fts glue httpfs iceberg inet
    postgres_scanner quack sqlite_scanner tpcds tpch unity_catalog vss
  ].freeze

  # The oldest CPU the build must run on, for the C/C++ wrapper and for rustc. Raise or lower per fleet.
  CPU_FLOOR = {
    arm:   ["-march=armv8.2-a", "--codegen target-feature=+v8.2a"],
    intel: ["-march=x86-64-v3", "--codegen target-cpu=x86-64-v3"],
  }.freeze

  depends_on "cmake" => [:build, :test]
  depends_on "rust" => :build # delta builds delta-kernel-rs with cargo
  depends_on "aws-sdk-cpp"
  depends_on "croaring"
  depends_on "jansson"
  depends_on "libpq"
  depends_on "minizip-ng"
  depends_on "openssl@3"
  depends_on "snappy"
  depends_on "xz"

  uses_from_macos "python" => :build
  uses_from_macos "curl"
  uses_from_macos "expat"

  def install
    # Under Homebrew's make/ninja shims its cc wrapper drops every -O and -mcpu flag a build passes
    # (refurbish_arg in shims/super/cc). Ask the wrapper for -O3 and CPU_FLOOR instead, so they reach
    # every compile, the extensions' included. On Linux brew also hands rustc target-cpu=native through
    # HOMEBREW_RUSTFLAGS (Hardware.rustflags_target_cpu), which would leak native code in via delta.
    ENV.O3
    ENV["HOMEBREW_OPTFLAGS"], ENV["HOMEBREW_RUSTFLAGS"] = CPU_FLOOR.fetch(Hardware::CPU.arm? ? :arm : :intel)
    # delta's cargo build compiles aws-lc's jitterentropy, which must be -O0 and is rejected otherwise;
    # the wrapper would rewrite that to -O3, so cargo's C compiles go to clang directly.
    ENV["TARGET_CC"] = DevelopmentTools.locate(OS.mac? ? "clang" : "gcc").to_s
    if OS.linux?
      # On Linux delta points openssl-sys at vcpkg's OpenSSL; the target-prefixed variables win over it.
      rust_target = "#{Hardware::CPU.arm? ? "aarch64" : "x86_64"}_unknown_linux_gnu".upcase
      ENV["#{rust_target}_OPENSSL_LIB_DIR"] = formula_opt_lib("openssl@3").to_s
      ENV["#{rust_target}_OPENSSL_INCLUDE_DIR"] = formula_opt_include("openssl@3").to_s
    end

    write_vcpkg_only_cmake_packages

    # postgres_scanner links libpq only into its loadable module, not the static target linked here.
    link_libpq = "-L#{formula_opt_lib("libpq")} -lpq"

    # ENABLE_EXTENSION_AUTOLOADING/AUTOINSTALL were removed in 2.0: both default to on at runtime.
    # Thin LTO (clang) / -flto (gcc); the wrapper passes -flto through.
    # Brew traps FetchContent so sources arrive as resources. Out-of-tree extensions are pinned (and
    # patched) per DuckDB commit in .github/config/extensions, which a --HEAD build must follow, so
    # let DuckDB fetch them itself rather than freeze 20 pins and their patches in this formula.
    args = %W[
      -DCMAKE_C_STANDARD=17
      -DHOMEBREW_ALLOW_FETCHCONTENT=ON
      -DBUILD_EXTENSIONS=#{LINKED_EXTENSIONS.join(";")}
      -DLINK_CORE_EXTENSIONS=ON
      -DCMAKE_PREFIX_PATH=#{buildpath}/cmake-packages
      -DOPENSSL_ROOT_DIR=#{formula_opt_prefix("openssl@3")}
      -DCMAKE_EXE_LINKER_FLAGS=#{link_libpq}
      -DCMAKE_SHARED_LINKER_FLAGS=#{link_libpq}
      -DDUCKDB_EXPLICIT_VERSION=v2.0.0-dev0
      -DCMAKE_LTO=thin
      -DCMAKE_LTO_JOBS=#{ENV.make_jobs}
    ]

    # DuckDB builds quack from this checkout instead of fetching its pinned commit. The DuckDB that
    # quack carries as a submodule goes: quack builds against the DuckDB being built here.
    quack = buildpath/"quack"
    resource("quack").stage(quack)
    rm_r quack/"duckdb"
    ENV["DUCKDB_QUACK_DIRECTORY"] = quack

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args

    # unity_catalog copies GetSecret and CatalogTypeIsSupported from postgres_scanner without making
    # them file-local, which collides once both are linked into one binary (upstream never does).
    unity_catalog = buildpath/"build/_deps/unity_catalog_extension_fc-src/src"
    inreplace unity_catalog/"unity_catalog_extension.cpp", /^unique_ptr<SecretEntry> GetSecret\(/, "static \\0"
    inreplace unity_catalog/"storage/uc_schema_entry.cpp", /^bool CatalogTypeIsSupported\(/, "static \\0"

    # Only the installed targets: the extensions link into them, and their loadable
    # .duckdb_extension builds carry a metadata footer that breaks Homebrew's ad-hoc re-signing.
    system "cmake", "--build", "build", "--target", "shell", "duckdb", "duckdb_static"
    system "cmake", "--install", "build"

    # The cli tool was renamed (0.1.8 -> 0.1.9)
    # Create a symlink to not break compatibility
    bin.install_symlink bin/"duckdb" => "duckdb_cli"
  end

  # avro finds jansson by vcpkg's CMake package name; Homebrew's jansson is built with autotools and
  # ships no CMake package, so map it onto the installed library.
  def write_vcpkg_only_cmake_packages
    {
      "jansson" => ["jansson::jansson", "jansson", "libjansson"],
    }.each do |package, (target, formula, library)|
      (buildpath/"cmake-packages/#{package}/#{package}Config.cmake").write <<~CMAKE
        if(NOT TARGET #{target})
          add_library(#{target} SHARED IMPORTED)
          set_target_properties(#{target} PROPERTIES
            IMPORTED_LOCATION "#{formula_opt_lib(formula)}/#{shared_library(library)}"
            INTERFACE_INCLUDE_DIRECTORIES "#{formula_opt_include(formula)}")
        endif()
      CMAKE
    end
  end

  test do
    sql_commands = <<~SQL
      CREATE TABLE weather (temp INTEGER);
      INSERT INTO weather (temp) VALUES (40), (45), (50);
      SELECT AVG(temp) FROM weather;
    SQL

    expected_output = <<~EOS
      ┌─────────────┐
      │ avg("temp") │
      │   double    │
      ├─────────────┤
      │        45.0 │
      └─────────────┘
    EOS

    assert_equal expected_output, pipe_output(bin/"duckdb_cli", sql_commands)

    linked = shell_output("#{bin}/duckdb -noheader -list -c " \
                          "\"SELECT extension_name FROM duckdb_extensions() " \
                          "WHERE install_mode = 'STATICALLY_LINKED'\"").split
    assert_empty LINKED_EXTENSIONS - linked

    (testpath/"test.cpp").write <<~CPP
      #include "duckdb.hpp"
      #include <iostream>
      using namespace duckdb;
      int main() {
        DuckDB db(nullptr);
        Connection con(db);
        con.Query("CREATE TABLE weather (temp INTEGER)");
        con.Query("INSERT INTO weather (temp) VALUES (40), (45), (50)");
        auto result = con.Query("SELECT AVG(temp) FROM weather");
        std::cout << result->Fetch()->GetValue(0, 0).ToString();
      }
    CPP

    (testpath/"CMakeLists.txt").write <<~CMAKE
      cmake_minimum_required(VERSION 3.10)
      project(test_duckdb)
      set(CMAKE_CXX_STANDARD 17)
      find_package(DuckDB REQUIRED)
      add_executable(test test.cpp)
      target_link_libraries(test duckdb)
    CMAKE

    system "cmake", "-S", testpath, "-B", testpath/"build"
    system "cmake", "--build", testpath/"build"
    assert_equal "45.0", shell_output(testpath/"build/test")
  end
end
