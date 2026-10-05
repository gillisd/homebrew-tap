class Duckdb < Formula
  desc "Embeddable SQL OLAP Database Management System"
  homepage "https://www.duckdb.org"
  # Tracks the 2.0 release branch; install with --HEAD, update with `brew upgrade --fetch-HEAD duckdb`.
  head "https://github.com/duckdb/duckdb.git", branch: "v2.0-cyanoptera"
  license "MIT"

  # A -dev build cannot INSTALL extensions (the repository is keyed by release commit), so every
  # first-party extension is linked in. Out-of-tree ones are fetched at configure time at the commits
  # pinned in .github/config/extensions/*.cmake. Left out: azure (the Azure SDK is not in Homebrew),
  # mysql_scanner (its build hardcodes vcpkg's include path), and the test-only sqlsmith/test-utils.
  LINKED_EXTENSIONS = %w[
    autocomplete avro aws delta ducklake encodings excel fts glue httpfs iceberg inet
    odbc_scanner postgres_scanner quack spatial sqlite_scanner tpcds tpch unity_catalog vss
  ].freeze

  depends_on "cmake" => [:build, :test]
  depends_on "rust" => :build # delta builds delta-kernel-rs with cargo
  depends_on "aws-sdk-cpp"
  depends_on "croaring"
  depends_on "gdal"
  depends_on "geos"
  depends_on "jansson"
  depends_on "libpq"
  depends_on "minizip-ng"
  depends_on "openssl@3"
  depends_on "proj"
  depends_on "snappy"
  depends_on "sqlite"
  depends_on "unixodbc"
  depends_on "xz"
  depends_on "zlib" # spatial demands a static zlib, which macOS does not ship

  uses_from_macos "python" => :build
  uses_from_macos "curl"
  uses_from_macos "expat"

  def install
    write_vcpkg_only_cmake_packages

    # postgres_scanner links libpq only into its loadable module, not the static target linked here.
    link_libpq = "-L#{formula_opt_lib("libpq")} -lpq"

    # ENABLE_EXTENSION_AUTOLOADING/AUTOINSTALL were removed in 2.0: both default to on at runtime.
    # Local build: -march=native and thin LTO (clang) / -flto (gcc). Not portable to other machines.
    args = %W[
      -DBUILD_EXTENSIONS=#{LINKED_EXTENSIONS.join(";")}
      -DLINK_CORE_EXTENSIONS=ON
      -DCMAKE_PREFIX_PATH=#{buildpath}/cmake-packages
      -DOPENSSL_ROOT_DIR=#{formula_opt_prefix("openssl@3")}
      -DCMAKE_EXE_LINKER_FLAGS=#{link_libpq}
      -DCMAKE_SHARED_LINKER_FLAGS=#{link_libpq}
      -DDUCKDB_EXPLICIT_VERSION=v2.0.0-dev0
      -DNATIVE_ARCH=ON
      -DCMAKE_LTO=thin
      -DCMAKE_LTO_JOBS=#{ENV.make_jobs}
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # The cli tool was renamed (0.1.8 -> 0.1.9)
    # Create a symlink to not break compatibility
    bin.install_symlink bin/"duckdb" => "duckdb_cli"
  end

  # avro and spatial find these by vcpkg's CMake package names; Homebrew's jansson is built with
  # autotools and its sqlite ships no CMake package, so map them onto the installed libraries.
  def write_vcpkg_only_cmake_packages
    {
      "jansson"            => ["jansson::jansson", "jansson", "libjansson"],
      "unofficial-sqlite3" => ["unofficial::sqlite3::sqlite3", "sqlite", "libsqlite3"],
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
      set(CMAKE_CXX_STANDARD 11)
      find_package(DuckDB REQUIRED)
      add_executable(test test.cpp)
      target_link_libraries(test duckdb)
    CMAKE

    system "cmake", "-S", testpath, "-B", testpath/"build"
    system "cmake", "--build", testpath/"build"
    assert_equal "45.0", shell_output(testpath/"build/test")
  end
end

