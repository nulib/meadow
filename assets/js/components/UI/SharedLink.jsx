import React from "react";
import PropTypes from "prop-types";
import classNames from "classnames";
import { IconAlert } from "@js/components/Icon";
import UIIconText from "@js/components/UI/IconText";
import { useClipboard } from "use-clipboard-copy";
import { Button } from "@nulib/admin-react-components";

function UISharedLink({
  isSuccess,
  isWarning,
  shareUrl,
  children,
  ...restProps
}) {
  const clipboard = useClipboard({
    copiedTimeout: 10000,
  });

  return (
    <div
      className={classNames(
        ["notification", "has-text-centered", "is-light", "my-5"],
        {
          "is-success": isSuccess,
          "is-warning": isWarning,
        }
      )}
      {...restProps}
    >
      <p>
        <UIIconText isCentered icon={<IconAlert size="21px" />}>
          {children}
        </UIIconText>
      </p>
      <p data-testid="link-url">
        <a href={shareUrl} target="_blank">
          {shareUrl}
        </a>
      </p>
      <p>
        <Button
          className={classNames({
            "is-success": isSuccess,
            "is-warning": isWarning,
          })}
          onClick={() => clipboard.copy(shareUrl)}
        >
          {clipboard.copied ? "Copied!" : "Copy Link"}
        </Button>
      </p>
    </div>
  );
}

UISharedLink.propTypes = {
  isSuccess: PropTypes.bool,
  isWarning: PropTypes.bool,
  shareUrl: PropTypes.string,
  children: PropTypes.node,
};

export default UISharedLink;
