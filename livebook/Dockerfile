FROM ghcr.io/livebook-dev/livebook:edge
ENV LIVEBOOK_IDENTITY_PROVIDER=custom:MeadowLivebookAuth
ENV LIVEBOOK_DISTRIBUTION=sname
ENV LIVEBOOK_IP=0.0.0.0
ENV LIVEBOOK_DATA_PATH=/data
ENV LIVEBOOK_HOME=${LIVEBOOK_DATA_PATH}/books
RUN mkdir -p ${LIVEBOOK_DATA_PATH}/books
RUN apt update -qq && apt install -y curl jq && apt clean
ADD https://raw.githubusercontent.com/sormy/aws-curl/master/aws-curl /usr/local/bin
ADD ./aws-s3 /usr/local/bin/aws-s3
ADD ./meadow_livebook_auth.exs /app/user/extensions/meadow_livebook_auth.exs
RUN chmod 0755 /usr/local/bin/aws-curl /usr/local/bin/aws-s3
