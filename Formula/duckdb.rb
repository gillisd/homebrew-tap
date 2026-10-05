class Duckdb < Formula
  desc "Embeddable SQL OLAP Database Management System"
  homepage "https://www.duckdb.org"
  # 2.0 has no release tag yet; pin the head of its release branch.
  url "https://github.com/duckdb/duckdb.git",
      branch:   "v2.0-cyanoptera",
      revision: "fc9d6e93409a2dc412b658cade45b963371cd033"
  version "2.0.0-dev"
  license "MIT"

  depends_on "cmake" => [:build, :test]
  uses_from_macos "python" => :build

  def install
    # core_functions, parquet, json and icu are built and statically linked by default
    # (extension/extension_config.cmake); autocomplete must be requested and linked explicitly.
    # ENABLE_EXTENSION_AUTOLOADING/AUTOINSTALL were removed in 2.0: both default to on at runtime.
    # Local build: -march=native and thin LTO (clang) / -flto (gcc). Not portable to other machines.
    args = %W[
      -DBUILD_EXTENSIONS=autocomplete
      -DLINK_CORE_EXTENSIONS=ON
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

