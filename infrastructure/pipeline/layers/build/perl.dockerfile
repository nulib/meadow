FROM amazonlinux:2023
RUN dnf install -y gcc gzip make patch perl-deprecate perl-devel tar 
RUN curl -L https://raw.githubusercontent.com/tokuhirom/Perl-Build/master/perl-build > /tmp/perl-build
ARG PERL_VERSION
RUN perl /tmp/perl-build ${PERL_VERSION} /opt/
RUN curl -L https://cpanmin.us | /opt/bin/perl - App::cpanminus
COPY perl.cpanfile /tmp/cpanfile
RUN /opt/bin/cpanm -n --installdeps /tmp/
RUN cp /lib64/libcrypt* /lib64/libcurl* /opt/lib/
WORKDIR /opt
CMD ["tar", "-c", "."]