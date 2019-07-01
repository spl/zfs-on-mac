These are instructions for downloading, installing, and configuring [OpenZFS on
OS X] on macOS 10.14 (Mojave). It was originally written for macOS 10.12
(Sierra) and has since been updated.

[OpenZFS on OS X]: https://openzfsonosx.org/

# Background

**NOTE**: Everything applies to my personal situation (e.g. w.r.t. to disks and
configuration choices). It is not comprehensive, but it might be helpful in
figuring out your own situation.

Here is the context in which this is written:

* I have two external USB hard disk drives (HDDs), each 3TB.

  While I would prefer solid-state drives (SSDs) for their quietness and
  reliability, HDDs (esp. at 3TB) are much cheaper.

* I want the disks to be mirrored to allow for the failure of one disk.

  Since I started using this setup, I've already had one failure. HDDs are
  unreliable, and I can't expect one to be enough.

* I want any disk problems to be identified early.

It seems that ZFS is the best way to handle the above requirements.

Here are some other considerations I've had:

* I would like to encrypt some or all of the disks.

  I previously used the built-in support for encrypting HFS+ disks and installed
  ZFS on top of that. (See the [Encryption Guide on OpenZFS on OS X].) This was
  before ZFS had native encryption.

  However, since then, I've discovered FUSE-based encryption such as
  [`gocryptfs`], [`securefs`], and [CryFS], and I've decided to use that to
  encrypt only a part of the data on disk. Consequently, I do not consider
  encryption in this document.

[Encryption Guide on OpenZFS on OS X]: https://openzfsonosx.org/wiki/Encryption
[`gocryptfs`]: https://nuetzlich.net/gocryptfs/
[`securefs`]: https://github.com/netheril96/securefs
[CryFS]: https://www.cryfs.org/

# Instructions

## Installing and Upgrading OpenZFS

I use [Homebrew] to install OpenZFS. It is regularly updated with the OpenZFS
releases.

[Homebrew]: https://brew.sh/

### Installing

First, update Homebrew:

```
$ brew update
```

Next, check the [`openzfs` formula] to make sure your macOS system is supported.
Look at `depends_on`. Also, make a note of the version for the next step.

[`openzfs` formula]: https://github.com/caskroom/homebrew-cask/blob/master/Casks/openzfs.rb

```
$ brew cask cat openzfs
```

Then, check the [OpenZFS Changelog] for the release notes of the version in the
Homebrew formula.

[OpenZFS Changelog]: https://openzfsonosx.org/wiki/Changelog

Finally, install `openzfs`:

```
$ brew cask install openzfs
```

### Upgrading

First, update Homebrew:

```
$ brew update
```

Next, check if you have an outdated `openzfs` cask:

```
$ brew cask outdated
```

