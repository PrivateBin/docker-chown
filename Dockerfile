FROM alpine:3.20

RUN apk add --no-cache \
	gcc \
	gnupg \
	make \
	musl-dev

ENV BUSYBOX_VERSION 1.36.1

RUN set -eux; \
	tarball="busybox-${BUSYBOX_VERSION}.tar.bz2"; \
	wget -O busybox.tar.bz2 "https://busybox.net/downloads/$tarball"; \
	wget -O busybox.tar.bz2.sig "https://busybox.net/downloads/$tarball.sig"; \
# pub   1024D/ACC9965B 2006-12-12
#       Key fingerprint = C9E9 416F 76E6 10DB D09D  040F 47B7 0C55 ACC9 965B
# uid                  Denis Vlasenko <vda.linux@googlemail.com>
# sub   1024g/2C766641 2006-12-12
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys C9E9416F76E610DBD09D040F47B70C55ACC9965B; \
	gpg --batch --verify busybox.tar.bz2.sig busybox.tar.bz2; \
	mkdir -p /usr/src/busybox; \
	tar -xf busybox.tar.bz2 -C /usr/src/busybox --strip-components 1; \
	rm busybox.tar.bz2*

WORKDIR /usr/src/busybox

# see https://wiki.musl-libc.org/wiki/Building_Busybox
COPY config /usr/src/busybox/.config

RUN set -eux; \
	make -j "$(nproc)" \
		busybox \
	; \
	./busybox --help || true; \
	mkdir -p rootfs/bin rootfs/mnt; \
	ln -v busybox rootfs/bin/chown



FROM scratch
LABEL \
	org.opencontainers.image.authors=support@privatebin.org \
	org.opencontainers.image.vendor=PrivateBin \
	org.opencontainers.image.documentation=https://github.com/PrivateBin/docker-chown/blob/master/README.md \
	org.opencontainers.image.source=https://github.com/PrivateBin/docker-chown \
	org.opencontainers.image.licenses=GPL-2.0 \
	org.opencontainers.image.version="${RELEASE}"
COPY --from=0 /usr/src/busybox/rootfs/ /
USER 0
WORKDIR /mnt
VOLUME /mnt
ENTRYPOINT ["/bin/chown"]
