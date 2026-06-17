import React from "react";
import { useQuery } from "@apollo/client/react";
import { Link } from "react-router-dom";
import { Button } from "@nulib/design-system";
import { LIST_ARCHIVES_SPACE_IMPORTS } from "@js/components/Project/archivesSpace.gql";
import ProjectArchivesSpaceImportModal from "@js/components/Project/ArchivesSpaceImportModal";
import AuthDisplayAuthorized from "@js/components/Auth/DisplayAuthorized";
import { IconExternalLink, IconImages, IconSearch } from "@js/components/Icon";
import { formatDate } from "@js/services/helpers";
import useFacetLinkClick from "@js/hooks/useFacetLinkClick";

export default function DashboardsArchivesSpaceList() {
  const [isModalHidden, setIsModalHidden] = React.useState(true);
  const { handleFacetLinkClick } = useFacetLinkClick();

  const { loading, error, data } = useQuery(LIST_ARCHIVES_SPACE_IMPORTS, {
    fetchPolicy: "cache-and-network",
  });

  const imports = data?.archivesSpaceImports || [];

  return (
    <div data-testid="archivesspace-imports">
      <div className="buttons is-justify-content-flex-end">
        <AuthDisplayAuthorized level="MANAGER">
          <Button
            isPrimary
            data-testid="button-archivesspace-ingest"
            onClick={() => setIsModalHidden(false)}
          >
            <span className="icon">
              <IconSearch />
            </span>
            <span>Ingest from ArchivesSpace</span>
          </Button>
        </AuthDisplayAuthorized>
      </div>

      {error && (
        <p data-testid="archivesspace-imports-error">{error.toString()}</p>
      )}

      {!loading && imports.length === 0 && (
        <p data-testid="archivesspace-imports-empty">
          No ArchivesSpace resources have been imported yet.
        </p>
      )}

      {imports.length > 0 && (
        <div className="table-container">
          <table
            className="table is-striped is-fullwidth"
            data-testid="archivesspace-imports-table"
          >
            <thead>
              <tr>
                <th>Finding Aid</th>
                <th>ArchivesSpace URI</th>
                <th>Works</th>
                <th>Sync Status</th>
                <th>Imported</th>
                <th></th>
              </tr>
            </thead>
            <tbody data-testid="archivesspace-imports-body">
              {imports.map((record) => {
                const {
                  id,
                  archivesSpaceUri,
                  findingAidUrl,
                  syncStatus,
                  workCount,
                  insertedAt,
                  collection,
                } = record;

                return (
                  <tr key={id} data-testid="archivesspace-import-row">
                    <td>
                      {collection ? (
                        <Link to={`/collection/${collection.id}`}>
                          {collection.title}
                        </Link>
                      ) : (
                        archivesSpaceUri
                      )}
                    </td>
                    <td>
                      <code>{archivesSpaceUri}</code>
                    </td>
                    <td>{workCount}</td>
                    <td>{syncStatus}</td>
                    <td>{formatDate(insertedAt)}</td>
                    <td>
                      <div className="field is-grouped is-justify-content-flex-end">
                        {collection && (
                          <Button
                            isLight
                            data-testid="button-view-works"
                            title="View works in search"
                            onClick={() =>
                              handleFacetLinkClick(
                                "Collection",
                                collection.title,
                              )
                            }
                          >
                            <IconImages />
                          </Button>
                        )}
                        {findingAidUrl && (
                          <a
                            className="button is-light"
                            href={findingAidUrl}
                            target="_blank"
                            rel="noreferrer"
                            title="Open finding aid"
                            data-testid="link-finding-aid"
                          >
                            <IconExternalLink />
                          </a>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      <ProjectArchivesSpaceImportModal
        closeModal={() => setIsModalHidden(true)}
        isHidden={isModalHidden}
      />
    </div>
  );
}