Then, if your version is old and you want to upgrade, first read the [OpenZFS
Changelog] to make sure everything you need will still work after an upgrade.
(If everything is working now, you don't necessarily need to upgrade.)

Finally, upgrade `openzfs`:

```
$ brew cask upgrade openzfs
```

*Resources*:

* [Installation Guide on OpenZFS on OS X](https://openzfsonosx.org/wiki/Install)

## Encrypting an external drive

These instructions are for OpenZFS on OS X 1.6.1, which does not have built-in
encryption. In future versions of OpenZFS, we expect to be able to use the
built-in encryption in ZFS.

There are multiple apparent ways to combine ZFS with encryption. From my naive
eyes, it seems like the following is the most convenient.

First, we need to see what volumes are available. After plugging in both of my
new external USB hard drives, I ran this:

```
$ ./list-volumes.sh
```

In my case, the result was this:

```
/dev/disk0 (internal, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *500.3 GB   disk0
   1:                        EFI EFI                     209.7 MB   disk0s1
   2:          Apple_CoreStorage Macintosh HD            499.4 GB   disk0s2
   3:                 Apple_Boot Recovery HD             650.0 MB   disk0s3

/dev/disk1 (internal, virtual):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:                  Apple_HFS Macintosh HD           +499.1 GB   disk1
                                 Logical Volume on disk0s2
                                 33070EB3-F7FF-45A0-BF9C-079ABB4079CC
                                 Unlocked Encrypted

/dev/disk2 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *3.0 TB     disk2
   1:             Windows_FAT_32 ADATA HM900             3.0 TB     disk2s1

/dev/disk3 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:     FDisk_partition_scheme                        *3.0 TB     disk3
   1:               Windows_NTFS Transcend               3.0 TB     disk3s1
```

Now, armed with the knowledge that we're working with the physical volumes
`/dev/disk2` and `/dev/disk3`, we need to repartition them to use the GUID
Partitioning Table scheme, which is required for Core Storage:

```
$ ./partition-disk-with-gpt.sh /dev/disk2 ADATA1
$ ./partition-disk-with-gpt.sh /dev/disk3 Transcend1
```

After partitioning, we see the following volumes:

```
/dev/disk2 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *3.0 TB     disk2
   1:                        EFI EFI                     314.6 MB   disk2s1
   2:                  Apple_HFS ADATA1                  3.0 TB     disk2s2

/dev/disk3 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *3.0 TB     disk3
   1:                        EFI EFI                     314.6 MB   disk3s1
   2:                  Apple_HFS Transcend1              3.0 TB     disk3s2
```

Next, we convert the `Apple_HFS` partitions to Core Storage, so that we can use
its encryption.

To convert the partitions, run this following:

```
$ ./convert-volume-to-core-storage.sh disk2s2
$ ./convert-volume-to-core-storage.sh disk3s2
```

We have now created encrypted logical volumes, which `./list-volumes.sh` shows
as:

```
/dev/disk4 (external, virtual):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:                  Apple_HFS ADATA1                 +3.0 TB     disk4
                                 Logical Volume on disk2s2
                                 FE33AD56-C280-410B-B54B-85382CA84D75
                                 Unlocked Encrypted

/dev/disk5 (external, virtual):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:                  Apple_HFS Transcend1             +3.0 TB     disk5
                                 Logical Volume on disk3s2
                                 3A7DAF85-DBDB-49A7-AE9B-24D55CA27000
                                 Unlocked Encrypted
```

You should now test your password on this volume. One way is to unmount (eject)
all volumes on the external drive, unplug the USB cable, and plug it back in.
You can eject the disks as follows:

```
$ ./eject-disk.sh ADATA1
$ ./eject-disk.sh Transcend1
```

After pluggin them back in, you should be asked for your password,

At this point, you should let the encryption conversion carry on before doing
anything else. You can check it's status with:

```
$ ./list-core-storage.sh | grep Conversion
```

I first see:

```
Conversion Status:       Converting (forward)
    Conversion Progress:   1%
```

Note that this process can take a _very_ long time. I took around 4 days with my
two 3 TB drives.

*Resources*:

* [Encryption Guide on OpenZFS on OS X](https://openzfsonosx.org/wiki/Encryption)
* `man diskutil`

## Creating a ZFS mirror pool

We're working with two disks, so we're going to create a ZFS mirror pool, in
which the disks are mirror images of each other. In case one fails, the other
has a full copy.

**IMPORTANT NOTE**: You should use volume identifier from `/var/run/disk`
instead of the `/dev` names when referencing your volumes. For example, USB
drives can be mounted at arbitrary `/dev` virtual devices depending on when they
were connected. I found that I lost ZFS pools after disconnecting and
reconnecting the drives. I'm not sure which identifier is the best, but I
decided to go with UUIDs as found in `/var/run/disk/by-id/media-$UUID`. A UUID
can also be used with `diskutil`, which makes it convenient.

To get the volume UUIDS, refer here:

```
$ ./list-volumes.sh
```

Run the following script with the name of the pool first followed by the two
volume UUIDs to use for the pool:

```
$ ./zfs-create-mirror-pool.sh passepartout \
  FE33AD56-C280-410B-B54B-85382CA84D75 \
  3A7DAF85-DBDB-49A7-AE9B-24D55CA27000
```

If this completed without error, you can see the created pool with:

```
$ ./zfs-list.sh
```

*Resources*:

* [Zpool on OpenZFS on OS X](https://openzfsonosx.org/wiki/Zpool)
* [Device names on OpenZFS on OS X](https://openzfsonosx.org/wiki/Device_names)

## Importing a ZFS pool

Import the pool with:

```
$ ./zfs-import.sh passepartout
```

You can see the status of currently connected pools with:

```
$ ./zfs-status.sh
```

## Setting user privileges on the ZFS volume

After the ZFS volume is mounted, it restricts writing to `root`, so you have to
keep typing your password every time you want to copy a file to the volume, for
example. To avoid this, you can change the restrictions to add write permission
for your own user:

1. In the Finder, select the volume.
2. Get Info (⌘ I).
3. Click the closed lock button (🔒) at the bottom and type in your password if
   requested.
4. Click the plus button (⊞) at the bottom to add a new user for permissions.
5. Select your user.
6. Change your user's permission to Read & Write.
7. Click the open lock button (🔓) at the bottom.

*Resources*:

* [Creating user privileges on OpenZFS on OS X](https://openzfsonosx.org/wiki/Creating_user_privileges)
