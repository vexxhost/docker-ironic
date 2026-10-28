# Ironic runtime patches

Add numbered `*.patch` files here, for example `0002-next-fix.patch`.
The build helper applies all patches in filename order before installing
the rebuilt wheel. New patches require no Dockerfile changes.

Backports must target files in the pinned wheel. Omit unrelated upstream
test, release-note, and build-system hunks. A patch that no longer applies
fails the build. With no patch files, the original wheel is used unchanged.
