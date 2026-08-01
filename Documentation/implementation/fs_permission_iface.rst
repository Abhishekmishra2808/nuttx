.. _fs-permission-unified-iface:

========================================
Filesystem Permission Interface
========================================

When ``CONFIG_FS_PERMISSION`` is enabled, the VFS applies POSIX-style
discretionary access control (DAC) using the caller's effective credentials
(``tg_euid`` / ``tg_egid``).  This page describes the common inode helpers,
how mountpoints participate, and how access across a mount is gated by
pseudoFS directory modes.

Prerequisite reading: :ref:`user-identity`.

Configuration
=============

=============================== =============================================
Option                          Role
=============================== =============================================
``CONFIG_SCHED_USER_IDENTITY``  Per-task-group UID/GID credentials
``CONFIG_PSEUDOFS_ATTRIBUTES``  Store ``i_mode`` / ``i_owner`` / ``i_group``
                                on pseudoFS inodes
``CONFIG_FS_PERMISSION``        Enable DAC helpers and VFS enforcement
                                (depends on the two options above)
``CONFIG_FS_TMPFS``             Needed for the mount-crossing cases in
                                ``examples/sectest``
=============================== =============================================

Without ``CONFIG_FS_PERMISSION``, the helpers described here return success
and no mode-based checks are performed.

Helpers
=======

======================== ====================================================
API                      Role
======================== ====================================================
``inode_permission``     Check ``amode`` (``R_OK`` / ``W_OK`` / ``X_OK``)
                         against an inode's ``i_owner`` / ``i_group`` /
                         ``i_mode``.
``inode_checksearchpath`` Require ``X_OK`` on every ancestor of an inode, and
                         on the inode itself when it is a pseudo directory or
                         a mountpoint (directory search / traverse).
``inode_checkopenperm``  Validate that the inode supports the requested open
                         access, then apply mode checks for non-mountpoint
                         inodes.
``fs_checkmode``         Core owner/group/other test used by the helpers
                         above and by filesystems such as tmpfs and littlefs.
======================== ====================================================

Optional mountpoint hook
------------------------

``struct mountpt_operations`` may provide a ``permission`` method for
in-volume DAC.  The field is at the **end** of the structure so existing
positional initialisers remain valid.

* **tmpfs** implements ``tmpfs_permission``.
* Filesystems without Unix ownership on disk (for example FAT and ROMFS)
  leave the method ``NULL``.

The VFS mount-crossing gate does **not** depend on this hook.  Entry into a
volume is enforced with ``inode_checksearchpath`` against the mountpoint
inode's stored ``i_mode``.  In-volume checks remain the filesystem's job
(tmpfs and littlefs enforce DAC inside their own open/mkdir/path helpers.
``mops->permission`` is an optional common entry point for the same policy;
the VFS does not invoke it for mount-crossing).

Open vs traverse
================

Mountpoint inodes are **not** open-mode-checked by ``inode_checkopenperm``.
Applying the mount directory's mode bits as file open modes would require
read/write on the mount directory merely to open a file beneath it.

Traverse is separate: callers use ``inode_checksearchpath`` so parent
directories and the mountpoint itself still require ``X_OK``.

Typical order after a successful ``inode_find``:

1. ``inode_checksearchpath(inode)`` — search permission on the path prefix
   (and on the mountpoint when entering a volume).
2. Operation-specific checks — ``inode_checkopenperm``, parent ``W_OK`` for
   create/remove in the pseudoFS, or the filesystem's own methods for paths
   inside a mount.

Mount-crossing
==============

Path walk stops at a mountpoint and returns that inode plus a relative path
into the volume.  Without traverse checks, a restrictive mode on a pseudoFS
parent would not protect objects under a filesystem mounted beneath it.

Example::

  /secure_dir          # pseudoFS directory, mode 0700, owner root
  /secure_dir/mnt      # mounted volume (tmpfs, FAT, ...)
  /secure_dir/mnt/a    # object inside the volume

``inode_checksearchpath`` requires ``X_OK`` on ``secure_dir`` and on the
mountpoint ``mnt``.  A non-root open of ``/secure_dir/mnt/a`` therefore
returns ``EACCES``, even if the mounted filesystem itself has no Unix DAC.

Where the checks run
--------------------

* After ``inode_find`` in open, unlink, mkdir, rmdir, rename, stat, chstat,
  statfs, readlink, mount, and umount (under ``inode_rlock`` /
  ``inode_lock`` so mode bits are stable during the check).
* Inside ``inode_reserve`` / ``inode_remove`` for pseudoFS create and remove
  (ancestor ``X_OK``, then parent ``W_OK``).

Who enforces what
-----------------

======================= =====================================================
Layer                   Responsibility
======================= =====================================================
PseudoFS parent dirs    ``X_OK`` (and ``W_OK`` when creating/removing)
Mountpoint inode        ``X_OK`` to enter the volume (stored ``i_mode``)
Inside the volume       Filesystem methods; optional ``mops->permission``
FAT / ROMFS             No Unix ownership on disk; entry still gated by the
                        mountpoint ``i_mode``
======================= =====================================================

Testing
=======

Automated
---------

With ``CONFIG_EXAMPLES_SECTEST=y`` (and the permission options above), run
under the simulator::

  nsh> sectest

``examples/sectest`` covers symlink permission and TOCTOU races,
mount-crossing with tmpfs under a ``0700`` parent (denied) versus a public
parent (allowed), and related credential hygiene APIs.

Manual check on NSH (sim)
-------------------------

NSH ``mkdir`` always creates directories with mode ``0777``.  It does **not**
accept a mode argument.  Set a private mode with ``chmod`` afterward.

Example session (as root, then as a non-root effective UID)::

  nsh> mkdir /secure
  nsh> mkdir /secure/mnt
  nsh> mount -t tmpfs /secure/mnt
  nsh> echo secret > /secure/mnt/a
  nsh> chmod 0700 /secure
  nsh> echo 'root:x:0:0:/' > /tmp/ostest_passwd
  nsh> echo 'testuser:x:1000:1000:/' >> /tmp/ostest_passwd
  nsh> su testuser
  nsh> id
  nsh> cat /secure/mnt/a

``cat`` should fail with ``EACCES`` (NSH reports ``open failed: 13``).

Notes:

* Create the passwd file before ``su`` if ``CONFIG_LIBC_PASSWD_FILE`` is
  enabled.  ``useradd`` is only available when NSH passwd utilities are
  configured.
* Once effective UID is non-zero, ``su root`` may be denied unless NSH login
  / password verification is enabled.  Restart the simulator to recover a
  root session if needed.
* Contrast: ``chmod 0755 /secure`` (as root) should allow the same ``cat``
  as ``testuser``.

References
==========

* ``fs/inode/fs_inode.c`` — ``inode_permission``, ``inode_checksearchpath``
* ``include/nuttx/fs/fs.h`` — ``struct mountpt_operations``
* ``fs/tmpfs/fs_tmpfs.c`` — ``tmpfs_permission``
* :ref:`user-identity` — credential model
* :doc:`/components/filesystem/littlefs` — littlefs in-volume DAC
* :doc:`/components/filesystem/tmpfs` — tmpfs overview
