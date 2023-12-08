FROM ghcr.io/livebook-dev/livebook:edge
ENV LIVEBOOK_IDENTITY_PROVIDER=custom:MeadowLivebookAuth
ENV LIVEBOOK_DISTRIBUTION=sname
ENV LIVEBOOK_IP=0.0.0.0
ENV LIVEBOOK_DATA_PATH=/data
ENV LIVEBOOK_HOME=${LIVEBOOK_DATA_PATH}/books
RUN mkdir -p ${LIVEBOOK_DATA_PATH}/books
ADD ./meadow_livebook_auth.exs /app/user/extensions/meadow_livebook_auth.exs
