import React from "react";
import type {
  ArchivesSpaceImportPreviewSubscription,
  ArchivesSpaceImportPreviewSubscriptionVariables,
  ArchivesSpaceResourceSearchQuery,
  ArchivesSpaceResourceSearchQueryVariables,
  ImportArchivesSpaceResourceMutation,
  ImportArchivesSpaceResourceMutationVariables,
  StartArchivesSpaceImportPreviewMutation,
  StartArchivesSpaceImportPreviewMutationVariables,
} from "@js/__generated__/graphql";
import { Button, Notification } from "@nulib/design-system";
import {
  useLazyQuery,
  useMutation,
  useSubscription,
} from "@apollo/client/react";
import { useHistory } from "react-router-dom";
import { toastWrapper } from "@js/services/helpers";
import { IconSearch } from "@js/components/Icon";
import { AuthContext } from "@js/components/Auth/Auth";
import UICheckbox from "@js/components/UI/Checkbox";
import UILoader from "@js/components/UI/Loader";
import {
  ARCHIVES_SPACE_IMPORT_PREVIEW_SUBSCRIPTION,
  IMPORT_ARCHIVES_SPACE_RESOURCE,
  SEARCH_ARCHIVES_SPACE_RESOURCES,
  START_ARCHIVES_SPACE_IMPORT_PREVIEW,
} from "@js/components/Project/archivesSpace.gql";

const AI_INGEST_ROLES = ["SUPERUSER", "ADMINISTRATOR", "SUPERMANAGER"];

function isPresent<T>(value: T | null | undefined): value is T {
  return value != null;
}

type Props = {
  closeModal: () => void;
  isHidden: boolean;
};

