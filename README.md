These are instructions for downloading, installing, and configuring [OpenZFS on
OS X](https://openzfsonosx.org/) on macOS 10.12 (Sierra).

# Instructions

These instructions apply to my situation. They are not comprehensive, but might
be helpful in figuring out the instructions your own situation.

## Installing OpenZFS

Install using [Homebrew](https://brew.sh/):

```
$ ./install-openzfs.sh
```

*Resources*:

* [Installation Guide on OpenZFS on OS X](https://openzfsonosx.org/wiki/Install)
* [`openzfs` for `homebrew-cask`](https://github.com/caskroom/homebrew-cask/blob/master/Casks/openzfs.rb)

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

*Resources*:

* [Encryption Guide on OpenZFS on OS X](https://openzfsonosx.org/wiki/Encryption)
* `man diskutil`

## Creating a ZFS mirror pool

We're working with two disks, so we're going to create a ZFS mirror pool, in
which the disks are mirror images of each other. In case one fails, the other
has a full copy.

```
$ ./create-zfs-mirror-pool.sh brobdingnag disk4 disk5
```

*Resources*:

* [Zpool on OpenZFS on OS X](https://openzfsonosx.org/wiki/Zpool)
* `man diskutil`
