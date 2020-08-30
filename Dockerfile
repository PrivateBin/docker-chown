FROM alpine:3.12

RUN apk add --no-cache \
	bzip2 \
	coreutils \
	curl \
	gcc \
	gnupg \
	linux-headers \
	make \
	musl-dev \
	tzdata

# pub   1024D/ACC9965B 2006-12-12
#       Key fingerprint = C9E9 416F 76E6 10DB D09D  040F 47B7 0C55 ACC9 965B
# uid                  Denis Vlasenko <vda.linux@googlemail.com>
# sub   1024g/2C766641 2006-12-12
RUN gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys C9E9416F76E610DBD09D040F47B70C55ACC9965B

ENV BUSYBOX_VERSION 1.31.1

RUN set -eux; \
	tarball="busybox-${BUSYBOX_VERSION}.tar.bz2"; \
	curl -fL -o busybox.tar.bz2 "https://busybox.net/downloads/$tarball"; \
	curl -fL -o busybox.tar.bz2.sig "https://busybox.net/downloads/$tarball.sig"; \
	gpg --batch --verify busybox.tar.bz2.sig busybox.tar.bz2; \
	mkdir -p /usr/src/busybox; \
	tar -xf busybox.tar.bz2 -C /usr/src/busybox --strip-components 1; \
	rm busybox.tar.bz2*

WORKDIR /usr/src/busybox

# https://www.mail-archive.com/toybox@lists.landley.net/msg02528.html
# https://www.mail-archive.com/toybox@lists.landley.net/msg02526.html
RUN sed -i 's/^struct kconf_id \*$/static &/g' scripts/kconfig/zconf.hash.c_shipped

# see https://wiki.musl-libc.org/wiki/Building_Busybox
COPY config /usr/src/busybox/.config

RUN set -eux; \
	make -j "$(nproc)" \
		busybox \
	; \
	./busybox --help || true; \
	mkdir -p rootfs/bin rootfs/mnt; \
	ln -vL busybox rootfs/bin/chown



FROM scratch
COPY --from=0 /usr/src/busybox/rootfs/ /
USER 0
WORKDIR /mnt
VOLUME /mnt
ENTRYPOINT ["/bin/chown"]
