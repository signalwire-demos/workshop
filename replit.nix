{ pkgs }: {
  deps = [
    # Default: Python (Pillar 1 / 2 / 3 reference implementations).
    pkgs.python312
    pkgs.python312Packages.pip

    # Uncomment the runtime(s) for the language(s) you want to try.
    # Each one adds ~hundreds of MB to the first fork's Nix download —
    # the workshop is faster if you only enable what you need.
    #
    # pkgs.nodejs_20         # TypeScript closing demo
    # pkgs.ruby_3_3          # Ruby parity port
    # pkgs.go                # Go parity port
    # pkgs.openjdk21         # Java parity port
    # pkgs.gradle            # Java parity port
    # pkgs.perl              # Perl parity port
    # pkgs.rustc             # Rust parity port
    # pkgs.cargo             # Rust parity port
    # pkgs.php83             # PHP parity port
    # pkgs.dotnet-sdk_8      # .NET parity port
    # pkgs.cmake             # C++ parity port
    # pkgs.gcc               # C++ parity port
  ];
}
