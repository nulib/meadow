FROM amazonlinux:2023
ARG EXIFTOOL_VERSION=12.70
RUN dnf install -y gzip tar zip
RUN curl -sL https://sourceforge.net/projects/exiftool/files/Image-ExifTool-${EXIFTOOL_VERSION}.tar.gz/download | tar xz
WORKDIR /Image-ExifTool-${EXIFTOOL_VERSION}
CMD ["tar", "-c", "exiftool", "lib"]
