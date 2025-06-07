# zu

[![status-badge](https://ci.uscope.dev/api/badges/3/status.svg)](https://ci.uscope.dev/repos/3)

A small library of useful zig utilities.

Issues and PRs to add features, tests, and general improvements are welcome.

Documentation is available at [https://zu.uscope.dev](https://zu.uscope.dev/).

To use in your project, first run:

```
zig fetch --save git+https://github.com/jcalabro/zu.git
```

Then, add this to your `build.zig`:

```zig
const zu = b.dependency("zu", .{});
my_library_or_exe.root_module.addImport("zu", zu.module("zu"));
```

<img src="https://github.com/user-attachments/assets/9df9e9fa-503e-4314-8a3d-ff8e0b1b5a35" alt="a couple zebras">
