import React from "react";
import PropTypes from "prop-types";
import classNames from "classnames";
import { IconAlert } from "@js/components/Icon";
import UIIconText from "@js/components/UI/IconText";
import { useClipboard } from "use-clipboard-copy";
import { Button, Notification } from "@nulib/design-system";

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
    <Notification isCentered className={classNames(["my-5"])} {...restProps}>
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
        <Button isPrimary onClick={() => clipboard.copy(shareUrl)}>
          {clipboard.copied ? "Copied!" : "Copy Link"}
        </Button>
      </p>
    </Notification>
  );
}

UISharedLink.propTypes = {
  isSuccess: PropTypes.bool,
  isWarning: PropTypes.bool,
  shareUrl: PropTypes.string,
  children: PropTypes.node,
};

export default UISharedLink;
