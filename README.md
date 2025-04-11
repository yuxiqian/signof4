# "The Sign of the Four"

Simplify the chores of verifying release candidates of ASF software.

## Verify SHA checksum and GPG signatures

* Install `gpg` and `wget`
* Import ASF keys with commands like `wget -O KEYS https://dist.apache.org/repos/dist/release/flink/KEYS && gpg --import KEYS`
* Run `export LANG=en` in localized environments
* Run `ruby verify.rb https://dist.apache.org/repos/dist/dev/flink/flink-connector-jdbc-3.3.0-rc1/ [...]`. It will recursively verify every tarball's checksum and signatures.

> The trailing slash (`/`) is required.

```shell
$ruby verify.rb https://dist.apache.org/repos/dist/dev/flink/flink-connector-jdbc-3.3.0-rc1/
===== Verifying dist - Revision 76200: /dev/flink/flink-connector-jdbc-3.3.0-rc1 =====
✅ SHA512 of flink-connector-jdbc-3.3.0-src.tgz matches.
✅ GPG signature of flink-connector-jdbc-3.3.0-src.tgz is valid.
   Ruan Hang <ruanhang1993@apache.org>
```

Verified tarballs will be saved in `./tmp` directory for further verification.

## Detect Jar compiling JDK version and Bytecode version

* Run `ruby jar-poker.rb XXX.jar [...]`

```shell
$ruby jar-poker.rb ./tmp/flink-connector-jdbc-3.3.0-1.20.jar
Summary: /Users/yux/Downloads/flink-connector-jdbc-3.3.0-1.20.jar
was built with JDK 1.8.0_301 and Apache Maven 3.8.6
Bytecode version is: 52.0
```
