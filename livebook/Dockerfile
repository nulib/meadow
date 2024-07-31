FROM ghcr.io/livebook-dev/livebook:latest
ENV LIVEBOOK_AWS_CREDENTIALS=true
ENV LIVEBOOK_DATA_PATH=/data
ENV LIVEBOOK_DISTRIBUTION=name
ENV LIVEBOOK_HOME=${LIVEBOOK_DATA_PATH}/books
ENV LIVEBOOK_IDENTITY_PROVIDER=custom:MeadowLivebookAuth
ENV LIVEBOOK_IP=0.0.0.0
ENV LIVEBOOK_TOKEN_ENABLED=false
RUN mkdir -p ${LIVEBOOK_DATA_PATH}/books
ADD ./meadow_livebook_auth.exs /app/user/extensions/meadow_livebook_auth.exs
