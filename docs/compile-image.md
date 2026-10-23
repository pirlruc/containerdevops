# Compile images

A compile image installs a compiler and the libraries a later build links.
Publish it with `container-lint`, `container-build`, `container-scan`, and
`container-publish`. Pin the base by digest and pass `size_class: ci_toolchain`
when the image is a CI toolchain.

## Structure test

`container-build` runs container-structure-test. A compile image fails that
check when the toolchain is missing. The config must include:

- the compiler (`c++ --version`, or the compiler the image claims)
- `cmake --version`
- a libc++ or libstdc++ shared library
- a non-root user
- no setuid or setgid files

Start from
[`templates/compile-image-structure-test.yml`](../templates/compile-image-structure-test.yml)
and change the uid when the image does not use `1000`.

## Overlay ports

When the image already contains a library that a vcpkg port would build,
ship an empty overlay port for that library. The port points `find_package`
at the prefix installed in the image. One port file per library. vcpkg then
uses the image copy instead of compiling the library again. OpenCV and Eigen
in a compile image are the usual case.
