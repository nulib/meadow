import useAcceptedMimeTypes from "@js/hooks/useAcceptedMimeTypes";
import { LIST_INGEST_BUCKET_OBJECTS } from "@js/components/Work/work.gql.js";
import React, {
  forwardRef,
  useEffect,
  useImperativeHandle,
  useMemo,
  useRef,
  useState,
} from "react";
import { useQuery } from "@apollo/client";
import Error from "@js/components/UI/Error";
import { FaSpinner } from "react-icons/fa";

const path = {
  basename: (path) => path.split("/").pop(),
  join: (...args) =>
    args
      .join("/")
      .replace(/\/+/g, "/")
      .replace(/(^\/)|(\/$)/, ""),
};

const S3ObjectProvider = forwardRef(
  ({ fileSetRole, workTypeId, prefix = "", children }, ref) => {
    const [files, setFiles] = useState([]);

    const { isFileValid } = useAcceptedMimeTypes();

    const {
      loading: queryLoading,
      error: queryError,
      data,
      refetch,
    } = useQuery(LIST_INGEST_BUCKET_OBJECTS, {
      variables: { prefix },
    });

    useImperativeHandle(ref, () => ({
      findFileSetByUri: (value) => {
        const objects = data?.ListIngestBucketObjects?.objects;
        if (!objects) return null;

        const found = objects.find(({ uri }) => uri == value);
        return { ...found, key: found.uri, uri: undefined };
      },
    }));

    useEffect(() => {
      if (!data) return;
      const { ListIngestBucketObjects: contents } = data;
      const newFiles = contents.objects
        .filter((entry) => {
          const { isValid } = isFileValid(fileSetRole, workTypeId, entry.mimeType);
          return isValid;
        })
        .map((entry) => {
          return {
            id: entry.uri,
            name: path.basename(entry.key),
            size: Number(entry.size),
            modDate: entry.lastModified,
            isDir: false,
            icon: entry.mimeType.split("/")[0],
          };
        })
        .concat(
          contents.folders.map((entry) => {
            return {
              id: entry,
              name: path.basename(entry),
              isDir: true,
            };
          }),
        );
      setFiles(newFiles);
    }, [data, setFiles]);

    useEffect(() => {
      refetch();
    }, [prefix]);

    const folderChain = useMemo(() => {
      const parts = prefix.split("/").filter((part) => part !== "");
      let id = "";

      const result = parts.map((part) => {
        id = path.join(id, part);
        return { id: id, name: part, isDir: true, icon: "" };
      });
      result.unshift({ id: "/", name: "ingest", isDir: true, icon: "" });
      return result;
    }, [prefix]);

    const childrenWithProps = React.Children.map(children, (child) =>
      React.cloneElement(child, { files, folderChain }),
    );

    if (queryLoading) return <FaSpinner className="spinner" />;
    if (queryError) return <Error error={queryError} />;

    return <>{childrenWithProps}</>;
  },
);

export default S3ObjectProvider;
