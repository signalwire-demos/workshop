{ pkgs }: {
  deps = [
    pkgs.python312
    pkgs.python312Packages.pip
    pkgs.nodejs_20
    pkgs.ruby_3_3
    pkgs.go
    pkgs.openjdk21
    pkgs.gradle
    pkgs.perl
    pkgs.rustc
    pkgs.cargo
    pkgs.php83
    pkgs.dotnet-sdk_8
    pkgs.cmake
    pkgs.gcc
  ];
}