function ProjectArchivesSpaceImportModal({ closeModal, isHidden }: Props) {
  const history = useHistory();
  const currentUser = React.useContext(AuthContext);
  const [searchValue, setSearchValue] = React.useState("");
  const [selectedUri, setSelectedUri] = React.useState<string | null>(null);
  const [aiIngest, setAiIngest] = React.useState(false);
  const [understood, setUnderstood] = React.useState(false);
  const [previewUri, setPreviewUri] = React.useState<string | null>(null);
  const [previewToken, setPreviewToken] = React.useState<string | null>(null);
  const canAiIngest = AI_INGEST_ROLES.includes(currentUser?.role);

  const [searchResources, { data, loading, error }] = useLazyQuery<
    ArchivesSpaceResourceSearchQuery,
    ArchivesSpaceResourceSearchQueryVariables
  >(SEARCH_ARCHIVES_SPACE_RESOURCES, {
    fetchPolicy: "no-cache",
  });

  // Generation runs in the background; the start mutation returns a token and
  // the finished preview arrives over the subscription. This survives the
  // proxy's request timeout, which a synchronous query would not.
  const [startPreview, { loading: startLoading }] = useMutation<
    StartArchivesSpaceImportPreviewMutation,
    StartArchivesSpaceImportPreviewMutationVariables
  >(START_ARCHIVES_SPACE_IMPORT_PREVIEW, {
    fetchPolicy: "no-cache",
    onCompleted({ archivesSpaceStartImportPreview }) {
      setPreviewToken(archivesSpaceStartImportPreview?.token || null);
    },
    onError({ message }) {
      toastWrapper("is-danger", message);
      setPreviewToken(null);
    },
  });

  const { data: subData } = useSubscription<
    ArchivesSpaceImportPreviewSubscription,
    ArchivesSpaceImportPreviewSubscriptionVariables
  >(ARCHIVES_SPACE_IMPORT_PREVIEW_SUBSCRIPTION, {
    variables: { token: previewToken || "" },
    skip: !previewToken,
    fetchPolicy: "no-cache",
  });

  const [importResource, { loading: importLoading }] = useMutation<
    ImportArchivesSpaceResourceMutation,
    ImportArchivesSpaceResourceMutationVariables
  >(IMPORT_ARCHIVES_SPACE_RESOURCE, {
    onCompleted({ importArchivesSpaceResource }) {
      if (!importArchivesSpaceResource?.id) {
        toastWrapper(
          "is-danger",
          "Unknown error importing the ArchivesSpace collection",
        );
        return;
      }

      toastWrapper(
        "is-success",
        `Import of ${
          importArchivesSpaceResource.title || "collection"
        } started. Works will appear in the collection as they are created.`,
      );
      handleClose();
      history.push(`/collection/${importArchivesSpaceResource.id}`);
    },
    onError({ graphQLErrors }) {
      const messages =
        graphQLErrors?.length > 0
          ? graphQLErrors.map(({ message }) => message).join(" \n ")
          : "Unknown error importing the ArchivesSpace collection";
      toastWrapper("is-danger", messages);
    },
  });

  const searchResults =
    data?.archivesSpaceResourceSearch?.results?.filter(isPresent) || [];
  const selectedResource = searchResults.find(({ uri }) => uri === selectedUri);
  const selectedValidation = selectedResource?.importValidation;
  const selectedBlocked = selectedValidation?.importable === false;

  // An AI ingest must be previewed and acknowledged before it can run.
  const needsPreview = canAiIngest && aiIngest;
  // A preview is "terminal" once the agent finishes (complete or error) for
  // the token we're currently waiting on.
  const subPreview = subData?.archivesSpaceImportPreview;
  const preview =
    subPreview &&
    subPreview.token === previewToken &&
    subPreview.status !== "PENDING"
      ? subPreview
      : null;
  const previewLoading =
    needsPreview && (startLoading || Boolean(previewToken && !preview));
  // The preview only applies to the resource it was generated for; changing
  // the selection (or toggling AI ingest) makes it stale.
  const previewReady = Boolean(
    preview && previewUri === selectedUri && needsPreview,
  );

  const resetPreview = () => {
    setPreviewUri(null);
    setPreviewToken(null);
    setUnderstood(false);
  };

  const handleClose = () => {
    setSearchValue("");
    setSelectedUri(null);
    setAiIngest(false);
    resetPreview();
    closeModal();
  };

  const handleSearch = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setSelectedUri(null);
    resetPreview();
    if (searchValue) {
      searchResources({ variables: { query: searchValue } });
    }
  };

  const handleSelect = (uri: string) => {
    setSelectedUri(uri);
    resetPreview();
  };

  const handleImport = () => {
    if (selectedUri && !selectedBlocked) {
      importResource({
        variables: {
          resourceUri: selectedUri,
          aiIngest: canAiIngest ? aiIngest : false,
        },
      });
    }
  };

  // When AI ingest is enabled, the primary button first kicks off a preview;
  // once the preview is acknowledged it performs the actual import.
  const handlePrimary = () => {
    if (!selectedUri || selectedBlocked) {
      return;
    }

    if (needsPreview && !previewReady) {
      setUnderstood(false);
      setPreviewToken(null);
      setPreviewUri(selectedUri);
      startPreview({ variables: { resourceUri: selectedUri } });
    } else {
      handleImport();
    }
  };

  const primaryLabel = previewLoading
    ? "Generating preview…"
    : needsPreview && !previewReady
      ? "Generate preview"
      : "Import collection";

  // Only require acknowledgment when there are previews to review; an empty or
  // errored preview result still lets the import proceed.
  const requiresAck =
    previewReady &&
    preview?.status === "COMPLETE" &&
    preview.previews.filter(isPresent).length > 0;
  const primaryDisabled =
    !selectedUri ||
    selectedBlocked ||
    importLoading ||
    previewLoading ||
    (requiresAck && !understood);

  return (
    <div
      className={`modal ${isHidden ? "" : "is-active"}`}
      data-testid="archivesspace-import-modal"
    >
      <div className="modal-background"></div>
      <div
        className="modal-card"
        style={{ width: "min(1100px, 90vw)", maxWidth: "90vw" }}
      >
        <header className="modal-card-head">
          <p className="modal-card-title">Ingest from ArchivesSpace</p>
          <button
            className="delete"
            aria-label="close"
            onClick={handleClose}
          ></button>
        </header>
        <section className="modal-card-body">
          <form onSubmit={handleSearch} data-testid="archivesspace-search-form">
            <div className="field has-addons">
              <div className="control is-expanded">
                <input
                  className="input"
                  type="text"
                  placeholder="Search ArchivesSpace collections"
                  aria-label="Search ArchivesSpace collections"
                  value={searchValue}
                  onChange={(e) => setSearchValue(e.target.value)}
                />
              </div>
              <div className="control">
                <Button type="submit" isPrimary disabled={!searchValue}>
                  <IconSearch />
                  <span>Search</span>
                </Button>
              </div>
            </div>
          </form>

          {error && (
            <Notification isDanger data-testid="archivesspace-search-error">
              {error.toString()}
            </Notification>
          )}

          {loading && <p>Searching…</p>}

          {data && searchResults.length === 0 && (
            <p data-testid="archivesspace-no-results">
              No ArchivesSpace collections match your search.
            </p>
          )}

          {searchResults.length > 0 && (
            <table
              className="table is-fullwidth is-hoverable mt-4"
              data-testid="archivesspace-search-results"
            >
              <thead>
                <tr>
                  <th></th>
                  <th>Title</th>
                  <th>Identifier</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {searchResults.map((result) => {
                  const validation = result.importValidation;
                  const blocked = validation?.importable === false;

                  return (
                    <tr key={result.uri}>
                      <td>
                        <input
                          type="radio"
                          name="archivesspace-resource"
                          aria-label={`Select ${result.title || result.uri}`}
                          checked={selectedUri === result.uri}
                          disabled={blocked}
                          onChange={() => handleSelect(result.uri)}
                        />
                      </td>
                      <td>{result.title}</td>
                      <td>{result.identifier}</td>
                      <td>
                        {blocked ? (
                          <span
                            className="tag is-warning"
                            data-testid="archivesspace-blocked-tag"
                          >
                            Already linked to Digital Collections
                          </span>
                        ) : (
                          <span className="tag is-success">Importable</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}

          {searchResults.some(
            ({ importValidation }) => importValidation?.importable === false,
          ) && (
            <Notification isWarning data-testid="archivesspace-import-blocked">
              Some matching finding aids already contain digital object links to
              Digital Collections or ARK records. Those resources are shown for
              context, but cannot be previewed or imported.
            </Notification>
          )}

          {previewLoading && (
            <div
              className="box has-text-centered mt-4"
              data-testid="archivesspace-preview-loading"
            >
              <p className="has-text-weight-semibold">Generating AI preview</p>
              <p className="has-text-grey">
                The metadata agent is analyzing sample images. This usually
                takes a minute or two — you can leave this modal open.
              </p>
              <div style={{ display: "flex", justifyContent: "center" }}>
                <UILoader />
              </div>
            </div>
          )}

          {previewReady && preview && (
            <div className="mt-5" data-testid="archivesspace-preview">
              <h2 className="title is-5">AI-Generated Preview</h2>

              {preview.status === "ERROR" ? (
                <Notification
                  isDanger
                  data-testid="archivesspace-preview-error"
                >
                  The AI preview could not be generated
                  {preview.error ? `: ${preview.error}` : "."} You can still
                  import the collection.
                </Notification>
              ) : preview.previews.filter(isPresent).length === 0 ? (
                <Notification>
                  No archival objects with images were found to preview. You can
                  still import the collection.
                </Notification>
              ) : (
                <>
                  <p className="mb-4">
                    Showing AI metadata for {preview.sampleCount} of{" "}
                    {preview.totalCount} archival objects.
                    {preview.estimatedCost != null && (
                      <>
                        {" "}
                        Estimated total cost:{" "}
                        <strong>
                          ${preview.estimatedCost.toFixed(2)}
                        </strong>{" "}
                        (actual cost may vary).
                      </>
                    )}
                  </p>
                  <div className="table-container">
                    <table className="table is-fullwidth is-striped">
                      <thead>
                        <tr>
                          <th style={{ width: "120px" }}>
                            <span className="is-sr-only">Thumbnail</span>
                          </th>
                          <th>Title</th>
                          <th>Description</th>
                          <th style={{ minWidth: "200px" }}>Subjects</th>
                        </tr>
                      </thead>
                      <tbody>
                        {preview.previews.filter(isPresent).map((item) => (
                          <tr key={item.workAccessionNumber}>
                            <td>
                              {item.thumbnail && (
                                <figure
                                  className="image"
                                  style={{
                                    width: "100px",
                                    height: "100px",
                                    margin: 0,
                                  }}
                                >
                                  <img
                                    src={`data:image/jpeg;base64,${item.thumbnail}`}
                                    alt={item.workAccessionNumber || ""}
                                    style={{
                                      width: "100%",
                                      height: "100%",
                                      objectFit: "cover",
                                      borderRadius: "0.25rem",
                                    }}
                                  />
                                </figure>
                              )}
                            </td>
                            <td>{item.title}</td>
                            <td>{item.description}</td>
                            <td>
                              {item.subjects &&
                                item.subjects.filter(isPresent).length > 0 && (
                                  <div className="content">
                                    <ul style={{ marginTop: 0 }}>
                                      {item.subjects
                                        .filter(isPresent)
                                        .map((subject) => (
                                          <li key={subject.id || subject.label}>
                                            <a
                                              href={subject.id || "#"}
                                              target="_blank"
                                              rel="noreferrer"
                                            >
                                              {subject.label}
                                            </a>
                                          </li>
                                        ))}
                                    </ul>
                                  </div>
                                )}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  <div className="field mt-4">
                    <label className="checkbox">
                      <input
                        type="checkbox"
                        checked={understood}
                        onChange={(e) => setUnderstood(e.target.checked)}
                        className="mr-2"
                        data-testid="archivesspace-preview-understood"
                      />
                      I understand that importing this collection with AI
                      metadata will generate metadata for every imported work.
                    </label>
                  </div>
                </>
              )}
            </div>
          )}
        </section>
        <footer className="modal-card-foot is-justify-content-space-between">
          {canAiIngest ? (
            <UICheckbox
              checked={aiIngest}
              onChange={setAiIngest}
              label="Enable AI-generated metadata"
              disabled={false}
              className=""
            />
          ) : (
            <div></div>
          )}
          <div className="buttons">
            <Button isText onClick={handleClose}>
              Cancel
            </Button>
            <Button
              isPrimary
              data-testid="button-import-resource"
              disabled={primaryDisabled}
              onClick={handlePrimary}
            >
              {primaryLabel}
            </Button>
          </div>
        </footer>
      </div>
    </div>
  );
}

export default ProjectArchivesSpaceImportModal;
