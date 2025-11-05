import React from "react";
import PropTypes from "prop-types";
import { Button } from "@nulib/design-system";
import { IconDownload } from "@js/components/Icon";
import classNames from "classnames";
import UIFormField from "@js/components/UI/Form/Field";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { WORK_ARCHIVER_ENDPOINT } from "@js/components/Work/work.gql";
import { useQuery } from "@apollo/client";
import { toastWrapper } from "@js/services/helpers";

/** @jsx jsx */
import { jsx } from "@emotion/react";
import styled from "@emotion/styled";

const Radio = styled.input`
  margin-right: 3px;
`;

const UIDownloadAll = ({ workId }) => {
  const [isModalVisible, setIsModalVisible] = React.useState(false);
  const [width, setWidth] = React.useState("1500");
  const { user } = useIsAuthorized();

  const { loading, error, data } = useQuery(WORK_ARCHIVER_ENDPOINT);

  if (loading) return <p>Loading...</p>;
  if (error) return <p>{error}</p>;

  function handleCancelClick() {
    setIsModalVisible(false);
  }

  function handleRadioChange(e) {
    setWidth(e.target.value);
  }

  function handleSubmit() {
    const url = data.workArchiverEndpoint.url;

    fetch(
      `${url}?${new URLSearchParams({
        workId,
        email: user.email,
        width,
      })}`,
      {
        method: "POST",
      }
    )
      .then((response) => {
        if (!response.ok) {
          throw new Error(
            "Bad network request posting to work archiver endpoint"
          );
        }
        toastWrapper(
          "is-success",
          `Your images are being packaged and you'll receive an email shortly with a link to download.`
        );
        setIsModalVisible(false);
      })
      .catch((error) => console.error(`Error: ${error}`));
  }

  return (
    <>
      <Button
        data-testid="download-all-button"
        onClick={() => setIsModalVisible(true)}
      >
        <IconDownload />
        <span>Download all</span>
      </Button>

      <div
        className={classNames("modal", {
          "is-active": isModalVisible,
        })}
        data-testid="download-all-modal"
      >
        <div className="modal-background"></div>
        <div className="modal-card">
          <div className="modal-card-head">
            <p className="modal-card-title">Download all filesets</p>
            <button
              className="delete"
              aria-label="close"
              onClick={handleCancelClick}
            ></button>
          </div>
          <section className="modal-card-body">
            <UIFormField label="Email">
              <p data-testid="email">{user.email}</p>
            </UIFormField>

            <UIFormField label="Select image width">
              <div className="control" data-testid="radio-image-size">
                <label className="radio">
                  <Radio
                    type="radio"
                    name="width"
                    value="1500"
                    checked={width === "1500"}
                    onChange={handleRadioChange}
                  />
                  1500
                </label>
                <label className="radio">
                  <Radio
                    type="radio"
                    name="width"
                    value="3000"
                    checked={width === "3000"}
                    onChange={handleRadioChange}
                  />
                  3000
                </label>
                <label className="radio">
                  <Radio
                    type="radio"
                    name="width"
                    value="full"
                    checked={width === "full"}
                    onChange={handleRadioChange}
                  />
                  full
                </label>
              </div>
            </UIFormField>
          </section>
          <footer className="modal-card-foot buttons is-right">
            <Button
              isText
              onClick={handleCancelClick}
              aria-label="close"
              data-testid="cancel-button"
            >
              Cancel
            </Button>
            <Button
              isPrimary
              onClick={handleSubmit}
              data-testid="submit-button"
            >
              Start download job
            </Button>
          </footer>
        </div>
      </div>
    </>
  );
};

UIDownloadAll.propTypes = {
  workId: PropTypes.string,
};

export default UIDownloadAll;
